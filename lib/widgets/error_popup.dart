import 'package:flutter/material.dart';

/// Simple toast notification system
class Toast {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static String? _pendingMessage;
  static bool _pendingIsError = true;

  /// Show error toast
  static void error(BuildContext context, String message) {
    _show(context, _simplify(message), Colors.red[700]!, Icons.error_outline);
  }

  /// Show success toast
  static void success(BuildContext context, String message) {
    _show(context, message, Colors.green[700]!, Icons.check_circle_outline);
  }

  /// Show warning toast
  static void warning(BuildContext context, String message) {
    _show(context, message, Colors.orange[700]!, Icons.warning_amber);
  }

  /// Show info toast
  static void info(BuildContext context, String message) {
    _show(context, message, Colors.blue[700]!, Icons.info_outline);
  }

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  /// Show error from anywhere using navigator key
  static void showGlobal(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      error(context, message);
    } else {
      _pendingMessage = message;
      _pendingIsError = true;
    }
  }

  /// Queue error for later display
  static void queueError(String title, String message) {
    _pendingMessage = message;
    _pendingIsError = true;
  }

  /// Show pending message if any
  static void showPendingErrors(BuildContext context) {
    if (_pendingMessage != null) {
      if (_pendingIsError) {
        error(context, _pendingMessage!);
      } else {
        info(context, _pendingMessage!);
      }
      _pendingMessage = null;
    }
  }

  static bool get hasPendingErrors => _pendingMessage != null;

  /// Convert technical error to simple message
  static String getUserFriendlyMessage(dynamic error) {
    return _simplify(error.toString());
  }

  /// Simplify error messages for users
  static String _simplify(String error) {
    final lower = error.toLowerCase();

    // Network errors
    if (lower.contains('socket') || lower.contains('network') || lower.contains('internet')) {
      return 'No internet connection';
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Connection timed out';
    }
    if (lower.contains('server') || lower.contains('502') || lower.contains('503')) {
      return 'Server unavailable';
    }

    // Auth errors - Wrong password
    if (lower.contains('invalid login') || 
        lower.contains('invalid credentials') ||
        lower.contains('wrong password') ||
        lower.contains('incorrect password')) {
      return 'Wrong password';
    }
    // Email not verified
    if (lower.contains('email not confirmed') || lower.contains('not verified')) {
      return 'Please verify your email';
    }
    // Account not registered
    if (lower.contains('user not found') || 
        lower.contains('no account') ||
        lower.contains('user_not_found')) {
      return 'Account is not registered';
    }

    // Database/RLS errors - Account not registered
    if (lower.contains('row-level security') || lower.contains('42501') || lower.contains('unauthorized')) {
      return 'Account is not registered';
    }
    if (lower.contains('postgrest') || lower.contains('violates')) {
      return 'Account is not registered';
    }

    // Permission errors
    if (lower.contains('permission') || lower.contains('denied')) {
      return 'Permission denied';
    }

    // Login/auth related generic errors
    if (lower.contains('login') || lower.contains('auth') || lower.contains('sign')) {
      return 'Wrong email or password';
    }

    // Generic - hide technical details
    return 'Something went wrong';
  }
}

// Backwards compatibility aliases
class ErrorPopup {
  static GlobalKey<NavigatorState> get navigatorKey => Toast.navigatorKey;
  static void show(BuildContext context, String message) => Toast.error(context, message);
  static void showGlobal(String message) => Toast.showGlobal(message);
  static void queueError(String title, String message) => Toast.queueError(title, message);
  static void showPendingErrors(BuildContext context) => Toast.showPendingErrors(context);
  static bool get hasPendingErrors => Toast.hasPendingErrors;
  static String getUserFriendlyMessage(dynamic error) => Toast.getUserFriendlyMessage(error);
}

class ErrorSnackBar {
  static void show(BuildContext context, String message) => Toast.error(context, message);
  static void showWarning(BuildContext context, String message) => Toast.warning(context, message);
}
