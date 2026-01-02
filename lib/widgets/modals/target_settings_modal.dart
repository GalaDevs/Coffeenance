import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/transaction_provider.dart';

/// Target Settings Modal - Allows admin to set and manage KPI targets
/// PULL: Reads current targets from TransactionProvider
/// PUSH: Updates targets back to TransactionProvider
class TargetSettingsModal extends StatefulWidget {
  const TargetSettingsModal({super.key});

  @override
  State<TargetSettingsModal> createState() => _TargetSettingsModalState();
}

class _TargetSettingsModalState extends State<TargetSettingsModal> {
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _modifiedKeys = {}; // Track which keys were actually modified
  bool _isSaving = false;
  bool _isInitialized = false;
  
  // Selected month and year (separate)
  late int _selectedMonth;
  late int _selectedYear;
  
  // Available months (1-12)
  final List<int> _months = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  
  // Available years for date picker (unlimited - 20 years back to 20 years forward)
  List<int> get _years {
    final now = DateTime.now();
    final List<int> years = [];
    for (int i = now.year - 20; i <= now.year + 20; i++) {
      years.add(i);
    }
    return years;
  }
  
  // Years to initialize controllers for (limited to avoid massive sync)
  List<int> get _initializationYears {
    final now = DateTime.now();
    return [now.year - 1, now.year, now.year + 1]; // Only 3 years
  }
  
  DateTime get _selectedDate => DateTime(_selectedYear, _selectedMonth, 1);
  
  // Generate list of available months (next 12 months) for initialization
  List<DateTime> get _availableMonths {
    final now = DateTime.now();
    final List<DateTime> months = [];
    
    for (int i = 1; i <= 12; i++) {
      final monthDate = DateTime(now.year, now.month + i, 1);
      months.add(monthDate);
    }
    
    return months;
  }
  
  String _getMonthKey(DateTime date) {
    return 'target_${date.year}_${date.month}';
  }
  
