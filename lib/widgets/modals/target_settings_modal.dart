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
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers immediately with current target values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<TransactionProvider>(context, listen: false);
        _initializeControllers(provider);
      }
    });
  }

  void _initializeControllers(TransactionProvider provider) {
    final targets = [
      // Daily Targets
      {'key': 'dailyRevenueTarget', 'label': 'Daily Revenue Target'},
      {'key': 'dailyTransactionsTarget', 'label': 'Daily Transactions Target'},
      // Weekly Targets
      {'key': 'weeklyRevenueTarget', 'label': 'Weekly Revenue Target'},
      {'key': 'weeklyTransactionsTarget', 'label': 'Weekly Transactions Target'},
      // Monthly Targets
      {'key': 'monthlyRevenueTarget', 'label': 'Monthly Revenue Target'},
      {'key': 'monthlyTransactionsTarget', 'label': 'Monthly Transactions Target'},
    ];

    for (var target in targets) {
      final key = target['key']!;
      final value = provider.getKPITarget(key);
      _controllers[key] = TextEditingController(
        text: _formatNumber(value),
      );
    }
    
    setState(() {
      _isInitialized = true;
    });
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
      for (var entry in _controllers.entries) {
        final cleanValue = entry.value.text.replaceAll(',', '');
        final value = double.tryParse(cleanValue);
        if (value != null && value > 0) {
          await provider.updateKPISetting(entry.key, value);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Targets updated successfully'),
            backgroundColor: Colors.green,
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
                'Target Settings Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Daily Targets:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('• Track your daily revenue and transaction goals\n'
                  '• Updates automatically every day at midnight'),
              SizedBox(height: 12),
              Text(
                'Weekly Targets:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('• Monitor performance over a 7-day period\n'
                  '• Helps identify weekly trends and patterns'),
              SizedBox(height: 12),
              Text(
                'Monthly Targets:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('• Long-term goals for the entire month\n'
                  '• Essential for business planning and growth'),
              SizedBox(height: 16),
              Text(
                'These targets are used across all dashboards to show your progress and help you make informed business decisions.',
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
                // Daily targets
                _controllers['dailyRevenueTarget']?.text = _formatNumber(10000.0);
                _controllers['dailyTransactionsTarget']?.text = _formatNumber(50.0);
                // Weekly targets (7x daily)
                _controllers['weeklyRevenueTarget']?.text = _formatNumber(70000.0);
                _controllers['weeklyTransactionsTarget']?.text = _formatNumber(350.0);
                // Monthly targets (30x daily)
                _controllers['monthlyRevenueTarget']?.text = _formatNumber(300000.0);
                _controllers['monthlyTransactionsTarget']?.text = _formatNumber(1500.0);
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
                          'Set your KPI targets',
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
                              'Set realistic targets to track your business performance',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Daily Targets Section
                    _SectionHeader(
                      icon: Icons.today_rounded,
                      title: 'Daily Targets',
                      subtitle: 'Set your daily revenue and transaction goals',
                    ),
                    const SizedBox(height: 16),
                    _TargetInputField(
                      label: 'Daily Revenue Target',
                      icon: Icons.payments_rounded,
                      controller: _controllers['dailyRevenueTarget']!,
                      hint: 'e.g., 10,000',
                      prefix: '₱',
                    ),
                    const SizedBox(height: 12),
                    _TargetInputField(
                      label: 'Daily Transactions Target',
                      icon: Icons.receipt_long_rounded,
                      controller: _controllers['dailyTransactionsTarget']!,
                      hint: 'e.g., 50',
                      suffix: 'transactions',
                    ),
                    const SizedBox(height: 24),

                    // Weekly Targets Section
                    _SectionHeader(
                      icon: Icons.calendar_view_week_rounded,
                      title: 'Weekly Targets',
                      subtitle: 'Set your weekly revenue and transaction goals',
                    ),
                    const SizedBox(height: 16),
                    _TargetInputField(
                      label: 'Weekly Revenue Target',
                      icon: Icons.payments_rounded,
                      controller: _controllers['weeklyRevenueTarget']!,
                      hint: 'e.g., 70,000',
                      prefix: '₱',
                    ),
                    const SizedBox(height: 12),
                    _TargetInputField(
                      label: 'Weekly Transactions Target',
                      icon: Icons.receipt_long_rounded,
                      controller: _controllers['weeklyTransactionsTarget']!,
                      hint: 'e.g., 350',
                      suffix: 'transactions',
                    ),
                    const SizedBox(height: 24),

                    // Monthly Targets Section
                    _SectionHeader(
                      icon: Icons.calendar_month_rounded,
                      title: 'Monthly Targets',
                      subtitle: 'Set your monthly revenue and transaction goals',
                    ),
                    const SizedBox(height: 16),
                    _TargetInputField(
                      label: 'Monthly Revenue Target',
                      icon: Icons.payments_rounded,
                      controller: _controllers['monthlyRevenueTarget']!,
                      hint: 'e.g., 300,000',
                      prefix: '₱',
                    ),
                    const SizedBox(height: 12),
                    _TargetInputField(
                      label: 'Monthly Transactions Target',
                      icon: Icons.receipt_long_rounded,
                      controller: _controllers['monthlyTransactionsTarget']!,
                      hint: 'e.g., 1,500',
                      suffix: 'transactions',
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
