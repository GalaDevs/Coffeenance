/// Activity Log Model
/// Represents user actions for revenue and expense tracking
class ActivityLog {
  final String id;
  final String adminId;
  final String userId;
  final String userName;
  final String userRole;
  final ActivityAction actionType;
  final String? transactionId;
  final String? transactionType;
  final double? amount;
  final String? category;
  final String? description;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    required this.adminId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.actionType,
    this.transactionId,
    this.transactionType,
    this.amount,
    this.category,
    this.description,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'],
      adminId: json['admin_id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userRole: json['user_role'],
      actionType: ActivityAction.fromString(json['action_type']),
      transactionId: json['transaction_id'],
      transactionType: json['transaction_type'],
      amount: json['amount'] != null ? double.parse(json['amount'].toString()) : null,
      category: json['category'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get actionDisplay {
    switch (actionType) {
      case ActivityAction.addRevenue:
        return 'Added Revenue';
      case ActivityAction.addExpense:
        return 'Added Expense';
      case ActivityAction.editTransaction:
        return 'Edited Transaction';
      case ActivityAction.deleteTransaction:
        return 'Deleted Transaction';
    }
  }

  String get roleDisplay {
    return userRole[0].toUpperCase() + userRole.substring(1);
  }
}

enum ActivityAction {
  addRevenue,
  addExpense,
  editTransaction,
  deleteTransaction;

  String get value {
    switch (this) {
      case ActivityAction.addRevenue:
        return 'add_revenue';
      case ActivityAction.addExpense:
        return 'add_expense';
      case ActivityAction.editTransaction:
        return 'edit_transaction';
      case ActivityAction.deleteTransaction:
        return 'delete_transaction';
    }
  }

  static ActivityAction fromString(String value) {
    switch (value) {
      case 'add_revenue':
        return ActivityAction.addRevenue;
      case 'add_expense':
        return ActivityAction.addExpense;
      case 'edit_transaction':
        return ActivityAction.editTransaction;
      case 'delete_transaction':
        return ActivityAction.deleteTransaction;
      default:
        return ActivityAction.addRevenue;
    }
  }
}
