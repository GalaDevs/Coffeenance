import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Custom Email Verification Service
/// Handles email verification without using Supabase Auth's built-in email confirmation
class EmailVerificationService {
  final SupabaseClient _supabase;

  // Resend API Configuration (Free tier: 100 emails/day)
  // Sign up at https://resend.com to get your API key
  // IMPORTANT: Replace with your actual Resend API key
  static const String _resendApiKey = 're_123456789'; // Replace with your Resend API key
  static const String _resendApiUrl = 'https://api.resend.com/emails';
  static const String _fromEmail = 'onboarding@resend.dev'; // Use this for testing, or your verified domain

  EmailVerificationService(this._supabase);

  /// Generate a 6-digit verification code
  String _generateCode() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  /// Create verification code and store in database
  Future<String> createVerificationCode({
    required String userId,
    required String email,
  }) async {
    try {
      debugPrint('📧 Creating verification code for: $email');

      // Try using the database function first
      try {
        final result = await _supabase.rpc(
          'generate_verification_code',
          params: {
            'p_user_id': userId,
            'p_email': email,
          },
        );
        
        if (result != null) {
          debugPrint('✅ Verification code created via RPC');
          return result.toString();
        }
      } catch (rpcError) {
        debugPrint('⚠️ RPC not available, using direct insert: $rpcError');
      }

      // Fallback: Direct insert
      final code = _generateCode();
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      // Delete existing codes for this user
      await _supabase
          .from('verification_codes')
          .delete()
          .eq('user_id', userId);

      // Insert new code
      await _supabase.from('verification_codes').insert({
        'user_id': userId,
        'email': email,
        'code': code,
        'expires_at': expiresAt.toIso8601String(),
        'verified': false,
        'attempts': 0,
      });

      debugPrint('✅ Verification code created: ${code.substring(0, 2)}****');
      return code;
    } catch (e) {
      debugPrint('❌ Error creating verification code: $e');
      rethrow;
    }
  }

  /// Send verification email using Resend API
  Future<bool> sendVerificationEmail({
    required String email,
    required String code,
    required String userName,
  }) async {
    try {
      debugPrint('📧 Sending verification email to: $email');

      // Check if Resend is configured
      if (_resendApiKey == 're_123456789' || _resendApiKey.isEmpty) {
        debugPrint('⚠️ Resend API not configured - showing code on screen');
        debugPrint('🔑 VERIFICATION CODE FOR $email: $code');
        // Return true so flow continues - user will see code on verification screen
        return true;
      }

      final response = await http.post(
        Uri.parse(_resendApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_resendApiKey',
        },
        body: jsonEncode({
          'from': 'Coffeenance <$_fromEmail>',
          'to': [email],
          'subject': 'Verify your Coffeenance account',
          'html': '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
    .container { max-width: 500px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #6B4423 0%, #8B5A2B 100%); padding: 30px; text-align: center; border-radius: 12px 12px 0 0; }
    .header h1 { color: white; margin: 0; font-size: 24px; }
    .header p { color: rgba(255,255,255,0.9); margin: 10px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 12px 12px; }
    .code-box { background: white; border: 2px solid #6B4423; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0; }
    .code { font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #6B4423; }
    .footer { text-align: center; color: #888; font-size: 12px; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>☕ Coffeenance</h1>
      <p>Your Coffee Shop Finance Manager</p>
    </div>
    <div class="content">
      <p>Hi <strong>$userName</strong>,</p>
      <p>Welcome to Coffeenance! Please verify your email address by entering this code:</p>
      <div class="code-box">
        <div class="code">$code</div>
      </div>
      <p style="color: #666; font-size: 14px;">This code expires in <strong>10 minutes</strong>.</p>
      <p style="color: #666; font-size: 14px;">If you didn't create an account, you can safely ignore this email.</p>
    </div>
    <div class="footer">
      <p>© ${DateTime.now().year} Coffeenance. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
''',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Verification email sent successfully via Resend');
        return true;
      } else {
        debugPrint('❌ Failed to send email: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending verification email: $e');
      // Don't throw - allow the process to continue
      // User can still verify manually with the code shown on screen
      return false;
    }
  }

  /// Verify the code entered by user
  Future<bool> verifyCode({
    required String userId,
    required String code,
  }) async {
    try {
      debugPrint('🔐 Verifying code for user: $userId');

      // Try using the database function first
      try {
        final result = await _supabase.rpc(
          'verify_email_code',
          params: {
            'p_user_id': userId,
            'p_code': code,
          },
        );

        if (result == true) {
          debugPrint('✅ Email verified via RPC');
          return true;
        } else if (result == false) {
          debugPrint('❌ Invalid or expired code');
          return false;
        }
      } catch (rpcError) {
        debugPrint('⚠️ RPC not available, using direct query: $rpcError');
      }

      // Fallback: Direct verification
      final verification = await _supabase
          .from('verification_codes')
          .select()
          .eq('user_id', userId)
          .single();

      if (verification == null) {
        throw Exception('No verification code found');
      }

      final storedCode = verification['code'] as String;
      final expiresAt = DateTime.parse(verification['expires_at']);
      final verified = verification['verified'] as bool;
      final attempts = verification['attempts'] as int;

      // Check if already verified
      if (verified) {
        return true;
      }

      // Check max attempts
      if (attempts >= 5) {
        throw Exception('Too many attempts. Please request a new code.');
      }

      // Increment attempts
      await _supabase
          .from('verification_codes')
          .update({'attempts': attempts + 1})
          .eq('user_id', userId);

      // Check expiration
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('Verification code has expired');
      }

      // Check code
      if (storedCode != code) {
        throw Exception('Invalid verification code');
      }

      // Mark as verified
      await _supabase
          .from('verification_codes')
          .update({'verified': true})
          .eq('user_id', userId);

      // Update user profile
      await _supabase
          .from('user_profiles')
          .update({'email_verified': true})
          .eq('id', userId);

      debugPrint('✅ Email verified successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error verifying code: $e');
      rethrow;
    }
  }

  /// Check if user's email is verified
  Future<bool> isEmailVerified(String userId) async {
    try {
      // Try RPC first
      try {
        final result = await _supabase.rpc(
          'is_email_verified',
          params: {'p_user_id': userId},
        );
        return result == true;
      } catch (rpcError) {
        debugPrint('⚠️ RPC not available: $rpcError');
      }

      // Fallback: Direct query
      final profile = await _supabase
          .from('user_profiles')
          .select('email_verified')
          .eq('id', userId)
          .single();

      return profile?['email_verified'] == true;
    } catch (e) {
      debugPrint('❌ Error checking email verification: $e');
      return false;
    }
  }

  /// Resend verification code
  Future<String> resendVerificationCode({
    required String userId,
    required String email,
    required String userName,
  }) async {
    try {
      // Generate new code
      final code = await createVerificationCode(
        userId: userId,
        email: email,
      );

      // Send email
      await sendVerificationEmail(
        email: email,
        code: code,
        userName: userName,
      );

      return code;
    } catch (e) {
      debugPrint('❌ Error resending verification code: $e');
      rethrow;
    }
  }

  /// Get verification status
  Future<Map<String, dynamic>?> getVerificationStatus(String userId) async {
    try {
      final result = await _supabase
          .from('verification_codes')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return result;
    } catch (e) {
      debugPrint('❌ Error getting verification status: $e');
      return null;
    }
  }
}
