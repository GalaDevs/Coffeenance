import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/sales_breakdown.dart';
import '../widgets/recent_transactions.dart';

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
                        'CoffeeFlow',
                        style: theme.textTheme.displayMedium,
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
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '☕',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          _buildPopupMenuItem(
                            '📊',
                            'Monthly P&L Summary',
                            'monthly_pl',
                          ),
                          _buildPopupMenuItem(
                            '📈',
                            'Revenue Trends',
                            'revenue_trends',
                          ),
                          _buildPopupMenuItem(
                            '💼',
                            'Inventory Status',
                            'inventory',
                          ),
                          _buildPopupMenuItem(
                            '👥',
                            'Staff Payroll',
                            'payroll',
                          ),
                          _buildPopupMenuItem(
                            '🎯',
                            'KPI Dashboard',
                            'kpi',
                          ),
                        ],
                        onSelected: (value) {
                          // TODO: Implement advanced reports
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$value feature coming soon'),
                            ),
                          );
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
                income: provider.totalIncome,
                expense: provider.totalExpense,
              ),
              const SizedBox(height: 24),

              // Tax Summary (Collapsible)
              _TaxSummaryCard(
                totalIncome: provider.totalIncome,
                expenses: provider.totalExpense,
              ),
              const SizedBox(height: 24),

              // Sales Monitoring
              _SalesMonitoringCard(
                transactions: provider.transactions,
              ),
              const SizedBox(height: 24),

              // Sales Breakdown
              SalesBreakdown(
                salesByMethod: provider.salesByMethod,
                totalSales: provider.totalIncome,
              ),
              const SizedBox(height: 24),

              // Expense Breakdown
              _ExpenseBreakdownCard(
                expensesByCategory: provider.expensesByCategory,
                totalExpenses: provider.totalExpense,
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
    String emoji,
    String title,
    String value,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
    );
  }
}

/// Tax Summary Card (Collapsible)
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
    final taxableIncome = widget.totalIncome - widget.expenses;
    final estimatedTax = taxableIncome * 0.08; // 8% tax rate

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
                        Icons.receipt_long,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Tax Summary',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildTaxRow(
                    'Gross Income',
                    widget.totalIncome,
                    theme,
                  ),
                  const SizedBox(height: 8),
                  _buildTaxRow(
                    'Deductible Expenses',
                    widget.expenses,
                    theme,
                  ),
                  const SizedBox(height: 8),
                  _buildTaxRow(
                    'Taxable Income',
                    taxableIncome,
                    theme,
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  _buildTaxRow(
                    'Estimated Tax (8%)',
                    estimatedTax,
                    theme,
                    isHighlight: true,
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
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold || isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}

/// Sales Monitoring Card
class _SalesMonitoringCard extends StatelessWidget {
  final List transactions;

  const _SalesMonitoringCard({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Simplified sales monitoring - can be expanded with charts
    final todayTransactions = transactions.where((t) {
      final today = DateTime.now().toIso8601String().split('T')[0];
      return t.date == today;
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Monitoring',
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  'Transactions',
                  todayTransactions.length.toString(),
                  Icons.receipt,
                  theme,
                ),
                _buildMetric(
                  'Avg Value',
                  todayTransactions.isEmpty
                      ? '₱0'
                      : '₱${(todayTransactions.fold(0.0, (sum, t) => sum + t.amount) / todayTransactions.length).toStringAsFixed(0)}',
                  Icons.trending_up,
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineMedium,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Expense Breakdown Card
class _ExpenseBreakdownCard extends StatelessWidget {
  final Map<String, double> expensesByCategory;
  final double totalExpenses;

  const _ExpenseBreakdownCard({
    required this.expensesByCategory,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Get top 3 expense categories
    final topExpenses = expensesByCategory.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Expenses',
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (topExpenses.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No expenses recorded'),
                ),
              )
            else
              ...topExpenses.take(3).map((entry) {
                final percentage = totalExpenses > 0
                    ? ((entry.value / totalExpenses) * 100).round()
                    : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                minHeight: 6,
                                backgroundColor: theme.colorScheme.secondary,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₱${entry.value.toStringAsFixed(0)}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
