import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Authentication Service
/// Handles all authentication operations using Supabase Auth
class AuthService {
  String? _error;
  String? get error => _error;

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

  /// Upload profile image to Supabase Storage
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'profile_images/$fileName';
      
      debugPrint('📤 Uploading profile image: $filePath');
      
      await _supabase!.storage
          .from('profiles')
          .upload(filePath, imageFile);
      
      final publicUrl = _supabase!.storage
          .from('profiles')
          .getPublicUrl(filePath);
      
      debugPrint('✅ Profile image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading profile image: $e');
      // Don't fail the entire registration if image upload fails
      return null;
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
    File? profileImage, // Optional profile image
  }) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }
    try {
      // Special case: Allow registration (creating admin without being logged in)
      final isRegistration = (role == UserRole.admin && createdByUserId.isEmpty);
      
      String adminId = createdByUserId;
      
      if (!isRegistration) {
        // Normal flow: Check if current user is admin or developer
        final currentProfile = await getUserProfile(createdByUserId);
        if (currentProfile?.role != UserRole.admin && currentProfile?.role != UserRole.developer) {
          throw Exception('Only admins and developers can create new users');
        }

        // Get admin ID (current user's ID for admin/developer, or their admin_id for manager/staff)
        adminId = createdByUserId;
        if (currentProfile?.role != UserRole.admin && currentProfile?.role != UserRole.developer) {
          // If not admin, get their admin_id
          final adminIdQuery = await _supabase!
              .from('user_profiles')
              .select('admin_id')
              .eq('id', createdByUserId)
              .single();
          adminId = adminIdQuery['admin_id'] ?? createdByUserId;
        }
        debugPrint('🏢 Admin ID for validation: $adminId');
      } else {
        debugPrint('🆕 REGISTRATION: Creating new admin account (no auth required)');
      }

      // Validate account limits PER ADMIN (skip for admin role - unlimited OR registration)
      if (role == UserRole.manager) {
        final managers = await _getManagerCount(adminId);
        debugPrint('👔 Current managers for this admin: $managers');
        if (managers >= 1) {
          throw Exception('Maximum 1 manager account allowed per admin');
        }
      } else if (role == UserRole.staff) {
        final staff = await _getStaffCount(adminId);
        debugPrint('👷 Current staff for this admin: $staff');
        if (staff >= 2) {
          throw Exception('Maximum 2 staff accounts allowed per admin');
        }
      } else if (role == UserRole.admin || role == UserRole.developer) {
        debugPrint('👑 Creating ${role.name} account - no limits');
      }

      debugPrint('✅ Account limit validation passed');
      debugPrint('🔐 Starting user creation process...');
      debugPrint('📧 Email: $email');
      debugPrint('👤 Name: $fullName');
      debugPrint('🎭 Role: ${role.name}');

      // Admin/Developer accounts: admin_id = NULL (they own themselves)
      // Manager/Staff accounts: admin_id = their admin's ID
      final String? assignedAdminId = (role == UserRole.admin || role == UserRole.developer) ? null : adminId;
      debugPrint('🏢 Admin ID for new user: ${assignedAdminId ?? "NULL (is admin/developer)"}');

      // For registration: Use signUp to create both Auth user and profile
      if (isRegistration) {
        debugPrint('📝 REGISTRATION: Creating auth user with signUp()...');
        
        final authResponse = await _supabase!.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'role': role.name,
            'admin_id': assignedAdminId,
          },
        );

        if (authResponse.user == null) {
          throw Exception('Failed to create auth user - no user returned');
        }

        final newUserId = authResponse.user!.id;
        debugPrint('✅ Auth user created with ID: $newUserId');

        // Upload profile image if provided
        String? profileImageUrl;
        if (profileImage != null) {
          debugPrint('📤 Uploading profile image...');
          profileImageUrl = await uploadProfileImage(newUserId, profileImage);
          if (profileImageUrl != null) {
            debugPrint('✅ Profile image uploaded successfully');
          }
        }

        // Create profile in database
        debugPrint('📝 Creating user profile in database...');
        final insertResponse = await _supabase!.from('user_profiles').insert({
          'id': newUserId,
          'email': email,
          'full_name': fullName,
          'role': role.name,
          'created_by': '', // Empty for registration
          'admin_id': assignedAdminId,
          'is_active': true,
          'profile_image_url': profileImageUrl,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).select();

        if (insertResponse == null || insertResponse.isEmpty) {
          throw Exception('Failed to create user profile - no data returned');
        }

        final profile = UserProfile.fromJson(insertResponse[0]);
        debugPrint('✅ Registration complete: ${profile.email}, role: ${profile.role}');
        return profile;
        
      } else {
        // Normal admin creating user: Create BOTH auth user and profile using signUp
        debugPrint('📝 ADMIN CREATING USER: Using signUp to create auth + profile...');
        debugPrint('📋 Creating auth user:');
        debugPrint('   - email: $email');
        debugPrint('   - full_name: $fullName');
        debugPrint('   - role: ${role.name}');
        debugPrint('   - created_by: $createdByUserId');
        debugPrint('   - admin_id: ${assignedAdminId ?? "NULL"} (MULTI-TENANCY)');
        
        String? newUserId;
        
        try {
          // Try to create auth user using signUp
          final authResponse = await _supabase!.auth.signUp(
            email: email,
            password: password,
            data: {
              'full_name': fullName,
              'role': role.name,
              'admin_id': assignedAdminId,  // Pass admin_id to trigger
              'created_by': createdByUserId,  // Pass created_by to trigger
            },
            emailRedirectTo: null, // Disable email confirmation redirect
          );

          if (authResponse.user == null) {
            throw Exception('Failed to create auth user - no user returned');
          }

          newUserId = authResponse.user!.id;
          debugPrint('✅ Auth user created with ID: $newUserId');
        } on AuthApiException catch (authError) {
          // If user already exists in auth.users, check if profile exists
          if (authError.code == 'user_already_exists' || authError.statusCode == 422) {
            debugPrint('⚠️ Auth user already exists, checking for profile...');
            
            // Check if profile exists for this email
            final existingProfile = await _supabase!
                .from('user_profiles')
                .select()
                .eq('email', email)
                .maybeSingle();
            
            if (existingProfile != null) {
              // Profile exists - update it with new admin_id
              debugPrint('📝 Profile exists, updating with new team info...');
              final updateResponse = await _supabase!
                  .from('user_profiles')
                  .update({
                    'full_name': fullName,
                    'role': role.name,
                    'admin_id': assignedAdminId,
                    'created_by': createdByUserId,
                    'is_active': true,
                    'updated_at': DateTime.now().toIso8601String(),
                  })
                  .eq('email', email)
                  .select();
              
              if (updateResponse == null || updateResponse.isEmpty) {
                throw Exception('Failed to update existing profile');
              }
              
              final profile = UserProfile.fromJson(updateResponse[0]);
              debugPrint('✅ Existing user updated to team!');
              debugPrint('   📧 Email: ${profile.email}');
              debugPrint('   🎭 Role: ${profile.role}');
              debugPrint('   🏢 Admin ID: ${assignedAdminId ?? "NULL"}');
              
              return profile;
            } else {
              // Auth exists but no profile - this shouldn't happen, but handle it
              throw Exception('User exists in auth but missing profile. Please contact support.');
            }
          } else {
            // Some other auth error
            throw Exception('Auth error: ${authError.message}');
          }
        }

        // Auth user created successfully
        // The trigger (handle_new_user) automatically creates the profile
        // We just need to fetch it to return
        debugPrint('📝 Waiting for trigger to create profile...');
        
        // Small delay to ensure trigger completes
        await Future.delayed(const Duration(milliseconds: 500));
        
        debugPrint('📝 Fetching created profile...');
        final profileResponse = await _supabase!
            .from('user_profiles')
            .select()
            .eq('id', newUserId)
            .maybeSingle();

        if (profileResponse == null) {
          throw Exception('Failed to fetch user profile after creation');
        }
        
        final profile = UserProfile.fromJson(profileResponse);
        debugPrint('✅ User created successfully!');
        debugPrint('   📧 Email: ${profile.email}');
        debugPrint('   🎭 Role: ${profile.role}');
        debugPrint('   🆔 ID: ${profile.id}');
        debugPrint('   🏢 Admin ID: ${assignedAdminId ?? "NULL (is admin)"}');
        debugPrint('   ✅ User can now login with email: $email and password');
        
        return profile;
      }
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error creating user: ${e.message}');
      throw Exception('Failed to create user: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error creating user: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  /// Get all users (Admin only) - Filtered by admin's tenant
  Future<List<UserProfile>> getAllUsers() async {
    if (_supabase == null) {
      debugPrint('❌ Supabase client is NULL!');
      throw Exception('Supabase not initialized');
    }
    
    try {
      // Get current user's ID
      final currentUserId = _supabase!.auth.currentUser?.id;
      if (currentUserId == null) {
        debugPrint('❌ No authenticated user');
        throw Exception('No authenticated user');
      }
      
      debugPrint('🔍 Fetching users for current admin...');
      debugPrint('👤 Current user ID: $currentUserId');
      
      // Get current user's profile to determine their admin_id
      final currentProfile = await getUserProfile(currentUserId);
      if (currentProfile == null) {
        debugPrint('❌ Could not fetch current user profile');
        throw Exception('Could not fetch current user profile');
      }
      
      debugPrint('👤 Current user role: ${currentProfile.role}');
      debugPrint('🏢 Current user admin_id: ${currentProfile.adminId ?? "NULL (is admin/developer)"}');
      
      // Determine the admin ID to filter by
      String filterAdminId;
      if (currentProfile.role == UserRole.admin || currentProfile.role == UserRole.developer) {
        // Admin/Developer user: show only their own tenant (where admin_id = current user's ID OR admin_id IS NULL AND id = current user)
        filterAdminId = currentUserId;
        debugPrint('🏢 Filtering for ${currentProfile.role.name} tenant: $filterAdminId');
      } else {
        // Manager/Staff: show users in their admin's tenant
        filterAdminId = currentProfile.adminId ?? currentUserId;
        debugPrint('🏢 Filtering for tenant: $filterAdminId');
      }
      
      // Fetch users: either users created by this admin OR users belonging to this admin's tenant
      final response = await _supabase!
          .from('user_profiles')
          .select()
          .or('id.eq.$filterAdminId,admin_id.eq.$filterAdminId')
          .order('created_at', ascending: false)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⏱️ TIMEOUT: Database did not respond in 10 seconds');
              throw Exception('Request timeout - database not responding');
            },
          );

      debugPrint('📊 Raw response from database: $response');
      debugPrint('📊 Response type: ${response.runtimeType}');
      debugPrint('📊 Response is null: ${response == null}');
      
      if (response == null) {
        debugPrint('⚠️ Response is null - returning empty list');
        return [];
      }
      
      if (response is! List) {
        debugPrint('❌ Response is not a List! Type: ${response.runtimeType}');
        debugPrint('❌ Response value: $response');
        return [];
      }
      
      final responseList = response as List;
      debugPrint('📊 Response length: ${responseList.length}');
      debugPrint('📊 First item (if any): ${responseList.isNotEmpty ? responseList[0] : "EMPTY"}');

      final users = responseList
          .map((json) {
            try {
              debugPrint('   Converting user: ${json['email']} (${json['role']})');
              return UserProfile.fromJson(json);
            } catch (e) {
              debugPrint('   ⚠️ Failed to convert user: $e');
              debugPrint('   JSON data: $json');
              return null;
            }
          })
          .whereType<UserProfile>()
          .toList();
      
      debugPrint('✅ Fetched ${users.length} users from database');
      debugPrint('✅ User emails: ${users.map((u) => u.email).join(", ")}');
      return users;
    } on PostgrestException catch (e) {
      debugPrint('❌ Postgrest error: ${e.message}');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Details: ${e.details}');
      debugPrint('   Hint: ${e.hint}');
      throw Exception('Database error: ${e.message}');
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout error: $e');
      throw Exception('Request timeout - please check your connection');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to fetch users: $e');
      debugPrint('Stack trace: $stackTrace');
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
  Future<bool> deleteUser(String userId) async {
    if (_supabase == null) {
      throw Exception('Supabase not initialized');
    }
    try {
      debugPrint('🗑️ Deleting user: $userId');
      
      // We can't delete from auth with anon key, so we'll just mark as inactive
      // and delete from user_profiles table
      await _supabase!
          .from('user_profiles')
          .delete()
          .eq('id', userId);
      
      debugPrint('✅ User deleted successfully from user_profiles');
      return true;
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error deleting user: ${e.message}');
      _error = 'Failed to delete user: ${e.message}';
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting user: $e');
      _error = 'Failed to delete user: $e';
      return false;
    }
  }

  /// Get manager count for a specific admin
  Future<int> _getManagerCount(String adminId) async {
    if (_supabase == null) return 0;
    try {
      final response = await _supabase!
          .from('user_profiles')
          .select('id')
          .eq('role', 'manager')
          .eq('is_active', true)
          .eq('admin_id', adminId); // Filter by admin

      debugPrint('📊 Manager count for admin $adminId: ${(response as List).length}');
      return (response as List).length;
    } catch (e) {
      debugPrint('❌ Error getting manager count: $e');
      return 0;
    }
  }

  /// Get staff count for a specific admin
  Future<int> _getStaffCount(String adminId) async {
    if (_supabase == null) return 0;
    try {
      final response = await _supabase!
          .from('user_profiles')
          .select('id')
          .eq('role', 'staff')
          .eq('is_active', true)
          .eq('admin_id', adminId); // Filter by admin

      debugPrint('📊 Staff count for admin $adminId: ${(response as List).length}');
      return (response as List).length;
    } catch (e) {
      debugPrint('❌ Error getting staff count: $e');
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
