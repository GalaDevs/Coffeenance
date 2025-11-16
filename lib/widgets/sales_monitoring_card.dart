import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

/// Sales Monitoring Card - Matches sales-monitoring.tsx
/// Shows payment methods breakdown with bar chart
class SalesMonitoringCard extends StatelessWidget {
  final List<Transaction> transactions;

  const SalesMonitoringCard({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final incomeTransactions = transactions.where((t) => t.type == TransactionType.income).toList();

    // Aggregate sales by method
    final salesByMethod = {
      'Cash': incomeTransactions
          .where((t) => t.category == IncomeCategories.cash)
          .fold(0.0, (sum, t) => sum + t.amount),
      'PayMaya': incomeTransactions
          .where((t) => t.category == IncomeCategories.paymaya)
          .fold(0.0, (sum, t) => sum + t.amount),
      'GCash': incomeTransactions
          .where((t) => t.category == IncomeCategories.gcash)
          .fold(0.0, (sum, t) => sum + t.amount),
      'Grab': incomeTransactions
          .where((t) => t.category == IncomeCategories.grab)
          .fold(0.0, (sum, t) => sum + t.amount),
    };

    final totalSales = salesByMethod.values.fold(0.0, (sum, value) => sum + value);

    final chartData = [
      {'name': 'Cash', 'value': salesByMethod['Cash']!, 'color': AppColors.chart1},
      {'name': 'PayMaya', 'value': salesByMethod['PayMaya']!, 'color': AppColors.chart2},
      {'name': 'GCash', 'value': salesByMethod['GCash']!, 'color': AppColors.chart3},
      {'name': 'Grab', 'value': salesByMethod['Grab']!, 'color': AppColors.chart4},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Monitoring',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Payment methods breakdown',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),

            // Bar Chart
            SizedBox(
              height: 192,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: chartData.map((e) => e['value'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final name = chartData[groupIndex]['name'] as String;
                        final value = rod.toY;
                        return BarTooltipItem(
                          '₱${value.toStringAsFixed(0)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                chartData[value.toInt()]['name'] as String,
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) {
                            return Text(
                              '₱0',
                              style: theme.textTheme.bodySmall,
                            );
                          }
                          if (value >= 1000) {
                            return Text(
                              '₱${(value / 1000).toInt()}K',
                              style: theme.textTheme.bodySmall,
                            );
                          }
                          return Text(
                            '₱${value.toInt()}',
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                        strokeWidth: 1,
                        dashArray: [3, 3],
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(chartData.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: chartData[index]['value'] as double,
                          color: chartData[index]['color'] as Color,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Summary Cards
            ...chartData.map((method) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: method['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          method['name'] as String,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Text(
                      '₱${(method['value'] as double).toStringAsFixed(0)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₱${totalSales.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
