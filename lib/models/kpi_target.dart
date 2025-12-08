/// KPI Target Model - Represents a target stored in Supabase
/// Supports cloud sync, multi-device access, and team sharing
class KPITarget {
  final String id;
  final String shopId;
  final String userId;
  final String targetKey;
  final double targetValue;
  final int? month; // 1-12 for month-specific, null for general
  final int? year; // Year for month-specific, null for general
  final DateTime createdAt;
  final DateTime updatedAt;

  KPITarget({
    required this.id,
    required this.shopId,
    required this.userId,
    required this.targetKey,
    required this.targetValue,
    this.month,
    this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create KPITarget from Supabase JSON
  factory KPITarget.fromJson(Map<String, dynamic> json) {
    return KPITarget(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      userId: json['user_id'] as String,
      targetKey: json['target_key'] as String,
      targetValue: (json['target_value'] as num).toDouble(),
      month: json['month'] as int?,
      year: json['year'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert KPITarget to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'user_id': userId,
      'target_key': targetKey,
      'target_value': targetValue,
      'month': month,
      'year': year,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to insert/update format (without id, timestamps)
  Map<String, dynamic> toInsertJson() {
    return {
      'shop_id': shopId,
      'user_id': userId,
      'target_key': targetKey,
      'target_value': targetValue,
      'month': month,
      'year': year,
    };
  }

  /// Create a copy with updated values
  KPITarget copyWith({
    String? id,
    String? shopId,
    String? userId,
    String? targetKey,
    double? targetValue,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KPITarget(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      userId: userId ?? this.userId,
      targetKey: targetKey ?? this.targetKey,
      targetValue: targetValue ?? this.targetValue,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'KPITarget(key: $targetKey, value: $targetValue, month: $month, year: $year)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KPITarget &&
        other.id == id &&
        other.shopId == shopId &&
        other.targetKey == targetKey &&
        other.month == month &&
        other.year == year;
  }

  @override
  int get hashCode {
    return Object.hash(id, shopId, targetKey, month, year);
  }
}
