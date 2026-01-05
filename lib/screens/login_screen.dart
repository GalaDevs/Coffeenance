import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/register_dialog.dart';
import '../screens/email_verification_screen.dart';
import '../services/email_verification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Login Screen - Beautiful authentication UI
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showErrorOverlay(String message, {IconData? icon, Color? color}) {
    debugPrint('🔴 _showErrorOverlay called with: $message');
    _removeOverlay();
    
    if (!mounted) {
      debugPrint('🔴 Widget not mounted, cannot show overlay');
      return;
    }
    
    final errorIcon = icon ?? _getErrorIcon(message);
    final errorColor = color ?? _getErrorColor(message);
    
    try {
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: errorColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(errorIcon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _removeOverlay,
                    child: const Icon(Icons.close, color: Colors.white70, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      
      Overlay.of(context).insert(_overlayEntry!);
      debugPrint('🔴 Overlay inserted successfully');
      
      // Auto-dismiss after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (_overlayEntry != null && mounted) {
          _removeOverlay();
        }
      });
    } catch (e) {
      debugPrint('🔴 Error showing overlay: $e');
      // Fallback to ScaffoldMessenger if overlay fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(errorIcon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success && mounted) {
      // Show success toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('Welcome back! Loading your dashboard...')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (!success && mounted && authProvider.error != null) {
      // Check if error is due to unverified email
      if (authProvider.error!.contains('EMAIL_NOT_VERIFIED:')) {
        final parts = authProvider.error!.split(':');
        final email = parts.length > 1 ? parts[1] : _emailController.text.trim();
        
        // Resend verification email via Supabase
        try {
          final verificationService = EmailVerificationService(Supabase.instance.client);
          await verificationService.resendVerificationCode(email: email);
          debugPrint('📧 Verification email resent to: $email');
        } catch (e) {
          debugPrint('⚠️ Could not resend verification: $e');
        }
        
        // Navigate to verification screen
        final verified = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: email,
            ),
          ),
        );
        
        if (verified == true) {
          // Retry login
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Great! Your email is verified. Please enter your password to log in.')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else if (authProvider.error!.contains('EMAIL_NOT_CONFIRMED:')) {
        // Supabase Auth email confirmation
        final email = authProvider.error!.split(':')[1];
        
        // Navigate to verification screen
        final verified = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: email,
            ),
          ),
        );
        
        if (verified == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Great! Your email is verified. Please enter your password to log in.')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        // Show error with user-friendly message as top overlay
        debugPrint('🔴 Error detected, showing overlay: ${authProvider.error}');
        final errorMessage = _parseLoginError(authProvider.error!);
        debugPrint('🔴 Parsed error message: $errorMessage');
        _showErrorOverlay(errorMessage);
      }
    }
    // Navigation is handled automatically by main.dart based on auth state
    // No need to manually navigate - the app will rebuild with HomeScreen
  }

  /// Parse error message to user-friendly format
  String _parseLoginError(String error) {
    final lowerError = error.toLowerCase();
    
    // Account not registered - check this FIRST
    if (lowerError.contains('account is not registered') ||
        lowerError.contains('no account found') ||
        lowerError.contains('user not found') ||
        lowerError.contains('user_not_found') ||
        lowerError.contains('no user')) {
      return 'Account is not registered';
    }
    // Wrong password (email exists but wrong password)
    if (lowerError.contains('invalid email or password') ||
        lowerError.contains('invalid login credentials') ||
        lowerError.contains('invalid_credentials') ||
        lowerError.contains('wrong password') ||
        lowerError.contains('incorrect password')) {
      return 'Wrong password';
    }
    // Email not verified
    if (lowerError.contains('email not confirmed') ||
        lowerError.contains('verify your email') ||
        lowerError.contains('email_not_confirmed')) {
      return 'Please verify your email first';
    }
    // Too many attempts
    if (lowerError.contains('too many') ||
        lowerError.contains('rate limit') ||
        lowerError.contains('too_many_requests')) {
      return 'Too many attempts. Please try again later';
    }
    // No internet
    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('internet') ||
        lowerError.contains('socket')) {
      return 'No internet connection';
    }
    // Timeout
    if (lowerError.contains('timeout')) {
      return 'Connection timed out. Please try again';
    }
    // Account disabled
    if (lowerError.contains('disabled') ||
        lowerError.contains('banned') ||
        lowerError.contains('suspended')) {
      return 'Account has been disabled';
    }
    // Account does not exist (RLS/profile errors)
    if (lowerError.contains('row-level security') ||
        lowerError.contains('rls') ||
        lowerError.contains('42501') ||
        lowerError.contains('unauthorized') ||
        lowerError.contains('failed to fetch user profile') ||
        lowerError.contains('failed to load user profile')) {
      return 'Account is not registered';
    }
    if (lowerError.contains('profile') && (lowerError.contains('fetch') || lowerError.contains('load'))) {
      return 'Account is not registered';
    }
    
    // Generic fallback
    return 'Wrong password';
  }

  /// Get appropriate icon for error type
  IconData _getErrorIcon(String error) {
    final lowerError = error.toLowerCase();
    
    if (lowerError.contains('password') || lowerError.contains('wrong')) {
      return Icons.lock_outline;
    }
    if (lowerError.contains('email') || lowerError.contains('verify')) {
      return Icons.email_outlined;
    }
    if (lowerError.contains('network') || lowerError.contains('internet') || lowerError.contains('connection')) {
      return Icons.wifi_off;
    }
    if (lowerError.contains('not registered') || lowerError.contains('account')) {
      return Icons.person_off;
    }
    if (lowerError.contains('too many') || lowerError.contains('attempts') || lowerError.contains('disabled')) {
      return Icons.timer_off;
    }
    
    return Icons.error_outline;
  }

  /// Get appropriate color for error type
  Color _getErrorColor(String error) {
    final lowerError = error.toLowerCase();
    
    if (lowerError.contains('verify') || lowerError.contains('email')) {
      return Colors.orange;
    }
    if (lowerError.contains('network') || lowerError.contains('internet') || lowerError.contains('timeout') || lowerError.contains('connection')) {
      return Colors.blueGrey;
    }
    
    return Colors.red;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Failed'),
        content: Text(message.replaceAll('Exception: ', '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRegisterDialog() {
    showDialog(
      context: context,
      builder: (context) => const RegisterDialog(),
    );
  }

  void _showRegisterDialogOld() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final coffeeShopNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.store_outlined, color: AppColors.chart1),
            SizedBox(width: 8),
            Text('Register Coffee Shop'),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Coffee Shop Name
                TextFormField(
                  controller: coffeeShopNameController,
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
                  controller: nameController,
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
                  controller: emailController,
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
                  controller: passwordController,
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
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (value != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
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
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              
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
                  return WillPopScope(
                    onWillPop: () async => false,
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Registering coffee shop...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );

              try {
                final authProvider = context.read<AuthProvider>();
                
                // Create admin account (registration mode - no auth required)
                final newUser = await authProvider.createUser(
                  email: emailController.text.trim(),
                  password: passwordController.text,
                  fullName: '${coffeeShopNameController.text.trim()} - ${nameController.text.trim()}',
                  role: UserRole.admin,
                  isRegistration: true, // Allow creation without being logged in
                ).timeout(
                  const Duration(seconds: 15),
                  onTimeout: () => null,
                );

                // Close loading dialog
                if (isLoading && loadingDialogContext != null && loadingDialogContext!.mounted) {
                  try {
                    Navigator.of(loadingDialogContext!, rootNavigator: true).pop();
                    isLoading = false;
                  } catch (navError) {
                    debugPrint('⚠️ Could not close loading dialog: $navError');
                  }
                }

                if (newUser != null) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('🎉 Account created! Please check your email (${emailController.text}) to verify, then log in.'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 10),
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('❌ Something went wrong. Please try again.'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              } catch (e) {
                debugPrint('❌ Exception during registration: $e');
                if (isLoading && loadingDialogContext != null && loadingDialogContext!.mounted) {
                  try {
                    Navigator.of(loadingDialogContext!, rootNavigator: true).pop();
                    isLoading = false;
                  } catch (navError) {
                    debugPrint('⚠️ Could not close dialog: $navError');
                  }
                }
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: const Text('❌ Something went wrong. Please check your connection and try again.'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.chart1,
              foregroundColor: Colors.white,
            ),
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1a1a1a),
                    const Color(0xFF0a0a0a),
                  ]
                : [
                    const Color(0xFFF5F5F5),
                    const Color(0xFFE5E5E5),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo/Icon
                        Image.asset(
                          'assets/icon.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.coffee_rounded,
                              size: 80,
                              color: AppColors.chart1,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // App Title
                        Text(
                          'Cafenance',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          'Sign in to continue',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'your@email.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withAlpha(10)
                                : Colors.grey.withAlpha(13),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withAlpha(10)
                                : Colors.grey.withAlpha(13),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.chart1,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Register Button
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _showRegisterDialog,
                          icon: const Icon(Icons.store_outlined),
                          label: const Text('Register Coffee Shop'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppColors.chart1, width: 2),
                            foregroundColor: AppColors.chart1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Info Text
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.chart1.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: AppColors.chart1,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'New to Cafenance? Register your coffee shop above',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
