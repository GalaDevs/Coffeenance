import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/revenue_breakdown.dart';
import '../widgets/recent_transactions.dart';
import '../widgets/modals/monthly_pl_modal.dart';
import '../widgets/modals/revenue_trends_modal.dart';
import '../widgets/modals/inventory_modal.dart';
import '../widgets/modals/payroll_modal.dart';
import '../widgets/modals/kpi_dashboard_modal.dart';
import '../widgets/sales_monitoring_card.dart';
import '../widgets/expense_breakdown_card.dart';

/// Dashboard Screen - Matches dashboard.tsx
/// Shows balance, sales breakdown, and recent transactions
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                        "Today's Performance",
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
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
                      ),
                      const SizedBox(width: 8),
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
                          _buildPopupMenuItem(
                            Icons.inventory_2_rounded,
                            'Inventory Status',
                            'inventory',
                          ),
                          _buildPopupMenuItem(
                            Icons.people_rounded,
                            'Staff Payroll',
                            'payroll',
                          ),
                          _buildPopupMenuItem(
                            Icons.dashboard_customize_rounded,
                            'KPI Dashboard',
                            'kpi',
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
                          } else if (value == 'inventory') {
                            showDialog(
                              context: context,
                              builder: (context) => const InventoryModal(),
                            );
                          } else if (value == 'payroll') {
                            showDialog(
                              context: context,
                              builder: (context) => const PayrollModal(),
                            );
                          } else if (value == 'kpi') {
                            showDialog(
                              context: context,
                              builder: (context) => const KPIDashboardModal(),
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
              const SizedBox(height: 24),

              // Main Balance Card
              BalanceCard(
                label: "Today's Balance",
                amount: provider.balance,
                income: provider.totalRevenue,
                expense: provider.totalTransactions,
              ),
              const SizedBox(height: 24),

              // Tax Summary (Collapsible)
              _TaxSummaryCard(
                totalIncome: provider.totalRevenue,
                expenses: provider.totalTransactions,
              ),
              const SizedBox(height: 24),

              // Sales Monitoring
              SalesMonitoringCard(
                transactions: provider.transactions,
              ),
              const SizedBox(height: 24),

              // Revenue Breakdown
              RevenueBreakdown(
                revenueByMethod: provider.revenueByMethod,
                totalRevenue: provider.totalRevenue,
              ),
              const SizedBox(height: 24),

              // Transaction Breakdown
              ExpenseBreakdownCard(
                expensesByCategory: provider.transactionsByCategory,
                totalExpenses: provider.totalTransactions,
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
