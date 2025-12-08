import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction.dart';

/// Monthly P&L Summary Modal - matches monthly-pl-modal.tsx
/// Shows profit & loss analysis with charts and tables
class MonthlyPLModal extends StatelessWidget {
  const MonthlyPLModal({super.key});

  // Generate monthly P&L data from transactions
  List<Map<String, dynamic>> _generateMonthlyData(TransactionProvider provider) {
    final now = DateTime.now();
    final monthlyData = <Map<String, dynamic>>[];
    
    for (int i = 5; i >= 0; i--) {
      final targetMonth = DateTime(now.year, now.month - i, 1);
      final monthName = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][targetMonth.month - 1];
      
      final monthStart = DateTime(targetMonth.year, targetMonth.month, 1);
      final monthEnd = DateTime(targetMonth.year, targetMonth.month + 1, 0);
      
      final monthTransactions = provider.getTransactionsByDateRange(monthStart, monthEnd);
      final revenue = monthTransactions.where((t) => t.type == TransactionType.revenue).fold(0.0, (sum, t) => sum + t.amount);
      final expenses = monthTransactions.where((t) => t.type == TransactionType.transaction).fold(0.0, (sum, t) => sum + t.amount);
      
      monthlyData.add({
        'month': monthName,
        'revenue': revenue,
        'expenses': expenses,
        'profit': revenue - expenses,
      });
    }
    
    return monthlyData;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<TransactionProvider>(context);
    final monthlyData = _generateMonthlyData(provider);
    
    final totalRevenue = monthlyData.fold(0.0, (sum, d) => sum + (d['revenue'] as num).toDouble());
    final totalExpenses = monthlyData.fold(0.0, (sum, d) => sum + (d['expenses'] as num).toDouble());
    final totalProfit = monthlyData.fold(0.0, (sum, d) => sum + (d['profit'] as num).toDouble());
    final profitMargin = totalRevenue > 0 ? ((totalProfit / totalRevenue) * 100).toStringAsFixed(1) : '0.0';

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly P&L Summary',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Profit & Loss analysis for the current year',
                            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary Cards
                    _buildSummaryCards(
                      theme,
                      totalRevenue,
                      totalExpenses,
                      totalProfit,
                      profitMargin,
                    ),
                    const SizedBox(height: 24),

                    // Revenue vs Expenses Chart
                    _buildRevenueExpensesChart(theme, monthlyData),
                    const SizedBox(height: 24),

                    // Monthly Profit Trend Chart
                    _buildProfitTrendChart(theme, monthlyData),
                    const SizedBox(height: 24),

