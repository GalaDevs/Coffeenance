import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

/// Sales Breakdown Widget - Matches sales-breakdown.tsx
class SalesBreakdown extends StatelessWidget {
  final Map<String, double> salesByMethod;
  final double totalSales;

  const SalesBreakdown({
    super.key,
    required this.salesByMethod,
    required this.totalSales,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 0,
    );

    // Filter out zero amounts and calculate percentages
    final salesData = salesByMethod.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {
              'method': entry.key,
              'amount': entry.value,
              'percentage': totalSales > 0
                  ? ((entry.value / totalSales) * 100).round()
                  : 0,
            })
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sales Breakdown',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        if (salesData.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No sales recorded yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: salesData.map((data) {
                  final method = data['method'] as String;
                  final amount = data['amount'] as double;
                  final percentage = data['percentage'] as int;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _getMethodIcon(method),
                                const SizedBox(width: 12),
                                Text(
                                  method,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              numberFormat.format(amount),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD97706), // Amber color
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            minHeight: 8,
                            backgroundColor: theme.colorScheme.secondary,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFD97706), // Amber color
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$percentage% of sales',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _getMethodIcon(String method) {
    IconData icon;
    Color color;

    switch (method) {
      case 'Cash':
        icon = Icons.payments_outlined;
        color = Colors.green;
        break;
      case 'GCash':
        icon = Icons.account_balance_wallet_outlined;
        color = Colors.blue;
        break;
      case 'Grab':
        icon = Icons.directions_car_outlined;
        color = Colors.green.shade700;
        break;
      case 'PayMaya':
        icon = Icons.credit_card;
        color = Colors.green.shade600;
        break;
      default:
        icon = Icons.attach_money;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 20);
  }
}
