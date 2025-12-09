import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import '../models/pending_transaction_edit.dart';
import '../services/notification_service.dart';

/// Provider for managing notifications and pending edits
class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<AppNotification> _notifications = [];
  List<PendingTransactionEdit> _pendingEdits = [];
  int _unreadCount = 0;
  int _pendingCount = 0;
  bool _isLoading = false;
  RealtimeChannel? _notificationChannel;
  RealtimeChannel? _pendingEditsChannel;

  List<AppNotification> get notifications => _notifications;
  List<PendingTransactionEdit> get pendingEdits => _pendingEdits;
  int get unreadCount => _unreadCount;
  int get pendingCount => _pendingCount;
  int get totalBadgeCount => _unreadCount + _pendingCount;
  bool get isLoading => _isLoading;

  /// Initialize notification provider with realtime subscriptions
  Future<void> initialize() async {
    await loadNotifications();
    await loadPendingEdits();
    _setupRealtimeSubscriptions();
  }

  /// Load notifications from database
  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _notificationService.getNotifications();
      _unreadCount = await _notificationService.getUnreadCount();
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load pending edits from database
  Future<void> loadPendingEdits() async {
    try {
      _pendingEdits = await _notificationService.getPendingEdits();
      _pendingCount = await _notificationService.getPendingEditsCount();
      notifyListeners();
    } catch (e) {
      print('Error loading pending edits: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final success = await _notificationService.markAsRead(notificationId);
    if (success) {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final success = await _notificationService.markAllAsRead();
    if (success) {
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    }
  }

  /// Approve pending edit
  Future<bool> approvePendingEdit(String pendingEditId) async {
    final success = await _notificationService.approvePendingEdit(pendingEditId);
    if (success) {
      await loadPendingEdits();
    }
    return success;
  }

  /// Reject pending edit
  Future<bool> rejectPendingEdit(String pendingEditId, {String? reason}) async {
    final success = await _notificationService.rejectPendingEdit(
      pendingEditId,
      reason: reason,
    );
    if (success) {
      await loadPendingEdits();
    }
    return success;
  }

  /// Setup realtime subscriptions
  void _setupRealtimeSubscriptions() {
    // Subscribe to notifications
    _notificationChannel = _notificationService.subscribeToNotifications(
      onNotification: (notification) {
        // Check if notification already exists
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          // Update existing
          _notifications[index] = notification;
        } else {
          // Add new
          _notifications.insert(0, notification);
        }
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      },
      onDelete: () {
        loadNotifications();
      },
    );

    // Subscribe to pending edits
    _pendingEditsChannel = _notificationService.subscribeToPendingEdits(
      onEdit: (edit) {
        final index = _pendingEdits.indexWhere((e) => e.id == edit.id);
        if (index != -1) {
          _pendingEdits[index] = edit;
        } else {
          _pendingEdits.insert(0, edit);
          _pendingCount++;
        }
        notifyListeners();
      },
      onUpdate: () {
        loadPendingEdits();
      },
    );
  }

  /// Dispose and cleanup
  @override
  void dispose() {
    _notificationChannel?.unsubscribe();
    _pendingEditsChannel?.unsubscribe();
    super.dispose();
  }

  /// Clear all data (on logout)
  void clear() {
    _notifications = [];
    _pendingEdits = [];
    _unreadCount = 0;
    _pendingCount = 0;
    _notificationChannel?.unsubscribe();
    _pendingEditsChannel?.unsubscribe();
    notifyListeners();
  }
}
