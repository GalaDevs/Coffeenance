import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import '../widgets/balance_card.dart';
import '../widgets/revenue_breakdown.dart';
import '../widgets/recent_transactions.dart';
import '../widgets/modals/monthly_pl_modal.dart';
import '../widgets/modals/revenue_trends_modal.dart';
import '../widgets/modals/inventory_modal.dart';
import '../widgets/modals/payroll_modal.dart';
import '../widgets/modals/kpi_dashboard_modal.dart';
import '../widgets/modals/target_settings_modal.dart';
import '../widgets/sales_monitoring_card.dart';
import '../widgets/expense_breakdown_card.dart';

/// Dashboard Screen - Matches dashboard.tsx
/// Shows balance, sales breakdown, and recent transactions
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Default to today
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  String _getFilterLabel() {
    if (_startDate == null || _endDate == null) return 'Select Date Range';
    
    final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    
    // Check if same day
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      if (start.year == today.year && start.month == today.month && start.day == today.day) {
        return "Today's Balance";
      }
      return DateFormat('MMM d, yyyy').format(start);
    }
    
    // Date range
    return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}';
  }

  String _getPerformanceLabel() {
    if (_startDate == null || _endDate == null) return 'Performance';
    
    final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      if (start.year == today.year && start.month == today.month && start.day == today.day) {
        return "Today's Performance";
      }
    }
    
    return 'Performance';
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
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
    final sevenDaysAgo = now.subtract(const Duration(days: 6)); // 7 days total (including today)
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isStaff = authProvider.currentUser?.role == UserRole.staff;

    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: 100, // Space for bottom nav
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
                        'Dashboard',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getPerformanceLabel(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          final currentUser = authProvider.currentUser;
                          final hasProfileImage = currentUser?.profileImageUrl != null;
                          
                          return Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: hasProfileImage
                                  ? Image.network(
                                      currentUser!.profileImageUrl!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/icon Cafenance.png',
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.coffee,
                                              size: 32,
                                              color: theme.colorScheme.primary,
                                            );
                                          },
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      'assets/icon Cafenance.png',
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.coffee,
                                          size: 32,
                                          color: theme.colorScheme.primary,
                                        );
                                      },
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      if (!isStaff) // Hide 3-dot menu for staff
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          _buildPopupMenuItem(
                            Icons.analytics_rounded,
                            'Monthly P&L Summary',
                            'monthly_pl',
                          ),
                          _buildPopupMenuItem(
                            Icons.show_chart_rounded,
                            'Revenue Trends',
                            'revenue_trends',
                          ),
                          // Temporarily hidden - will be added later
                          // _buildPopupMenuItem(
                          //   Icons.inventory_2_rounded,
                          //   'Inventory Status',
                          //   'inventory',
                          // ),
                          // _buildPopupMenuItem(
                          //   Icons.people_rounded,
                          //   'Staff Payroll',
                          //   'payroll',
                          // ),
                          _buildPopupMenuItem(
                            Icons.dashboard_customize_rounded,
                            'KPI Dashboard',
                            'kpi',
                          ),
                          _buildPopupMenuItem(
                            Icons.flag_rounded,
                            'Target Settings',
                            'target',
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'monthly_pl') {
                            showDialog(
                              context: context,
                              builder: (context) => const MonthlyPLModal(),
                            );
                          } else if (value == 'revenue_trends') {
                            showDialog(
                              context: context,
                              builder: (context) => const RevenueTrendsModal(),
                            );
                          } 
                          // Temporarily hidden features
                          // else if (value == 'inventory') {
                          //   showDialog(
                          //     context: context,
                          //     builder: (context) => const InventoryModal(),
                          //   );
                          // } else if (value == 'payroll') {
                          //   showDialog(
                          //     context: context,
                          //     builder: (context) => const PayrollModal(),
                          //   );
                          // } 
                          else if (value == 'kpi') {
                            showDialog(
                              context: context,
                              builder: (context) => const KPIDashboardModal(),
                            );
                          } else if (value == 'target') {
                            showDialog(
                              context: context,
                              builder: (context) => const TargetSettingsModal(),
                            );
                          } else {
                            // TODO: Implement other advanced reports
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$value feature coming soon'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sync Status Indicator
              Consumer<TransactionProvider>(
                builder: (context, provider, child) {
                  if (provider.pendingSyncCount == 0 && !provider.isSyncing) {
                    return const SizedBox.shrink();
                  }
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: provider.isSyncing
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: provider.isSyncing
                            ? Colors.blue.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (provider.isSyncing)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                            ),
                          )
                        else
                          Icon(
                            Icons.cloud_upload_rounded,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            provider.isSyncing
                                ? 'Syncing ${provider.pendingSyncCount} transaction${provider.pendingSyncCount > 1 ? 's' : ''}...'
                                : '${provider.pendingSyncCount} transaction${provider.pendingSyncCount > 1 ? 's' : ''} pending sync',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: provider.isSyncing ? Colors.blue.shade700 : Colors.orange.shade700,
                            ),
                          ),
                        ),
                        if (!provider.isSyncing)
                          TextButton(
                            onPressed: () => provider.syncPendingTransactions(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Sync Now',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              // Date Range Selector
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
                            onTap: _setToday,
                            isSelected: _isToday(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickFilterButton(
                            label: 'This Week',
                            onTap: _setThisWeek,
                            isSelected: _isThisWeek(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickFilterButton(
                            label: 'This Month',
                            onTap: _setThisMonth,
                            isSelected: _isThisMonth(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Main Balance Card
              BalanceCard(
                label: _getFilterLabel(),
                amount: provider.getCustomRangeBalance(_startDate!, _endDate!),
                income: provider.getCustomRangeRevenue(_startDate!, _endDate!),
                expense: provider.getCustomRangeTransactions(_startDate!, _endDate!),
              ),
              const SizedBox(height: 24),

              // Tax Summary (Collapsible)
              _TaxSummaryCard(
                totalIncome: provider.getCustomRangeRevenue(_startDate!, _endDate!),
                expenses: provider.getCustomRangeTransactions(_startDate!, _endDate!),
              ),
              const SizedBox(height: 24),

              // Sales Monitoring
              SalesMonitoringCard(
                transactions: provider.getCustomRangeTransactionsList(_startDate!, _endDate!),
              ),
              const SizedBox(height: 24),

              // Revenue Breakdown
              RevenueBreakdown(
                revenueByMethod: provider.getCustomRangeRevenueByMethod(_startDate!, _endDate!),
                totalRevenue: provider.getCustomRangeRevenue(_startDate!, _endDate!),
              ),
              const SizedBox(height: 24),

              // Transaction Breakdown
              ExpenseBreakdownCard(
                expensesByCategory: provider.getCustomRangeTransactionsByCategory(_startDate!, _endDate!),
                totalExpenses: provider.getCustomRangeTransactions(_startDate!, _endDate!),
              ),
              const SizedBox(height: 24),

              // Recent Transactions
              RecentTransactions(
                transactions: provider.transactions.take(5).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  PopupMenuEntry<String> _buildPopupMenuItem(
    IconData icon,
    String title,
    String value,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
    );
  }
}

/// Tax Summary Card (Collapsible) - Matches tax-summary.tsx
class _TaxSummaryCard extends StatefulWidget {
  final double totalIncome;
  final double expenses;

  const _TaxSummaryCard({
    required this.totalIncome,
    required this.expenses,
  });

  @override
  State<_TaxSummaryCard> createState() => _TaxSummaryCardState();
}

class _TaxSummaryCardState extends State<_TaxSummaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Tax calculations matching Next.js
    const vatRate = 0.12;
    final grossSales = widget.totalIncome;
    final vatTax = grossSales * vatRate;
    final totalTaxes = vatTax;
    final netSales = grossSales - totalTaxes;

    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Tax Summary',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 0, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildTaxRow(
                    'Gross Sales',
                    grossSales,
                    theme,
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildTaxRow(
                    'VAT (12%)',
                    vatTax,
                    theme,
                    isNegative: true,
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildTaxRow(
                      'Total Taxes',
                      totalTaxes,
                      theme,
                      isBold: true,
                      isNegative: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildTaxRow(
                    'Net Sales',
                    netSales,
                    theme,
                    isBold: true,
                    isPrimary: true,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaxRow(
    String label,
    double amount,
    ThemeData theme, {
    bool isBold = false,
    bool isNegative = false,
    bool isPrimary = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: isBold && isPrimary ? theme.colorScheme.primary : null,
          ),
        ),
        Text(
          '${isNegative ? "-" : ""}₱${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isPrimary
                ? theme.colorScheme.primary
                : isNegative
                    ? theme.colorScheme.error
                    : null,
          ),
        ),
      ],
    );
  }
}

/// Quick Filter Button Widget
class _QuickFilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const _QuickFilterButton({
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 11,
              color: isSelected ? theme.colorScheme.primary : null,
            ),
          ),
        ),
      ),
    );
  }
}
