import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
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
  // Generate KPI cards from real data (PULL from provider)
  List<Map<String, dynamic>> _generateKPICards(TransactionProvider provider) {
    final todayTransactions = provider.todayTransactions;
    final revenueTransactions = todayTransactions.where((t) => t.type == TransactionType.revenue).toList();
    final expenseTransactions = todayTransactions.where((t) => t.type == TransactionType.transaction).toList();
    
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
        'value': '₱${dailyRevenue.toStringAsFixed(0)}',
        'valueNum': dailyRevenue,
        'target': '₱${dailyRevenueTarget.toStringAsFixed(0)}',
        'targetNum': dailyRevenueTarget,
        'status': dailyRevenue >= dailyRevenueTarget ? 'above-target' : 'on-track',
        'key': 'dailyRevenueTarget',
      },
      {
        'label': 'Daily Transactions',
        'value': revenueCount.toString(),
        'valueNum': revenueCount.toDouble(),
        'target': dailyTransactionsTarget.toStringAsFixed(0),
        'targetNum': dailyTransactionsTarget,
        'status': revenueCount >= dailyTransactionsTarget ? 'above-target' : 'on-track',
        'key': 'dailyTransactionsTarget',
      },
      {
        'label': 'Average Transaction',
        'value': '₱${avgTransaction.toStringAsFixed(0)}',
        'valueNum': avgTransaction,
        'target': '₱${avgTransactionTarget.toStringAsFixed(0)}',
        'targetNum': avgTransactionTarget,
        'status': avgTransaction >= avgTransactionTarget ? 'above-target' : 'on-track',
        'key': 'avgTransactionTarget',
      },
      {
        'label': 'Daily Expenses',
        'value': '₱${dailyExpenses.toStringAsFixed(0)}',
        'valueNum': dailyExpenses,
        'target': '₱${dailyExpensesTarget.toStringAsFixed(0)}',
        'targetNum': dailyExpensesTarget,
        'status': dailyExpenses <= dailyExpensesTarget ? 'above-target' : 'on-track',
        'key': 'dailyExpensesTarget',
      },
    ];
  }
  
  // PUSH: Edit KPI target
  void _editTarget(BuildContext context, String label, String key, double currentTarget) async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final controller = TextEditingController(text: currentTarget.toStringAsFixed(0));
    
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
              final newValue = double.tryParse(controller.text);
              if (newValue != null && newValue > 0) {
                await provider.updateKPISetting(key, newValue);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label target updated to ₱${newValue.toStringAsFixed(0)}')),
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

  // KPI Trends Data (sample - could be enhanced with historical data)
  static final List<Map<String, dynamic>> kpiTrends = [
    {'week': 'W1', 'satisfaction': 85.0, 'efficiency': 78.0, 'retention': 92.0},
    {'week': 'W2', 'satisfaction': 87.0, 'efficiency': 82.0, 'retention': 93.0},
    {'week': 'W3', 'satisfaction': 89.0, 'efficiency': 85.0, 'retention': 94.0},
    {'week': 'W4', 'satisfaction': 91.0, 'efficiency': 88.0, 'retention': 95.0},
  ];

  // Performance Radar Data - PULL from provider
  List<Map<String, dynamic>> _getPerformanceRadar(TransactionProvider provider) {
    return [
      {
        'metric': 'Customer\nSatisfaction',
        'value': provider.getKPITarget('customerSatisfaction'),
        'key': 'customerSatisfaction',
      },
      {
        'metric': 'Operational\nEfficiency',
        'value': provider.getKPITarget('operationalEfficiency'),
        'key': 'operationalEfficiency',
      },
      {
        'metric': 'Staff\nRetention',
        'value': provider.getKPITarget('staffRetention'),
        'key': 'staffRetention',
      },
      {
        'metric': 'Inventory\nTurnover',
        'value': provider.getKPITarget('inventoryTurnover'),
        'key': 'inventoryTurnover',
      },
      {
        'metric': 'Revenue\nGrowth',
        'value': provider.getKPITarget('revenueGrowth'),
        'key': 'revenueGrowth',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final kpiCards = _generateKPICards(provider);
        final performanceRadar = _getPerformanceRadar(provider);

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
                    Text(
                      'Key performance indicators and business metrics',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
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

                // Performance Score Radar Chart
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
                          'Performance Score',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 250,
                          child: _RadarChartWidget(data: performanceRadar),
                        ),
                      ],
                    ),
                  ),
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
                              label: 'Satisfaction',
                            ),
                            _LegendItem(
                              color: const Color(0xFF3b82f6),
                              label: 'Efficiency',
                            ),
                            _LegendItem(
                              color: const Color(0xFFf59e0b),
                              label: 'Retention',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 250,
                          child: _LineChartWidget(data: kpiTrends),
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
          padding: const EdgeInsets.all(12),
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
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onEditTarget != null)
                    Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                    ),
                ],
              ),
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
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Target: $target',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
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
                        fontSize: 11,
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

// Radar Chart Widget
class _RadarChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _RadarChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        tickCount: 5,
        ticksTextStyle: const TextStyle(fontSize: 10, color: Colors.transparent),
        radarBorderData: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
        gridBorderData: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
        tickBorderData: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
        getTitle: (index, angle) {
          if (index >= data.length) return const RadarChartTitle(text: '');
          return RadarChartTitle(
            text: data[index]['metric'],
            angle: angle,
          );
        },
        dataSets: [
          RadarDataSet(
            fillColor: Colors.blue.withValues(alpha: 0.2),
            borderColor: Colors.blue,
            borderWidth: 2,
            dataEntries: data.map((item) {
              return RadarEntry(value: item['value'] as double);
            }).toList(),
          ),
        ],
        titleTextStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        titlePositionPercentageOffset: 0.15,
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
          // Customer Satisfaction - Green
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value['satisfaction'] as double,
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
          // Staff Retention - Amber
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value['retention'] as double,
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
                  label = 'Satisfaction';
                } else if (touchedSpot.barIndex == 1) {
                  label = 'Efficiency';
                } else if (touchedSpot.barIndex == 2) {
                  label = 'Retention';
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
