import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../widgets/revenue_breakdown.dart';

/// Revenue Screen - Shows all revenue transactions and breakdown
/// Matches Next.js sales-page.tsx
class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _setToday();
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _setToday() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
  }

  void _setThisWeek() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    setState(() {
      _startDate = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
  }

  void _setThisMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
  }

  bool _isToday() {
    if (_startDate == null || _endDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final endDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    return startDay == today && endDay == today;
  }

  bool _isThisWeek() {
    if (_startDate == null || _endDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final sevenDaysAgoDay = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);
    final startDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final endDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    return startDay == sevenDaysAgoDay && endDay == today;
  }

  bool _isThisMonth() {
    if (_startDate == null || _endDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final startDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final endDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    return startDay == firstOfMonth && endDay == today;
  }

  String _getFilterLabel() {
    if (_startDate == null || _endDate == null) return 'Select Date Range';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final endDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

    if (startDay == today && endDay == today) {
      return 'Today';
    }

    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final sevenDaysAgoDay = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);
    if (startDay == sevenDaysAgoDay && endDay == today) {
      return 'This Week';
    }

    final firstOfMonth = DateTime(now.year, now.month, 1);
    if (startDay == firstOfMonth && endDay == today) {
      return 'This Month';
    }

    return '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final List<Transaction> revenueTransactions = _startDate != null && _endDate != null
            ? provider.getCustomRangeRevenueList(_startDate!, _endDate!)
            : provider.revenueTransactions;
        final double totalRevenue = _startDate != null && _endDate != null
            ? provider.getCustomRangeRevenue(_startDate!, _endDate!)
            : provider.totalRevenue;
        final Map<String, double> revenueByMethod = _startDate != null && _endDate != null
            ? provider.getCustomRangeRevenueByMethod(_startDate!, _endDate!)
            : provider.revenueByMethod;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revenue Report',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track all your revenue sources',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.show_chart_rounded,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date Filter
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    // Date Range Display & Picker Button
                    InkWell(
                      onTap: _selectDateRange,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _getFilterLabel(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Quick Filter Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _QuickFilterButton(
                            label: 'Today',
                            onPressed: _setToday,
                            isSelected: _isToday(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickFilterButton(
                            label: 'This Week',
                            onPressed: _setThisWeek,
                            isSelected: _isThisWeek(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickFilterButton(
                            label: 'This Month',
                            onPressed: _setThisMonth,
                            isSelected: _isThisMonth(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Total Revenue Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                      theme.colorScheme.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Revenue',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '₱${NumberFormat('#,###.00').format(totalRevenue)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.trending_up,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 48,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Revenue Breakdown by Method
              RevenueBreakdown(
                revenueByMethod: revenueByMethod,
                totalRevenue: totalRevenue,
              ),
              const SizedBox(height: 24),

              // Revenue Transactions List
              Text(
                'All Revenue Transactions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (revenueTransactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No revenue transactions yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...revenueTransactions.map((transaction) {
                  return _TransactionCard(transaction: transaction);
                }),
            ],
          ),
        );
      },
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            _getCategoryIcon(transaction.category),
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${transaction.category} • ${transaction.paymentMethod}'),
            if (transaction.receiptNumber.isNotEmpty)
              Text(
                'Receipt: ${transaction.receiptNumber}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₱${NumberFormat('#,###.00').format(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              transaction.date,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        isThreeLine: transaction.receiptNumber.isNotEmpty,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Cash':
        return Icons.paid_rounded;
      case 'GCash':
        return Icons.smartphone_rounded;
      case 'Grab':
        return Icons.local_taxi_rounded;
      case 'Maya':
        return Icons.credit_card_rounded;
      case 'Credit Card':
        return Icons.credit_card_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }
}

class _QuickFilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isSelected;

  const _QuickFilterButton({
    required this.label,
    required this.onPressed,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        backgroundColor: isSelected 
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        side: BorderSide(
          color: theme.colorScheme.primary,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
