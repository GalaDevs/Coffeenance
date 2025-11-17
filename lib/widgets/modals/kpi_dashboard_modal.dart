import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// KPI Dashboard Modal - Matches Next.js kpi-modal.tsx exactly
/// Shows key performance indicators with charts and metrics
class KPIDashboardModal extends StatelessWidget {
  const KPIDashboardModal({super.key});

  // KPI Trends Data
  static final List<Map<String, dynamic>> kpiTrends = [
    {'week': 'W1', 'satisfaction': 85.0, 'efficiency': 78.0, 'retention': 92.0},
    {'week': 'W2', 'satisfaction': 87.0, 'efficiency': 82.0, 'retention': 93.0},
    {'week': 'W3', 'satisfaction': 89.0, 'efficiency': 85.0, 'retention': 94.0},
    {'week': 'W4', 'satisfaction': 91.0, 'efficiency': 88.0, 'retention': 95.0},
  ];

  // Performance Radar Data
  static final List<Map<String, dynamic>> performanceRadar = [
    {'metric': 'Customer\nSatisfaction', 'value': 91.0},
    {'metric': 'Operational\nEfficiency', 'value': 88.0},
    {'metric': 'Staff\nRetention', 'value': 95.0},
    {'metric': 'Inventory\nTurnover', 'value': 82.0},
    {'metric': 'Revenue\nGrowth', 'value': 78.0},
  ];

  // KPI Cards Data
  static final List<Map<String, String>> kpiCards = [
    {
      'label': 'Customer Satisfaction',
      'value': '91%',
      'target': '95%',
      'status': 'on-track',
    },
    {
      'label': 'Daily Transactions',
      'value': '324',
      'target': '300',
      'status': 'above-target',
    },
    {
      'label': 'Average Transaction',
      'value': '₱580',
      'target': '₱600',
      'status': 'on-track',
    },
    {
      'label': 'Staff Efficiency',
      'value': '88%',
      'target': '85%',
      'status': 'above-target',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KPI Dashboard',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Key performance indicators and business metrics',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content - Scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
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
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Performance Score Radar Chart
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Performance Score',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 300,
                              child: _RadarChartWidget(data: performanceRadar),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Weekly Trends Line Chart
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weekly Trends',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 300,
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
  }
}

// KPI Card Widget
class _KPICard extends StatelessWidget {
  final String label;
  final String value;
  final String target;
  final String status;

  const _KPICard({
    required this.label,
    required this.value,
    required this.target,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAboveTarget = status == 'above-target';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
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
            fillColor: Colors.blue.withOpacity(0.2),
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
            getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.8),
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
