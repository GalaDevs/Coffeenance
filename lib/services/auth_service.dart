import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'package:flutter/foundation.dart';

/// Authentication Service
/// Handles all authentication operations using Supabase Auth
class AuthService {
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (e) {
      debugPrint('Supabase client not available: $e');
      return null;
    }
  }

  /// Get current authenticated user
  User? get currentUser {
    try {
      return _supabase?.auth.currentUser;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  /// Get current user session
  Session? get currentSession {
    try {
      return _supabase?.auth.currentSession;
    } catch (e) {
      debugPrint('Error getting current session: $e');
      return null;
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Sign in with email and password
  Future<UserProfile?> signIn({
    required String email,
    required String password,
  }) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized. Please configure valid credentials.');
    }
    
    try {
      debugPrint('🔐 AuthService: Starting sign in for $email');
      
      final response = await _supabase!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint('🔐 AuthService: Auth response received');
      debugPrint('🔐 AuthService: User ID: ${response.user?.id}');
      debugPrint('🔐 AuthService: Session: ${response.session != null ? "exists" : "null"}');

      if (response.user == null) {
        throw Exception('Login failed: No user returned');
      }

      // Fetch user profile
      debugPrint('🔐 AuthService: Fetching user profile for ${response.user!.id}');
      final profile = await getUserProfile(response.user!.id);
      debugPrint('🔐 AuthService: Profile fetched: ${profile?.email}, role: ${profile?.role}');
      
      return profile;
    } on AuthException catch (e) {
      debugPrint('❌ AuthService: Auth exception: ${e.message}');
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      debugPrint('❌ AuthService: Error: $e');
      throw Exception('Login failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }
    try {
      await _supabase!.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Get user profile from database
  Future<UserProfile?> getUserProfile(String userId) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }
    try {
      debugPrint('🔐 AuthService: Querying user_profiles for userId: $userId');
      
      final response = await _supabase!
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      debugPrint('🔐 AuthService: Query response: $response');
      
      if (response == null) {
        debugPrint('⚠️ AuthService: No profile found for user $userId');
        debugPrint('⚠️ Creating default profile...');
        
        // Get user email from auth
        final user = _supabase!.auth.currentUser;
        final email = user?.email ?? 'unknown@email.com';
        
        // Create a default profile
        final newProfile = {
          'id': userId,
          'email': email,
          'role': 'staff', // Default role
          'full_name': email.split('@')[0],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        await _supabase!.from('user_profiles').insert(newProfile);
        
        return UserProfile.fromJson(newProfile);
      }

      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('❌ AuthService: Error fetching profile: $e');
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  /// Create a new user account (Admin only)
  /// This creates both auth user and profile
  Future<UserProfile> createUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    required String createdByUserId,
  }) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }
    try {
      // Check if current user is admin
      final currentProfile = await getUserProfile(createdByUserId);
      if (currentProfile?.role != UserRole.admin) {
        throw Exception('Only admins can create new users');
      }

      // Validate account limits
      if (role == UserRole.manager) {
        final managers = await _getManagerCount();
        if (managers >= 1) {
          throw Exception('Maximum 1 manager account allowed');
        }
      } else if (role == UserRole.staff) {
        final staff = await _getStaffCount();
        if (staff >= 2) {
          throw Exception('Maximum 2 staff accounts allowed');
        }
      }

      // Create auth user using admin API
      // Note: This requires service_role key or admin privileges
      final response = await _supabase!.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
          userMetadata: {
            'full_name': fullName,
            'role': role.name,
          },
        ),
      );

      if (response.user == null) {
        throw Exception('Failed to create user account');
      }

      // Profile should be auto-created by trigger
      // Wait a bit for trigger to execute
      await Future.delayed(const Duration(milliseconds: 500));

      // Fetch the created profile
      final profile = await getUserProfile(response.user!.id);
      if (profile == null) {
        throw Exception('User created but profile not found');
      }

      return profile;
    } on AuthException catch (e) {
      throw Exception('Failed to create user: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Get all users (Admin only)
  Future<List<UserProfile>> getAllUsers() async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }
    try {
      final response = await _supabase!
          .from('user_profiles')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    bool? isActive,
  }) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (isActive != null) updates['is_active'] = isActive;

      await _supabase!
          .from('user_profiles')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Delete user (Admin only)
  Future<void> deleteUser(String userId) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }
    try {
      // Delete from auth (this will cascade to user_profiles)
      await _supabase!.auth.admin.deleteUser(userId);
    } on AuthException catch (e) {
      throw Exception('Failed to delete user: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Get manager count
  Future<int> _getManagerCount() async {
    if (_supabase == null) return 0;
    try {
      final response = await _supabase!
          .from('user_profiles')
          .select('id')
          .eq('role', 'manager')
          .eq('is_active', true);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get staff count
  Future<int> _getStaffCount() async {
    if (_supabase == null) return 0;
    try {
      final response = await _supabase!
          .from('user_profiles')
          .select('id')
          .eq('role', 'staff')
          .eq('is_active', true);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Stream auth state changes
  Stream<AuthState> get authStateChanges {
    if (_supabase == null) {
      // Return empty stream if Supabase not initialized
      return Stream.empty();
    }
    return _supabase!.auth.onAuthStateChange;
  }

  /// Check user role
  Future<UserRole?> getUserRole() async {
    final user = currentUser;
    if (user == null) return null;

    final profile = await getUserProfile(user.id);
    return profile?.role;
  }
}
