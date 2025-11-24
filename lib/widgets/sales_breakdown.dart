import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Sales Breakdown Widget - Matches sales-breakdown.tsx exactly
class SalesBreakdown extends StatefulWidget {
  final Map<String, double> salesByMethod;
  final double totalSales;

  const SalesBreakdown({
    super.key,
    required this.salesByMethod,
    required this.totalSales,
  });

  @override
  State<SalesBreakdown> createState() => _SalesBreakdownState();
}

class _SalesBreakdownState extends State<SalesBreakdown> {
  bool showDetails = false;

  // Method configurations matching Next.js
  final List<Map<String, dynamic>> methods = [
    {'name': 'Cash', 'key': 'Cash', 'icon': Icons.paid_rounded, 'color': Color(0xFF8B5CF6)}, // chart-1
    {'name': 'GCash', 'key': 'GCash', 'icon': Icons.smartphone_rounded, 'color': Color(0xFF06B6D4)}, // chart-2
    {'name': 'Grab', 'key': 'Grab', 'icon': Icons.local_taxi_rounded, 'color': Color(0xFF10B981)}, // chart-3
    {'name': 'Maya', 'key': 'Maya', 'icon': Icons.credit_card_rounded, 'color': Color(0xFFF59E0B)}, // chart-4
    {'name': 'Credit Card', 'key': 'Credit Card', 'icon': Icons.credit_card_rounded, 'color': Color(0xFFEC4899)}, // chart-5
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with View/Hide button
            Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sales by Method',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18, // text-lg
                fontWeight: FontWeight.w600, // font-semibold
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  showDetails = !showDetails;
                });
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                showDetails ? 'Hide' : 'View',
                style: TextStyle(
                  fontSize: 14, // text-sm
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Quick Overview - Grid of 4 cards (2x2) - Shows/Hides based on button
        Visibility(
          visible: showDetails,
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: methods.map((method) {
            final amount = widget.salesByMethod[method['key']] ?? 0.0;
            final percentage = widget.totalSales > 0 
                ? (amount / widget.totalSales) * 100 
                : 0.0;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // rounded-xl
                side: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2), // border-border
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12), // p-4 reduced
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon and percentage
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          method['icon'] as IconData,
                          size: 20,
                          color: method['color'] as Color,
                        ),
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11, // text-xs reduced
                            fontWeight: FontWeight.w500, // font-medium
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6), // text-muted-foreground
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // mb-3 reduced
                    // Method name
                    Text(
                      method['name'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11, // text-xs reduced
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6), // text-muted-foreground
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3), // mb-1 reduced
                    // Amount
                    Text(
                      '₱${NumberFormat('#,###').format(amount)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 16, // text-lg reduced
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6), // mt-2 reduced
                    // Progress bar
                    Container(
                      height: 6, // h-1.5
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest, // bg-secondary
                        borderRadius: BorderRadius.circular(9999), // rounded-full
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: method['color'] as Color,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          ),
        ),

        // Add spacing only when grid is visible
        if (showDetails) const SizedBox(height: 16),

        // Total Card - Full Width
        SizedBox(
          width: double.infinity, // Full width
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest, // bg-secondary
              borderRadius: BorderRadius.circular(12), // rounded-xl
            ),
            padding: const EdgeInsets.all(16), // p-4
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Text(
                'Total Sales',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14, // text-sm
                  fontWeight: FontWeight.w500, // font-medium
                ),
              ),
              Text(
                '₱${NumberFormat('#,###').format(widget.totalSales)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 20, // text-xl
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary, // text-primary
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
