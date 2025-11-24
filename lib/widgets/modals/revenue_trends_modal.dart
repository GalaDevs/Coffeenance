import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction.dart';

/// Revenue Trends Modal - matches revenue-trends-modal.tsx
/// Shows weekly sales performance and category analysis with area chart
class RevenueTrendsModal extends StatelessWidget {
  const RevenueTrendsModal({super.key});

  // Generate weekly revenue data from real transactions
  List<Map<String, dynamic>> _generateWeeklyData(TransactionProvider provider) {
    final now = DateTime.now();
    final weeklyData = <Map<String, dynamic>>[];
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      final dayName = dayNames[targetDate.weekday - 1];
      final dateStr = targetDate.toIso8601String().split('T')[0];
      
      final dayTransactions = provider.transactions.where((t) => 
        t.date == dateStr && t.type == TransactionType.revenue
      ).toList();
      
      final sales = dayTransactions.fold(0.0, (sum, t) => sum + t.amount);
      
      weeklyData.add({
        'date': dayName,
        'sales': sales,
        'target': 15000.0, // Target remains constant
      });
    }
    
    return weeklyData;
  }

  // Generate category breakdown from real transactions
  List<Map<String, dynamic>> _generateCategoryData(TransactionProvider provider) {
    final revenueTransactions = provider.revenueTransactions;
    
    // Group by payment method (category)
    final categoryTotals = <String, double>{};
    for (final transaction in revenueTransactions) {
      categoryTotals[transaction.category] = 
        (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }
    
    // Convert to list format with sample trend data
    return categoryTotals.entries.map((entry) {
      return {
        'category': entry.key,
        'revenue': entry.value,
        'trend': (entry.value / 1000).clamp(0, 20).toDouble(), // Simple trend calculation
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<TransactionProvider>(context);
    
    final revenueData = _generateWeeklyData(provider);
    final categoryData = _generateCategoryData(provider);

    // Calculate KPIs
    final weeklyTotal = revenueData.fold<double>(
      0,
      (sum, item) => sum + (item['sales'] as double),
    );
    final avgDaily = weeklyTotal / revenueData.length;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Revenue Trends',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Weekly sales performance and category analysis',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    // KPI Cards
                    Row(
                      children: [
                        Expanded(
                          child: _KPICard(
                            title: 'Weekly Total',
                            value: '₱${(weeklyTotal / 1000).toStringAsFixed(0)}K',
                            color: const Color(0xFF10B981), // green-600
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KPICard(
                            title: 'Daily Average',
                            value: '₱${avgDaily.toStringAsFixed(0)}',
                            color: const Color(0xFF3B82F6), // blue-600
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Daily Sales vs Target Chart
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Sales vs Target',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 300,
                              child: Builder(
                                builder: (context) {
                                  // Calculate max revenue for dynamic scaling
                                  final maxRevenue = revenueData.isEmpty 
                                      ? 100.0 
                                      : revenueData.map((d) => d['sales'] as double).reduce((a, b) => a > b ? a : b);
                                  final maxY = maxRevenue == 0 ? 100.0 : maxRevenue * 1.2;
                                  // Calculate interval to show max 5-6 labels
                                  final interval = (maxY / 5).ceilToDouble();
                                  // Round to nice numbers
                                  var roundedInterval = interval < 1000
                                      ? (interval / 100).ceil() * 100.0
                                      : (interval / 1000).ceil() * 1000.0;
                                  // Ensure interval is never zero
                                  if (roundedInterval <= 0) roundedInterval = 100.0;

                                  return LineChart(
                                    LineChartData(
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: true,
                                        horizontalInterval: roundedInterval,
                                        getDrawingHorizontalLine: (value) {
                                          return FlLine(
                                            color: theme.colorScheme.outline
                                                .withValues(alpha: 0.2),
                                            strokeWidth: 1,
                                            dashArray: [5, 5],
                                          );
                                        },
                                      ),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 50,
                                            interval: roundedInterval,
                                            getTitlesWidget: (value, meta) {
                                              if (value == 0) {
                                                return Text(
                                                  '₱0',
                                                  style: theme.textTheme.bodySmall
                                                      ?.copyWith(fontSize: 10),
                                                );
                                              }
                                              if (value >= 1000) {
                                                return Text(
                                                  '₱${(value / 1000).toInt()}K',
                                                  style: theme.textTheme.bodySmall
                                                      ?.copyWith(fontSize: 10),
                                                );
                                              }
                                              return Text(
                                                '₱${value.toInt()}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(fontSize: 10),
                                              );
                                            },
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              if (value >= 0 &&
                                                  value < revenueData.length) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(top: 8),
                                                  child: Text(
                                                    revenueData[value.toInt()]
                                                        ['date'] as String,
                                                    style:
                                                        theme.textTheme.bodySmall,
                                                  ),
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      minX: 0,
                                      maxX: (revenueData.length - 1).toDouble(),
                                      minY: 0,
                                      maxY: maxY,
                                  lineBarsData: [
                                    // Actual Sales Line (filled area)
                                    LineChartBarData(
                                      spots: revenueData.asMap().entries.map((e) {
                                        return FlSpot(
                                          e.key.toDouble(),
                                          e.value['sales'] as double,
                                        );
                                      }).toList(),
                                      isCurved: true,
                                      color: const Color(0xFF10B981), // green-500
                                      barWidth: 3,
                                      dotData: const FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    // Target Line
                                    LineChartBarData(
                                      spots: revenueData.asMap().entries.map((e) {
                                        return FlSpot(
                                          e.key.toDouble(),
                                          e.value['target'] as double,
                                        );
                                      }).toList(),
                                      isCurved: false,
                                      color: const Color(0xFF6B7280), // gray-500
                                      barWidth: 2,
                                      dotData: const FlDotData(show: false),
                                      dashArray: [5, 5],
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: const Color(0xFFF3F4F6)
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((spot) {
                                          final text = spot.barIndex == 0
                                              ? 'Sales: ₱${spot.y.toStringAsFixed(0)}'
                                              : 'Target: ₱${spot.y.toStringAsFixed(0)}';
                                          return LineTooltipItem(
                                            text,
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Legend
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _LegendItem(
                                  color: const Color(0xFF10B981),
                                  label: 'Actual Sales',
                                ),
                                const SizedBox(width: 24),
                                _LegendItem(
                                  color: const Color(0xFF6B7280),
                                  label: 'Target',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Revenue by Category
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Revenue by Category',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...categoryData.map((item) {
                              final trend = item['trend'] as double;
                              final isPositive = trend > 0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['category'] as String,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '₱${NumberFormat('#,###').format(item['revenue'])}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontSize: 12,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${isPositive ? '+' : ''}${trend.toStringAsFixed(0)}%',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isPositive
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final ThemeData theme;

  const _KPICard({
    required this.title,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
              ),
        ),
      ],
    );
  }
}
