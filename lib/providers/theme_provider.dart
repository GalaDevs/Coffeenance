import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Provider - Manages dark/light mode state
/// Persists theme preference using SharedPreferences
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = true;

  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadThemePreference();
  }

  /// Load theme preference from storage
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('isDarkMode');
      
      if (isDark != null) {
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      } else {
        // Default to light mode
        _themeMode = ThemeMode.light;
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
      // Default to light mode on error
      _themeMode = ThemeMode.light;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', isDark);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  /// Set theme mode explicitly
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.system) {
        await prefs.remove('isDarkMode');
      } else {
        await prefs.setBool('isDarkMode', mode == ThemeMode.dark);
      }
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  /// Reset to system theme
  Future<void> useSystemTheme() async {
    _themeMode = ThemeMode.system;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isDarkMode');
    } catch (e) {
      debugPrint('Error resetting theme preference: $e');
    }
  }
}
