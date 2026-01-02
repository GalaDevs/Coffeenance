import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// Balance Card Widget - Matches balance-card.tsx
/// Displays current balance with income/expense breakdown
class BalanceCard extends StatelessWidget {
  final String label;
  final double amount;
  final double income;
  final double expense;

  const BalanceCard({
    super.key,
    required this.label,
    required this.amount,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate income as Revenue - Expenses
    final calculatedIncome = income - expense;
    final isPositive = calculatedIncome >= 0;
    
    // Format with commas: xxx,xxx.xx
    final numberFormat = NumberFormat('#,##0.00', 'en_US');

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightPrimary,
            Color(0xFF4A3329), // Slightly darker for gradient effect
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightPrimary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Amount (Income = Revenue - Expenses)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '₱${numberFormat.format(calculatedIncome.abs())}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.white : Colors.red,
                  letterSpacing: -0.5,
                ),
              ),
              if (!isPositive)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.trending_down_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Revenue/Expenses Row
          Row(
            children: [
              // Total Revenue or Sales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Revenue or Sales',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${numberFormat.format(income)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                width: 1,
                height: 48,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 16),

              // Total Expenses
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Expenses',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${numberFormat.format(expense)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
  }
}
