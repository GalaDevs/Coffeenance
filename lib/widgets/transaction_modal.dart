import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

/// Transaction Modal - Matches transaction-modal.tsx
/// Shows a bottom sheet with animations for adding transactions
class TransactionModal extends StatefulWidget {
  final TransactionType? initialType;
  
  const TransactionModal({super.key, this.initialType});

  @override
  State<TransactionModal> createState() => _TransactionModalState();

  /// Show the modal with animation (matching Next.js animate-in)
  static Future<void> show(BuildContext context, {TransactionType? initialType}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionModal(initialType: initialType),
    );
  }
}

class _TransactionModalState extends State<TransactionModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Match Next.js state: revenue vs transaction
  late TransactionType _type;
  String? _category;
  bool _isCategoryDropdownOpen = false;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentMethodController = TextEditingController();
  final TextEditingController _transactionNumberController = TextEditingController();
  final TextEditingController _receiptNumberController = TextEditingController();
  final TextEditingController _tinNumberController = TextEditingController();
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _supplierAddressController = TextEditingController();
  int _vat = 0; // 0 or 12

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? TransactionType.revenue;
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
    _paymentMethodController.dispose();
    _transactionNumberController.dispose();
    _receiptNumberController.dispose();
    _tinNumberController.dispose();
    _supplierNameController.dispose();
    _supplierAddressController.dispose();
    super.dispose();
  }

  List<String> get _categories =>
      _type == TransactionType.revenue
          ? RevenueCategories.all
          : TransactionCategories.all;

  // Get icon for category
  IconData _getCategoryIcon(String category) {
    if (_type == TransactionType.revenue) {
      switch (category) {
        case 'Cash':
          return Icons.paid_rounded;
        case 'GCash':
          return Icons.smartphone_rounded;
        case 'Grab':
          return Icons.local_taxi_rounded;
        case 'PayMaya':
          return Icons.credit_card_rounded;
        case 'Others':
          return Icons.more_horiz_rounded;
        default:
          return Icons.account_balance_wallet_rounded;
      }
    } else {
      // Transaction/Expense categories
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
  }

  // Get icon for payment method
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
      case 'PayMaya':
        return Icons.credit_card_rounded;
      case 'Others':
        return Icons.more_horiz_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  void _handleSubmit() {
    // Match Next.js validation: category, amount, description required
    if (_category == null ||
        _descriptionController.text.isEmpty ||
        _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill required fields'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Match Next.js logic: create transaction with all fields
    final now = DateTime.now();
    final transaction = Transaction(
      id: 0, // Will be assigned by provider
      date: now.toIso8601String().split('T')[0],
      type: _type,
      category: _category!,
      description: _descriptionController.text,
      amount: amount,
      paymentMethod: _paymentMethodController.text.isEmpty 
          ? _category! 
          : _paymentMethodController.text,
      transactionNumber: _transactionNumberController.text.isEmpty
          ? 'TXN${now.millisecondsSinceEpoch}'
          : _transactionNumberController.text,
      receiptNumber: _receiptNumberController.text.isEmpty
          ? 'RCP${now.millisecondsSinceEpoch}'
          : _receiptNumberController.text,
      tinNumber: _tinNumberController.text,
      vat: _vat,
      supplierName: _supplierNameController.text,
      supplierAddress: _supplierAddressController.text,
    );

    context.read<TransactionProvider>().addTransaction(transaction);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction added successfully'),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
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
                    // Header - Match Next.js
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _type == TransactionType.revenue ? 'Add Revenue' : 'Add Transaction',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 28),
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            foregroundColor: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Type Toggle - Match Next.js grid-cols-2
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
                              'Revenue',
                              TransactionType.revenue,
                              theme,
                            ),
                          ),
                          Expanded(
                            child: _buildTypeButton(
                              'Transaction',
                              TransactionType.transaction,
                              theme,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Selection - Dropdown with Grid Layout
                    Text(
                      'Category',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Dropdown Container
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Dropdown Header
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isCategoryDropdownOpen = !_isCategoryDropdownOpen;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      if (_category != null) ...[
                                        Icon(
                                          _getCategoryIcon(_category!),
                                          size: 18,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(
                                        _category ?? 'Select a category',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: _category != null
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
                          // Dropdown Content - Grid in 2 columns inside tile
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
                                itemCount: _categories.length,
                                itemBuilder: (context, index) {
                                  final category = _categories[index];
                                  final isSelected = _category == category;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _category = category;
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
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
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
                                                style: theme.textTheme.bodySmall?.copyWith(
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
                    _buildTextField(
                      label: 'Description',
                      controller: _descriptionController,
                      hint: 'e.g., Morning sales',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    Text(
                      'Amount (₱)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
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
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefix: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '₱',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    // Payment Method - Dropdown
                    Text(
                      'Payment Method',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: 'Select payment method',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      items: PaymentMethods.all.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Row(
                            children: [
                              Icon(
                                _getPaymentMethodIcon(method),
                                size: 18,
                                color: theme.colorScheme.onSurface,
                              ),
                              const SizedBox(width: 8),
                              Text(method, style: theme.textTheme.bodySmall),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _paymentMethodController.text = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Transaction Number
                    _buildTextField(
                      label: 'Transaction Number',
                      controller: _transactionNumberController,
                      hint: 'e.g., TXN001',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),

                    // Official Receipt Number
                    _buildTextField(
                      label: 'Official Receipt Number',
                      controller: _receiptNumberController,
                      hint: 'e.g., RCP001',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),

                    // TIN Number
                    _buildTextField(
                      label: 'TIN Number',
                      controller: _tinNumberController,
                      hint: 'e.g., 123-456-789',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),

                    // VAT Selection - Match Next.js toggle
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
                          child: _buildVATButton('No VAT', 0, theme),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildVATButton('12% VAT', 12, theme),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Supplier Name
                    _buildTextField(
                      label: 'Supplier / Vendor Name',
                      controller: _supplierNameController,
                      hint: 'e.g., Coffee Supplier Inc.',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),

                    // Supplier Address
                    _buildTextField(
                      label: 'Supplier Address',
                      controller: _supplierAddressController,
                      hint: 'e.g., Manila, PH',
                      theme: theme,
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons - Match Next.js grid-cols-2
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: theme.dividerColor),
                            ),
                            child: Text(
                              'Cancel',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Save',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildVATButton(String label, int vatValue, ThemeData theme) {
    final isSelected = _vat == vatValue;
    return GestureDetector(
      onTap: () => setState(() => _vat = vatValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.secondary,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
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
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
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
