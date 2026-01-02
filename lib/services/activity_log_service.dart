import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_log.dart';
import '../models/transaction.dart';

/// Service for managing activity logs
class ActivityLogService {
  final SupabaseClient _client;

  ActivityLogService(this._client);

  /// Get all activity logs for admin's circle
  Future<List<ActivityLog>> getActivityLogs({int limit = 100}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      // Get user's admin_id
      final userProfile = await _client
          .from('user_profiles')
          .select('admin_id, id, role')
          .eq('id', userId)
          .single();

      final adminId = userProfile['admin_id'] ?? userProfile['id'];

      final response = await _client
          .from('activity_logs')
          .select()
          .eq('admin_id', adminId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ActivityLog.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching activity logs: $e');
      return [];
    }
  }

  /// Log an activity
  Future<void> logActivity({
    required String userId,
    required String userName,
    required String userRole,
    required ActivityAction actionType,
    required String adminId,
    String? transactionId,
    String? transactionType,
    double? amount,
    String? category,
    String? description,
  }) async {
    try {
      await _client.from('activity_logs').insert({
        'admin_id': adminId,
        'user_id': userId,
        'user_name': userName,
        'user_role': userRole,
        'action_type': actionType.value,
        'transaction_id': transactionId,
        'transaction_type': transactionType,
        'amount': amount,
        'category': category,
        'description': description,
      });
      print('✅ Activity logged: ${actionType.value} by $userName');
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  /// Log transaction addition
  Future<void> logTransactionAdd({
    required String userId,
    required String userName,
    required String userRole,
    required String adminId,
    required Transaction transaction,
  }) async {
    final actionType = transaction.type == TransactionType.revenue
        ? ActivityAction.addRevenue
        : ActivityAction.addExpense;

    await logActivity(
      userId: userId,
      userName: userName,
      userRole: userRole,
      adminId: adminId,
      actionType: actionType,
      transactionId: transaction.id.toString(),
      transactionType: transaction.type == TransactionType.revenue ? 'revenue' : 'expense',
      amount: transaction.amount,
      category: transaction.category,
      description: transaction.description,
    );
  }

  /// Get activity logs filtered by action type
  Future<List<ActivityLog>> getActivityLogsByType(ActivityAction actionType) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final userProfile = await _client
          .from('user_profiles')
          .select('admin_id, id')
          .eq('id', userId)
          .single();

      final adminId = userProfile['admin_id'] ?? userProfile['id'];

      final response = await _client
          .from('activity_logs')
          .select()
          .eq('admin_id', adminId)
          .eq('action_type', actionType.value)
          .order('created_at', ascending: false)
          .limit(100);

      return (response as List)
          .map((json) => ActivityLog.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching filtered activity logs: $e');
      return [];
    }
  }

  /// Get activity log statistics
  Future<Map<String, int>> getActivityStats() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return {};

      final userProfile = await _client
          .from('user_profiles')
          .select('admin_id, id')
          .eq('id', userId)
          .single();

      final adminId = userProfile['admin_id'] ?? userProfile['id'];

      final response = await _client
          .from('activity_logs')
          .select()
          .eq('admin_id', adminId);

      final logs = (response as List)
          .map((json) => ActivityLog.fromJson(json))
          .toList();

      return {
        'total': logs.length,
        'add_revenue': logs.where((l) => l.actionType == ActivityAction.addRevenue).length,
        'add_expense': logs.where((l) => l.actionType == ActivityAction.addExpense).length,
        'edit_transaction': logs.where((l) => l.actionType == ActivityAction.editTransaction).length,
        'delete_transaction': logs.where((l) => l.actionType == ActivityAction.deleteTransaction).length,
      };
    } catch (e) {
      print('Error getting activity stats: $e');
      return {};
    }
  }
}
