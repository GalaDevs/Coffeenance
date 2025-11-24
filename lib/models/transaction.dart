import 'package:json_annotation/json_annotation.dart';

part 'transaction.g.dart';

/// Transaction model matching Next.js transaction structure
/// Maps from: { id, date, type, category, description, amount, paymentMethod, transactionNumber, receiptNumber, tinNumber, vat, supplierName, supplierAddress }
@JsonSerializable()
class Transaction {
  final int id;
  final String date; // ISO format: "2025-11-09"
  final TransactionType type;
  final String category;
  final String description;
  final double amount;
  final String paymentMethod;
  final String transactionNumber;
  final String receiptNumber;
  final String tinNumber;
  final int vat;
  final String supplierName;
  final String supplierAddress;

  Transaction({
    required this.id,
    required this.date,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    this.paymentMethod = '',
    this.transactionNumber = '',
    this.receiptNumber = '',
    this.tinNumber = '',
    this.vat = 0,
    this.supplierName = '',
    this.supplierAddress = '',
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
    String? paymentMethod,
    String? transactionNumber,
    String? receiptNumber,
    String? tinNumber,
    int? vat,
    String? supplierName,
    String? supplierAddress,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      tinNumber: tinNumber ?? this.tinNumber,
      vat: vat ?? this.vat,
      supplierName: supplierName ?? this.supplierName,
      supplierAddress: supplierAddress ?? this.supplierAddress,
    );
  }
}

enum TransactionType {
  @JsonValue('revenue')
  revenue,
  @JsonValue('transaction')
  transaction,
  
  // Backward compatibility aliases
  @JsonValue('income')
  income,
  @JsonValue('expense')
  expense,
}

/// Revenue categories matching Next.js REVENUE_CATEGORIES
class RevenueCategories {
  static const String cash = 'Cash';
  static const String gcash = 'GCash';
  static const String grab = 'Grab';
  static const String paymaya = 'Maya';
  static const String creditCard = 'Credit Card';
  static const String others = 'Others';

  static const List<String> all = [cash, gcash, grab, paymaya, creditCard, others];
}

/// Transaction categories matching Next.js TRANSACTION_CATEGORIES
class TransactionCategories {
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

// Type aliases for backward compatibility
typedef IncomeCategories = RevenueCategories;
typedef ExpenseCategories = TransactionCategories;

/// Payment methods matching Next.js PAYMENT_METHODS
class PaymentMethods {
  static const String cash = 'Cash';
  static const String check = 'Check';
  static const String bankTransfer = 'Bank Transfer';
  static const String creditCard = 'Credit Card';
  static const String gcash = 'GCash';
  static const String paymaya = 'Maya';
  static const String others = 'Others';

  static const List<String> all = [
    cash,
    check,
    bankTransfer,
    creditCard,
    gcash,
    paymaya,
    others,
  ];
}
