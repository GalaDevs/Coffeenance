import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
    });
    return controller;
  }

  void _initializeControllers(TransactionProvider provider) {
    // Initialize controllers for all available months (next 12 months only)
    for (var monthDate in _availableMonths) {
      final monthKey = _getMonthKey(monthDate);
      final revenueKey = '${monthKey}_revenue';
      final transactionsKey = '${monthKey}_transactions';
      
      final revenueValue = provider.getKPITarget(revenueKey);
      final transactionsValue = provider.getKPITarget(transactionsKey);
      
      _controllers[revenueKey] = _createTrackedController(
        revenueKey,
        revenueValue > 0 ? revenueValue : 300000.0,
      );
      _controllers[transactionsKey] = _createTrackedController(
        transactionsKey,
        transactionsValue > 0 ? transactionsValue : 1500.0,
      );
    }
    
    // Only initialize controllers for a LIMITED range (3 years) to avoid massive sync
    // The date picker can still go to any year, but controllers are created on-demand
    for (var year in _initializationYears) {
      for (var month in _months) {
        final monthDate = DateTime(year, month, 1);
        final monthKey = _getMonthKey(monthDate);
        final revenueKey = '${monthKey}_revenue';
        final transactionsKey = '${monthKey}_transactions';
        
        // Only create if not already created
        if (!_controllers.containsKey(revenueKey)) {
          final revenueValue = provider.getKPITarget(revenueKey);
          final transactionsValue = provider.getKPITarget(transactionsKey);
          
          _controllers[revenueKey] = _createTrackedController(
            revenueKey,
            revenueValue > 0 ? revenueValue : 300000.0,
          );
          _controllers[transactionsKey] = _createTrackedController(
            transactionsKey,
            transactionsValue > 0 ? transactionsValue : 1500.0,
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
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(number.round());
  }

  Future<void> _saveTargets() async {
    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<TransactionProvider>(context, listen: false);
    
    try {
      int savedCount = 0;
      
      // Only save controllers that were actually modified
      for (var key in _modifiedKeys) {
        final controller = _controllers[key];
        if (controller != null) {
          final cleanValue = controller.text.replaceAll(',', '');
          final value = double.tryParse(cleanValue);
          if (value != null && value > 0) {
            await provider.updateKPISetting(key, value);
            savedCount++;
          }
        }
      }
      
      debugPrint('💾 Saved $savedCount modified KPI targets (out of ${_controllers.length} total)');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(savedCount > 0 
                    ? 'Saved $savedCount target(s) successfully!'
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
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.green),
            SizedBox(width: 12),
            Text('Apply to All Dashboards'),
          ],
        ),
        content: const Text(
          'This will apply the current target settings to all dashboards that display revenue and transactions, including:\n\n'
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
        final provider = Provider.of<TransactionProvider>(context, listen: false);
        
        // Get all targets from kpiSettings (unlimited years)
        final targets = <Map<String, dynamic>>[];
        final allSettings = provider.kpiSettings;
        
        // Extract unique month keys from settings
        // Keys are in format: "target_YYYY_M_revenue" or "target_YYYY_M_transactions"
        final monthKeys = <String>{};
        for (var key in allSettings.keys) {
          if (key.startsWith('target_') && (key.endsWith('_revenue') || key.endsWith('_transactions'))) {
            // Remove suffix to get month key (e.g., "target_2025_12")
            final monthKey = key.replaceAll('_revenue', '').replaceAll('_transactions', '');
            monthKeys.add(monthKey);
          }
        }
        
        // Build targets list from extracted month keys
        for (var monthKey in monthKeys) {
          final revenueValue = provider.getKPITarget('${monthKey}_revenue');
          final transactionsValue = provider.getKPITarget('${monthKey}_transactions');
          
          if (revenueValue > 0 || transactionsValue > 0) {
            // Parse month key (format: "target_YYYY_M")
            try {
              final parts = monthKey.split('_');
              // parts[0] = "target", parts[1] = year, parts[2] = month
              if (parts.length >= 3) {
                final year = int.parse(parts[1]);
                final month = int.parse(parts[2]);
                targets.add({
                  'date': DateTime(year, month, 1),
                  'revenue': revenueValue,
                  'transactions': transactionsValue,
                });
              }
            } catch (e) {
              // Skip invalid keys
              debugPrint('⚠️ Could not parse month key: $monthKey - $e');
            }
          }
        }
        
        // Sort by date descending (most recent first)
        targets.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
        
        return Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'All Targets Overview',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: targets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 64,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Targets Set Yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start by setting targets for each month',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: targets.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final target = targets[index];
                            final date = target['date'] as DateTime;
                            final revenue = target['revenue'] as double;
                            final transactions = target['transactions'] as double;
                            
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          DateFormat('MMMM yyyy').format(date),
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.payments_rounded,
                                                  size: 16,
                                                  color: Colors.green.shade700,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Revenue',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '₱${_formatNumber(revenue)}',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.receipt_long_rounded,
                                                  size: 16,
                                                  color: Colors.blue.shade700,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Transactions',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatNumber(transactions),
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                'Transaction Targets:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('• Set monthly transaction count goals\n'
                  '• Monitor customer traffic and sales volume'),
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

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Target Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Plan your monthly targets ahead',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 3-dot menu for applying targets
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'apply_all',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('Apply to All Dashboards'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'info',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('About Targets'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'apply_all') {
                        _applyToAllDashboards();
                      } else if (value == 'info') {
                        _showTargetInfo();
                      }
                    },
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: !_isInitialized
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Set monthly targets for the next 12 months to plan your business growth',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // View All Targets Button
                    OutlinedButton.icon(
                      onPressed: _showAllTargets,
                      icon: const Icon(Icons.visibility_rounded),
                      label: const Text('View All Targets'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Month and Year Selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Select Target Period',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Modern iOS-style Date Picker Button
                          GestureDetector(
                            onTap: () => _showModernDatePicker(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.calendar_today_rounded,
                                      color: theme.colorScheme.primary,
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
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Selected Month Targets
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.flag_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Targets for ${DateFormat('MMMM yyyy').format(_selectedDate)}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Set your revenue and transaction goals',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Consumer<TransactionProvider>(
                            builder: (context, provider, child) {
                              final revenueKey = '${_getMonthKey(_selectedDate)}_revenue';
                              final transactionsKey = '${_getMonthKey(_selectedDate)}_transactions';
                              
                              return Column(
                                children: [
                                  _TargetInputField(
                                    label: 'Revenue Target',
                                    icon: Icons.payments_rounded,
                                    controller: _getOrCreateController(revenueKey, provider),
                                    hint: 'e.g., 300,000',
                                    prefix: '₱',
                                  ),
                                  const SizedBox(height: 16),
                                  _TargetInputField(
                                    label: 'Transactions Target',
                                    icon: Icons.receipt_long_rounded,
                                    controller: _getOrCreateController(transactionsKey, provider),
                                    hint: 'e.g., 1,500',
                                    suffix: 'transactions',
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reset Button
                    OutlinedButton.icon(
                      onPressed: _resetToDefaults,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reset to Defaults'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveTargets,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(_isSaving ? 'Saving...' : 'Save Targets'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isExpanded;
  final VoidCallback onTap;

  const _ExpandableSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TargetTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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

class _TargetInputField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final String? prefix;
  final String? suffix;

  const _TargetInputField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.hint,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            suffixText: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
