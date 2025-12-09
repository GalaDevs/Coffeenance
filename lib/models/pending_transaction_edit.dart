import '../models/transaction.dart';

/// Pending transaction edit model for staff edit requests
class PendingTransactionEdit {
  final String id;
  final String transactionId;
  final String userId;
  final String ownerId;
  final Transaction originalData;
  final Transaction editedData;
  final EditStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PendingTransactionEdit({
    required this.id,
    required this.transactionId,
    required this.userId,
    required this.ownerId,
    required this.originalData,
    required this.editedData,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PendingTransactionEdit.fromJson(Map<String, dynamic> json) {
    return PendingTransactionEdit(
      id: json['id'] as String,
      transactionId: json['transaction_id'].toString(),
      userId: json['user_id'] as String,
      ownerId: json['admin_id'] as String,
      originalData: Transaction.fromJson(json['original_data'] as Map<String, dynamic>),
      editedData: Transaction.fromJson(json['edited_data'] as Map<String, dynamic>),
      status: EditStatus.fromString(json['status'] as String),
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'user_id': userId,
      'admin_id': ownerId,
      'original_data': originalData.toJson(),
      'edited_data': editedData.toJson(),
      'status': status.value,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PendingTransactionEdit copyWith({
    String? id,
    String? transactionId,
    String? userId,
    String? ownerId,
    Transaction? originalData,
    Transaction? editedData,
    EditStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PendingTransactionEdit(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      userId: userId ?? this.userId,
      ownerId: ownerId ?? this.ownerId,
      originalData: originalData ?? this.originalData,
      editedData: editedData ?? this.editedData,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum EditStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  final String value;
  const EditStatus(this.value);

  static EditStatus fromString(String value) {
    return EditStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EditStatus.pending,
    );
  }
}