  String _getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2000, month, 1));
  }

  @override
  void initState() {
    super.initState();
    // Set initial selected date to next month
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    _selectedMonth = nextMonth.month;
    _selectedYear = nextMonth.year;
    
    // Initialize controllers immediately with current target values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<TransactionProvider>(context, listen: false);
        _initializeControllers(provider);
      }
    });
  }

  // Helper to create a controller with modification tracking
  TextEditingController _createTrackedController(String key, double value) {
    final controller = TextEditingController(
      text: _formatNumber(value),
    );
    controller.addListener(() {
      _modifiedKeys.add(key);
      // Removed excessive logging
    });
    return controller;
  }

  void _initializeControllers(TransactionProvider provider) {
    // Initialize controllers for all available months (next 12 months only)
    for (var monthDate in _availableMonths) {
      final monthKey = _getMonthKey(monthDate);
      final revenueKey = '${monthKey}_revenue';
      final expensesKey = '${monthKey}_expenses';
      
      final revenueValue = provider.getKPITarget(revenueKey);
      final expensesValue = provider.getKPITarget(expensesKey);
      
      _controllers[revenueKey] = _createTrackedController(
        revenueKey,
        revenueValue > 0 ? revenueValue : 300000.0,
      );
      _controllers[expensesKey] = _createTrackedController(
        expensesKey,
        expensesValue > 0 ? expensesValue : 150000.0,
      );
    }
    
    // Only initialize controllers for a LIMITED range (3 years) to avoid massive sync
    // The date picker can still go to any year, but controllers are created on-demand
    for (var year in _initializationYears) {
      for (var month in _months) {
        final monthDate = DateTime(year, month, 1);
        final monthKey = _getMonthKey(monthDate);
        final revenueKey = '${monthKey}_revenue';
        final expensesKey = '${monthKey}_expenses';
        
        // Only create if not already created
        if (!_controllers.containsKey(revenueKey)) {
          final revenueValue = provider.getKPITarget(revenueKey);
          final expensesValue = provider.getKPITarget(expensesKey);
          
          _controllers[revenueKey] = _createTrackedController(
            revenueKey,
            revenueValue > 0 ? revenueValue : 300000.0,
          );
          _controllers[expensesKey] = _createTrackedController(
            expensesKey,
            expensesValue > 0 ? expensesValue : 150000.0,
          );
        }
      }
    }
    
    setState(() {
      _isInitialized = true;
    });
  }
  
  void _changeMonth(int month) {
    setState(() {
      _selectedMonth = month;
    });
  }
  
  void _changeYear(int year) {
    setState(() {
      _selectedYear = year;
    });
  }
  
  // Helper method to safely get or create a controller
  TextEditingController _getOrCreateController(String key, TransactionProvider provider) {
    if (!_controllers.containsKey(key)) {
      final value = provider.getKPITarget(key);
      _controllers[key] = _createTrackedController(
        key,
        value > 0 ? value : (key.contains('revenue') ? 300000.0 : 1500.0),
      );
    }
    return _controllers[key]!;
  }
  
  // Mark a key as modified (called when user changes value)
  void _markAsModified(String key) {
    _modifiedKeys.add(key);
    // Removed excessive logging
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(number.round());
  }

  Future<void> _saveTargets() async {
    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<TransactionProvider>(context, listen: false);
    
    try {
      int savedCount = 0;
      
      // Get the current selected month's keys
      final currentMonthKey = _getMonthKey(_selectedDate);
      final revenueKey = '${currentMonthKey}_revenue';
      final expensesKey = '${currentMonthKey}_expenses';
      
      debugPrint('🔍 Saving monthly targets for: $_selectedDate');
      debugPrint('🔍 Revenue key: $revenueKey, Expenses key: $expensesKey');
      
      // Save revenue target for current month
      final revenueController = _controllers[revenueKey];
      if (revenueController != null) {
        final cleanValue = revenueController.text.replaceAll(',', '');
        var value = double.tryParse(cleanValue);
        debugPrint('🔍 Revenue: raw="${revenueController.text}", clean="$cleanValue", value=$value');
        
        if (value != null && value > 0) {
          await provider.updateKPISetting(revenueKey, value);
          savedCount++;
          debugPrint('✅ Saved revenue: $revenueKey = $value');
        }
      }
      
      // Save expenses budget for current month
      final expensesController = _controllers[expensesKey];
      if (expensesController != null) {
        final cleanValue = expensesController.text.replaceAll(',', '');
        var value = double.tryParse(cleanValue);
        debugPrint('🔍 Expenses: raw="${expensesController.text}", clean="$cleanValue", value=$value');
        
        if (value != null && value > 0) {
          await provider.updateKPISetting(expensesKey, value);
          savedCount++;
          debugPrint('✅ Saved expenses: $expensesKey = $value');
        }
      }
      
      debugPrint('💾 Saved $savedCount targets for ${DateFormat('MMMM yyyy').format(_selectedDate)}');
      
      // Force provider to notify listeners
      provider.notifyListeners();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(savedCount > 0 
                    ? 'Saved $savedCount targets for ${DateFormat('MMMM yyyy').format(_selectedDate)}!'
                    : 'No changes to save'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating targets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _applyToAllDashboards() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: const Text('Apply to All Dashboards'),
            ),
          ],
        ),
        content: const Text(
          'This will apply the current target settings to all dashboards that display revenue and expenses, including:\n\n'
          '• KPI Dashboard\n'
          '• Revenue Screen\n'
          '• Transaction Screen\n'
          '• Monthly P&L Report\n\n'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog
              
              // Save current targets first
              await _saveTargets();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Targets applied to all dashboards successfully!'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showModernDatePicker(BuildContext context) {
    final theme = Theme.of(context);
    DateTime tempDate = _selectedDate;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 380,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      'Select Period',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedMonth = tempDate.month;
                          _selectedYear = tempDate.year;
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Date Picker
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.monthYear,
                  initialDateTime: _selectedDate,
                  minimumYear: DateTime.now().year - 20,
                  maximumYear: DateTime.now().year + 20,
                  onDateTimeChanged: (DateTime newDate) {
                    setModalState(() {
                      tempDate = newDate;
                    });
                  },
                ),
              ),
              // Selected date preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMMM yyyy').format(tempDate),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllTargets() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        
        // Wrap with Consumer to listen to provider changes
        return Consumer<TransactionProvider>(
          builder: (context, provider, child) {
            // Get all targets from kpiSettings (unlimited years)
            final targets = <Map<String, dynamic>>[];
            final allSettings = provider.kpiSettings;
            
            // Debug: Print ALL keys to understand the format
            debugPrint('🔍 Total KPI Settings: ${allSettings.keys.length}');
            debugPrint('🔍 ALL KEYS: ${allSettings.keys.toList()}');
            final targetKeys = allSettings.keys.where((k) => k.startsWith('target_')).toList();
            debugPrint('🔍 Keys starting with target_: $targetKeys');
            final sampleKeys = allSettings.keys.where((k) => k.contains('revenue') || k.contains('transactions')).take(10).toList();
            debugPrint('🔍 Sample target keys with revenue/transactions: $sampleKeys');
            
            // Extract targets with different storage formats in the database
            // Format 1 (new): target_YYYY_M_revenue with month/year columns
            // Format 2 (old): M_revenue with embedded month, null year columns
            final monthTargets = <String, Map<String, double>>{};
            
            debugPrint('🔍 Parsing ${allSettings.length} KPI settings...');
            
            for (var entry in allSettings.entries) {
              final key = entry.key;
              final value = entry.value;
              
              if (!key.contains('revenue') && !key.contains('transactions')) {
                continue; // Skip non-target keys
              }
              
              int? month;
              int? year;
              String? type;
              
              // Pattern 1: target_YYYY_M_revenue/transactions (new format)
              final regex1 = RegExp(r'^target_(\d{4})_(\d{1,2})_(revenue|transactions)$');
              var match = regex1.firstMatch(key);
              if (match != null) {
                year = int.parse(match.group(1)!);
                month = int.parse(match.group(2)!);
                type = match.group(3);
              }
              
              // Pattern 2: M_revenue/transactions (old format - just month)
              if (month == null) {
                final regex2 = RegExp(r'^(\d{1,2})_(revenue|transactions)$');
                match = regex2.firstMatch(key);
                if (match != null) {
                  month = int.parse(match.group(1)!);
                  year = DateTime.now().year; // Assume current year for old data
                  type = match.group(2);
                }
              }
              
              // Pattern 3: YYYY_M_revenue/transactions (no target_ prefix)
              if (month == null) {
                final regex3 = RegExp(r'^(\d{4})_(\d{1,2})_(revenue|transactions)$');
                match = regex3.firstMatch(key);
                if (match != null) {
                  year = int.parse(match.group(1)!);
                  month = int.parse(match.group(2)!);
                  type = match.group(3);
                }
              }
              
              if (month != null && year != null && type != null) {
                final monthKey = '${year}_$month';
                monthTargets[monthKey] ??= {'revenue': 0, 'transactions': 0};
                
                // Convert value to double
                double numValue = 0;
                if (value is num) {
                  numValue = value.toDouble();
                } else if (value is String) {
                  numValue = double.tryParse(value) ?? 0;
                }
                
                monthTargets[monthKey]![type] = numValue;
                debugPrint('📝 Parsed: $key -> $monthKey ($type = $numValue)');
              }
            }
            
            debugPrint('🔍 Unique months found: ${monthTargets.length}');
            
            // Build targets list from parsed data - show ALL parsed targets
            for (var entry in monthTargets.entries) {
              final parts = entry.key.split('_');
              if (parts.length == 2) {
                final year = int.parse(parts[0]);
                final month = int.parse(parts[1]);
                final targetDate = DateTime(year, month, 1);
                final revenue = entry.value['revenue'] ?? 0;
                final transactions = entry.value['transactions'] ?? 0;
                
                // Show all targets that were ever set (exist in the system)
                debugPrint('✅ Adding target: ${DateFormat('MMM yyyy').format(targetDate)} - Revenue: $revenue, Expenses: $transactions');
                targets.add({
                  'date': targetDate,
                  'revenue': revenue,
                  'transactions': transactions,
                });
              }
            }
            
            // Sort by date descending (most recent first)
            targets.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
            
            debugPrint('📊 Total targets to display: ${targets.length}');
            
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Compact Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'All Targets',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${targets.length} targets set',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Clear All Button
                      if (targets.isNotEmpty)
                        IconButton(
                          onPressed: () => _showClearAllConfirmation(context, provider),
                          icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 22),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          tooltip: 'Clear All Targets',
                        ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: targets.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.flag_outlined,
                                    size: 48,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Targets Set',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Set targets for each month\nto track your progress',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: targets.length,
                          itemBuilder: (context, index) {
                            final target = targets[index];
                            final date = target['date'] as DateTime;
                            final revenue = target['revenue'] as double;
                            final expenses = target['transactions'] as double;
                            final isCurrentMonth = date.year == DateTime.now().year && 
                                                   date.month == DateTime.now().month;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isCurrentMonth 
                                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isCurrentMonth
                                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                                      : theme.colorScheme.outline.withValues(alpha: 0.1),
                                  width: isCurrentMonth ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    // Month Header
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: isCurrentMonth
                                                ? const Color(0xFF8B4513)  // Brown for current month
                                                : const Color(0xFFD2B48C),  // Light brown/tan for other months
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            DateFormat('MMM yyyy').format(date),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        if (isCurrentMonth) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'CURRENT',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Target Values Row
                                    Row(
                                      children: [
                                        // Revenue
                                        Expanded(
                                          child: _TargetValueChip(
                                            icon: Icons.trending_up_rounded,
                                            iconColor: Colors.green,
                                            label: 'Revenue',
                                            value: '₱${_formatNumber(revenue)}',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Expenses
                                        Expanded(
                                          child: _TargetValueChip(
                                            icon: Icons.account_balance_wallet_rounded,
                                            iconColor: Colors.orange,
                                            label: 'Expenses',
                                            value: '₱${_formatNumber(expenses)}',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
    );
  }

  void _showTargetInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.blue),
            SizedBox(width: 12),
            Text('About Targets'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Monthly Target Planning',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Plan Ahead:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('• Set targets for the next 12 months in advance\n'
                  '• Helps with long-term business planning\n'
                  '• Adjust targets based on seasonal trends'),
              SizedBox(height: 12),
              Text(
                'Revenue Targets:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('• Set monthly revenue goals for each month\n'
                  '• Track progress against your targets'),
              SizedBox(height: 12),
              Text(
                'Expense Targets:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('• Set monthly expense goals\n'
                  '• Monitor and control business costs'),
              SizedBox(height: 16),
              Text(
                'These targets are used in your Monthly P&L Summary to show performance percentages and help you make informed business decisions.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showClearAllConfirmation(BuildContext dialogContext, TransactionProvider provider) {
    showDialog(
      context: dialogContext,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Clear All Targets'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete all saved targets?',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context); // Close confirmation dialog
                await _clearAllTargets(provider);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext); // Close All Targets dialog
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllTargets(TransactionProvider provider) async {
    try {
      debugPrint('🗑️ Starting clear all targets...');
      
      // Get all target keys to clear
      final allSettings = provider.kpiSettings;
      final keysToRemove = <String>[];
      
      debugPrint('🔍 Current kpiSettings keys: ${allSettings.keys.toList()}');
      
      for (var key in allSettings.keys) {
        if (key.contains('revenue') || key.contains('transactions')) {
          // Check if it's a monthly target key (not a general setting)
          if (key.contains('_') && !key.contains('daily') && 
              !key.contains('weekly') && !key.contains('monthly') &&
              !key.contains('Target')) {
            keysToRemove.add(key);
          }
        }
      }
      
      debugPrint('🔍 Keys to clear (monthly): $keysToRemove');
      
      // Clear from provider/cloud
      for (var key in keysToRemove) {
        debugPrint('🗑️ Clearing monthly target: $key');
        await provider.updateKPISetting(key, 0.0);
      }
      
      // Also clear the general monthly target fallback
      debugPrint('🗑️ Clearing general monthlyRevenueTarget...');
      await provider.updateKPISetting('monthlyRevenueTarget', 0.0);
      debugPrint('🗑️ Clearing general monthlyTransactionsTarget...');
      await provider.updateKPISetting('monthlyTransactionsTarget', 0.0);
      
      // Verify the values are now 0
      debugPrint('✅ Verify after clear - monthlyRevenueTarget: ${provider.getKPITarget('monthlyRevenueTarget')}');
      debugPrint('✅ Verify after clear - monthlyTransactionsTarget: ${provider.getKPITarget('monthlyTransactionsTarget')}');
      
      // Also clear from Supabase directly
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        // Get shop_id
        final userProfile = await Supabase.instance.client
            .from('user_profiles')
            .select('admin_id')
            .eq('id', userId)
            .single();
        
        final shopId = userProfile['admin_id'] ?? userId;
        
        // Delete all monthly targets from kpi_targets table
        await Supabase.instance.client
            .from('kpi_targets')
            .delete()
            .eq('shop_id', shopId)
            .not('month', 'is', null); // Only delete month-specific targets
        
        debugPrint('🗑️ Cleared all monthly targets from cloud');
      }
      
      // Clear local controllers
      setState(() {
        for (var controller in _controllers.values) {
          controller.text = '';
        }
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('All targets cleared successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error clearing targets: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Error clearing targets: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showDebugInfo() {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final allSettings = provider.kpiSettings;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    
    // Collect debug info
    final targetKeys = allSettings.keys.where((k) => 
      k.contains('revenue') || k.contains('transactions')
    ).toList()..sort();
    
    final nonZeroTargets = targetKeys.where((k) {
      final value = allSettings[k];
      return value is num && value > 0;
    }).toList();
    
    // Parse month keys
    final monthTargets = <String, Map<String, dynamic>>{};
    for (var key in targetKeys) {
      int? month;
      int? year;
      String? type;
      
      // Pattern 1: target_YYYY_M_type
      final regex1 = RegExp(r'^target_(\d{4})_(\d{1,2})_(revenue|transactions)$');
      var match = regex1.firstMatch(key);
      if (match != null) {
        year = int.parse(match.group(1)!);
        month = int.parse(match.group(2)!);
        type = match.group(3);
      }
      
      // Pattern 2: M_type (old format)
      if (month == null) {
        final regex2 = RegExp(r'^(\d{1,2})_(revenue|transactions)$');
        match = regex2.firstMatch(key);
        if (match != null) {
          month = int.parse(match.group(1)!);
          year = DateTime.now().year;
          type = match.group(2);
        }
      }
      
      if (month != null && year != null && type != null) {
        final monthKey = '${year}_$month';
        monthTargets[monthKey] ??= {'year': year, 'month': month, 'revenue': 0.0, 'transactions': 0.0};
        monthTargets[monthKey]![type] = allSettings[key] ?? 0.0;
      }
    }
    
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bug_report_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Target Settings Debug',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Info
                        _DebugSection(
                          title: '👤 User Info',
                          children: [
                            _DebugRow(label: 'User ID', value: userId ?? 'Not logged in'),
                            _DebugRow(label: 'Shop ID', value: provider.currentShopId ?? 'Not set'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Settings Summary
                        _DebugSection(
                          title: '📊 Settings Summary',
                          children: [
                            _DebugRow(label: 'Total KPI Settings', value: '${allSettings.length}'),
                            _DebugRow(label: 'Target Keys', value: '${targetKeys.length}'),
                            _DebugRow(label: 'Non-Zero Targets', value: '${nonZeroTargets.length}'),
                            _DebugRow(label: 'Unique Months', value: '${monthTargets.length}'),
                            _DebugRow(label: 'Controllers', value: '${_controllers.length}'),
                            _DebugRow(label: 'Modified Keys', value: '${_modifiedKeys.length}'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Current Selection
                        _DebugSection(
                          title: '📅 Current Selection',
                          children: [
                            _DebugRow(label: 'Month', value: '$_selectedMonth (${_getMonthName(_selectedMonth)})'),
                            _DebugRow(label: 'Year', value: '$_selectedYear'),
                            _DebugRow(label: 'Month Key', value: _getMonthKey(_selectedDate)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Sample Keys
                        _DebugSection(
                          title: '🔑 Sample Target Keys (first 10)',
                          children: targetKeys.take(10).map((k) {
                            final value = allSettings[k];
                            return _DebugRow(
                              label: k,
                              value: value?.toString() ?? 'null',
                              valueColor: value != null && value > 0 ? Colors.green : Colors.grey,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        
                        // Non-Zero Targets
                        if (nonZeroTargets.isNotEmpty) ...[
                          _DebugSection(
                            title: '✅ Non-Zero Targets (${nonZeroTargets.length})',
                            children: nonZeroTargets.take(20).map((k) {
                              final value = allSettings[k];
                              return _DebugRow(
                                label: k,
                                value: '₱${_formatNumber((value as num).toDouble())}',
                                valueColor: Colors.green,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Month Targets Summary
                        _DebugSection(
                          title: '📆 Month Targets (${monthTargets.length})',
                          children: monthTargets.entries.take(12).map((e) {
                            final data = e.value;
                            final rev = (data['revenue'] as num?)?.toDouble() ?? 0;
                            final exp = (data['transactions'] as num?)?.toDouble() ?? 0;
                            final monthName = DateFormat('MMM yyyy').format(
                              DateTime(data['year'] as int, data['month'] as int, 1)
                            );
                            return _DebugRow(
                              label: monthName,
                              value: 'R: ₱${_formatNumber(rev)} | E: ₱${_formatNumber(exp)}',
                              valueColor: (rev > 0 || exp > 0) ? Colors.green : Colors.grey,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Print full debug to console
                            debugPrint('═══════════════════════════════════════════');
                            debugPrint('🐛 TARGET SETTINGS DEBUG DUMP');
                            debugPrint('═══════════════════════════════════════════');
                            debugPrint('User ID: $userId');
                            debugPrint('Shop ID: ${provider.currentShopId}');
                            debugPrint('Total Settings: ${allSettings.length}');
                            debugPrint('Target Keys: ${targetKeys.length}');
                            debugPrint('Non-Zero: ${nonZeroTargets.length}');
                            debugPrint('───────────────────────────────────────────');
                            debugPrint('ALL TARGET KEYS:');
                            for (var k in targetKeys) {
                              debugPrint('  $k = ${allSettings[k]}');
                            }
                            debugPrint('───────────────────────────────────────────');
                            debugPrint('MONTH TARGETS:');
                            for (var e in monthTargets.entries) {
                              debugPrint('  ${e.key}: ${e.value}');
                            }
                            debugPrint('═══════════════════════════════════════════');
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Debug info printed to console'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.terminal, size: 18),
                          label: const Text('Print to Console'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            // Refresh data from cloud
                            Navigator.pop(context);
                            await provider.refreshKPITargets();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Refreshed KPI targets from cloud'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Refresh'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('Are you sure you want to reset all targets to default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                // Reset all monthly targets to defaults
                for (var monthDate in _availableMonths) {
                  final monthKey = _getMonthKey(monthDate);
                  _controllers['${monthKey}_revenue']?.text = _formatNumber(300000.0);
                  _controllers['${monthKey}_transactions']?.text = _formatNumber(1500.0);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: 12, 
        vertical: isSmallScreen ? 24 : 40,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: screenHeight * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.flag_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Target Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Quick actions
                  IconButton(
                    onPressed: _showDebugInfo,
                    icon: const Icon(Icons.bug_report_rounded, color: Colors.white70, size: 18),
                    tooltip: 'Debug',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    onPressed: _showAllTargets,
                    icon: const Icon(Icons.list_alt_rounded, color: Colors.white, size: 20),
                    tooltip: 'View All',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: !_isInitialized
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Month Selector Card
                    GestureDetector(
                      onTap: () => _showModernDatePicker(context),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                              theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Target Period',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('MMMM yyyy').format(_selectedDate),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.edit_calendar_rounded,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Monthly Target Info
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Set your monthly targets for ${DateFormat('MMMM yyyy').format(_selectedDate)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Target Input Cards (Revenue Target + Expenses Budget)
                    Consumer<TransactionProvider>(
                      builder: (context, provider, child) {
                        final revenueKey = '${_getMonthKey(_selectedDate)}_revenue';
                        final expensesKey = '${_getMonthKey(_selectedDate)}_expenses';
                        
                        return Column(
                          children: [
                            // Revenue Target Card
                            _MobileTargetCard(
                              label: 'Monthly Revenue Target',
                              icon: Icons.trending_up_rounded,
                              iconColor: Colors.green,
                              controller: _getOrCreateController(revenueKey, provider),
                              prefix: '₱',
                              hint: '300,000',
                              onChanged: () => _markAsModified(revenueKey),
                            ),
                            const SizedBox(height: 12),
                            // Expenses Budget Card
                            _MobileTargetCard(
                              label: 'Monthly Expenses Budget',
                              icon: Icons.account_balance_wallet_rounded,
                              iconColor: Colors.orange,
                              controller: _getOrCreateController(expensesKey, provider),
                              prefix: '₱',
                              hint: '150,000',
                              onChanged: () => _markAsModified(expensesKey),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Quick Actions Row
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.info_outline_rounded,
                            label: 'Info',
                            onTap: _showTargetInfo,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.refresh_rounded,
                            label: 'Reset',
                            onTap: _resetToDefaults,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.dashboard_customize_rounded,
                            label: 'Apply All',
                            onTap: _applyToAllDashboards,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Sticky Save Button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _saveTargets,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

// Mobile-friendly target input card
class _MobileTargetCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final TextEditingController controller;
  final String? prefix;
  final String hint;
  final VoidCallback? onChanged;

  const _MobileTargetCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.controller,
    this.prefix,
    required this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => onChanged?.call(),
                  enabled: true, // Explicitly enable editing
                  readOnly: false, // Explicitly NOT read-only
                  autofocus: false,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      fontWeight: FontWeight.normal,
                    ),
                    prefixText: prefix,
                    prefixStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    suffixIcon: Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Quick action button
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Target value chip for All Targets Overview
class _TargetValueChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _TargetValueChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Debug section widget
class _DebugSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DebugSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

// Debug row widget
class _DebugRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DebugRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? theme.colorScheme.onSurface,
                fontSize: 11,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}