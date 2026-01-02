import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import '../services/shop_settings_service.dart';
import '../services/email_verification_service.dart';
import '../screens/email_verification_screen.dart';
import '../theme/app_theme.dart';

class RegisterDialog extends StatefulWidget {
  const RegisterDialog({super.key});

  @override
  State<RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<RegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _coffeeShopNameController = TextEditingController();
  bool _isVatRegistered = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _coffeeShopNameController.dispose();
    super.dispose();
  }

  /// Show result dialog with success or error
  void _showResultDialog({
    required BuildContext context,
    required bool isSuccess,
    required String title,
    required String message,
    String? details,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
            if (details != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  details,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDismiss?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isSuccess ? 'Continue' : 'OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final email = _emailController.text.trim();
    final shopName = _coffeeShopNameController.text.trim();
    final userName = _nameController.text.trim();
    
    // Close register dialog
    navigator.pop();

    // Show loading
    bool isLoading = true;
    BuildContext? loadingDialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        loadingDialogContext = dialogContext;
        return PopScope(
          canPop: false,
          child: Center(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.chart1),
                    const SizedBox(height: 20),
                    const Text(
                      'Creating your account...',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      shopName,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // Helper to close loading dialog
    void closeLoadingDialog() {
      if (isLoading && loadingDialogContext != null && loadingDialogContext!.mounted) {
        try {
          Navigator.of(loadingDialogContext!, rootNavigator: true).pop();
          isLoading = false;
        } catch (e) {
          debugPrint('⚠️ Could not close loading dialog: $e');
        }
      }
    }

    try {
      final authProvider = context.read<AuthProvider>();
      
      debugPrint('📝 Starting registration for: $email');
      
      // Create admin account (registration mode - no auth required)
      final newUser = await authProvider.createUser(
        email: email,
        password: _passwordController.text,
        fullName: '$shopName - $userName',
        role: UserRole.admin,
        isRegistration: true,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏱️ Registration timed out');
          throw Exception('Registration timed out. Please check your internet connection and try again.');
        },
      );

      closeLoadingDialog();

      if (newUser != null) {
        debugPrint('✅ User created successfully: ${newUser.id}');
        
        // IMPORTANT: Sign out immediately after registration
        // User must verify email before they can log in
        try {
          await Supabase.instance.client.auth.signOut();
          debugPrint('🔐 Signed out after registration - email verification required');
        } catch (e) {
          debugPrint('⚠️ Could not sign out after registration: $e');
        }
        
        // Create shop settings
        bool shopSettingsCreated = false;
        try {
          final shopSettingsService = ShopSettingsService(Supabase.instance.client);
          await shopSettingsService.upsertShopSettings(
            adminId: newUser.id,
            shopName: shopName,
            isVatRegistered: _isVatRegistered,
          );
          shopSettingsCreated = true;
          debugPrint('✅ Shop settings created');
        } catch (e) {
          debugPrint('⚠️ Could not create shop settings: $e');
        }

        // Create verification code
        String? verificationCode;
        bool emailSent = false;
        try {
          final verificationService = EmailVerificationService(Supabase.instance.client);
          verificationCode = await verificationService.createVerificationCode(
            userId: newUser.id,
            email: email,
          );
          debugPrint('✅ Verification code created');
          
          // Try to send email
          emailSent = await verificationService.sendVerificationEmail(
            email: email,
            code: verificationCode,
            userName: userName,
          );
          debugPrint(emailSent ? '✅ Verification email sent' : '⚠️ Email not sent (will show code on screen)');
        } catch (e) {
          debugPrint('⚠️ Could not create/send verification code: $e');
        }

        if (mounted) {
          // Show success dialog first
          _showResultDialog(
            context: context,
            isSuccess: true,
            title: 'Account Created!',
            message: 'Your coffee shop "$shopName" has been registered successfully.',
            details: emailSent 
                ? 'A verification code has been sent to:\n$email'
                : 'Please verify your email on the next screen.',
            onDismiss: () async {
              // Navigate to email verification screen
              if (mounted) {
                final verified = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => EmailVerificationScreen(
                      email: email,
                      userId: newUser.id,
                      userName: userName,
                      verificationCode: verificationCode,
                    ),
                  ),
                );

                if (verified == true && mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Email verified! You can now login.'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              }
            },
          );
        }
      } else {
        // Registration failed
        debugPrint('❌ Registration failed: ${authProvider.error}');
        
        String errorMessage = authProvider.error ?? 'Unknown error occurred';
        String? errorDetails;
        String errorLower = errorMessage.toLowerCase();
        
        // Parse common errors for user-friendly messages
        if (errorLower.contains('already registered') || 
            errorLower.contains('already exists') ||
            errorLower.contains('user_already_exists') ||
            errorLower.contains('duplicate') ||
            errorLower.contains('unique constraint') ||
            errorLower.contains('email has already been taken') ||
            errorLower.contains('422')) {
          errorMessage = 'This email is already registered';
          errorDetails = 'An account with this email already exists.\n\nPlease:\n• Use a different email, or\n• Try logging in instead';
        } else if (errorLower.contains('invalid email') || errorLower.contains('invalid_email')) {
          errorMessage = 'Invalid email address';
          errorDetails = 'Please check your email format and try again.\nExample: yourname@email.com';
        } else if (errorLower.contains('weak password') || 
                   errorLower.contains('password') && errorLower.contains('short') ||
                   errorLower.contains('password should be')) {
          errorMessage = 'Password is too weak';
          errorDetails = 'Password must be at least 6 characters long.\nTip: Use a mix of letters and numbers.';
        } else if (errorLower.contains('network') || 
                   errorLower.contains('connection') ||
                   errorLower.contains('socket') ||
                   errorLower.contains('host')) {
          errorMessage = 'Network error';
          errorDetails = 'Could not connect to server.\n\nPlease check your internet connection and try again.';
        } else if (errorLower.contains('timeout') || errorLower.contains('timed out')) {
          errorMessage = 'Request timed out';
          errorDetails = 'The server took too long to respond.\n\nPlease try again.';
        } else if (errorLower.contains('rate limit') || errorLower.contains('too many')) {
          errorMessage = 'Too many attempts';
          errorDetails = 'Please wait a few minutes before trying again.';
        } else {
          errorDetails = errorMessage.replaceAll('Exception: ', '');
          errorMessage = 'Registration failed';
        }

        if (mounted) {
          _showResultDialog(
            context: context,
            isSuccess: false,
            title: 'Registration Failed',
            message: errorMessage,
            details: errorDetails,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Exception during registration: $e');
      closeLoadingDialog();
      
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      String? errorDetails;
      
      // Parse common errors
      if (errorMessage.contains('timed out')) {
        errorDetails = 'The server took too long to respond. Please try again.';
      } else if (errorMessage.contains('SocketException') || errorMessage.contains('network')) {
        errorMessage = 'Network error';
        errorDetails = 'Please check your internet connection and try again.';
      } else {
        errorDetails = errorMessage;
        errorMessage = 'Something went wrong';
      }

      if (mounted) {
        _showResultDialog(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: errorMessage,
          details: errorDetails,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.store_outlined, color: AppColors.chart1),
          SizedBox(width: 8),
          Text('Register Coffee Shop'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Coffee Shop Name
              TextFormField(
                controller: _coffeeShopNameController,
                decoration: const InputDecoration(
                  labelText: 'Coffee Shop Name',
                  prefixIcon: Icon(Icons.store),
                  helperText: 'Your business name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your coffee shop name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Admin Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  helperText: 'Min. 6 characters',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // VAT Registration
              SwitchListTile(
                title: const Text('VAT Registered'),
                subtitle: const Text('Is your business VAT registered?'),
                value: _isVatRegistered,
                onChanged: (bool value) {
                  setState(() {
                    _isVatRegistered = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.chart1,
            foregroundColor: Colors.white,
          ),
          child: const Text('Register'),
        ),
      ],
    );
  }
}
