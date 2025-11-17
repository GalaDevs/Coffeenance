import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

/// Expense Breakdown Card - Matches expense-breakdown.tsx
/// Shows expenses by category with pie chart
class ExpenseBreakdownCard extends StatelessWidget {
  final Map<String, double> expensesByCategory;
  final double totalExpenses;

  const ExpenseBreakdownCard({
    super.key,
    required this.expensesByCategory,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = [
      AppColors.chart1,
      AppColors.chart2,
      AppColors.chart3,
      AppColors.chart4,
      AppColors.chart5,
    ];

    final chartData = expensesByCategory.entries
        .where((e) => e.value > 0)
        .toList()
        .asMap()
        .map((index, entry) => MapEntry(
              index,
              {
                'category': entry.key,
                'value': entry.value,
                'color': colors[index % colors.length],
              },
            ))
        .values
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'By category',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),

            if (chartData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Text('No transaction data'),
                ),
              )
            else ...[
              // Pie Chart
              SizedBox(
                height: 192,
                child: PieChart(
                  PieChartData(
                    sections: chartData.map((data) {
                      final percentage = (data['value'] as double) / totalExpenses * 100;
                      return PieChartSectionData(
                        value: data['value'] as double,
                        title: '',
                        color: data['color'] as Color,
                        radius: 60,
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 0,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Category List
              ...chartData.map((data) {
                final category = data['category'] as String;
                final value = data['value'] as double;
                final color = data['color'] as Color;
                final percentage = ((value / totalExpenses) * 100).toStringAsFixed(1);

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
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₱${value.toStringAsFixed(0)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ],
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
                    'Total Transactions',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '-₱${totalExpenses.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
