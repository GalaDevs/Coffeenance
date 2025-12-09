import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

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
        }
      } else {
        debugPrint('⚠️ Invalid Supabase credentials - running in offline mode');
        debugPrint('   App functionality will be limited');
        debugPrint('   Get real key from: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/settings/api');
      }
    } catch (e, stack) {
      debugPrint('⚠️ Error during Supabase setup: $e');
      debugPrint('Stack: $stack');
      // Continue anyway - app can work with local storage
    }
    
    runApp(const CafenanceApp());
  } catch (e, stack) {
    debugPrint('💥 Fatal error in main: $e');
    debugPrint('Stack: $stack');
    // Run app anyway with minimal functionality
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('App initialization failed: $e'),
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
            title: 'Coffeenance - Coffee Shop Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: _buildHome(authProvider),
            builder: (context, widget) {
              // Add error boundary
              ErrorWidget.builder = (FlutterErrorDetails details) {
                debugPrint('Widget Error: ${details.exception}');
                debugPrint('Stack: ${details.stack}');
                return Material(
                  child: Container(
                    color: Colors.white,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'App Error: ${details.exception}',
                          style: const TextStyle(color: Colors.red),
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

  Widget _buildHome(AuthProvider authProvider) {
    // Show loading while checking auth
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If authenticated, show home screen
    // Otherwise, show login screen
    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      debugPrint('✅ User authenticated: ${authProvider.currentUser?.email}, showing HomeScreen');
      return const HomeScreen();
    } else {
      debugPrint('❌ No user authenticated, showing LoginScreen');
      return const LoginScreen();
    }
  }
}
