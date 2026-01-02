// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      category: json['category'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String? ?? '',
      transactionNumber: json['transaction_number'] as String? ?? '',
      receiptNumber: json['receipt_number'] as String? ?? '',
      tinNumber: json['tin_number'] as String? ?? '',
      vat: (json['vat'] as num?)?.toInt() ?? 0,
      supplierName: json['supplier_name'] as String? ?? '',
      supplierAddress: json['supplier_address'] as String? ?? '',
      subCategory: json['sub_category'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? '',
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'category': instance.category,
      'description': instance.description,
      'amount': instance.amount,
      'payment_method': instance.paymentMethod,
      'transaction_number': instance.transactionNumber,
      'receipt_number': instance.receiptNumber,
      'tin_number': instance.tinNumber,
      'vat': instance.vat,
      'supplier_name': instance.supplierName,
      'supplier_address': instance.supplierAddress,
      'sub_category': instance.subCategory,
      'invoice_number': instance.invoiceNumber,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.revenue: 'revenue',
  TransactionType.transaction: 'transaction',
  TransactionType.income: 'income',
  TransactionType.expense: 'expense',
};
