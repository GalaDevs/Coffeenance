import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// Expense Breakdown Card - Matches expense-breakdown.tsx
/// Shows expenses by category with pie chart
class ExpenseBreakdownCard extends StatefulWidget {
  final Map<String, double> expensesByCategory;
  final double totalExpenses;

  const ExpenseBreakdownCard({
    super.key,
    required this.expensesByCategory,
    required this.totalExpenses,
  });

  @override
  State<ExpenseBreakdownCard> createState() => _ExpenseBreakdownCardState();
}

class _ExpenseBreakdownCardState extends State<ExpenseBreakdownCard> {
  int touchedIndex = -1;

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

    // Filter out categories with zero values and sort by amount (highest first)
    final chartData = widget.expensesByCategory.entries
        .where((e) => e.value > 0)
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    // Map to chart data with colors
    final mappedChartData = chartData
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
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Distribution of expenses across categories',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),

            if (mappedChartData.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Text('No transaction data'),
                ),
              )
            else ...[
              // Pie Chart
              Center(
                child: SizedBox(
                  height: 220,
                  width: 220,
                  child: PieChart(
                    PieChartData(
                      sections: mappedChartData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        final isTouched = index == touchedIndex;
                        final percentage = ((data['value'] as double) / widget.totalExpenses) * 100;
                        final radius = isTouched ? 90.0 : 80.0;
                        final fontSize = isTouched ? 14.0 : 12.0;
                        
                        return PieChartSectionData(
                          value: data['value'] as double,
                          title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          color: data['color'] as Color,
                          radius: radius,
                          badgeWidget: isTouched
                              ? Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '₱${NumberFormat('#,##0.00').format(data['value'] as double)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: data['color'] as Color,
                                    ),
                                  ),
                                )
                              : null,
                          badgePositionPercentageOffset: 1.2,
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 0,
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Category List
              ...mappedChartData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final category = data['category'] as String;
                final value = data['value'] as double;
                final color = data['color'] as Color;
                final percentage = ((value / widget.totalExpenses) * 100).toStringAsFixed(1);
                final isTouched = index == touchedIndex;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      touchedIndex = touchedIndex == index ? -1 : index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isTouched
                          ? color.withValues(alpha: 0.3)
                          : theme.colorScheme.secondary.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: isTouched
                          ? Border.all(color: color, width: 2)
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: isTouched ? 14 : 12,
                              height: isTouched ? 14 : 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: isTouched
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₱${NumberFormat('#,##0.00').format(value)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isTouched ? FontWeight.bold : FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$percentage%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                    'Total Expenses',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '-₱${NumberFormat('#,##0.00').format(widget.totalExpenses)}',
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
