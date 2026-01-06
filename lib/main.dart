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
          );
          debugPrint('✅ Supabase initialized successfully');
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
  
  @override
  void initState() {
    super.initState();
    
    // Listen for auth changes and trigger rebuild
    widget.authProvider.addListener(_onAuthChanged);
    
    // Show initialization error after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInitializationErrorIfNeeded();
    });
    
    // Set up deep link handling
    _handleDeepLinks();
  }
  
  @override
  void dispose() {
    widget.authProvider.removeListener(_onAuthChanged);
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
    debugPrint('🔗 Processing deep link: $uri');
    debugPrint('   Host: ${uri.host}');
    debugPrint('   Path: ${uri.path}');
    debugPrint('   Fragment: ${uri.fragment}');
    
    // Check if it's a password reset link
    if (uri.host == 'reset-password' || 
        uri.path.contains('reset-password') ||
        uri.fragment.contains('type=recovery')) {
      debugPrint('🔐 Password reset deep link detected');
      
      // Navigate to reset password screen
      // Supabase has already exchanged the token for a session
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/reset-password', (route) => false);
        }
      });
      return;
    }
    
    // Check if it's an email verification link
    if (uri.host == 'verify-email' || 
        uri.path.contains('verify-email') ||
        uri.fragment.contains('type=signup')) {
      debugPrint('✅ Email verification deep link detected');
      
      // Supabase automatically handles the token validation
      // Just wait a moment and check auth state
      Future.delayed(const Duration(seconds: 1), () {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null && user.emailConfirmedAt != null) {
          debugPrint('✅ Email verified successfully via deep link');
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Your email has been verified! You can now log in.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
            
            // No need to refresh auth state - it's automatic
          }
        }
      });
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
