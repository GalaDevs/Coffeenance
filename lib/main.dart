import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

/// Main entry point - Matches Next.js layout.tsx and page.tsx
/// Provides state management and adaptive theming for iOS/Android/Web
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add error handling for crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
  };
  
  // Initialize Supabase with error handling
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('⚠️ Supabase initialization failed: $e');
    // Continue anyway - app can work with local storage
  }
  
  runApp(const CafenanceApp());
}

class CafenanceApp extends StatelessWidget {
  const CafenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Cafenance - Coffee Shop Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
            builder: (context, widget) {
              // Add error boundary
              ErrorWidget.builder = (FlutterErrorDetails details) {
                return Material(
                  child: Container(
                    color: Colors.white,
                    child: Center(
                      child: Text(
                        'App Error: ${details.exception}',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                );
              };
              return widget ?? SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
