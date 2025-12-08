import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../widgets/expense_breakdown_card.dart';

/// Transactions Screen - Shows all expense/transaction records
/// Matches Next.js expenses-page.tsx
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
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
        final List<Transaction> transactionRecords = _startDate != null && _endDate != null
            ? provider.getCustomRangeExpenseList(_startDate!, _endDate!)
            : provider.transactionList;
        
        final double totalTransaction = _startDate != null && _endDate != null
            ? provider.getCustomRangeTransactions(_startDate!, _endDate!)
            : provider.totalTransaction;
        
        final Map<String, double> transactionsByCategoryAmounts = _startDate != null && _endDate != null
            ? provider.getCustomRangeTransactionsByCategory(_startDate!, _endDate!)
            : provider.transactionsByCategory;

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
                        'Transactions',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track all your business expenses',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      size: 32,
                      color: Colors.red.shade600,
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
                          color: Colors.red.shade600.withValues(alpha: 0.1),
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
                                  color: Colors.red.shade600,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _getFilterLabel(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: Colors.red.shade600,
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

              // Total Transactions Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade400,
                      Colors.red.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                          'Total Transactions',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '₱${NumberFormat('#,###.00').format(totalTransaction)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.trending_down,
                      color: Colors.white.withValues(alpha: 0.9), // replaced withOpacity
                      size: 48,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Transaction Breakdown by Category
              ExpenseBreakdownCard(
                expensesByCategory: transactionsByCategoryAmounts,
                totalExpenses: totalTransaction,
              ),
              const SizedBox(height: 24),

              // Transaction Records List
              Text(
                'All Transaction Records',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (transactionRecords.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...transactionRecords.map((transaction) {
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
          backgroundColor: Colors.red.shade50,
          child: Icon(
            _getCategoryIcon(transaction.category),
            color: Colors.red.shade700,
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
            if (transaction.supplierName.isNotEmpty)
              Text(
                'Supplier: ${transaction.supplierName}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.outline,
                ),
              ),
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
                color: Colors.red.shade700,
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
        isThreeLine: true,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Inventory':
        return Icons.inventory_2_rounded;
      case 'Ingredients':
        return Icons.restaurant_rounded;
      case 'Rent':
        return Icons.home_rounded;
      case 'Utilities':
        return Icons.bolt_rounded;
      case 'Payroll':
        return Icons.people_rounded;
      case 'Marketing':
        return Icons.campaign_rounded;
      default:
        return Icons.receipt_long_rounded;
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
            ? Colors.red.shade600.withValues(alpha: 0.15)
            : Colors.transparent,
        side: BorderSide(
          color: Colors.red.shade600,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: Colors.red.shade600,
        ),
      ),
    );
  }
}
