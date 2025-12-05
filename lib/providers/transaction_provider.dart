import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

/// TransactionProvider manages all transaction state
/// Replaces Next.js useState for transactions management
/// Persists to local storage (SharedPreferences)
class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  
  // Inventory management
  List<Map<String, dynamic>> _inventory = [];
  
  // Staff/Payroll management
  List<Map<String, dynamic>> _staff = [];
  
  // KPI Settings and Targets
  Map<String, dynamic> _kpiSettings = {};
  
  // Tax Settings
  Map<String, dynamic> _taxSettings = {};

  // Getters
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get inventory => List.unmodifiable(_inventory);
  List<Map<String, dynamic>> get staff => List.unmodifiable(_staff);
  Map<String, dynamic> get kpiSettings => Map.unmodifiable(_kpiSettings);
  Map<String, dynamic> get taxSettings => Map.unmodifiable(_taxSettings);

  // Computed properties matching Next.js logic
  List<Transaction> get revenueTransactions =>
      _transactions.where((t) => t.type == TransactionType.revenue).toList();

  List<Transaction> get transactionList =>
      _transactions.where((t) => t.type == TransactionType.transaction).toList();

  List<Transaction> get transactionRecords => transactionList; // Alias

  double get totalRevenue =>
      revenueTransactions.fold(0.0, (sum, t) => sum + t.amount);

  double get totalTransaction =>
      transactionList.fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalRevenue - totalTransaction;

  // Backward compatibility aliases
  double get totalIncome => totalRevenue;
  double get totalExpense => totalTransaction;
  double get totalTransactions => totalTransaction; // Plural alias
  Map<String, double> get salesByMethod => revenueByMethod;
  Map<String, double> get expensesByCategory => transactionsByCategory;

  /// Get revenue breakdown by payment method (matching Next.js revenueByMethod)
  Map<String, double> get revenueByMethod {
    return {
      RevenueCategories.cash: revenueTransactions
          .where((t) => t.category == RevenueCategories.cash)
          .fold(0.0, (sum, t) => sum + t.amount),
      RevenueCategories.gcash: revenueTransactions
          .where((t) => t.category == RevenueCategories.gcash)
          .fold(0.0, (sum, t) => sum + t.amount),
      RevenueCategories.grab: revenueTransactions
          .where((t) => t.category == RevenueCategories.grab)
          .fold(0.0, (sum, t) => sum + t.amount),
      RevenueCategories.paymaya: revenueTransactions
          .where((t) => t.category == RevenueCategories.paymaya)
          .fold(0.0, (sum, t) => sum + t.amount),
      RevenueCategories.others: revenueTransactions
          .where((t) => t.category == RevenueCategories.others)
          .fold(0.0, (sum, t) => sum + t.amount),
    };
  }

  /// Get transactions breakdown by category
  Map<String, double> get transactionsByCategory {
    return {
      TransactionCategories.supplies: transactionList
          .where((t) => t.category == TransactionCategories.supplies)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.pastries: transactionList
          .where((t) => t.category == TransactionCategories.pastries)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.rent: transactionList
          .where((t) => t.category == TransactionCategories.rent)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.utilities: transactionList
          .where((t) => t.category == TransactionCategories.utilities)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.manpower: transactionList
          .where((t) => t.category == TransactionCategories.manpower)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.marketing: transactionList
          .where((t) => t.category == TransactionCategories.marketing)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.others: transactionList
          .where((t) => t.category == TransactionCategories.others)
          .fold(0.0, (sum, t) => sum + t.amount),
    };
  }

  TransactionProvider() {
    _loadInitialData();
    _loadInventoryData();
    _loadStaffData();
    _loadKPISettings();
    _loadTaxSettings();
  }

  /// Load initial inventory data from local storage
  Future<void> _loadInventoryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? inventoryJson = prefs.getString('inventory_data');
      if (inventoryJson != null) {
        _inventory = List<Map<String, dynamic>>.from(json.decode(inventoryJson));
      } else {
        _inventory = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading inventory from local storage: $e');
      _inventory = [];
    }
  }

  /// Load initial staff data from local storage
  Future<void> _loadStaffData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? staffJson = prefs.getString('staff_data');
      if (staffJson != null) {
        _staff = List<Map<String, dynamic>>.from(json.decode(staffJson));
      } else {
        _staff = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading staff from local storage: $e');
      _staff = [];
    }
  }

  /// Load initial data from local storage
  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? transactionsJson = prefs.getString('transactions');

      if (transactionsJson != null) {
        final List<dynamic> decoded = json.decode(transactionsJson);
        _transactions = decoded.map((t) => Transaction.fromJson(t)).toList();
      } else {
        _transactions = [];
      }
    } catch (e) {
      debugPrint('Error loading transactions from local storage: $e');
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save transactions to local storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = json.encode(_transactions.map((t) => t.toJson()).toList());
      await prefs.setString('transactions', encoded);
    } catch (e) {
      debugPrint('Error saving transactions to local storage: $e');
    }
  }

  /// Save inventory to local storage
  Future<void> _saveInventoryToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('inventory_data', json.encode(_inventory));
    } catch (e) {
      debugPrint('Error saving inventory to local storage: $e');
    }
  }

  /// Save staff to local storage
  Future<void> _saveStaffToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('staff_data', json.encode(_staff));
    } catch (e) {
      debugPrint('Error saving staff to local storage: $e');
    }
  }

  /// Add transaction - saves to local storage only
  Future<void> addTransaction(Transaction transaction) async {
    try {
      // Generate new ID
      final int newId = _transactions.isEmpty
          ? 1
          : _transactions.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;

      final newTransaction = transaction.copyWith(
        id: newId,
        date: DateTime.now().toIso8601String().split('T')[0],
      );

      _transactions.insert(0, newTransaction);
      await _saveToStorage();
      notifyListeners();
      debugPrint('✅ Transaction added to local storage');
    } catch (e) {
      debugPrint('❌ Failed to add transaction: $e');
      rethrow;
    }
  }

  /// Delete transaction - deletes from local storage only
  Future<void> deleteTransaction(int id) async {
    try {
      _transactions.removeWhere((t) => t.id == id);
      await _saveToStorage();
      notifyListeners();
      debugPrint('✅ Transaction deleted from local storage');
    } catch (e) {
      debugPrint('❌ Failed to delete transaction: $e');
      rethrow;
    }
  }

  /// Update transaction - updates in local storage only
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        await _saveToStorage();
        notifyListeners();
        debugPrint('✅ Transaction updated in local storage');
      }
    } catch (e) {
      debugPrint('❌ Failed to update transaction: $e');
      rethrow;
    }
  }

  /// Clear all transactions from local storage
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('transactions');
      await prefs.remove('inventory_data');
      await prefs.remove('staff_data');
      _transactions.clear();
      _inventory.clear();
      _staff.clear();
      notifyListeners();
      debugPrint('✅ All data cleared from local storage');
    } catch (e) {
      debugPrint('❌ Failed to clear data: $e');
      rethrow;
    }
  }

  /// Update inventory item in local storage
  Future<void> updateInventoryItem(String itemId, Map<String, dynamic> updates) async {
    try {
      final index = _inventory.indexWhere((item) => item['id'] == itemId);
      if (index != -1) {
        _inventory[index] = {..._inventory[index], ...updates};
        await _saveInventoryToStorage();
        notifyListeners();
        debugPrint('✅ Inventory item updated in local storage');
      }
    } catch (e) {
      debugPrint('❌ Failed to update inventory item: $e');
      rethrow;
    }
  }

  /// Add inventory item to local storage
  Future<void> addInventoryItem(Map<String, dynamic> item) async {
    try {
      final itemId = DateTime.now().millisecondsSinceEpoch.toString();
      _inventory.add({...item, 'id': itemId});
      await _saveInventoryToStorage();
      notifyListeners();
      debugPrint('✅ Inventory item added to local storage');
    } catch (e) {
      debugPrint('❌ Failed to add inventory item: $e');
      rethrow;
    }
  }

  /// Update staff member in local storage
  Future<void> updateStaffMember(String staffId, Map<String, dynamic> updates) async {
    try {
      final index = _staff.indexWhere((member) => member['id'] == staffId);
      if (index != -1) {
        _staff[index] = {..._staff[index], ...updates};
        await _saveStaffToStorage();
        notifyListeners();
        debugPrint('✅ Staff member updated in local storage');
      }
    } catch (e) {
      debugPrint('❌ Failed to update staff member: $e');
      rethrow;
    }
  }

  /// Add staff member to local storage
  Future<void> addStaffMember(Map<String, dynamic> member) async {
    try {
      final staffId = DateTime.now().millisecondsSinceEpoch.toString();
      _staff.add({...member, 'id': staffId});
      await _saveStaffToStorage();
      notifyListeners();
      debugPrint('✅ Staff member added to local storage');
    } catch (e) {
      debugPrint('❌ Failed to add staff member: $e');
      rethrow;
    }
  }

  /// Filter transactions by date range
  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _transactions.where((t) {
      final transactionDate = DateTime.parse(t.date);
      return transactionDate.isAfter(start.subtract(const Duration(days: 1))) &&
          transactionDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get transactions for today
  List<Transaction> get todayTransactions {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    return _transactions.where((t) => t.date == todayStr).toList();
  }

  /// Load KPI settings from storage
  Future<void> _loadKPISettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? kpiJson = prefs.getString('kpi_settings');

      if (kpiJson != null) {
        _kpiSettings = json.decode(kpiJson);
      } else {
        // Default KPI targets
        _kpiSettings = {
          'dailyRevenueTarget': 50000.0,
          'dailyTransactionsTarget': 100,
          'avgTransactionTarget': 500.0,
          'dailyExpensesTarget': 20000.0,
          'customerSatisfaction': 91.0,
          'operationalEfficiency': 88.0,
          'staffRetention': 95.0,
          'inventoryTurnover': 82.0,
          'revenueGrowth': 78.0,
        };
        await _saveKPISettings();
      }
    } catch (e) {
      debugPrint('Error loading KPI settings: $e');
    }
  }

  /// Save KPI settings to storage
  Future<void> _saveKPISettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('kpi_settings', json.encode(_kpiSettings));
    } catch (e) {
      debugPrint('Error saving KPI settings: $e');
    }
  }

  /// Update KPI setting
  Future<void> updateKPISetting(String key, dynamic value) async {
    // Ensure value is stored as double
    if (value is int) {
      _kpiSettings[key] = value.toDouble();
    } else if (value is double) {
      _kpiSettings[key] = value;
    } else {
      _kpiSettings[key] = double.tryParse(value.toString()) ?? 0.0;
    }
    notifyListeners();
    await _saveKPISettings();
  }

  /// Update multiple KPI settings
  Future<void> updateKPISettings(Map<String, dynamic> updates) async {
    updates.forEach((key, value) {
      // Ensure all values are stored as double
      if (value is int) {
        _kpiSettings[key] = value.toDouble();
      } else if (value is double) {
        _kpiSettings[key] = value;
      } else {
        _kpiSettings[key] = double.tryParse(value.toString()) ?? 0.0;
      }
    });
    notifyListeners();
    await _saveKPISettings();
  }

  /// Get KPI target value
  double getKPITarget(String key) {
    final value = _kpiSettings[key] ?? 0.0;
    if (value is int) {
      return value.toDouble();
    }
    return value as double;
  }

  /// Load tax settings from storage
  Future<void> _loadTaxSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? taxJson = prefs.getString('tax_settings');

      if (taxJson != null) {
        _taxSettings = json.decode(taxJson);
      } else {
        // Default tax settings
        _taxSettings = {
          'vatRate': 12.0,
          'enableVAT': true,
          'taxInclusive': false,
          'businessTIN': '',
          'businessName': '',
          'businessAddress': '',
          'zeroRatedEnabled': true,
          'vatExemptEnabled': true,
        };
        await _saveTaxSettings();
      }
    } catch (e) {
      debugPrint('Error loading tax settings: \$e');
    }
  }

  /// Save tax settings to storage
  Future<void> _saveTaxSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tax_settings', json.encode(_taxSettings));
    } catch (e) {
      debugPrint('Error saving tax settings: \$e');
    }
  }

  /// Update tax setting
  Future<void> updateTaxSetting(String key, dynamic value) async {
    _taxSettings[key] = value;
    notifyListeners();
    await _saveTaxSettings();
  }

  /// Update multiple tax settings
  Future<void> updateTaxSettings(Map<String, dynamic> updates) async {
    _taxSettings.addAll(updates);
    notifyListeners();
    await _saveTaxSettings();
  }

  /// Get tax setting value
  dynamic getTaxSetting(String key) {
    return _taxSettings[key];
  }

  /// Calculate VAT amount
  double calculateVAT(double amount, {int? vatRate}) {
    if (_taxSettings['enableVAT'] != true) return 0.0;
    final rate = vatRate ?? (_taxSettings['vatRate'] ?? 12.0);
    if (_taxSettings['taxInclusive'] == true) {
      // Tax-inclusive: VAT = amount - (amount / (1 + rate/100))
      return amount - (amount / (1 + rate / 100));
    } else {
      // Tax-exclusive: VAT = amount * (rate/100)
      return amount * (rate / 100);
    }
  }

  /// Calculate total with VAT
  double calculateTotalWithVAT(double amount, {int? vatRate}) {
    if (_taxSettings['enableVAT'] != true) return amount;
    if (_taxSettings['taxInclusive'] == true) {
      return amount; // Already includes VAT
    } else {
      final vat = calculateVAT(amount, vatRate: vatRate);
      return amount + vat;
    }
  }
}
