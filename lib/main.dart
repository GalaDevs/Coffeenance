import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'config/supabase_config.dart';
import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/reset_password_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/error_popup.dart';

/// Store initialization errors to show to user after app starts
String? _initializationError;
String? _initializationErrorDetails;

/// Main entry point - Matches Next.js layout.tsx and page.tsx
/// Provides state management and adaptive theming for iOS/Android/Web
void main() async {
  // Wrap in runZonedGuarded to catch ALL async errors including Supabase deep link errors
  runZonedGuarded(() async {
    // Wrap everything in try-catch to prevent crashes
    try {
      WidgetsFlutterBinding.ensureInitialized();
      
      // Add error handling for crashes
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('Flutter Error: ${details.exception}');
        debugPrint('Stack: ${details.stack}');
        // Queue error for display to user
        ErrorPopup.queueError(
          'App Error',
          ErrorPopup.getUserFriendlyMessage(details.exception),
        );
      };
    
    // Initialize Supabase with error handling
    // Skip initialization if credentials are invalid to prevent crashes
    try {
      // Check if we have valid Supabase credentials
      if (SupabaseConfig.supabaseAnonKey.startsWith('eyJ') && 
          SupabaseConfig.supabaseAnonKey.length > 100) {
        try {
          await Supabase.initialize(
            url: SupabaseConfig.supabaseUrl,
            anonKey: SupabaseConfig.supabaseAnonKey,
            authOptions: const FlutterAuthClientOptions(
              // Let us handle deep links manually to avoid crashes
              authFlowType: AuthFlowType.pkce,
            ),
          );
          debugPrint('✅ Supabase initialized successfully');
          
          // Add global error handler for auth exceptions
          // This catches errors from Supabase's internal deep link handling
          Supabase.instance.client.auth.onAuthStateChange.listen(
            (data) {
              // Normal handling done elsewhere
            },
            onError: (error) {
              debugPrint('⚠️ Auth stream error (handled): $error');
              // Errors like expired tokens are caught here
            },
          );
        } catch (e) {
          debugPrint('⚠️ Supabase initialization failed: $e');
          debugPrint('   App will continue in offline mode');
          // Store error for user display
          _initializationError = 'Server Connection Failed';
          _initializationErrorDetails = 'Could not connect to the backend server.\n\n'
              'The app will run in limited offline mode.\n\n'
              'Error: ${ErrorPopup.getUserFriendlyMessage(e)}';
        }
      } else {
        debugPrint('⚠️ Invalid Supabase credentials - running in offline mode');
        _initializationError = 'Configuration Error';
        _initializationErrorDetails = 'Invalid server configuration.\n\n'
            'Please contact support to resolve this issue.';
      }
    } catch (e, stack) {
      debugPrint('⚠️ Error during Supabase setup: $e');
      debugPrint('Stack: $stack');
      _initializationError = 'Setup Error';
      _initializationErrorDetails = ErrorPopup.getUserFriendlyMessage(e);
    }
    
    runApp(const CafenanceApp());
  } catch (e, stack) {
    debugPrint('💥 Fatal error in main: $e');
    debugPrint('Stack: $stack');
    // Run app with error display
    runApp(MaterialApp(
      navigatorKey: ErrorPopup.navigatorKey,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'App Failed to Start',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ErrorPopup.getUserFriendlyMessage(e),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      e.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
  }, (error, stackTrace) {
    // Global error handler for all async errors (including Supabase deep link errors)
    debugPrint('🛡️ Caught async error in runZonedGuarded: $error');
    
    // Check if it's an auth exception (expired link, etc.)
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('authexception') || 
        errorString.contains('expired') ||
        errorString.contains('otp_expired') ||
        errorString.contains('invalid')) {
      debugPrint('   → Auth/expired link error - safely ignored');
      // These are expected errors from expired password reset links
      // They're handled by our _processDeepLink error checking
      return;
    }
    
    debugPrint('   Stack: $stackTrace');
  });
}

class CafenanceApp extends StatelessWidget {
  const CafenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, child) {
          return MaterialApp(
            title: 'Cafenance - Coffee Shop Tracker',
            debugShowCheckedModeBanner: false,
            navigatorKey: ErrorPopup.navigatorKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: _InitialScreen(authProvider: authProvider),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/reset-password': (context) => const ResetPasswordScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/email-verification') {
                // Get email from arguments
                final email = settings.arguments as String?;
                if (email != null) {
                  return MaterialPageRoute(
                    builder: (context) => EmailVerificationScreen(email: email),
                  );
                }
                // Fallback to login if no email provided
                return MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                );
              }
              return null;
            },
            builder: (context, widget) {
              // Add error boundary
              ErrorWidget.builder = (FlutterErrorDetails details) {
                debugPrint('Widget Error: ${details.exception}');
                debugPrint('Stack: ${details.stack}');
                // Queue error for user display
                ErrorPopup.queueError(
                  'Widget Error',
                  ErrorPopup.getUserFriendlyMessage(details.exception),
                );
                return Material(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Something went wrong',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ErrorPopup.getUserFriendlyMessage(details.exception),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              };
              return widget ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}

/// Initial screen that shows loading, handles errors, and navigates to appropriate screen
class _InitialScreen extends StatefulWidget {
  final AuthProvider authProvider;
  
  const _InitialScreen({required this.authProvider});

  @override
  State<_InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<_InitialScreen> {
  bool _hasShownInitError = false;
  final _appLinks = AppLinks();
  StreamSubscription<AuthState>? _authSubscription;
  
  @override
  void initState() {
    super.initState();
    
    // Listen for auth changes and trigger rebuild
    widget.authProvider.addListener(_onAuthChanged);
    
    // Listen for Supabase auth state changes (for password recovery)
    _setupAuthListener();
    
    // Show initialization error after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInitializationErrorIfNeeded();
    });
    
    // Set up deep link handling
    _handleDeepLinks();
  }
  
  /// Set up Supabase auth state listener for password recovery
  void _setupAuthListener() {
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        debugPrint('🔔 Auth state change: ${data.event}');
        
        if (data.event == AuthChangeEvent.passwordRecovery) {
          debugPrint('🔐 Password recovery event detected');
          // Navigate to reset password screen
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/reset-password', (route) => false);
            }
          });
        }
      });
    } catch (e) {
      debugPrint('⚠️ Error setting up auth listener: $e');
    }
  }
  
  @override
  void dispose() {
    widget.authProvider.removeListener(_onAuthChanged);
    _authSubscription?.cancel();
    super.dispose();
  }
  
  void _onAuthChanged() {
    debugPrint('🔄 Auth state changed in _InitialScreen, rebuilding...');
    debugPrint('   isAuthenticated: ${widget.authProvider.isAuthenticated}');
    debugPrint('   currentUser: ${widget.authProvider.currentUser?.email}');
    if (mounted) {
      setState(() {});
    }
  }
  
  /// Handle deep links for email verification
  void _handleDeepLinks() {
    // Handle initial deep link (app opened from link)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        debugPrint('📩 Initial deep link: $uri');
        _processDeepLink(uri);
      }
    }).catchError((err) {
      debugPrint('⚠️ Error getting initial link: $err');
    });
    
    // Listen for deep links while app is running
    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('📩 Deep link received: $uri');
      _processDeepLink(uri);
    }, onError: (err) {
      debugPrint('⚠️ Error handling deep link: $err');
    });
  }
  
  /// Process deep link URLs
  void _processDeepLink(Uri uri) {
    try {
      debugPrint('🔗 Processing deep link: $uri');
      debugPrint('   Scheme: ${uri.scheme}');
      debugPrint('   Host: ${uri.host}');
      debugPrint('   Path: ${uri.path}');
      debugPrint('   Fragment: ${uri.fragment}');
      debugPrint('   Query: ${uri.queryParameters}');
      
      // Parse the fragment for Supabase auth tokens
      // Supabase sends tokens in fragment like: #access_token=xxx&type=recovery
      Map<String, String> fragmentParams = {};
      if (uri.fragment.isNotEmpty) {
        try {
          fragmentParams = Uri.splitQueryString(uri.fragment);
          debugPrint('   Fragment params: $fragmentParams');
        } catch (e) {
          debugPrint('   Error parsing fragment: $e');
        }
      }
      
      // Also check query parameters (some redirects use query instead of fragment)
      final allParams = {...uri.queryParameters, ...fragmentParams};
      
      // *** CHECK FOR ERRORS FIRST ***
      // Supabase sends errors in query params when link is expired/invalid
      if (allParams.containsKey('error') || allParams.containsKey('error_code')) {
        final errorCode = allParams['error_code'] ?? allParams['error'] ?? 'unknown';
        final errorDesc = allParams['error_description'] ?? 'Link is invalid or has expired';
        debugPrint('⚠️ Deep link contains error: $errorCode - $errorDesc');
        
        // Show user-friendly error and redirect to login
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ ${errorDesc.replaceAll('+', ' ')}. Please request a new reset link.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        });
        return; // Don't process further
      }
      
      // Check if it's a password reset/recovery link
      final isPasswordReset = uri.host == 'reset-password' || 
          uri.path.contains('reset-password') ||
          allParams['type'] == 'recovery' ||
          uri.toString().contains('type=recovery');
      
      if (isPasswordReset) {
        debugPrint('🔐 Password reset deep link detected');
        
        // If we have an access token, try to set the session
        if (allParams.containsKey('access_token')) {
          debugPrint('🔑 Found access token, setting session...');
          _handleRecoveryToken(allParams);
        } else {
          // Navigate directly to reset password screen
          debugPrint('📱 Navigating to reset password screen...');
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/reset-password', (route) => false);
            }
          });
        }
        return;
      }
      
      // Check if it's an email verification link
      final isEmailVerification = uri.host == 'verify-email' || 
          uri.path.contains('verify-email') ||
          allParams['type'] == 'signup' ||
          allParams['type'] == 'email' ||
          uri.toString().contains('type=signup');
      
      if (isEmailVerification) {
        debugPrint('✅ Email verification deep link detected');
        
        // If we have an access token, set the session first
        if (allParams.containsKey('access_token')) {
          _handleVerificationToken(allParams);
        } else {
          // Just wait and check auth state
          Future.delayed(const Duration(seconds: 1), () {
            try {
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null && user.emailConfirmedAt != null) {
                debugPrint('✅ Email verified successfully via deep link');
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Your email has been verified! You can now log in.'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              }
            } catch (e) {
              debugPrint('⚠️ Error checking user state: $e');
            }
          });
        }
        return;
      }
      
      // If we get here with recovery type in the URL, still handle it
      if (uri.toString().contains('recovery') || uri.toString().contains('reset')) {
        debugPrint('🔐 Fallback: Detected recovery in URL, navigating to reset password');
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/reset-password', (route) => false);
          }
        });
      }
    } catch (e, stack) {
      debugPrint('❌ Error processing deep link: $e');
      debugPrint('   Stack: $stack');
    }
  }
  
  /// Handle recovery token from password reset email
  Future<void> _handleRecoveryToken(Map<String, String> params) async {
    try {
      final accessToken = params['access_token'];
      final refreshToken = params['refresh_token'] ?? '';
      
      if (accessToken != null && accessToken.isNotEmpty) {
        debugPrint('🔑 Setting session with recovery token...');
        debugPrint('   Access token length: ${accessToken.length}');
        debugPrint('   Refresh token length: ${refreshToken.length}');
        
        try {
          // Set the session using the tokens from the URL
          // Need both access_token and refresh_token
          if (refreshToken.isNotEmpty) {
            await Supabase.instance.client.auth.setSession(accessToken);
          } else {
            // If no refresh token, try to recover session differently
            // The auth state change listener should handle this
            debugPrint('⚠️ No refresh token, relying on auth state listener');
          }
          
          debugPrint('✅ Session set successfully');
        } catch (sessionError) {
          debugPrint('⚠️ Session set error (may be okay): $sessionError');
          // Continue anyway - the passwordRecovery event may have already been fired
        }
        
        // Navigate to reset password screen
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/reset-password', (route) => false);
          }
        });
      } else {
        debugPrint('⚠️ No access token found, navigating anyway');
        // Navigate to reset password screen anyway
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/reset-password', (route) => false);
          }
        });
      }
    } catch (e, stack) {
      debugPrint('❌ Error handling recovery token: $e');
      debugPrint('   Stack: $stack');
      // Still try to navigate
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/reset-password', (route) => false);
        }
      });
    }
  }
  
  /// Handle verification token from email verification
  Future<void> _handleVerificationToken(Map<String, String> params) async {
    try {
      final accessToken = params['access_token'];
      
      if (accessToken != null && accessToken.isNotEmpty) {
        debugPrint('🔑 Setting session with verification token...');
        try {
          await Supabase.instance.client.auth.setSession(accessToken);
          debugPrint('✅ Email verification session set');
        } catch (sessionError) {
          debugPrint('⚠️ Session set error (may be okay): $sessionError');
        }
        
        try {
          final user = Supabase.instance.client.auth.currentUser;
          if (user != null && user.emailConfirmedAt != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Your email has been verified! You can now log in.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 5),
                ),
              );
              setState(() {}); // Refresh to show appropriate screen
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error checking user state: $e');
        }
      }
    } catch (e, stack) {
      debugPrint('❌ Error handling verification token: $e');
      debugPrint('   Stack: $stack');
    }
  }

  void _showInitializationErrorIfNeeded() {
    // Show stored initialization error
    if (!_hasShownInitError && _initializationError != null) {
      _hasShownInitError = true;
      ErrorPopup.show(context, _initializationErrorDetails ?? 'Could not connect to server.');
    }
    
    // Show any other pending errors
    if (ErrorPopup.hasPendingErrors) {
      ErrorPopup.showPendingErrors(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking auth
    if (widget.authProvider.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Check for auth errors
    if (widget.authProvider.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorSnackBar.showWarning(context, widget.authProvider.error!);
      });
    }

    // If authenticated, check email verification
    if (widget.authProvider.isAuthenticated && widget.authProvider.currentUser != null) {
      final user = Supabase.instance.client.auth.currentUser;
      
      // Check if email is verified
      if (user != null && user.emailConfirmedAt == null) {
        debugPrint('⚠️ User email not verified, showing verification screen');
        return EmailVerificationScreen(email: user.email ?? '');
      }
      
      debugPrint('✅ User authenticated: ${widget.authProvider.currentUser?.email}, showing HomeScreen');
      return const HomeScreen();
    } else {
      debugPrint('❌ No user authenticated, showing LoginScreen');
      return const LoginScreen();
    }
  }
}
