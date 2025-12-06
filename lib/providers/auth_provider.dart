import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// Auth Provider - Manages authentication state
/// Handles login, logout, and user profile management
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isLoadingProfile = false; // Prevent duplicate profile loads

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  UserRole? get userRole => _currentUser?.role;

  AuthProvider() {
    // Initialize auth asynchronously to prevent blocking UI
    Future.microtask(() => _initAuth());
  }

  /// Initialize auth state
  Future<void> _initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if user is already logged in
      final user = _authService.currentUser;
      debugPrint('🔐 Init: Current user from Supabase: ${user?.email}');
      
      if (user != null) {
        try {
          final profile = await _authService.getUserProfile(user.id);
          if (profile != null) {
            _currentUser = profile;
            debugPrint('✅ Init: User profile loaded: ${_currentUser?.email}, role: ${_currentUser?.role}');
          } else {
            debugPrint('⚠️ Init: Profile is null for user ${user.id}');
          }
        } catch (e) {
          debugPrint('❌ Init: Error loading user profile: $e');
          _currentUser = null;
        }
      } else {
        debugPrint('🔐 Init: No current user session found');
      }

      // Listen to auth state changes
      _authService.authStateChanges.listen((authState) {
        debugPrint('🔐 Auth state changed: ${authState.event}');
        
        if (authState.event == AuthChangeEvent.signedIn || 
            authState.event == AuthChangeEvent.initialSession ||
            authState.event == AuthChangeEvent.tokenRefreshed) {
          final user = authState.session?.user;
          if (user != null) {
            // Load profile asynchronously without blocking
            _loadUserProfile(user.id);
          }
        } else if (authState.event == AuthChangeEvent.signedOut) {
          debugPrint('🔐 User signed out');
          _currentUser = null;
          _isLoading = false;
          notifyListeners();
        } else {
          debugPrint('🔐 Auth event (no action): ${authState.event}');
        }
      });
    } catch (e) {
      _error = e.toString();
      debugPrint('Auth initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user profile asynchronously (helper for auth state listener)
  Future<void> _loadUserProfile(String userId) async {
    // Prevent duplicate profile loads
    if (_isLoadingProfile) {
      debugPrint('⚠️ Profile load already in progress, skipping...');
      return;
    }
    
    // If we already have the current user, skip loading
    if (_currentUser?.id == userId) {
      debugPrint('✅ Profile already loaded for user $userId, skipping...');
      return;
    }
    
    _isLoadingProfile = true;
    _isLoading = true;
    notifyListeners();
    
    try {
      final profile = await _authService.getUserProfile(userId);
      if (profile != null) {
        _currentUser = profile;
        debugPrint('✅ User profile loaded: ${_currentUser?.email}, role: ${_currentUser?.role}');
      } else {
        debugPrint('⚠️ Profile is null for user $userId');
      }
    } catch (e) {
      debugPrint('❌ Error loading user profile: $e');
    } finally {
      _isLoadingProfile = false;
      _isLoading = false;
      notifyListeners();
      debugPrint('🔐 Auth state processed: isAuth=$isAuthenticated, user=${_currentUser?.email}');
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔐 AuthProvider: Attempting sign in for: $email');
      final userProfile = await _authService.signIn(
        email: email,
        password: password,
      );
      
      debugPrint('🔐 AuthProvider: Sign in response received');
      
      if (userProfile != null) {
        _currentUser = userProfile;
        _isLoading = false;
        debugPrint('✅ AuthProvider: Sign in successful: ${_currentUser?.email}, role: ${_currentUser?.role}');
        debugPrint('✅ AuthProvider: Current user set, isAuthenticated: $isAuthenticated');
        notifyListeners();
        
        // Extra delay to ensure all listeners process the change
        await Future.delayed(const Duration(milliseconds: 50));
        debugPrint('✅ AuthProvider: State fully propagated');
        
        return true;
      } else {
        debugPrint('❌ AuthProvider: Sign in returned null user profile');
        throw Exception('Failed to load user profile after login');
      }
    } catch (e) {
      debugPrint('❌ AuthProvider: Sign in error: $e');
      _error = e.toString();
      _currentUser = null; // Ensure user is cleared on error
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Sign out error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create new user (Admin only)
  Future<UserProfile?> createUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    if (_currentUser?.role != UserRole.admin) {
      _error = 'Only admins can create users';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newUser = await _authService.createUser(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        createdByUserId: _currentUser!.id,
      );

      _isLoading = false;
      notifyListeners();
      return newUser;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Get all users (Admin only)
  Future<List<UserProfile>> getAllUsers() async {
    if (_currentUser?.role != UserRole.admin) {
      return [];
    }

    try {
      return await _authService.getAllUsers();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile({
    required String userId,
    String? fullName,
    bool? isActive,
  }) async {
    if (_currentUser?.role != UserRole.admin) {
      _error = 'Only admins can update users';
      notifyListeners();
      return false;
    }

    try {
      await _authService.updateUserProfile(
        userId: userId,
        fullName: fullName,
        isActive: isActive,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete user (Admin only)
  Future<bool> deleteUser(String userId) async {
    if (_currentUser?.role != UserRole.admin) {
      _error = 'Only admins can delete users';
      notifyListeners();
      return false;
    }

    try {
      await _authService.deleteUser(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Permission checks
  bool get canAccessSettings => _currentUser?.canAccessSettings ?? false;
  bool get canAccessDashboard => _currentUser?.canAccessDashboard ?? false;
  bool get canAccessRevenue => _currentUser?.canAccessRevenue ?? false;
  bool get canAccessTransactions => _currentUser?.canAccessTransactions ?? false;
  bool get canManageUsers => _currentUser?.canManageUsers ?? false;
  bool get canManageInventory => _currentUser?.canManageInventory ?? false;
  bool get canManageStaff => _currentUser?.canManageStaff ?? false;
  bool get canDeleteTransactions => _currentUser?.canDeleteTransactions ?? false;
  bool get canEditTransactions => _currentUser?.canEditTransactions ?? false;
}
