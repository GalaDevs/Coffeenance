import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// Staff Payroll Modal - matches payroll-modal.tsx
/// Shows employee roster and salary information
class PayrollModal extends StatelessWidget {
  const PayrollModal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sample staff data matching Next.js
    final staffData = [
      {
        'id': 1,
        'name': 'Maria Santos',
        'position': 'Manager',
        'salary': 25000.0,
        'status': 'Full-time',
        'startDate': '2023-01'
      },
      {
        'id': 2,
        'name': 'Juan Dela Cruz',
        'position': 'Barista',
        'salary': 18000.0,
        'status': 'Full-time',
        'startDate': '2023-06'
      },
      {
        'id': 3,
        'name': 'Rosa Garcia',
        'position': 'Cashier',
        'salary': 16000.0,
        'status': 'Full-time',
        'startDate': '2023-09'
      },
      {
        'id': 4,
        'name': 'Pedro Lim',
        'position': 'Barista',
        'salary': 18000.0,
        'status': 'Full-time',
        'startDate': '2024-01'
      },
      {
        'id': 5,
        'name': 'Anna Wong',
        'position': 'Part-time Staff',
        'salary': 12000.0,
        'status': 'Part-time',
        'startDate': '2024-03'
      },
    ];

    final payrollSummary = [
      {'name': 'Salaries', 'value': 89000.0, 'color': const Color(0xFF3B82F6)},
      {'name': 'Benefits', 'value': 12000.0, 'color': const Color(0xFF10B981)},
      {
        'name': 'Contributions',
        'value': 8000.0,
        'color': const Color(0xFFF59E0B)
      },
    ];

    // Calculate stats
    final totalPayroll =
        staffData.fold<double>(0, (sum, s) => sum + (s['salary'] as double));
    final staffCount = staffData.length;
    final avgSalary = totalPayroll / staffCount;

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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Staff Payroll',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Employee roster and salary information',
                          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
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
            const Divider(height: 1),
            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _SummaryCard(
                            title: 'Total Staff',
                            value: staffCount.toString(),
                            color: theme.colorScheme.primary,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _SummaryCard(
                            title: 'Monthly Payroll',
                            value:
                                '₱${(totalPayroll / 1000).toStringAsFixed(0)}K',
                            color: const Color(0xFF3B82F6), // blue-600
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _SummaryCard(
                            title: 'Average Salary',
                            value: '₱${avgSalary.toStringAsFixed(0)}',
                            color: theme.colorScheme.primary,
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Payroll Composition Pie Chart
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
                              'Payroll Composition',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 250,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: PieChart(
                                      PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 0,
                                        sections: payrollSummary
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final item = entry.value;
                                          final value =
                                              item['value'] as double;
                                          final color = item['color'] as Color;
                                          final total = payrollSummary.fold<double>(
                                              0,
                                              (sum, i) =>
                                                  sum + (i['value'] as double));
                                          final percentage =
                                              (value / total * 100)
                                                  .toStringAsFixed(0);

                                          return PieChartSectionData(
                                            color: color,
                                            value: value,
                                            title: '$percentage%',
                                            radius: 80,
                                            titleStyle: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          );
                                        }).toList(),
                                        pieTouchData: PieTouchData(
                                          touchCallback:
                                              (FlTouchEvent event, response) {},
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Legend
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: payrollSummary.map((item) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 16,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                color: item['color'] as Color,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['name'] as String,
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  '₱${NumberFormat('#,###').format(item['value'])}',
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    fontSize: 11,
                                                    color: theme.colorScheme
                                                        .onSurface
                                                        .withValues(alpha: 0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Staff Directory
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
                              'Staff Directory',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...staffData.map((staff) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.outline
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              staff['name'] as String,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${staff['position']} • ${staff['status']} • Since ${staff['startDate']}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                fontSize: 12,
                                                color: theme
                                                    .colorScheme.onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₱${NumberFormat('#,###').format(staff['salary'])}',
                                        style:
                                            theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }
}
