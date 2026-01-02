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
    
    // Calculate daily target from current month's revenue target divided by days in month
    final currentMonthKey = 'target_${now.year}_${now.month}_revenue';
    var monthlyRevenueTarget = provider.getKPITarget(currentMonthKey);
    
    // If no target found, try without the "target_" prefix
    if (monthlyRevenueTarget <= 0) {
      monthlyRevenueTarget = provider.getKPITarget('${now.year}_${now.month}_revenue');
    }
    
    // If still no target, use default
    if (monthlyRevenueTarget <= 0) {
      monthlyRevenueTarget = provider.getKPITarget('monthlyRevenueTarget');
    }
    
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyTarget = monthlyRevenueTarget / daysInMonth;
    
    debugPrint('🎯 Revenue Trends: Current month ${now.month}/${now.year}');
    debugPrint('🎯 Target key: $currentMonthKey = $monthlyRevenueTarget');
    debugPrint('🎯 Daily target: $dailyTarget (${monthlyRevenueTarget} / $daysInMonth days)');
    
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
        'target': dailyTarget,
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

    // Get current month info for target calculations
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final weeksInMonth = daysInMonth / 7.0;
    
    // Get monthly target - check all possible keys
    final currentMonthKey = 'target_${now.year}_${now.month}_revenue';
    var monthlyTarget = provider.getKPITarget(currentMonthKey);
    debugPrint('🎯 Revenue Trends: Checking target key: $currentMonthKey = $monthlyTarget');
    
    if (monthlyTarget <= 0) {
      final altKey = '${now.year}_${now.month}_revenue';
      monthlyTarget = provider.getKPITarget(altKey);
      debugPrint('🎯 Revenue Trends: Checking alt key: $altKey = $monthlyTarget');
    }
    if (monthlyTarget <= 0) {
      monthlyTarget = provider.getKPITarget('monthlyRevenueTarget');
      debugPrint('🎯 Revenue Trends: Checking fallback monthlyRevenueTarget = $monthlyTarget');
    }
    
    // Targets will be 0 if not set or cleared
    final hasTargetSet = monthlyTarget > 0;
    
    // Calculate derived targets (will be 0 if no target set)
    final dailyTarget = hasTargetSet ? (monthlyTarget / daysInMonth) : 0.0;
    final weeklyTarget = hasTargetSet ? (monthlyTarget / weeksInMonth) : 0.0;
    
    debugPrint('🎯 Revenue Trends: Final monthly=$monthlyTarget, daily=$dailyTarget, weekly=$weeklyTarget');

    // Calculate KPIs from actual data
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
                    // KPI Cards - Top Row
                    Row(
                      children: [
                        Expanded(
                          child: _KPICard(
                            title: 'Weekly Total',
                            value: '₱${NumberFormat('#,##0.00').format(weeklyTotal)}',
                            color: const Color(0xFF10B981), // green-600
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KPICard(
                            title: 'Daily Average',
                            value: '₱${NumberFormat('#,##0.00').format(avgDaily)}',
                            color: const Color(0xFF3B82F6), // blue-600
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // KPI Cards - Target Row
                    Row(
                      children: [
                        Expanded(
                          child: _KPICard(
                            title: 'Daily Target',
                            value: hasTargetSet 
                                ? '₱${NumberFormat('#,##0.00').format(dailyTarget)}'
                                : 'Not Set',
                            subtitle: hasTargetSet 
                                ? '${DateFormat('MMM').format(now)} ÷ $daysInMonth days'
                                : 'Set in Target Settings',
                            color: const Color(0xFFF59E0B), // amber-500
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KPICard(
                            title: 'Weekly Target',
                            value: hasTargetSet 
                                ? '₱${NumberFormat('#,##0.00').format(weeklyTarget)}'
                                : 'Not Set',
                            subtitle: hasTargetSet 
                                ? '${DateFormat('MMM').format(now)} ÷ ${weeksInMonth.toStringAsFixed(1)} wks'
                                : 'Set in Target Settings',
                            color: const Color(0xFF8B5CF6), // violet-500
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
                                    // Actual Sales Line - color based on target comparison
                                    LineChartBarData(
                                      spots: revenueData.asMap().entries.map((e) {
                                        return FlSpot(
                                          e.key.toDouble(),
                                          e.value['sales'] as double,
                                        );
                                      }).toList(),
                                      isCurved: true,
                                      // Line color stays neutral gray
                                      color: const Color(0xFF6B7280),
                                      barWidth: 3,
                                      // Color each dot gray
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 5,
                                            color: const Color(0xFF6B7280), // gray
                                            strokeWidth: 2,
                                            strokeColor: Colors.white,
                                          );
                                        },
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        // Gradient based on overall performance
                                        color: const Color(0xFF6B7280)
                                            .withValues(alpha: 0.1),
                                      ),
                                    ),
                                    // Target Line (dashed)
                                    LineChartBarData(
                                      spots: revenueData.asMap().entries.map((e) {
                                        return FlSpot(
                                          e.key.toDouble(),
                                          e.value['target'] as double,
                                        );
                                      }).toList(),
                                      isCurved: false,
                                      color: const Color(0xFFF59E0B), // amber/gold for target
                                      barWidth: 2,
                                      dotData: const FlDotData(show: false),
                                      dashArray: [5, 5],
                                      belowBarData: BarAreaData(
                                        show: false,
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
                                  color: const Color(0xFF6B7280),
                                  label: 'Actual Sales',
                                ),
                                const SizedBox(width: 16),
                                _LegendItem(
                                  color: const Color(0xFFF59E0B),
                                  label: 'Target Line',
                                  isDashed: true,
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
                                            '₱${NumberFormat('#,##0.00').format(item['revenue'])}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontSize: 6,
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
  final String? subtitle;
  final Color color;
  final ThemeData theme;

  const _KPICard({
    required this.title,
    required this.value,
    this.subtitle,
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
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        isDashed
            ? Container(
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: color,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
                child: CustomPaint(
                  painter: _DashedLinePainter(color: color),
                ),
              )
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  
  _DashedLinePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    const dashWidth = 4.0;
    const dashSpace = 2.0;
    double startX = 0;
    
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
