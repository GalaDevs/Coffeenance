import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Email Verification Service using Supabase Auth
/// Uses Supabase's built-in email verification (no external email provider needed)
class EmailVerificationService {
  final SupabaseClient _supabase;

  EmailVerificationService(this._supabase);

  /// Send verification email using Supabase Auth
  /// This uses Supabase's built-in email templates
  Future<bool> sendVerificationEmail({
    required String email,
  }) async {
    try {
      debugPrint('📧 Sending Supabase verification email to: $email');

      // Use Supabase's resend method to send OTP email
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );

      debugPrint('✅ Verification email sent via Supabase');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending verification email: $e');
      // Don't throw - the email might have already been sent during signup
      return false;
    }
  }

  /// Verify the OTP code entered by user using Supabase Auth
  Future<bool> verifyCode({
    required String email,
    required String code,
  }) async {
    try {
      debugPrint('🔐 Verifying Supabase OTP for: $email');

      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.signup,
      );

      if (response.user != null) {
        debugPrint('✅ Email verified successfully via Supabase');
        
        // Also update user_profiles if it exists
        try {
          await _supabase
              .from('user_profiles')
              .update({'email_verified': true})
              .eq('id', response.user!.id);
          debugPrint('✅ User profile updated with email_verified = true');
        } catch (e) {
          debugPrint('⚠️ Could not update user profile: $e');
        }
        
        return true;
      } else {
        debugPrint('❌ Verification failed - no user returned');
        return false;
      }
    } on AuthException catch (e) {
      debugPrint('❌ Auth error verifying OTP: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('❌ Error verifying code: $e');
      rethrow;
    }
  }

  /// Check if user's email is verified (by checking Supabase Auth and user_profiles)
  Future<bool> isEmailVerified(String userId) async {
    try {
      // Check Supabase Auth first
      final user = _supabase.auth.currentUser;
      if (user != null && user.emailConfirmedAt != null) {
        return true;
      }

      // Fallback: Check user_profiles table
      try {
        final profile = await _supabase
            .from('user_profiles')
            .select('email_verified')
            .eq('id', userId)
            .maybeSingle();

        return profile?['email_verified'] == true;
      } catch (e) {
        debugPrint('⚠️ Could not check user_profiles: $e');
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking email verification: $e');
      return false;
    }
  }

  /// Check if email is verified and update user_profiles
  /// This is called when user clicks "Confirm" button after clicking email link
  Future<bool> checkAndConfirmVerification({
    required String email,
  }) async {
    try {
      debugPrint('🔐 Checking verification status for: $email');

      // First, get the user profile by email
      final profileResponse = await _supabase
          .from('user_profiles')
          .select('id, email_verified')
          .eq('email', email.toLowerCase().trim())
          .maybeSingle();

      if (profileResponse == null) {
        debugPrint('❌ No profile found for email: $email');
        return false;
      }

      final userId = profileResponse['id'] as String;
      final alreadyVerified = profileResponse['email_verified'] == true;

      if (alreadyVerified) {
        debugPrint('✅ Email already verified in user_profiles');
        return true;
      }

      // Check if Supabase Auth has confirmed the email
      // Try to get fresh user data by checking auth.users table via RPC or session refresh
      try {
        // Refresh the session to get latest auth state
        await _supabase.auth.refreshSession();
        
        final currentUser = _supabase.auth.currentUser;
        if (currentUser != null && currentUser.emailConfirmedAt != null) {
          debugPrint('✅ Supabase Auth confirms email is verified');
          
          // Update user_profiles to mark as verified
          await _supabase
              .from('user_profiles')
              .update({'email_verified': true})
              .eq('id', userId);
          
          debugPrint('✅ Updated user_profiles with email_verified = true');
          return true;
        }
      } catch (e) {
        debugPrint('⚠️ Could not refresh session: $e');
      }

      // Alternative: Check auth.users directly using admin-safe query
      try {
        final authCheck = await _supabase
            .rpc('check_email_confirmed', params: {'user_email': email.toLowerCase().trim()});
        
        if (authCheck == true) {
          debugPrint('✅ RPC confirms email is verified');
          
          // Update user_profiles
          await _supabase
              .from('user_profiles')
              .update({'email_verified': true})
              .eq('id', userId);
          
          return true;
        }
      } catch (e) {
        debugPrint('⚠️ RPC check_email_confirmed not available: $e');
      }

      debugPrint('❌ Email not yet verified');
      return false;
    } catch (e) {
      debugPrint('❌ Error checking verification: $e');
      return false;
    }
  }

  /// Resend verification code using Supabase
  Future<void> resendVerificationCode({
    required String email,
  }) async {
    try {
      debugPrint('📧 Resending Supabase verification email to: $email');
      
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );

      debugPrint('✅ Verification email resent');
    } on AuthException catch (e) {
      debugPrint('❌ Auth error resending: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('❌ Error resending verification code: $e');
      rethrow;
    }
  }
}
