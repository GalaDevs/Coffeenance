import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';

/// Transaction Modal - Matches transaction-modal.tsx
/// Shows a bottom sheet with animations for adding transactions
class TransactionModal extends StatefulWidget {
  const TransactionModal({super.key});

  @override
  State<TransactionModal> createState() => _TransactionModalState();

  /// Show the modal with animation (matching Next.js animate-in)
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransactionModal(),
    );
  }
}

class _TransactionModalState extends State<TransactionModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  TransactionType _type = TransactionType.income;
  String? _category;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _othersSpecificationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _othersSpecificationController.dispose();
    super.dispose();
  }

  List<String> get _categories =>
      _type == TransactionType.income
          ? IncomeCategories.all
          : ExpenseCategories.all;

  void _handleSubmit() {
    if (_category == null ||
        _descriptionController.text.isEmpty ||
        _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: AppColors.lightDestructive,
        ),
      );
      return;
    }

    // Validate "Others" specification field if "Others" category is selected
    if ((_category == ExpenseCategories.others || _category == IncomeCategories.others) &&
        _othersSpecificationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify what "Others" is for'),
          backgroundColor: AppColors.lightDestructive,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: AppColors.lightDestructive,
        ),
      );
      return;
    }

    // If "Others" category is selected, append the specification to description
    String finalDescription = _descriptionController.text;
    if ((_category == ExpenseCategories.others || _category == IncomeCategories.others) &&
        _othersSpecificationController.text.isNotEmpty) {
      finalDescription = '${_descriptionController.text} (${_othersSpecificationController.text})';
    }

    final transaction = Transaction(
      id: 0, // Will be assigned by provider
      date: _selectedDate.toIso8601String().split('T')[0],
      type: _type,
      category: _category!,
      description: finalDescription,
      amount: amount,
    );

    context.read<TransactionProvider>().addTransaction(transaction);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction added successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
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
                bottom: MediaQuery.of(context).viewInsets.bottom,
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
                          'Add Transaction',
                          style: theme.textTheme.displayMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Type Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTypeButton(
                              'Income',
                              TransactionType.income,
                              theme,
                            ),
                          ),
                          Expanded(
                            child: _buildTypeButton(
                              'Transaction',
                              TransactionType.expense,
                              theme,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date Selection
                    Text(
                      'Date',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedDate = DateTime.now();
                              });
                            },
                            icon: const Icon(Icons.today),
                            label: const Text('Today'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: _selectedDate.difference(DateTime.now()).inDays == 0
                                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDate = picked;
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Category Selection
                    Text(
                      'Category',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        final isSelected = _category == category;
                        return GestureDetector(
                          onTap: () => setState(() => _category = category),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary,
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              category,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Others Specification Field - Shows when "Others" is selected for either Income or Transaction
                    if ((_type == TransactionType.expense && _category == ExpenseCategories.others) ||
                        (_type == TransactionType.income && _category == IncomeCategories.others)) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Specify Others',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _othersSpecificationController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Miscellaneous items, Repairs, etc.',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Description Input
                    Text(
                      'Description',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Morning sales',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Amount Input
                    Text(
                      'Amount (₱)',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        prefixText: '₱ ',
                        prefixStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    String label,
    TransactionType type,
    ThemeData theme,
  ) {
    final isSelected = _type == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _type = type;
          _category = null; // Reset category when type changes
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
