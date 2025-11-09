import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/transaction_provider.dart';

/// Settings Page Screen - Matches settings-page.tsx
/// Shows app settings and preferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    setState(() {
      _isDarkMode = value;
    });
    // Note: In a complete implementation, this would update the app theme
    // using a ThemeProvider or similar state management
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            style: theme.textTheme.displayMedium,
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
                  value: _isDarkMode,
                  onChanged: _toggleTheme,
                  secondary: Icon(
                    _isDarkMode ? Icons.dark_mode : Icons.light_mode,
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
                    Icons.info,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.code,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Technology'),
                  subtitle: const Text('Built with Flutter'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.article,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Converted from Next.js'),
                  subtitle: const Text('Pixel-faithful mobile version'),
                ),
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
          'This feature will export your transaction data to a JSON file.',
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
            child: const Text('Export'),
          ),
        ],
      ),
    );
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
