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
    final isPositive = amount >= 0;
    final numberFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );

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

          // Amount
          Text(
            '${isPositive ? '+' : ''}${numberFormat.format(amount)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),

          // Income/Transaction Row
          Row(
            children: [
              // Income
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+${numberFormat.format(income)}',
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

              // Transactions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '-${numberFormat.format(expense)}',
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
