import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

/// Sales Page Screen - Matches sales-page.tsx
/// Shows sales report with payment method breakdown
class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final salesData = provider.salesByMethod.entries
            .where((entry) => entry.value > 0)
            .map((entry) => {
                  'method': entry.key,
                  'amount': entry.value,
                  'percentage': provider.totalIncome > 0
                      ? ((entry.value / provider.totalIncome) * 100).round()
                      : 0,
                })
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - matches Next.js
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sales Report',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Payment method breakdown',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Total Sales Card - matches Next.js exactly
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFD97706), // from-amber-600
                      Color(0xFFB45309), // to-amber-700
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16), // rounded-2xl
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24), // p-6
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Sales',
                      style: TextStyle(
                        fontSize: 14, // text-sm
                        fontWeight: FontWeight.w500, // font-medium
                        color: Colors.white.withOpacity(0.9), // opacity-90
                      ),
                    ),
                    const SizedBox(height: 8), // mt-2
                    Text(
                      '₱${provider.totalIncome.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 28, // Reduced from 36
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12), // mt-3
                    Text(
                      '${provider.incomeTransactions.length} transactions',
                      style: TextStyle(
                        fontSize: 12, // text-xs
                        color: Colors.white.withOpacity(0.75), // opacity-75
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sales by Method - matches Next.js
              Text(
                'Sales by Method',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 18, // text-lg
                  fontWeight: FontWeight.bold, // font-bold
                ),
              ),
              const SizedBox(height: 12),

              if (salesData.isEmpty)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // rounded-lg
                    side: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No sales data available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                )
              else
                ...salesData.map((data) {
                  final method = data['method'] as String;
                  final amount = data['amount'] as double;
                  final percentage = data['percentage'] as int;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 0, // matches Next.js flat design
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // rounded-lg
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.2), // border-border
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16), // p-4
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row - method name and amount - matches Next.js
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  method,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 16, // text-base font-medium
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '₱${NumberFormat('#,###').format(amount)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 14, // text-sm
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary, // text-primary
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8), // mb-2
                            // Progress bar with gradient - matches Next.js
                            Container(
                              height: 8, // h-2
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9999), // rounded-full
                                color: theme.colorScheme.surfaceContainerHighest, // bg-secondary
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: percentage / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9999), // rounded-full
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFF59E0B), // from-amber-500
                                        Color(0xFFD97706), // to-amber-600
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4), // mt-1
                            // Percentage text below progress bar - matches Next.js
                            Text(
                              '$percentage% of sales',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12, // text-xs
                                color: theme.colorScheme.onSurface.withOpacity(0.6), // text-muted-foreground
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),

              // Recent Sales - matches Next.js
              Text(
                'Recent Sales',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 18, // text-lg
                  fontWeight: FontWeight.bold, // font-bold
                ),
              ),
              const SizedBox(height: 12),

              if (provider.incomeTransactions.isEmpty)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // rounded-lg
                    side: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No sales yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                )
              else
                ...provider.incomeTransactions.take(10).map((transaction) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      elevation: 0, // matches Next.js flat design
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // rounded-lg
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.2), // border-border
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16), // p-4
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction.description,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 14, // font-medium text-foreground
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    transaction.category,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 12, // text-xs
                                      color: theme.colorScheme.onSurface.withOpacity(0.6), // text-muted-foreground
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '+₱${NumberFormat('#,###').format(transaction.amount)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 14, // font-bold
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF16A34A), // text-green-600
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
