import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Monthly P&L Summary Modal - matches monthly-pl-modal.tsx
/// Shows profit & loss analysis with charts and tables
class MonthlyPLModal extends StatelessWidget {
  const MonthlyPLModal({super.key});

  // Sample monthly data (in a real app, this would come from the provider)
  static const List<Map<String, dynamic>> monthlyData = [
    {'month': 'Jan', 'revenue': 45000.0, 'expenses': 28000.0, 'profit': 17000.0},
    {'month': 'Feb', 'revenue': 52000.0, 'expenses': 31000.0, 'profit': 21000.0},
    {'month': 'Mar', 'revenue': 48000.0, 'expenses': 29000.0, 'profit': 19000.0},
    {'month': 'Apr', 'revenue': 61000.0, 'expenses': 35000.0, 'profit': 26000.0},
    {'month': 'May', 'revenue': 58000.0, 'expenses': 32000.0, 'profit': 26000.0},
    {'month': 'Jun', 'revenue': 67000.0, 'expenses': 38000.0, 'profit': 29000.0},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalRevenue = monthlyData.fold(0.0, (sum, d) => sum + d['revenue'] as double);
    final totalExpenses = monthlyData.fold(0.0, (sum, d) => sum + d['expenses'] as double);
    final totalProfit = monthlyData.fold(0.0, (sum, d) => sum + d['profit'] as double);
    final profitMargin = ((totalProfit / totalRevenue) * 100).toStringAsFixed(1);

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
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                    _buildRevenueExpensesChart(theme),
                    const SizedBox(height: 24),

                    // Monthly Profit Trend Chart
                    _buildProfitTrendChart(theme),
                    const SizedBox(height: 24),

                    // Monthly Breakdown Table
                    _buildMonthlyBreakdownTable(theme),
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
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            theme,
            'Total Revenue',
            '₱${(totalRevenue / 1000).toStringAsFixed(0)}K',
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            theme,
            'Total Expenses',
            '₱${(totalExpenses / 1000).toStringAsFixed(0)}K',
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            theme,
            'Total Profit',
            '₱${(totalProfit / 1000).toStringAsFixed(0)}K',
            Colors.blue,
            subtitle: '$profitMargin% margin',
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueExpensesChart(ThemeData theme) {
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
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 70000,
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
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toInt()}K',
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
                    horizontalInterval: 10000,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitTrendChart(ThemeData theme) {
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
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5000,
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
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toInt()}K',
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
                  maxY: 35000,
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
                        color: Colors.blue.withOpacity(0.1),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBreakdownTable(ThemeData theme) {
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
              child: DataTable(
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
                      'Expenses',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
                  DataColumn(
                    label: Text(
                      'Margin',
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
                  final margin = ((profit / revenue) * 100).toStringAsFixed(1);

                  return DataRow(
                    cells: [
                      DataCell(Text(month)),
                      DataCell(
                        Text(
                          '₱${revenue.toInt().toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                      DataCell(
                        Text(
                          '₱${expenses.toInt().toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      DataCell(
                        Text(
                          '₱${profit.toInt().toStringAsFixed(0)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(Text('$margin%')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
