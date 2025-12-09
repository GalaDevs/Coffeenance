import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import 'package:intl/intl.dart';

/// Custom formatter for currency input with comma separators
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters except decimal point
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    
    // Ensure only one decimal point
    if (digitsOnly.split('.').length > 2) {
      return oldValue;
    }

    // Split into integer and decimal parts
    List<String> parts = digitsOnly.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Limit decimal to 2 digits
    if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    }

    // Format integer part with commas - handle unlimited amounts
    if (integerPart.isNotEmpty) {
      try {
        // Use BigInt for unlimited amount support
        final number = BigInt.parse(integerPart);
        
        // Format with commas manually to avoid overflow
        String formatted = number.toString();
        String result = '';
        int count = 0;
        
        for (int i = formatted.length - 1; i >= 0; i--) {
          if (count == 3) {
            result = ',$result';
            count = 0;
          }
          result = formatted[i] + result;
          count++;
        }
        
        integerPart = result;
      } catch (e) {
        // If parsing fails, keep the old value
        return oldValue;
      }
    }

    // Combine parts
    String formattedText = integerPart;
    if (parts.length > 1) {
      formattedText += '.$decimalPart';
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

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

  // Match Next.js state: revenue vs expenses
  late TransactionType _type;
  String? _category;
  String? _productType;
  bool _isCategoryDropdownOpen = false;
  bool _isProductDropdownOpen = false;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentMethodController = TextEditingController();
  final TextEditingController _transactionNumberController = TextEditingController();
  final TextEditingController _receiptNumberController = TextEditingController();
  final TextEditingController _tinNumberController = TextEditingController();
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _supplierAddressController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  int _vat = 0; // 0 or 12
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? TransactionType.revenue;
    
    // Add listener to format amount with .00 when focus is lost
    _amountFocusNode.addListener(() {
      if (!_amountFocusNode.hasFocus && _amountController.text.isNotEmpty) {
        _formatAmountWithDecimals();
      }
    });
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
    _amountFocusNode.dispose();
    _scrollController.dispose();
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

  void _formatAmountWithDecimals() {
    String text = _amountController.text.replaceAll(',', '');
    if (text.isEmpty) return;
    
    // Parse the amount
    double? amount = double.tryParse(text);
    if (amount == null) return;
    
    // Format with exactly 2 decimal places and commas
    final formatter = NumberFormat('#,##0.00');
    _amountController.text = formatter.format(amount);
  }

  List<String> get _categories =>
      _type == TransactionType.revenue
          ? RevenueCategories.all
          : TransactionCategories.all;

  // Mock data for product types
  List<Map<String, dynamic>> get _productTypes => [
    {'name': 'Coffee', 'icon': Icons.local_cafe_rounded},
    {'name': 'Espresso', 'icon': Icons.coffee_rounded},
    {'name': 'Latte', 'icon': Icons.emoji_food_beverage_rounded},
    {'name': 'Cappuccino', 'icon': Icons.coffee_maker_rounded},
    {'name': 'Americano', 'icon': Icons.local_cafe_outlined},
    {'name': 'Croissant', 'icon': Icons.bakery_dining_rounded},
    {'name': 'Muffin', 'icon': Icons.cake_rounded},
    {'name': 'Cookie', 'icon': Icons.cookie_rounded},
    {'name': 'Donut', 'icon': Icons.donut_small_rounded},
    {'name': 'Brownie', 'icon': Icons.cake_outlined},
  ];

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
        case 'Maya':
          return Icons.credit_card_rounded;
        case 'Credit Card':
          return Icons.credit_card_rounded;
        case 'Others':
          return Icons.more_horiz_rounded;
        default:
          return Icons.account_balance_wallet_rounded;
      }
    } else {
      // Expense categories
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
      case 'Maya':
        return Icons.credit_card_rounded;
      case 'Others':
        return Icons.more_horiz_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
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

  void _handleSubmit() {
    // Validation: category and amount required
    if (_category == null ||
        _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill required fields'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Remove commas before parsing the amount
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText);
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
    final transaction = Transaction(
      id: 0, // Will be assigned by provider
      date: _selectedDate.toIso8601String().split('T')[0],
      type: _type,
      category: _category!,
      description: _descriptionController.text,
      amount: amount,
      paymentMethod: _paymentMethodController.text.isEmpty 
          ? _category! 
          : _paymentMethodController.text,
      transactionNumber: _transactionNumberController.text.isEmpty
          ? 'TXN${DateTime.now().millisecondsSinceEpoch}'
          : _transactionNumberController.text,
      receiptNumber: _receiptNumberController.text.isEmpty
          ? 'RCP${DateTime.now().millisecondsSinceEpoch}'
          : _receiptNumberController.text,
      tinNumber: _tinNumberController.text,
      vat: _vat,
      supplierName: _supplierNameController.text,
      supplierAddress: _supplierAddressController.text,
    );

    context.read<TransactionProvider>().addTransaction(transaction);
    
    // Reset all fields for next entry
    setState(() {
      _category = null;
      _productType = null;
      _descriptionController.clear();
      _amountController.clear();
      _paymentMethodController.clear();
      _transactionNumberController.clear();
      _receiptNumberController.clear();
      _tinNumberController.clear();
      _supplierNameController.clear();
      _supplierAddressController.clear();
      _vat = 0;
      _selectedDate = DateTime.now();
      _isCategoryDropdownOpen = false;
      _isProductDropdownOpen = false;
    });
    
    // Scroll to top of modal
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    
    // Show success toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Transaction saved successfully! ✓')),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside text fields
        FocusScope.of(context).unfocus();
      },
      child: FadeTransition(
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
                controller: _scrollController,
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
                          _type == TransactionType.revenue ? 'Add Revenue' : 'Add Expenses',
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
                              'Expenses',
                              TransactionType.transaction,
                              theme,
                            ),
                          ),
                        ],
                      ),
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
                              style: theme.textTheme.bodyMedium?.copyWith(
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
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: !_isToday(_selectedDate)
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_isToday(_selectedDate)
                                  ? theme.colorScheme.primary // Use theme's primary brown color
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

                    // Amount - Unique Design
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
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                              focusNode: _amountFocusNode,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                CurrencyInputFormatter(),
                              ],
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 18),
                                filled: true,
                                fillColor: Colors.transparent,
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

                    // Category/Mode of Payment Selection
                    Text(
                      _type == TransactionType.revenue ? 'Mode of Payment' : 'Category',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // For Revenue: Show grid directly without dropdown
                    if (_type == TransactionType.revenue)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 3.5,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _category == category;
                          return GestureDetector(
                            onTap: () => setState(() => _category = category),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
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
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    else
                      // For Transaction: Show dropdown with grid inside
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

                    // Product Type - Only show for revenue
                    if (false && _type == TransactionType.revenue) ...[
                      Text(
                        'Product Type',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 3.5,
                          ),
                          itemCount: _productTypes.length,
                          itemBuilder: (context, index) {
                            final product = _productTypes[index];
                            final isSelected = _productType == product['name'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _productType = product['name'];
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.surface,
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.dividerColor,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      product['icon'],
                                      size: 18,
                                      color: isSelected
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        product['name'],
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Description
                    _buildTextField(
                      label: 'Description',
                      controller: _descriptionController,
                      hint: 'e.g., Morning sales',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),

                    // Expense-only fields
                    if (_type == TransactionType.transaction) ...[
                      // Mode of Payment
                      Text(
                        'Mode of Payment',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText: 'Select mode of payment',
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

                      // Voucher
                      _buildTextField(
                        label: 'Voucher',
                        controller: _transactionNumberController,
                        hint: 'e.g., VCH001',
                        theme: theme,
                      ),
                      const SizedBox(height: 16),

                      // Invoice Number
                      _buildTextField(
                        label: 'Invoice Number',
                        controller: _receiptNumberController,
                        hint: 'e.g., INV001',
                        theme: theme,
                      ),
                      const SizedBox(height: 16),

                      // Supplier Name
                      _buildTextField(
                        label: 'Supplier Name',
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
                            child: _buildVATButton('No VAT', 0, theme),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildVATButton('12% VAT', 12, theme),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // TIN Number
                      _buildTextField(
                        label: 'TIN Number',
                        controller: _tinNumberController,
                        hint: 'e.g., 123-456-789',
                        theme: theme,
                      ),
                      const SizedBox(height: 24),
                    ] else
                      const SizedBox(height: 8),

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
    // Use blue/indigo color for Revenue/Expense buttons to distinguish from Date buttons
    final buttonColor = type == TransactionType.revenue 
        ? Colors.green.shade600 
        : Colors.red.shade600;

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
              ? buttonColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: buttonColor.withValues(alpha: 0.3),
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
                ? Colors.white
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
