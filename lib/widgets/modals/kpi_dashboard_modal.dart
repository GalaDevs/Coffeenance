import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction.dart';

/// KPI Dashboard Modal - Matches Next.js kpi-modal.tsx exactly
/// Shows key performance indicators with charts and metrics
/// PULL: Reads real-time data and targets from TransactionProvider
/// PUSH: Allows updating KPI targets back to TransactionProvider
class KPIDashboardModal extends StatefulWidget {
  const KPIDashboardModal({super.key});

  @override
  State<KPIDashboardModal> createState() => _KPIDashboardModalState();
}

class _KPIDashboardModalState extends State<KPIDashboardModal> {
  DateTime _selectedDate = DateTime.now();

  // Format number with comma separators
  String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(number.round());
  }

  // Format date for display
  String _formatDate(DateTime date) {
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  // Pick date
  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Generate KPI cards from real data (PULL from provider)
  List<Map<String, dynamic>> _generateKPICards(TransactionProvider provider) {
    // Get transactions for selected date
    final selectedDateStr = _selectedDate.toIso8601String().split('T')[0];
    final dateTransactions = provider.transactions.where((t) => t.date == selectedDateStr).toList();
    final revenueTransactions = dateTransactions.where((t) => t.type == TransactionType.revenue).toList();
    final expenseTransactions = dateTransactions.where((t) => t.type == TransactionType.transaction).toList();
    
    final dailyRevenue = revenueTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final dailyExpenses = expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final revenueCount = revenueTransactions.length;
    final avgTransaction = revenueCount > 0 ? dailyRevenue / revenueCount : 0.0;
    
    // Get targets from provider (PULL)
    final dailyRevenueTarget = provider.getKPITarget('dailyRevenueTarget');
    final dailyTransactionsTarget = provider.getKPITarget('dailyTransactionsTarget');
    final avgTransactionTarget = provider.getKPITarget('avgTransactionTarget');
    final dailyExpensesTarget = provider.getKPITarget('dailyExpensesTarget');
    
    return [
      {
        'label': 'Daily Revenue',
        'value': '₱${_formatNumber(dailyRevenue)}',
        'valueNum': dailyRevenue,
        'target': '₱${_formatNumber(dailyRevenueTarget)}',
        'targetNum': dailyRevenueTarget,
        'status': dailyRevenue >= dailyRevenueTarget ? 'above-target' : 'on-track',
        'key': 'dailyRevenueTarget',
      },
      {
        'label': 'Daily Transactions',
        'value': _formatNumber(revenueCount.toDouble()),
        'valueNum': revenueCount.toDouble(),
        'target': _formatNumber(dailyTransactionsTarget),
        'targetNum': dailyTransactionsTarget,
        'status': revenueCount >= dailyTransactionsTarget ? 'above-target' : 'on-track',
        'key': 'dailyTransactionsTarget',
      },
      {
        'label': 'Average Transaction',
        'value': '₱${_formatNumber(avgTransaction)}',
        'valueNum': avgTransaction,
        'target': '₱${_formatNumber(avgTransactionTarget)}',
        'targetNum': avgTransactionTarget,
        'status': avgTransaction >= avgTransactionTarget ? 'above-target' : 'on-track',
        'key': 'avgTransactionTarget',
      },
      {
        'label': 'Daily Expenses',
        'value': '₱${_formatNumber(dailyExpenses)}',
        'valueNum': dailyExpenses,
        'target': '₱${_formatNumber(dailyExpensesTarget)}',
        'targetNum': dailyExpensesTarget,
        'status': dailyExpenses <= dailyExpensesTarget ? 'above-target' : 'on-track',
        'key': 'dailyExpensesTarget',
      },
    ];
  }
  
  // PUSH: Edit KPI target
  void _editTarget(BuildContext context, String label, String key, double currentTarget) async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final controller = TextEditingController(text: _formatNumber(currentTarget));
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Target Value',
            prefixText: '₱',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Remove commas before parsing
              final cleanValue = controller.text.replaceAll(',', '');
              final newValue = double.tryParse(cleanValue);
              if (newValue != null && newValue > 0) {
                await provider.updateKPISetting(key, newValue);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label target updated to ₱${_formatNumber(newValue)}')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // KPI Trends Data - PULL from provider and calculate from real weekly data
  List<Map<String, dynamic>> _getWeeklyTrends(TransactionProvider provider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<Map<String, dynamic>> weeklyData = [];
    
    // Get data for last 4 weeks
    for (int i = 3; i >= 0; i--) {
      // Calculate week boundaries properly
      final weekEnd = today.subtract(Duration(days: 7 * i));
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      
      // Get transactions for this week using date string comparison
      final weekTransactions = provider.transactions.where((t) {
        try {
          final transactionDate = DateTime.parse(t.date);
          final dateOnly = DateTime(transactionDate.year, transactionDate.month, transactionDate.day);
          // Check if date is within week range (inclusive)
          return !dateOnly.isBefore(weekStart) && !dateOnly.isAfter(weekEnd);
        } catch (e) {
          return false;
        }
      }).toList();
      
      final revenueTransactions = weekTransactions.where((t) => t.type == TransactionType.revenue).toList();
      final expenseTransactions = weekTransactions.where((t) => t.type == TransactionType.transaction).toList();
      
      final totalRevenue = revenueTransactions.fold(0.0, (sum, t) => sum + t.amount);
      final totalExpenses = expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);
      
      // Calculate metrics (0-100 scale normalized to realistic values)
      // Revenue - normalized to show meaningful growth (divide by 100 to get percentage scale)
      final revenueGrowth = (totalRevenue / 100).clamp(0.0, 100.0);
      
      // Operational Efficiency (inverse of expense ratio)
      final efficiency = totalRevenue > 0 
          ? (100 - ((totalExpenses / totalRevenue) * 100)).clamp(0.0, 100.0)
          : 50.0;
      
      // Profit Margin
      final profitMargin = totalRevenue > 0
          ? (((totalRevenue - totalExpenses) / totalRevenue) * 100).clamp(0.0, 100.0)
          : 0.0;
      
      weeklyData.add({
        'week': 'W${4 - i}',
        'revenue': revenueGrowth,
        'efficiency': efficiency,
        'profit': profitMargin,
      });
    }
    
    return weeklyData;
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final kpiCards = _generateKPICards(provider);
        final weeklyTrends = _getWeeklyTrends(provider);

        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 900,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KPI Dashboard',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _pickDate(context),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDate(_selectedDate),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
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
        const Divider(height: 1),
        // Scrollable Content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // KPI Cards Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: kpiCards.length,
                  itemBuilder: (context, index) {
                    final kpi = kpiCards[index];
                    return _KPICard(
                      label: kpi['label']!,
                      value: kpi['value']!,
                      target: kpi['target']!,
                      status: kpi['status']!,
                      onEditTarget: () => _editTarget(
                        context,
                        kpi['label']!,
                        kpi['key']!,
                        kpi['targetNum'] as double,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Weekly Trends Line Chart
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
                          'Weekly Trends',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Legend
                        Wrap(
                          spacing: 16,
                          children: [
                            _LegendItem(
                              color: const Color(0xFF10b981),
                              label: 'Revenue',
                            ),
                            _LegendItem(
                              color: const Color(0xFF3b82f6),
                              label: 'Efficiency',
                            ),
                            _LegendItem(
                              color: const Color(0xFFf59e0b),
                              label: 'Profit',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 240,
                          child: _LineChartWidget(data: weeklyTrends),
                        ),
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
      },
    );
  }
}// KPI Card Widget
class _KPICard extends StatelessWidget {
  final String label;
  final String value;
  final String target;
  final String status;
  final VoidCallback? onEditTarget;

  const _KPICard({
    required this.label,
    required this.value,
    required this.target,
    required this.status,
    this.onEditTarget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAboveTarget = status == 'above-target';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: onEditTarget,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onEditTarget != null)
                    Icon(
                      Icons.edit_rounded,
                      size: 13,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Target: $target',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isAboveTarget
                          ? Colors.green.shade100
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isAboveTarget ? '✓ Above' : '◔ On Track',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isAboveTarget
                            ? Colors.green.shade800
                            : Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Line Chart Widget
class _LineChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _LineChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[value.toInt()]['week'],
                      style: const TextStyle(fontSize: 12),
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
              interval: 20,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          // Revenue Growth - Green
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value['revenue'] as double,
              );
            }).toList(),
            isCurved: true,
            color: const Color(0xFF10b981),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
          // Operational Efficiency - Blue
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value['efficiency'] as double,
              );
            }).toList(),
            isCurved: true,
            color: const Color(0xFF3b82f6),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
          // Profit Margin - Amber
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value['profit'] as double,
              );
            }).toList(),
            isCurved: true,
            color: const Color(0xFFf59e0b),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.blueGrey.withValues(alpha: 0.8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                String label = '';
                if (touchedSpot.barIndex == 0) {
                  label = 'Revenue';
                } else if (touchedSpot.barIndex == 1) {
                  label = 'Efficiency';
                } else if (touchedSpot.barIndex == 2) {
                  label = 'Profit';
                }
                return LineTooltipItem(
                  '$label\n${touchedSpot.y.toStringAsFixed(0)}%',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

// Legend Item Widget
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
