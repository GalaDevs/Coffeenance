import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
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

          // Firebase Cloud Sync (Coming Soon)
          // Uncomment when Firestore sync methods are implemented
          /*
          _buildSectionTitle('Cloud Sync', theme),
          Consumer<TransactionProvider>(
            builder: (context, provider, child) {
              return Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.cloud_upload_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('Sync to Cloud'),
                      subtitle: Text(
                        provider.isSyncing
                            ? 'Syncing...'
                            : 'Upload data to Firebase',
                      ),
                      trailing: provider.isSyncing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: provider.isSyncing
                          ? null
                          : () => _syncToCloud(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.cloud_download_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('Load from Cloud'),
                      subtitle: Text(
                        provider.isLoading
                            ? 'Loading...'
                            : 'Download data from Firebase',
                      ),
                      trailing: provider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: provider.isLoading
                          ? null
                          : () => _loadFromCloud(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.cloud_sync_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('Real-time Sync'),
                      subtitle: const Text('Enable automatic cloud sync'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _enableRealtimeSync(context),
                    ),
                  ],
                ),
              );
            },
          ),
          */
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
                  onTap: () => _showTaxSettings(context),
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
      )
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

  void _showTaxSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TaxSettingsDialog(),
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
      csvBuffer.writeln('Cafenance Transaction Export');
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

      // Create file name with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'cafenance_export_$timestamp.csv';
      
      // Get Downloads directory (for iOS, use documents directory)
      Directory? directory;
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        // macOS or other platforms
        directory = await getDownloadsDirectory();
      }
      
      if (directory == null) {
        throw Exception('Could not access downloads directory');
      }

      final file = File('${directory.path}/$fileName');
      
      // Write CSV to file
      await file.writeAsString(csvBuffer.toString());

      if (!context.mounted) return;
      
      // Automatically open the file
      final result = await OpenFilex.open(file.path);
      
      // Show success notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✅ Export Successful!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('File: $fileName'),
              Text('Saved to: ${directory.path}'),
              if (result.message.isNotEmpty)
                Text('Status: ${result.message}'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Open Again',
            textColor: Colors.white,
            onPressed: () {
              OpenFilex.open(file.path);
            },
          ),
        ),
      );
      
      // Close the export dialog if it's open
      Navigator.of(context).pop();
      
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

  // Cloud Sync Methods (Commented out until Firestore sync is implemented)
  /*
  void _syncToCloud(BuildContext context) async {
    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      await provider.syncToFirestore();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('✅ Data successfully synced to cloud!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('❌ Sync failed: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _loadFromCloud(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load from Cloud'),
        content: const Text(
          'This will download data from Firebase and replace your local data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final provider = Provider.of<TransactionProvider>(context, listen: false);
                await provider.loadFromFirestore();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('✅ Data loaded from cloud!'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('❌ Load failed: ${e.toString()}'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }

  void _enableRealtimeSync(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_sync_rounded, color: Colors.blue),
            SizedBox(width: 12),
            Text('Real-time Sync'),
          ],
        ),
        content: const Text(
          'Enable real-time cloud sync? Your data will automatically sync across all devices.\n\nNote: This will consume more data and battery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final provider = Provider.of<TransactionProvider>(context, listen: false);
              provider.enableRealtimeSync();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('✅ Real-time sync enabled!'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }
  */
}

/// Tax Settings Dialog
class TaxSettingsDialog extends StatefulWidget {
  const TaxSettingsDialog({super.key});

  @override
  State<TaxSettingsDialog> createState() => _TaxSettingsDialogState();
}

class _TaxSettingsDialogState extends State<TaxSettingsDialog> {
  late TextEditingController _vatRateController;
  late TextEditingController _tinController;
  late TextEditingController _businessNameController;
  late TextEditingController _businessAddressController;
  late bool _enableVAT;
  late bool _taxInclusive;
  late bool _zeroRatedEnabled;
  late bool _vatExemptEnabled;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TransactionProvider>();
    _vatRateController = TextEditingController(
      text: (provider.getTaxSetting('vatRate') ?? 12.0).toString(),
    );
    _tinController = TextEditingController(
      text: provider.getTaxSetting('businessTIN') ?? '',
    );
    _businessNameController = TextEditingController(
      text: provider.getTaxSetting('businessName') ?? '',
    );
    _businessAddressController = TextEditingController(
      text: provider.getTaxSetting('businessAddress') ?? '',
    );
    _enableVAT = provider.getTaxSetting('enableVAT') ?? true;
    _taxInclusive = provider.getTaxSetting('taxInclusive') ?? false;
    _zeroRatedEnabled = provider.getTaxSetting('zeroRatedEnabled') ?? true;
    _vatExemptEnabled = provider.getTaxSetting('vatExemptEnabled') ?? true;
  }

  @override
  void dispose() {
    _vatRateController.dispose();
    _tinController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  Future<void> _saveTaxSettings() async {
    final provider = context.read<TransactionProvider>();
    final vatRate = double.tryParse(_vatRateController.text) ?? 12.0;

    await provider.updateTaxSettings({
      'vatRate': vatRate,
      'enableVAT': _enableVAT,
      'taxInclusive': _taxInclusive,
      'businessTIN': _tinController.text,
      'businessName': _businessNameController.text,
      'businessAddress': _businessAddressController.text,
      'zeroRatedEnabled': _zeroRatedEnabled,
      'vatExemptEnabled': _vatExemptEnabled,
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tax settings saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tax Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // VAT Enable Toggle
                    SwitchListTile(
                      title: const Text('Enable VAT'),
                      subtitle: const Text('Apply VAT to transactions'),
                      value: _enableVAT,
                      onChanged: (value) => setState(() => _enableVAT = value),
                    ),
                    const SizedBox(height: 16),

                    // VAT Rate
                    TextField(
                      controller: _vatRateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'VAT Rate (%)',
                        helperText: 'Default: 12% for Philippines',
                        border: OutlineInputBorder(),
                      ),
                      enabled: _enableVAT,
                    ),
                    const SizedBox(height: 16),

                    // Tax Inclusive Toggle
                    SwitchListTile(
                      title: const Text('Tax-Inclusive Pricing'),
                      subtitle: const Text('Prices already include VAT'),
                      value: _taxInclusive,
                      onChanged: _enableVAT
                          ? (value) => setState(() => _taxInclusive = value)
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Zero-Rated Toggle
                    SwitchListTile(
                      title: const Text('Allow Zero-Rated Transactions'),
                      subtitle: const Text('0% VAT transactions'),
                      value: _zeroRatedEnabled,
                      onChanged: _enableVAT
                          ? (value) =>
                              setState(() => _zeroRatedEnabled = value)
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // VAT Exempt Toggle
                    SwitchListTile(
                      title: const Text('Allow VAT-Exempt Transactions'),
                      subtitle: const Text('Exempt from VAT'),
                      value: _vatExemptEnabled,
                      onChanged: _enableVAT
                          ? (value) =>
                              setState(() => _vatExemptEnabled = value)
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Business Information Section
                    Text(
                      'Business Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(
                        labelText: 'Business Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _tinController,
                      decoration: const InputDecoration(
                        labelText: 'TIN Number',
                        helperText: 'Tax Identification Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _businessAddressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Business Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveTaxSettings,
                    child: const Text('Save Settings'),
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
