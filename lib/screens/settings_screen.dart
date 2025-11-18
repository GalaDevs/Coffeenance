import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';

/// Settings Page Screen - Matches settings-page.tsx
/// Shows app settings and preferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Settings',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your preferences',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionTitle('Appearance', theme),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark color theme'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => themeProvider.toggleTheme(value),
                  secondary: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Data Management Section
          _buildSectionTitle('Data Management', theme),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.file_download,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Export Data'),
                  subtitle: const Text('Download your transaction history'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showExportDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.file_upload,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Import Data'),
                  subtitle: const Text('Restore from backup'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showImportDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                  ),
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Remove all transactions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showClearDataDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Business Information Section
          _buildSectionTitle('Business Information', theme),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.store,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Shop Name'),
                  subtitle: const Text('CoffeeFlow Coffee Shop'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showComingSoon(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Location'),
                  subtitle: const Text('Not set'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showComingSoon(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.receipt_long,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Tax Settings'),
                  subtitle: const Text('Configure tax rates'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          _buildSectionTitle('About', theme),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.info_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.code_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Technology'),
                  subtitle: const Text('Built with Flutter'),
                ),
                const Divider(height: 1),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.headlineMedium,
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feature coming soon'),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'This will export all your transaction data to a CSV file that you can open in Excel or any spreadsheet application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _exportData(context);
            },
            child: const Text('Export to CSV'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      // Show loading indicator
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing CSV export...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Get transaction data
      final transactionProvider = context.read<TransactionProvider>();
      final transactions = transactionProvider.transactions;

      // Create CSV content
      final csvBuffer = StringBuffer();
      
      // Add summary header
      csvBuffer.writeln('Coffeenance Transaction Export');
      csvBuffer.writeln('Export Date,${DateTime.now().toString().split('.')[0]}');
      csvBuffer.writeln('Total Transactions,${transactions.length}');
      csvBuffer.writeln('Total Revenue,${transactionProvider.totalRevenue.toStringAsFixed(2)}');
      csvBuffer.writeln('Total Expenses,${transactionProvider.totalTransactions.toStringAsFixed(2)}');
      csvBuffer.writeln('Balance,${transactionProvider.balance.toStringAsFixed(2)}');
      csvBuffer.writeln('');
      
      // Add CSV headers
      csvBuffer.writeln('ID,Date,Type,Category,Description,Amount,Payment Method,Transaction Number,Receipt Number,TIN Number,VAT,Supplier Name,Supplier Address');
      
      // Add transaction data
      for (var t in transactions) {
        final type = t.type.toString().split('.').last;
        csvBuffer.writeln(
          '${t.id},'
          '"${t.date}",'
          '"$type",'
          '"${t.category}",'
          '"${_escapeCsv(t.description)}",'
          '${t.amount.toStringAsFixed(2)},'
          '"${t.paymentMethod}",'
          '"${t.transactionNumber}",'
          '"${t.receiptNumber}",'
          '"${t.tinNumber}",'
          '${t.vat},'
          '"${_escapeCsv(t.supplierName)}",'
          '"${_escapeCsv(t.supplierAddress)}"'
        );
      }

      // Use app's document directory which is accessible
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'coffeenance_export_$timestamp.csv';
      
      // Save to system temp directory first
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/$fileName');
      
      // Write CSV to file
      await file.writeAsString(csvBuffer.toString());

      if (!context.mounted) return;
      
      // Show success with instructions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'CSV exported successfully!\n'
            'File: $fileName\n'
            'Location: Temp directory\n'
            'Open Finder and press Cmd+Shift+G, paste:\n'
            '${tempDir.path}'
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Copy Path',
            textColor: Colors.white,
            onPressed: () {
              // Copy path to clipboard would require clipboard package
            },
          ),
        ),
      );
      
      // Also show a dialog with more details
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Successful! 📊'),
            content: SelectableText(
              'Your data has been exported to:\n\n'
              '$fileName\n\n'
              'Location:\n${tempDir.path}\n\n'
              'To access:\n'
              '1. Open Finder\n'
              '2. Press Cmd+Shift+G\n'
              '3. Paste the path above\n'
              '4. Copy the file to your desired location\n\n'
              'You can open this file in Excel, Numbers, or any spreadsheet application.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  String _escapeCsv(String value) {
    // Escape quotes and commas for CSV format
    if (value.contains('"')) {
      return value.replaceAll('"', '""');
    }
    return value;
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'This feature will restore your transaction data from a backup file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon(context);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all transactions? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<TransactionProvider>().clearAll();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared successfully'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
