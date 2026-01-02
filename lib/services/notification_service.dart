import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import '../models/pending_transaction_edit.dart';
import '../models/transaction.dart';

/// Service for managing notifications and pending edits
class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================
  // Notifications
  // ============================================

  /// Get all notifications for current user
  Future<List<AppNotification>> getNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('⚠️ No user logged in for notifications');
        return [];
      }

      print('🔍 Fetching notifications for user: $userId');
      
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final notifications = (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
      
      print('📬 Found ${notifications.length} notifications');
      return notifications;
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      return true;
    } catch (e) {
      print('Error marking all as read: $e');
      return false;
    }
  }

  /// Create notification for transaction deletion by manager
  Future<bool> notifyTransactionDeleted({
    required String adminId,
    required String managerId,
    required String ownerId,
    required Transaction transaction,
  }) async {
    try {
      await _supabase.rpc('create_notification', params: {
        'p_user_id': adminId,
        'p_owner_id': ownerId,
        'p_type': 'transaction_deleted',
        'p_title': 'Transaction Deleted by Manager',
        'p_message': 'A transaction of ₱${transaction.amount.toStringAsFixed(2)} was deleted',
        'p_data': {
          'transaction_id': transaction.id,
          'deleted_by': managerId,
          'amount': transaction.amount,
          'description': transaction.description,
          'date': transaction.date,
        },
      });
      
      // Send email notification to owner
      await _sendEmailNotification(
        recipientId: adminId,
        subject: 'Transaction Deleted by Manager',
        message: 'A transaction of ₱${transaction.amount.toStringAsFixed(2)} was deleted on ${transaction.date}. Description: ${transaction.description}',
      );
      
      return true;
    } catch (e) {
      print('Error creating deletion notification: $e');
      return false;
    }
  }

  /// Create notification for edit request from staff
  Future<bool> notifyEditRequest({
    required String adminOrManagerId,
    required String staffId,
    required String ownerId,
    required String pendingEditId,
    required Transaction transaction,
  }) async {
    try {
      print('📨 Creating edit request notification:');
      print('  - Admin/Manager ID: $adminOrManagerId');
      print('  - Staff ID: $staffId');
      print('  - Owner ID: $ownerId');
      print('  - Pending Edit ID: $pendingEditId');
      
      final result = await _supabase.rpc('create_notification', params: {
        'p_user_id': adminOrManagerId,
        'p_owner_id': ownerId,
        'p_type': 'edit_request',
        'p_title': 'Edit Request from Staff',
        'p_message': 'A staff member requested to edit a transaction',
        'p_data': {
          'pending_edit_id': pendingEditId,
          'transaction_id': transaction.id,
          'requested_by': staffId,
        },
      });
      
      print('✅ Notification created successfully: $result');
      
      // Send email notification to admin/manager
      await _sendEmailNotification(
        recipientId: adminOrManagerId,
        subject: 'Edit Request from Staff',
        message: 'A staff member requested to edit a transaction. Please review the request in the app.',
      );
      
      return true;
    } catch (e) {
      print('❌ Error creating edit request notification: $e');
      return false;
    }
  }

  /// Subscribe to notifications realtime
  RealtimeChannel subscribeToNotifications({
    required Function(AppNotification) onNotification,
    required Function() onDelete,
  }) {
    final userId = _supabase.auth.currentUser?.id;
    
    final channel = _supabase
        .channel('notifications-${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: userId != null ? PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ) : null,
          callback: (payload) {
            try {
              final notification = AppNotification.fromJson(payload.newRecord);
              // Double check user_id matches
              if (notification.userId == userId) {
                onNotification(notification);
              }
            } catch (e) {
              print('Error processing notification: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: userId != null ? PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ) : null,
          callback: (payload) {
            try {
              final notification = AppNotification.fromJson(payload.newRecord);
              // Double check user_id matches
              if (notification.userId == userId) {
                onNotification(notification);
              }
            } catch (e) {
              print('Error processing notification update: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'notifications',
          filter: userId != null ? PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ) : null,
          callback: (payload) {
            onDelete();
          },
        )
        .subscribe();

    return channel;
  }

  // ============================================
  // Pending Transaction Edits
  // ============================================

  /// Get all pending edits (for admin/manager)
  Future<List<PendingTransactionEdit>> getPendingEdits() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('⚠️ No user logged in for pending edits');
        return [];
      }

      print('🔍 Fetching pending edits for user: $userId');

      // Get current user's admin_id from user_profiles
      final profileResponse = await _supabase
          .from('user_profiles')
          .select('admin_id, id')
          .eq('id', userId)
          .single();

      final userAdminId = profileResponse['admin_id'];
      // If admin_id is null, this user IS the admin, so use their own ID
      final adminId = userAdminId ?? profileResponse['id'];
      print('👤 User admin_id: $userAdminId, Effective admin ID: $adminId');

      print('🔎 Querying pending_transaction_edits with admin_id: $adminId');
      
      final response = await _supabase
          .from('pending_transaction_edits')
          .select()
          .eq('admin_id', adminId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final pendingEdits = (response as List)
          .map((json) => PendingTransactionEdit.fromJson(json))
          .toList();
      
      print('📝 Found ${pendingEdits.length} pending edits');
      return pendingEdits;
    } catch (e) {
      print('❌ Error fetching pending edits: $e');
      return [];
    }
  }

  /// Get pending edits count
  Future<int> getPendingEditsCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      // Get current user's admin_id from user_profiles
      final profileResponse = await _supabase
          .from('user_profiles')
          .select('admin_id, id')
          .eq('id', userId)
          .single();

      final userAdminId = profileResponse['admin_id'];
      // If admin_id is null, this user IS the admin, so use their own ID
      final adminId = userAdminId ?? profileResponse['id'];
      print('📊 Pending edits count for admin_id: $adminId');

      final response = await _supabase
          .from('pending_transaction_edits')
          .select('id')
          .eq('admin_id', adminId)
          .eq('status', 'pending');

      final count = (response as List).length;
      print('📊 Pending edits count: $count');
      return count;
    } catch (e) {
      print('❌ Error fetching pending edits count: $e');
      return 0;
    }
  }

  /// Create pending edit request (staff)
  Future<String?> createPendingEdit({
    required Transaction original,
    required Transaction edited,
    required String ownerId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('⚠️ No user logged in for createPendingEdit');
        return null;
      }

      print('📝 Creating pending edit:');
      print('   Transaction ID: ${original.id}');
      print('   User ID: $userId');
      print('   Owner ID: $ownerId');
      
      final response = await _supabase
          .from('pending_transaction_edits')
          .insert({
            'transaction_id': original.id,
            'user_id': userId,
            'admin_id': ownerId,
            'original_data': original.toJson(),
            'edited_data': edited.toJson(),
            'status': 'pending',
          })
          .select()
          .single();

      final pendingEditId = response['id'] as String;
      print('✅ Pending edit created with ID: $pendingEditId');
      return pendingEditId;
    } catch (e) {
      print('❌ Error creating pending edit: $e');
      return null;
    }
  }

  /// Approve pending edit (admin/manager)
  Future<bool> approvePendingEdit(String pendingEditId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Get the pending edit
      final editResponse = await _supabase
          .from('pending_transaction_edits')
          .select()
          .eq('id', pendingEditId)
          .single();

      final pendingEdit = PendingTransactionEdit.fromJson(editResponse);

      // Update the transaction
      await _supabase
          .from('transactions')
          .update(pendingEdit.editedData.toJson())
          .eq('id', pendingEdit.transactionId);

      // Mark as approved
      await _supabase
          .from('pending_transaction_edits')
          .update({
            'status': 'approved',
            'reviewed_by': userId,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', pendingEditId);

      // Notify the staff member
      await _supabase.rpc('create_notification', params: {
        'p_user_id': pendingEdit.userId,
        'p_owner_id': pendingEdit.ownerId,
        'p_type': 'edit_approved',
        'p_title': 'Edit Request Approved',
        'p_message': 'Your transaction edit request has been approved',
        'p_data': {
          'transaction_id': pendingEdit.transactionId,
          'approved_by': userId,
        },
      });

      return true;
    } catch (e) {
      print('Error approving pending edit: $e');
      return false;
    }
  }

  /// Reject pending edit (admin/manager)
  Future<bool> rejectPendingEdit(String pendingEditId, {String? reason}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Get the pending edit
      final editResponse = await _supabase
          .from('pending_transaction_edits')
          .select()
          .eq('id', pendingEditId)
          .single();

      final pendingEdit = PendingTransactionEdit.fromJson(editResponse);

      // Mark as rejected
      await _supabase
          .from('pending_transaction_edits')
          .update({
            'status': 'rejected',
            'reviewed_by': userId,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', pendingEditId);

      // Notify the staff member
      await _supabase.rpc('create_notification', params: {
        'p_user_id': pendingEdit.userId,
        'p_owner_id': pendingEdit.ownerId,
        'p_type': 'edit_rejected',
        'p_title': 'Edit Request Rejected',
        'p_message': reason ?? 'Your transaction edit request has been rejected',
        'p_data': {
          'transaction_id': pendingEdit.transactionId,
          'rejected_by': userId,
          'reason': reason,
        },
      });

      return true;
    } catch (e) {
      print('Error rejecting pending edit: $e');
      return false;
    }
  }

  /// Subscribe to pending edits realtime
  RealtimeChannel subscribeToPendingEdits({
    required Function(PendingTransactionEdit) onEdit,
    required Function() onUpdate,
  }) {
    final channel = _supabase
        .channel('pending-edits-${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'pending_transaction_edits',
          callback: (payload) {
            try {
              final edit = PendingTransactionEdit.fromJson(payload.newRecord);
              onEdit(edit);
            } catch (e) {
              print('Error processing pending edit: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'pending_transaction_edits',
          callback: (payload) {
            onUpdate();
          },
        )
        .subscribe();

    return channel;
  }
  
  // ============================================
  // Email Notifications
  // ============================================
  
  /// Send email notification to owner
  Future<void> _sendEmailNotification({
    required String recipientId,
    required String subject,
    required String message,
  }) async {
    try {
      // Get recipient email from user profile
      final profile = await _supabase
          .from('user_profiles')
          .select('email')
          .eq('id', recipientId)
          .single();
      
      if (profile == null || profile['email'] == null) {
        print('⚠️ No email found for user $recipientId');
        return;
      }
      
      final recipientEmail = profile['email'] as String;
      
      // Use Supabase Edge Function to send email
      // Note: You need to create this Edge Function in Supabase
      await _supabase.functions.invoke('send-email', body: {
        'to': recipientEmail,
        'subject': subject,
        'message': message,
      });
      
      print('✅ Email notification sent to $recipientEmail');
    } catch (e) {
      print('⚠️ Error sending email notification: $e');
      // Don't throw - email is optional, notification still created
    }
  }
}
