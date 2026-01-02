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
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'transaction_number')
  final String transactionNumber;
  @JsonKey(name: 'receipt_number')
  final String receiptNumber;
  @JsonKey(name: 'tin_number')
  final String tinNumber;
  final int vat;
  @JsonKey(name: 'supplier_name')
  final String supplierName;
  @JsonKey(name: 'supplier_address')
  final String supplierAddress;
  @JsonKey(name: 'sub_category')
  final String subCategory;
  @JsonKey(name: 'invoice_number')
  final String invoiceNumber;

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
    this.subCategory = '',
    this.invoiceNumber = '',
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
    String? subCategory,
    String? invoiceNumber,
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
      subCategory: subCategory ?? this.subCategory,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
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
  static const String transpoAndDeliveries = 'Transpo and Deliveries';
  static const String rm = 'R&M';
  static const String mandatories = 'MANDATORIES';
  static const String pestControl = 'Pest control';
  static const String misc = 'MISC';
  static const String commissions = 'COMMISIONS';
  static const String taxes = 'TAXES';
  static const String others = 'OTHERS';

  static const List<String> all = [
    supplies,
    pastries,
    rent,
    utilities,
    manpower,
    marketing,
    transpoAndDeliveries,
    rm,
    mandatories,
    pestControl,
    misc,
    commissions,
    taxes,
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