                    // Monthly Breakdown Table
                    _buildMonthlyBreakdownTable(theme, monthlyData),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    ThemeData theme,
    double totalRevenue,
    double totalExpenses,
    double totalProfit,
    String profitMargin,
  ) {
    final revenueGrowth = '+12.5%'; // Sample data
    final expenseGrowth = '+8.3%'; // Sample data

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildSummaryCard(
            theme,
            'Total Revenue',
            '₱${(totalRevenue / 1000).toStringAsFixed(0)}K',
            Colors.green,
            subtitle: revenueGrowth,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _buildSummaryCard(
            theme,
            'Total Expenses',
            '₱${(totalExpenses / 1000).toStringAsFixed(0)}K',
            Colors.red,
            subtitle: expenseGrowth,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _buildSummaryCard(
            theme,
            'Total Profit',
            '₱${(totalProfit / 1000).toStringAsFixed(0)}K',
            Colors.blue,
            subtitle: '$profitMargin%',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    String title,
    String value,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 18,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueExpensesChart(ThemeData theme, List<Map<String, dynamic>> monthlyData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue vs Expenses',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: Builder(
                builder: (context) {
                  // Calculate max value dynamically
                  final maxRevenue = monthlyData.isEmpty 
                      ? 0.0 
                      : monthlyData.map((d) => (d['revenue'] as num).toDouble()).reduce((a, b) => a > b ? a : b);
                  final maxExpenses = monthlyData.isEmpty 
                      ? 0.0 
                      : monthlyData.map((d) => (d['expenses'] as num).toDouble()).reduce((a, b) => a > b ? a : b);
                  final maxValue = maxRevenue > maxExpenses ? maxRevenue : maxExpenses;
                  final maxY = maxValue == 0 ? 100.0 : maxValue * 1.2;
                  // Calculate interval to show max 5-6 labels
                  final interval = (maxY / 5).ceilToDouble();
                  // Round to nice numbers (10000, 15000, etc.)
                  var roundedInterval = interval < 1000
                      ? (interval / 100).ceil() * 100.0
                      : (interval / 10000).ceil() * 10000.0;
                  // Ensure interval is never zero
                  if (roundedInterval <= 0) roundedInterval = 100.0;

                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final month = monthlyData[groupIndex]['month'] as String;
                            final value = rod.toY.toInt();
                            final label = rodIndex == 0 ? 'Revenue' : 'Expenses';
                            return BarTooltipItem(
                              '$month\n$label: ₱${value.toStringAsFixed(0)}',
                              const TextStyle(color: Colors.white),
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
                              if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    monthlyData[value.toInt()]['month'] as String,
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
                            interval: roundedInterval,
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
                        horizontalInterval: roundedInterval,
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(monthlyData.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: monthlyData[index]['revenue'] as double,
                          color: Colors.green,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: monthlyData[index]['expenses'] as double,
                          color: Colors.red,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitTrendChart(ThemeData theme, List<Map<String, dynamic>> monthlyData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Profit Trend',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Builder(
                builder: (context) {
                  // Calculate max profit for dynamic scaling
                  final maxProfit = monthlyData.isEmpty 
                      ? 100.0 
                      : monthlyData.map((d) => d['profit'] as double).reduce((a, b) => a > b ? a : b);
                  final maxY = maxProfit == 0 ? 100.0 : maxProfit * 1.2;
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
                        drawVerticalLine: false,
                        horizontalInterval: roundedInterval,
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    monthlyData[value.toInt()]['month'] as String,
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
                            interval: roundedInterval,
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
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (monthlyData.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        monthlyData.length,
                        (index) => FlSpot(
                          index.toDouble(),
                          monthlyData[index]['profit'] as double,
                        ),
                      ),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final month = monthlyData[spot.x.toInt()]['month'] as String;
                          return LineTooltipItem(
                            '$month\nProfit: ₱${spot.y.toInt().toStringAsFixed(0)}',
                            const TextStyle(color: Colors.white),
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
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBreakdownTable(ThemeData theme, List<Map<String, dynamic>> monthlyData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Consumer<TransactionProvider>(
                builder: (context, provider, child) {
                  final monthlyRevenueTarget = provider.getKPITarget('monthlyRevenueTarget');
                  final monthlyTransactionsTarget = provider.getKPITarget('monthlyTransactionsTarget');
                  
                  return DataTable(
                    columnSpacing: 24,
                    horizontalMargin: 12,
                    columns: [
                      DataColumn(
                        label: Text(
                          'Month',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Revenue',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Target %',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Expenses',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Budget %',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Profit',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    rows: monthlyData.map((data) {
                      final month = data['month'] as String;
                      final revenue = data['revenue'] as double;
                      final expenses = data['expenses'] as double;
                      final profit = data['profit'] as double;
                      
                      // Calculate target percentages
                      final revenuePercent = monthlyRevenueTarget > 0 
                          ? ((revenue / monthlyRevenueTarget) * 100).toStringAsFixed(0)
                          : '0';
                      final expensesBudget = monthlyRevenueTarget * 0.7; // 70% of revenue as budget
                      final expensesPercent = expensesBudget > 0
                          ? ((expenses / expensesBudget) * 100).toStringAsFixed(0)
                          : '0';
                      
                      final isRevenueGood = (double.tryParse(revenuePercent) ?? 0) >= 80;
                      final isExpensesGood = (double.tryParse(expensesPercent) ?? 0) <= 100;

                      return DataRow(
                        cells: [
                          DataCell(Text(month, style: theme.textTheme.bodyMedium)),
                          DataCell(
                            Text(
                              '₱${(revenue / 1000).toStringAsFixed(1)}K',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isRevenueGood 
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$revenuePercent%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isRevenueGood ? Colors.green.shade700 : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '₱${(expenses / 1000).toStringAsFixed(1)}K',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isExpensesGood
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$expensesPercent%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isExpensesGood ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '₱${(profit / 1000).toStringAsFixed(1)}K',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: profit >= 0 ? Colors.blue.shade700 : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}
