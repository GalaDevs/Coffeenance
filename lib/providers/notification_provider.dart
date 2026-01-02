import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  Function(AppNotification)? _newAnnouncementCallback;

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
      print('📬 Loading notifications from database...');
      _notifications = await _notificationService.getNotifications();
      _unreadCount = await _notificationService.getUnreadCount();
      print('📬 Loaded ${_notifications.length} notifications, ${_unreadCount} unread');
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

  /// Get unread announcements
  List<AppNotification> getUnreadAnnouncements() {
    return _notifications
        .where((n) => n.type == NotificationType.announcement && !n.isRead)
        .toList();
  }

  /// Set callback for new announcements
  void setAnnouncementCallback(Function(AppNotification)? callback) {
    _newAnnouncementCallback = callback;
  }

  /// Check for announcements that were made while user was logged out
  Future<void> syncMissedAnnouncements() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      print('📢 Syncing missed announcements for user...');

      // Get user's admin_id
      final userProfile = await Supabase.instance.client
          .from('user_profiles')
          .select('admin_id')
          .eq('id', userId)
          .single();

      final adminId = userProfile['admin_id'] ?? userId;

      // Get all announced announcements
      final announcementsResponse = await Supabase.instance.client
          .from('announcements')
          .select('id, title, description, download_link, created_by')
          .not('announced_at', 'is', null)
          .eq('is_active', true);

      final announcements = announcementsResponse as List;
      print('📢 Found ${announcements.length} total announced announcements');

      // Get existing notification IDs for this user
      final existingNotifications = await Supabase.instance.client
          .from('notifications')
          .select('data')
          .eq('user_id', userId)
          .eq('type', 'announcement');

      final existingAnnouncementIds = (existingNotifications as List)
          .map((n) => (n['data'] as Map)['announcement_id'] as String?)
          .where((id) => id != null)
          .toSet();

      print('📢 User already has ${existingAnnouncementIds.length} announcement notifications');

      // Create notifications for missed announcements
      final missedAnnouncements = announcements
          .where((a) => !existingAnnouncementIds.contains(a['id']))
          .toList();

      if (missedAnnouncements.isNotEmpty) {
        print('📢 Creating ${missedAnnouncements.length} missed announcement notifications');

        final newNotifications = missedAnnouncements.map((announcement) {
          final data = {
            'announcement_id': announcement['id'],
          };
          if (announcement['download_link'] != null && (announcement['download_link'] as String).isNotEmpty) {
            data['download_link'] = announcement['download_link'];
          }
          
          return {
            'user_id': userId,
            'admin_id': adminId,
            'type': 'announcement',
            'title': announcement['title'],
            'message': announcement['description'],
            'data': data,
            'is_read': false,
            'created_by': announcement['created_by'],
          };
        }).toList();

        await Supabase.instance.client
            .from('notifications')
            .insert(newNotifications);

        print('📢 Successfully created ${newNotifications.length} missed notifications');
        
        // Reload notifications to include the new ones
        await loadNotifications();
      } else {
        print('📢 No missed announcements');
      }
    } catch (e) {
      print('📢 Error syncing missed announcements: $e');
    }
  }

  /// Show announcement popups
  Future<void> showAnnouncementPopups(BuildContext context) async {
    // First, sync any missed announcements
    await syncMissedAnnouncements();
    
    final announcements = getUnreadAnnouncements();
    print('🎯 Checking for unread announcements...');
    print('🎯 Found ${announcements.length} unread announcements');
    
    for (final announcement in announcements) {
      print('🎯 Showing announcement: ${announcement.title}');
      
      // Get download link from notification data if available
      final downloadLink = announcement.data['download_link'] as String?;
      
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.campaign_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  announcement.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              announcement.message,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          actions: [
            if (downloadLink != null && downloadLink.isNotEmpty)
              TextButton.icon(
                onPressed: () async {
                  // Open download link
                  try {
                    final uri = Uri.parse(downloadLink);
                    // Use url_launcher or similar to open the link
                    // For now, just print it
                    print('📥 Opening download link: $downloadLink');
                    
                    // Import url_launcher at the top of file
                    // await launchUrl(uri, mode: LaunchMode.externalApplication);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening: $downloadLink'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error opening link: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid download link'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('Download'),
              ),
            FilledButton(
              onPressed: () async {
                // Mark as read and close
                await markAsRead(announcement.id);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Got it'),
            ),
          ],
        ),
      );
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
        
        // Trigger announcement popup callback if it's an announcement
        if (notification.type == NotificationType.announcement && !notification.isRead) {
          print('🔥 REALTIME: Triggering announcement callback for: ${notification.title}');
          _newAnnouncementCallback?.call(notification);
        } else {
          print('🔥 REALTIME: New notification (type: ${notification.type.value}): ${notification.title}');
        }
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
