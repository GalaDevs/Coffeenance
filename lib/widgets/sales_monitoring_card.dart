import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
    final revenueTransactions = transactions.where((t) => t.type == TransactionType.revenue).toList();

    // Aggregate sales by method
    final salesByMethod = {
      'Cash': revenueTransactions
          .where((t) => t.category == RevenueCategories.cash)
          .fold(0.0, (sum, t) => sum + t.amount),
      'Maya': revenueTransactions
          .where((t) => t.category == RevenueCategories.paymaya)
          .fold(0.0, (sum, t) => sum + t.amount),
      'Credit Card': revenueTransactions
          .where((t) => t.category == RevenueCategories.creditCard)
          .fold(0.0, (sum, t) => sum + t.amount),
      'GCash': revenueTransactions
          .where((t) => t.category == RevenueCategories.gcash)
          .fold(0.0, (sum, t) => sum + t.amount),
      'Grab': revenueTransactions
          .where((t) => t.category == RevenueCategories.grab)
          .fold(0.0, (sum, t) => sum + t.amount),
    };

    final totalSales = salesByMethod.values.fold(0.0, (sum, value) => sum + value);

    final chartData = [
      {'name': 'GCash', 'value': salesByMethod['GCash']!, 'color': AppColors.chart3},
      {'name': 'Maya', 'value': salesByMethod['Maya']!, 'color': AppColors.chart2},
      {'name': 'Grab', 'value': salesByMethod['Grab']!, 'color': AppColors.chart4},
      {'name': 'Credit Card', 'value': salesByMethod['Credit Card']!, 'color': AppColors.chart5},
      {'name': 'Cash', 'value': salesByMethod['Cash']!, 'color': AppColors.chart1},
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
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),

            // Bar Chart
            SizedBox(
              height: 192,
              child: Builder(
                builder: (context) {
                  final maxValue = chartData.isEmpty 
                      ? 100.0 
                      : chartData.map((e) => e['value'] as double).reduce((a, b) => a > b ? a : b);
                  final maxY = maxValue == 0 ? 100.0 : maxValue * 1.2;
                  // Calculate interval to show max 5-6 labels (evenly spaced)
                  final interval = (maxY / 5).ceilToDouble();
                  // Round interval to nice numbers (1000, 2000, 5000, 10000, etc.)
                  // Ensure interval is never 0
                  var roundedInterval = interval < 1000 
                      ? (interval / 100).ceil() * 100 
                      : (interval / 1000).ceil() * 1000;
                  if (roundedInterval <= 0) roundedInterval = 100;
                  
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final value = rod.toY;
                            return BarTooltipItem(
                              '₱${NumberFormat('#,###').format(value)}',
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
                            reservedSize: 50,
                            interval: roundedInterval.toDouble(),
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
                        horizontalInterval: roundedInterval.toDouble(),
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.colorScheme.outline.withValues(alpha: 0.2),
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
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Summary Cards
            ...chartData.map((method) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.5),
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
                      '₱${NumberFormat('#,###').format(method['value'] as double)}',
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
                  '₱${NumberFormat('#,###').format(totalSales)}',
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
