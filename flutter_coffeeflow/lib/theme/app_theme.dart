import 'package:flutter/material.dart';

/// Coffee-themed color palette matching Next.js globals.css
/// Converted from oklch color space to Flutter Color values
class AppColors {
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFAFAFA); // oklch(0.98 0 0)
  static const Color lightForeground = Color(0xFF404040); // oklch(0.25 0 0)
  static const Color lightCard = Color(0xFFFFFFFF); // oklch(1 0 0)
  static const Color lightCardForeground = Color(0xFF404040);
  
  // Primary: Rich coffee brown
  static const Color lightPrimary = Color(0xFF5C4033); // oklch(0.35 0.08 44)
  static const Color lightPrimaryForeground = Color(0xFFFAFAFA);
  
  // Secondary: Warm cream/tan
  static const Color lightSecondary = Color(0xFFEBE7E0); // oklch(0.92 0.02 44)
  static const Color lightSecondaryForeground = Color(0xFF5C4033);
  
  // Muted: Light beige
  static const Color lightMuted = Color(0xFFE0DCD4); // oklch(0.88 0.01 44)
  static const Color lightMutedForeground = Color(0xFF808080);
  
  // Accent: Medium caramel brown
  static const Color lightAccent = Color(0xFF8B6F47); // oklch(0.55 0.06 44)
  static const Color lightAccentForeground = Color(0xFFFAFAFA);
  
  // Destructive
  static const Color lightDestructive = Color(0xFFDC2626);
  static const Color lightDestructiveForeground = Color(0xFFFAFAFA);
  
  // Border & Input
  static const Color lightBorder = Color(0xFFEBE7E0);
  static const Color lightInput = Color(0xFFF2F0EB);
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF262626); // oklch(0.15 0 0)
  static const Color darkForeground = Color(0xFFEBEBEB); // oklch(0.92 0 0)
  static const Color darkCard = Color(0xFF383838); // oklch(0.22 0 0)
  static const Color darkCardForeground = Color(0xFFEBEBEB);
  
  // Primary: Rich coffee brown (lighter in dark mode)
  static const Color darkPrimary = Color(0xFFA67C52); // oklch(0.65 0.08 44)
  static const Color darkPrimaryForeground = Color(0xFF262626);
  
  // Secondary: Warm cream/tan (darker in dark mode)
  static const Color darkSecondary = Color(0xFF474340); // oklch(0.28 0.02 44)
  static const Color darkSecondaryForeground = Color(0xFFEBEBEB);
  
  // Muted
  static const Color darkMuted = Color(0xFF595550); // oklch(0.35 0.01 44)
  static const Color darkMutedForeground = Color(0xFFB3B3B3);
  
  // Accent
  static const Color darkAccent = Color(0xFFBFA080); // oklch(0.75 0.06 44)
  static const Color darkAccentForeground = Color(0xFF262626);
  
  // Destructive
  static const Color darkDestructive = Color(0xFF991B1B);
  static const Color darkDestructiveForeground = Color(0xFFEBEBEB);
  
  // Border & Input
  static const Color darkBorder = Color(0xFF4D4A47);
  static const Color darkInput = Color(0xFF474340);
  
  // Chart Colors (warm tones)
  static const Color chart1 = Color(0xFF5C4033);
  static const Color chart2 = Color(0xFF8B6F47);
  static const Color chart3 = Color(0xFFB39A7A);
  static const Color chart4 = Color(0xFF735D42);
  static const Color chart5 = Color(0xFF9E826B);
  
  // Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFEA580C);
  static const Color info = Color(0xFF0284C7);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: AppColors.lightPrimary,
      onPrimary: AppColors.lightPrimaryForeground,
      secondary: AppColors.lightSecondary,
      onSecondary: AppColors.lightSecondaryForeground,
      surface: AppColors.lightCard,
      onSurface: AppColors.lightCardForeground,
      error: AppColors.lightDestructive,
      onError: AppColors.lightDestructiveForeground,
      outline: AppColors.lightBorder,
    ),
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightBorder, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightForeground,
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightCard,
      selectedItemColor: AppColors.lightPrimary,
      unselectedItemColor: AppColors.lightMutedForeground,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: AppColors.lightForeground,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.lightForeground,
      ),
      displaySmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.lightForeground,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.lightForeground,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.lightForeground,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.lightForeground,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppColors.lightMutedForeground,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.lightPrimaryForeground,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkPrimaryForeground,
      secondary: AppColors.darkSecondary,
      onSecondary: AppColors.darkSecondaryForeground,
      surface: AppColors.darkCard,
      onSurface: AppColors.darkCardForeground,
      error: AppColors.darkDestructive,
      onError: AppColors.darkDestructiveForeground,
      outline: AppColors.darkBorder,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkForeground,
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkCard,
      selectedItemColor: AppColors.darkPrimary,
      unselectedItemColor: AppColors.darkMutedForeground,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: AppColors.darkForeground,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.darkForeground,
      ),
      displaySmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.darkForeground,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.darkForeground,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.darkForeground,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.darkForeground,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppColors.darkMutedForeground,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkPrimaryForeground,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}
