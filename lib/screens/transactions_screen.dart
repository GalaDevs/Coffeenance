import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../models/transaction.dart';
import '../models/user_profile.dart';
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
  DateTime? _selectedSingleDate; // For single day picker

  @override
  void initState() {
    super.initState();
    _setToday();
  }

  void _selectSingleDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedSingleDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedSingleDate = picked;
        // Set date range to cover the entire selected day
        _startDate = DateTime(picked.year, picked.month, picked.day);
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
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
        _selectedSingleDate = null; // Clear single date selection
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _setToday() {
    final now = DateTime.now();
    setState(() {
      _selectedSingleDate = null; // Clear single date
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
  }

  void _setThisWeek() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    setState(() {
      _selectedSingleDate = null; // Clear single date
      _startDate = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
  }

  void _setThisMonth() {
    final now = DateTime.now();
    setState(() {
      _selectedSingleDate = null; // Clear single date
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    });
  }

  void _setYearly() {
    final now = DateTime.now();
    setState(() {
      _selectedSingleDate = null; // Clear single date
      _startDate = DateTime(now.year, 1, 1); // January 1 of current year
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

  bool _isYearly() {
    if (_startDate == null || _endDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstOfYear = DateTime(now.year, 1, 1);
    final startDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final endDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    return startDay == firstOfYear && endDay == today;
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
      return 'Past 7 Days';
    }

    final firstOfMonth = DateTime(now.year, now.month, 1);
    if (startDay == firstOfMonth && endDay == today) {
      return 'Month to Date';
    }

    final firstOfYear = DateTime(now.year, 1, 1);
    if (startDay == firstOfYear && endDay == today) {
      return 'Yearly';
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
                        'Expenses',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          final userName = authProvider.currentUser?.fullName ?? 'User';
                          return Text(
                            userName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
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
                            label: 'Past 7 Days',
                            onPressed: _setThisWeek,
                            isSelected: _isThisWeek(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickFilterButton(
                            label: 'Month to Date',
                            onPressed: _setThisMonth,
                            isSelected: _isThisMonth(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickFilterButton(
                            label: 'Yearly',
                            onPressed: _setYearly,
                            isSelected: _isYearly(),
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

              // Transaction Records List with Date Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Transaction Records',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _selectSingleDate,
                    icon: Icon(
                      Icons.calendar_today,
                      color: _selectedSingleDate != null
                          ? Colors.red.shade600
                          : theme.colorScheme.onSurface,
                    ),
                    tooltip: _selectedSingleDate != null
                        ? 'Selected: ${DateFormat('MMM dd, yyyy').format(_selectedSingleDate!)}'
                        : 'Select a specific day',
                    style: IconButton.styleFrom(
                      backgroundColor: _selectedSingleDate != null
                          ? Colors.red.shade50
                          : null,
                    ),
                  ),
                ],
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
                          'No expenses yet',
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
    final authProvider = context.watch<AuthProvider>();
    final userRole = authProvider.userRole;
    final userId = authProvider.currentUser?.id ?? '';
    final ownerId = authProvider.currentUser?.adminId ?? authProvider.currentUser?.id ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  _formatDate(transaction.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          ),
          // Action buttons based on role
          if (userRole != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Edit button
                  TextButton.icon(
                    onPressed: () => _handleEdit(context, transaction, userRole, userId, ownerId),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: Text(userRole == UserRole.staff ? 'Request Edit' : 'Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button (Admin and Manager only)
                  if (userRole == UserRole.admin || userRole == UserRole.manager)
                    TextButton.icon(
                      onPressed: () => _handleDelete(context, transaction, userRole, userId, ownerId),
                      icon: const Icon(Icons.delete_rounded, size: 16),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleEdit(
    BuildContext context,
    Transaction transaction,
    UserRole role,
    String userId,
    String ownerId,
  ) async {
    // Show edit modal
    final result = await _EditTransactionDialog.show(context, transaction);

    if (result != null && context.mounted) {
      final transactionProvider = context.read<TransactionProvider>();
      final success = await transactionProvider.editTransactionWithRole(
        original: transaction,
        edited: result,
        role: role,
        userId: userId,
        ownerId: ownerId,
      );

      if (success && context.mounted) {
        final message = role == UserRole.staff
            ? 'Edit request sent for approval'
            : 'Transaction updated successfully';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    Transaction transaction,
    UserRole role,
    String userId,
    String ownerId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this transaction?'),
            const SizedBox(height: 16),
            Text(
              '₱${NumberFormat('#,###.00').format(transaction.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(transaction.description),
            if (role == UserRole.manager) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Admin will be notified of this deletion',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final transactionProvider = context.read<TransactionProvider>();
      final success = await transactionProvider.deleteTransactionWithRole(
        transactionId: transaction.id,
        role: role,
        userId: userId,
        ownerId: ownerId,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return dateStr;
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: Colors.red.shade600,
        ),
      ),
    );
  }
}

/// Edit Transaction Modal - Matches Add Transaction layout exactly
class _EditTransactionDialog extends StatefulWidget {
  final Transaction transaction;

  const _EditTransactionDialog({required this.transaction});

  @override
  State<_EditTransactionDialog> createState() => _EditTransactionDialogState();

  static Future<Transaction?> show(BuildContext context, Transaction transaction) {
    return showModalBottomSheet<Transaction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditTransactionDialog(transaction: transaction),
    );
  }
}

class _EditTransactionDialogState extends State<_EditTransactionDialog> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _supplierNameController;
  late TextEditingController _supplierAddressController;
  late TextEditingController _receiptNumberController;
  late TextEditingController _tinNumberController;
  late TextEditingController _paymentMethodController;
  late TextEditingController _voucherController;
  late DateTime _selectedDate;
  late String? _selectedCategory;
  late String _selectedPaymentMethod;
  late double _vat;
  bool _isCategoryDropdownOpen = false;

  // Categories for expenses - matching add transaction modal
  final List<String> _expenseCategories = [
    'Supplies',
    'Pastries',
    'Rent',
    'Utilities',
    'Manpower',
    'Marketing',
    'Others',
  ];

  final List<String> _paymentMethods = [
    'Cash',
    'Check',
    'Bank Transfer',
    'Credit Card',
    'GCash',
    'Maya',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _amountController = TextEditingController(text: t.amount.toStringAsFixed(2).replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), ''));
    _descriptionController = TextEditingController(text: t.description);
    _supplierNameController = TextEditingController(text: t.supplierName);
    _supplierAddressController = TextEditingController(text: t.supplierAddress);
    _receiptNumberController = TextEditingController(text: t.receiptNumber);
    _tinNumberController = TextEditingController(text: t.tinNumber);
    _paymentMethodController = TextEditingController(text: t.paymentMethod);
    _voucherController = TextEditingController(text: t.transactionNumber);
    _selectedDate = DateTime.parse(t.date);
    _selectedCategory = t.category;
    _selectedPaymentMethod = t.paymentMethod;
    _vat = t.vat.toDouble();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _supplierNameController.dispose();
    _supplierAddressController.dispose();
    _receiptNumberController.dispose();
    _tinNumberController.dispose();
    _paymentMethodController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Supplies':
        return Icons.inventory_2_rounded;
      case 'Pastries':
        return Icons.restaurant_rounded;
      case 'Rent':
        return Icons.home_rounded;
      case 'Utilities':
        return Icons.bolt_rounded;
      case 'Manpower':
        return Icons.people_rounded;
      case 'Marketing':
        return Icons.campaign_rounded;
      case 'Others':
        return Icons.more_horiz_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'Cash':
        return Icons.paid_rounded;
      case 'Check':
        return Icons.receipt_long_rounded;
      case 'Bank Transfer':
        return Icons.account_balance_rounded;
      case 'Credit Card':
        return Icons.credit_card_rounded;
      case 'GCash':
        return Icons.smartphone_rounded;
      case 'Maya':
        return Icons.credit_card_rounded;
      case 'Others':
        return Icons.more_horiz_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveChanges() {
    // Validation
    if (_selectedCategory == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final edited = widget.transaction.copyWith(
      amount: amount,
      description: _descriptionController.text,
      category: _selectedCategory!,
      paymentMethod: _paymentMethodController.text.isEmpty ? _selectedCategory! : _paymentMethodController.text,
      date: _selectedDate.toIso8601String().split('T')[0],
      supplierName: _supplierNameController.text,
      supplierAddress: _supplierAddressController.text,
      receiptNumber: _receiptNumberController.text,
      tinNumber: _tinNumberController.text,
      transactionNumber: _voucherController.text,
      vat: _vat.toInt(),
    );
    Navigator.pop(context, edited);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Expense',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date Selection
                Text(
                  'Date',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime.now();
                          });
                        },
                        icon: Icon(
                          Icons.today_rounded,
                          size: 20,
                          color: _isToday(_selectedDate)
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                        label: Text(
                          'Today',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _isToday(_selectedDate)
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isToday(_selectedDate)
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _isToday(_selectedDate)
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickDate,
                        icon: Icon(
                          Icons.calendar_today_rounded,
                          size: 20,
                          color: !_isToday(_selectedDate)
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                        label: Text(
                          _isToday(_selectedDate)
                              ? 'Pick Date'
                              : DateFormat('MMM dd, yyyy').format(_selectedDate),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: !_isToday(_selectedDate)
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_isToday(_selectedDate)
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: !_isToday(_selectedDate)
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount
                Text(
                  'Amount (₱)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.05),
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          '₱',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 18),
                          ),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Category Selection
                Text(
                  'Category',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isCategoryDropdownOpen = !_isCategoryDropdownOpen;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  if (_selectedCategory != null) ...[
                                    Icon(
                                      _getCategoryIcon(_selectedCategory!),
                                      size: 18,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    _selectedCategory ?? 'Select a category',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: _selectedCategory != null
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                _isCategoryDropdownOpen
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: theme.colorScheme.onSurface,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isCategoryDropdownOpen) ...[
                        Divider(height: 1, color: theme.dividerColor),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6,
                              childAspectRatio: 3.5,
                            ),
                            itemCount: _expenseCategories.length,
                            itemBuilder: (context, index) {
                              final category = _expenseCategories[index];
                              final isSelected = _selectedCategory == category;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category;
                                    _isCategoryDropdownOpen = false;
                                  });
                                },
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  elevation: isSelected ? 4 : 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.dividerColor,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _getCategoryIcon(category),
                                          size: 18,
                                          color: isSelected
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            category,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? theme.colorScheme.onPrimary
                                                  : theme.colorScheme.onSurface,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g., Office supplies',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Mode of Payment
                Text(
                  'Mode of Payment',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _paymentMethods.contains(_selectedPaymentMethod) ? _selectedPaymentMethod : 'Cash',
                  decoration: InputDecoration(
                    hintText: 'Select mode of payment',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  items: _paymentMethods.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Row(
                        children: [
                          Icon(_getPaymentMethodIcon(method), size: 18),
                          const SizedBox(width: 8),
                          Text(method),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _paymentMethodController.text = value ?? '';
                      _selectedPaymentMethod = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Voucher
                TextField(
                  controller: _voucherController,
                  decoration: InputDecoration(
                    labelText: 'Voucher',
                    hintText: 'e.g., VCH001',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Invoice Number
                TextField(
                  controller: _receiptNumberController,
                  decoration: InputDecoration(
                    labelText: 'Invoice Number',
                    hintText: 'e.g., INV001',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Supplier Name
                TextField(
                  controller: _supplierNameController,
                  decoration: InputDecoration(
                    labelText: 'Supplier Name',
                    hintText: 'e.g., Coffee Supplier Inc.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Supplier Address
                TextField(
                  controller: _supplierAddressController,
                  decoration: InputDecoration(
                    labelText: 'Supplier Address',
                    hintText: 'e.g., Manila, PH',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // VAT Selection
                Text(
                  'VAT',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _vat = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _vat == 0
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary,
                            border: Border.all(
                              color: _vat == 0
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'No VAT',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _vat == 0
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _vat = 12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _vat == 12
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary,
                            border: Border.all(
                              color: _vat == 12
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '12% VAT',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _vat == 12
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // TIN Number
                TextField(
                  controller: _tinNumberController,
                  decoration: InputDecoration(
                    labelText: 'TIN Number',
                    hintText: 'e.g., 123-456-789',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
