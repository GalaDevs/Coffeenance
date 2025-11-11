import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Inventory Status Modal - matches inventory-modal.tsx
/// Shows current stock levels and reorder recommendations
class InventoryModal extends StatelessWidget {
  const InventoryModal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sample inventory data matching Next.js
    final inventoryData = [
      {
        'item': 'Coffee Beans',
        'stock': 45,
        'unit': 'kg',
        'status': 'good',
        'reorder': 30
      },
      {
        'item': 'Milk',
        'stock': 12,
        'unit': 'L',
        'status': 'warning',
        'reorder': 20
      },
      {
        'item': 'Sugar',
        'stock': 8,
        'unit': 'kg',
        'status': 'critical',
        'reorder': 15
      },
      {
        'item': 'Pastry Dough',
        'stock': 25,
        'unit': 'kg',
        'status': 'good',
        'reorder': 20
      },
      {
        'item': 'Cups (12oz)',
        'stock': 200,
        'unit': 'pcs',
        'status': 'good',
        'reorder': 500
      },
      {
        'item': 'Napkins',
        'stock': 80,
        'unit': 'pcs',
        'status': 'warning',
        'reorder': 200
      },
    ];

    final consumptionData = [
      {'item': 'Coffee Beans', 'daily': 2.5},
      {'item': 'Milk', 'daily': 1.2},
      {'item': 'Sugar', 'daily': 0.8},
      {'item': 'Cups', 'daily': 150.0},
    ];

    // Calculate stats
    final totalItems = inventoryData.length;
    final criticalItems =
        inventoryData.where((i) => i['status'] == 'critical').length;
    final lowItems = inventoryData.where((i) => i['status'] == 'warning').length;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 896), // max-w-4xl
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
                          'Inventory Status',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current stock levels and reorder recommendations',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
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
                    // Status Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Total Items',
                            value: totalItems.toString(),
                            color: theme.colorScheme.primary,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Critical Items',
                            value: criticalItems.toString(),
                            color: const Color(0xFFDC2626), // red-600
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Low Stock',
                            value: lowItems.toString(),
                            color: const Color(0xFFCA8A04), // yellow-600
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Daily Consumption Chart
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Consumption',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 250,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: 160,
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        return BarTooltipItem(
                                          '${consumptionData[groupIndex]['item']}\n${rod.toY}',
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
                                        reservedSize: 60,
                                        getTitlesWidget: (value, meta) {
                                          if (value >= 0 &&
                                              value < consumptionData.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8),
                                              child: Transform.rotate(
                                                angle: -0.785398, // -45 degrees
                                                child: Text(
                                                  consumptionData[value.toInt()]
                                                      ['item'] as String,
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(fontSize: 10),
                                                  textAlign: TextAlign.end,
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            value.toInt().toString(),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(fontSize: 10),
                                          );
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
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: 20,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: theme.colorScheme.outline
                                            .withOpacity(0.2),
                                        strokeWidth: 1,
                                        dashArray: [5, 5],
                                      );
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: consumptionData
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    return BarChartGroupData(
                                      x: entry.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: entry.value['daily'] as double,
                                          color: const Color(0xFF3B82F6), // blue-500
                                          width: 24,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Inventory Table
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stock Levels',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...inventoryData.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: theme.colorScheme.outline
                                          .withOpacity(0.2),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['item'] as String,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Stock: ${item['stock']} ${item['unit']} | Reorder: ${item['reorder']} ${item['unit']}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                fontSize: 12,
                                                color: theme
                                                    .colorScheme.onSurface
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _StatusBadge(
                                        status: item['status'] as String,
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final ThemeData theme;

  const _SummaryCard({
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
          color: theme.colorScheme.outline.withOpacity(0.2),
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
                color: theme.colorScheme.onSurface.withOpacity(0.6),
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

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color _getBackgroundColor() {
    switch (status) {
      case 'good':
        return const Color(0xFFDCFCE7); // green-100
      case 'warning':
        return const Color(0xFFFEF3C7); // yellow-100
      case 'critical':
        return const Color(0xFFFEE2E2); // red-100
      default:
        return const Color(0xFFF3F4F6); // gray-100
    }
  }

  Color _getTextColor() {
    switch (status) {
      case 'good':
        return const Color(0xFF166534); // green-800
      case 'warning':
        return const Color(0xFF854D0E); // yellow-800
      case 'critical':
        return const Color(0xFF991B1B); // red-800
      default:
        return const Color(0xFF1F2937); // gray-800
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getTextColor(),
        ),
      ),
    );
  }
}
