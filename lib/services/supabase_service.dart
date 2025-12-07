import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';

/// Supabase Service - Handles all database operations
/// Manages CRUD operations for transactions, inventory, staff, KPI and tax settings
/// Now includes REALTIME subscriptions for live updates
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ============================================
  // REALTIME SUBSCRIPTIONS
  // ============================================
  
  /// Subscribe to realtime changes in transactions table
  RealtimeChannel subscribeToTransactions({
    required void Function(Map<String, dynamic> payload) onInsert,
    required void Function(Map<String, dynamic> payload) onUpdate,
    required void Function(Map<String, dynamic> payload) onDelete,
  }) {
    final channel = _client
        .channel('transactions_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'transactions',
          callback: (payload) {
            print('🔔 Realtime INSERT: ${payload.newRecord}');
            onInsert(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'transactions',
          callback: (payload) {
            print('🔔 Realtime UPDATE: ${payload.newRecord}');
            onUpdate(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'transactions',
          callback: (payload) {
            print('🔔 Realtime DELETE: ${payload.oldRecord}');
            onDelete(payload.oldRecord);
          },
        )
        .subscribe();
    
    return channel;
  }

  /// Subscribe to realtime changes in inventory table
  RealtimeChannel subscribeToInventory({
    required void Function(Map<String, dynamic> payload) onInsert,
    required void Function(Map<String, dynamic> payload) onUpdate,
    required void Function(Map<String, dynamic> payload) onDelete,
  }) {
    final channel = _client
        .channel('inventory_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'inventory',
          callback: (payload) => onInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'inventory',
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'inventory',
          callback: (payload) => onDelete(payload.oldRecord),
        )
        .subscribe();
    
    return channel;
  }

  /// Subscribe to realtime changes in staff table
  RealtimeChannel subscribeToStaff({
    required void Function(Map<String, dynamic> payload) onInsert,
    required void Function(Map<String, dynamic> payload) onUpdate,
    required void Function(Map<String, dynamic> payload) onDelete,
  }) {
    final channel = _client
        .channel('staff_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'staff',
          callback: (payload) => onInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'staff',
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'staff',
          callback: (payload) => onDelete(payload.oldRecord),
        )
        .subscribe();
    
    return channel;
  }

  // ============================================
  // TRANSACTIONS
  // ============================================
  
  /// Fetch all transactions from Supabase
  Future<List<Transaction>> fetchTransactions() async {
    try {
      final response = await _client
          .from('transactions')
          .select()
          .order('date', ascending: false);
      
      return (response as List)
          .map((json) => Transaction.fromJson({
                'id': json['id'],
                'date': json['date'],
                'type': json['type'],
                'category': json['category'],
                'description': json['description'],
                'amount': (json['amount'] as num).toDouble(),
                'paymentMethod': json['payment_method'] ?? '',
                'transactionNumber': json['transaction_number'] ?? '',
                'receiptNumber': json['receipt_number'] ?? '',
                'tinNumber': json['tin_number'] ?? '',
                'vat': json['vat'] ?? 0,
                'supplierName': json['supplier_name'] ?? '',
                'supplierAddress': json['supplier_address'] ?? '',
              }))
          .toList();
    } catch (e) {
      print('❌ Error fetching transactions: $e');
      rethrow;
    }
  }

  /// Add a transaction to Supabase
  Future<Transaction> addTransaction(Transaction transaction) async {
    try {
      // Get current user's ID for owner-based isolation
      final currentUserId = _client.auth.currentUser?.id;
      
      if (currentUserId == null) {
        throw Exception('User must be authenticated to add transactions');
      }
      
      final response = await _client.from('transactions').insert({
        'date': transaction.date,
        'type': transaction.type.toString().split('.').last,
        'category': transaction.category,
        'description': transaction.description,
        'amount': transaction.amount,
        'payment_method': transaction.paymentMethod,
        'transaction_number': transaction.transactionNumber,
        'receipt_number': transaction.receiptNumber,
        'tin_number': transaction.tinNumber,
        'vat': transaction.vat,
        'supplier_name': transaction.supplierName,
        'supplier_address': transaction.supplierAddress,
        'owner_id': currentUserId, // STRICT ISOLATION: Current user owns this record
      }).select().single();

      print('✅ Transaction added to Supabase: ${response['id']}');
      
      return Transaction.fromJson({
        'id': response['id'],
        'date': response['date'],
        'type': response['type'],
        'category': response['category'],
        'description': response['description'],
        'amount': (response['amount'] as num).toDouble(),
        'paymentMethod': response['payment_method'] ?? '',
        'transactionNumber': response['transaction_number'] ?? '',
        'receiptNumber': response['receipt_number'] ?? '',
        'tinNumber': response['tin_number'] ?? '',
        'vat': response['vat'] ?? 0,
        'supplierName': response['supplier_name'] ?? '',
        'supplierAddress': response['supplier_address'] ?? '',
      });
    } catch (e) {
      print('❌ Error adding transaction: $e');
      rethrow;
    }
  }

  /// Update a transaction in Supabase
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _client.from('transactions').update({
        'date': transaction.date,
        'type': transaction.type.toString().split('.').last,
        'category': transaction.category,
        'description': transaction.description,
        'amount': transaction.amount,
        'payment_method': transaction.paymentMethod,
        'transaction_number': transaction.transactionNumber,
        'receipt_number': transaction.receiptNumber,
        'tin_number': transaction.tinNumber,
        'vat': transaction.vat,
        'supplier_name': transaction.supplierName,
        'supplier_address': transaction.supplierAddress,
      }).eq('id', transaction.id);

      print('✅ Transaction updated in Supabase: ${transaction.id}');
    } catch (e) {
      print('❌ Error updating transaction: $e');
      rethrow;
    }
  }

  /// Delete a transaction from Supabase
  Future<void> deleteTransaction(int id) async {
    try {
      await _client.from('transactions').delete().eq('id', id);
      print('✅ Transaction deleted from Supabase: $id');
    } catch (e) {
      print('❌ Error deleting transaction: $e');
      rethrow;
    }
  }

  // ============================================
  // INVENTORY
  // ============================================
  
  /// Fetch all inventory items from Supabase
  Future<List<Map<String, dynamic>>> fetchInventory() async {
    try {
      final response = await _client
          .from('inventory')
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching inventory: $e');
      rethrow;
    }
  }

  /// Add an inventory item to Supabase
  Future<Map<String, dynamic>> addInventoryItem(Map<String, dynamic> item) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      
      if (currentUserId == null) {
        throw Exception('User must be authenticated to add inventory');
      }
      
      // Ensure owner_id is set
      final itemWithOwner = {...item, 'owner_id': currentUserId};
      
      final response = await _client
          .from('inventory')
          .insert(itemWithOwner)
          .select()
          .single();
      
      print('✅ Inventory item added to Supabase: ${response['id']}');
      return response;
    } catch (e) {
      print('❌ Error adding inventory item: $e');
      rethrow;
    }
  }

  /// Update an inventory item in Supabase
  Future<void> updateInventoryItem(int id, Map<String, dynamic> item) async {
    try {
      await _client.from('inventory').update(item).eq('id', id);
      print('✅ Inventory item updated in Supabase: $id');
    } catch (e) {
      print('❌ Error updating inventory item: $e');
      rethrow;
    }
  }

  /// Delete an inventory item from Supabase
  Future<void> deleteInventoryItem(int id) async {
    try {
      await _client.from('inventory').delete().eq('id', id);
      print('✅ Inventory item deleted from Supabase: $id');
    } catch (e) {
      print('❌ Error deleting inventory item: $e');
      rethrow;
    }
  }

  // ============================================
  // STAFF
  // ============================================
  
  /// Fetch all staff members from Supabase
  Future<List<Map<String, dynamic>>> fetchStaff() async {
    try {
      final response = await _client
          .from('staff')
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching staff: $e');
      rethrow;
    }
  }

  /// Add a staff member to Supabase
  Future<Map<String, dynamic>> addStaffMember(Map<String, dynamic> staff) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      
      if (currentUserId == null) {
        throw Exception('User must be authenticated to add staff');
      }
      
      // Ensure owner_id is set
      final staffWithOwner = {...staff, 'owner_id': currentUserId};
      
      final response = await _client
          .from('staff')
          .insert(staffWithOwner)
          .select()
          .single();
      
      print('✅ Staff member added to Supabase: ${response['id']}');
      return response;
    } catch (e) {
      print('❌ Error adding staff member: $e');
      rethrow;
    }
  }

  /// Update a staff member in Supabase
  Future<void> updateStaffMember(int id, Map<String, dynamic> staff) async {
    try {
      await _client.from('staff').update(staff).eq('id', id);
      print('✅ Staff member updated in Supabase: $id');
    } catch (e) {
      print('❌ Error updating staff member: $e');
      rethrow;
    }
  }

  /// Delete a staff member from Supabase
  Future<void> deleteStaffMember(int id) async {
    try {
      await _client.from('staff').delete().eq('id', id);
      print('✅ Staff member deleted from Supabase: $id');
    } catch (e) {
      print('❌ Error deleting staff member: $e');
      rethrow;
    }
  }

  // ============================================
  // KPI SETTINGS
  // ============================================
  
  /// Fetch KPI settings from Supabase
  Future<Map<String, dynamic>> fetchKPISettings() async {
    try {
      final response = await _client.from('kpi_settings').select();
      
      Map<String, dynamic> settings = {};
      for (var row in response) {
        settings[row['setting_key']] = row['setting_value'];
      }
      return settings;
    } catch (e) {
      print('❌ Error fetching KPI settings: $e');
      return {};
    }
  }

  /// Save KPI settings to Supabase
  Future<void> saveKPISettings(Map<String, dynamic> settings) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      
      if (currentUserId == null) {
        throw Exception('User must be authenticated to save settings');
      }
      
      for (var entry in settings.entries) {
        await _client.from('kpi_settings').upsert({
          'setting_key': entry.key,
          'setting_value': entry.value,
          'owner_id': currentUserId, // Ensure owner_id is always set
        }, onConflict: 'setting_key');
      }
      print('✅ KPI settings saved to Supabase');
    } catch (e) {
      print('❌ Error saving KPI settings: $e');
      rethrow;
    }
  }

  // ============================================
  // TAX SETTINGS
  // ============================================
  
  /// Fetch tax settings from Supabase
  Future<Map<String, dynamic>> fetchTaxSettings() async {
    try {
      final response = await _client.from('tax_settings').select();
      
      Map<String, dynamic> settings = {};
      for (var row in response) {
        settings[row['setting_key']] = row['setting_value'];
      }
      return settings;
    } catch (e) {
      print('❌ Error fetching tax settings: $e');
      return {};
    }
  }

  /// Save tax settings to Supabase
  Future<void> saveTaxSettings(Map<String, dynamic> settings) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      
      if (currentUserId == null) {
        throw Exception('User must be authenticated to save settings');
      }
      
      for (var entry in settings.entries) {
        await _client.from('tax_settings').upsert({
          'setting_key': entry.key,
          'setting_value': entry.value,
          'owner_id': currentUserId, // Ensure owner_id is always set
        }, onConflict: 'setting_key');
      }
      print('✅ Tax settings saved to Supabase');
    } catch (e) {
      print('❌ Error saving tax settings: $e');
      rethrow;
    }
  }
}
