import 'package:json_annotation/json_annotation.dart';

part 'transaction.g.dart';

/// Transaction model matching Next.js transaction structure
/// Maps from: { id, date, type, category, description, amount }
@JsonSerializable()
class Transaction {
  final int id;
  final String date; // ISO format: "2025-11-09"
  final TransactionType type;
  final String category;
  final String description;
  final double amount;

  Transaction({
    required this.id,
    required this.date,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  Transaction copyWith({
    int? id,
    String? date,
    TransactionType? type,
    String? category,
    String? description,
    double? amount,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
    );
  }
}

enum TransactionType {
  @JsonValue('income')
  income,
  @JsonValue('expense')
  expense,
}

/// Income categories matching Next.js INCOME_CATEGORIES
class IncomeCategories {
  static const String cash = 'Cash';
  static const String gcash = 'GCash';
  static const String grab = 'Grab';
  static const String paymaya = 'PayMaya';

  static const List<String> all = [cash, gcash, grab, paymaya];
}

/// Expense categories matching Next.js EXPENSE_CATEGORIES
class ExpenseCategories {
  static const String supplies = 'Supplies';
  static const String pastries = 'Pastries';
  static const String rent = 'Rent';
  static const String utilities = 'Utilities';
  static const String manpower = 'Manpower';
  static const String marketing = 'Marketing';
  static const String others = 'Others';

  static const List<String> all = [
    supplies,
    pastries,
    rent,
    utilities,
    manpower,
    marketing,
    others,
  ];
}
