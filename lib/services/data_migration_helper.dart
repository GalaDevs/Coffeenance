import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';

/// Migration utility to sync local data to Supabase
/// Useful for first-time setup or manual data migration
class DataMigrationHelper {
  /// Sync all local data to Supabase
  /// This will reload data from Supabase, overwriting local data
  static Future<void> syncToSupabase(BuildContext context) async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    
    try {
      debugPrint('🔄 Starting data sync to Supabase...');
      
      // Reload all data from Supabase
      // This will automatically fall back to local storage if Supabase is unavailable
      await provider.refreshAllData();
      
      debugPrint('✅ Data sync complete!');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Your data has been synced successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Data sync failed: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Sync failed. Please check your internet connection and try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Clear all local data and reload from Supabase
  static Future<void> resetToSupabase(BuildContext context) async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Supabase?'),
        content: const Text(
          'This will clear all local data and reload from Supabase. '
          'Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      debugPrint('🔄 Resetting to Supabase data...');
      
      // Clear local data
      await provider.clearAll();
      
      // Reload from Supabase
      await provider.refreshAllData();
      
      debugPrint('✅ Reset complete!');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Your data has been reset successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Reset failed: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Reset failed. Please check your internet connection and try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
