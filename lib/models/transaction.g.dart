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
      paymentMethod: json['paymentMethod'] as String,
      transactionNumber: json['transactionNumber'] as String,
      receiptNumber: json['receiptNumber'] as String,
      tinNumber: json['tinNumber'] as String? ?? '',
      vat: (json['vat'] as num?)?.toInt() ?? 0,
      supplierName: json['supplierName'] as String? ?? '',
      supplierAddress: json['supplierAddress'] as String? ?? '',
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'category': instance.category,
      'description': instance.description,
      'amount': instance.amount,
      'paymentMethod': instance.paymentMethod,
      'transactionNumber': instance.transactionNumber,
      'receiptNumber': instance.receiptNumber,
      'tinNumber': instance.tinNumber,
      'vat': instance.vat,
      'supplierName': instance.supplierName,
      'supplierAddress': instance.supplierAddress,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.revenue: 'revenue',
  TransactionType.transaction: 'transaction',
};
