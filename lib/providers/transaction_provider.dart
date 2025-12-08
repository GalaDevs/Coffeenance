import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';
import '../services/supabase_service.dart';

/// TransactionProvider manages all transaction state
/// Now syncs with Supabase for cloud storage with REALTIME updates
/// Falls back to local storage (SharedPreferences) when offline
class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  final SupabaseService _supabaseService = SupabaseService();
  
  // Realtime subscriptions
  RealtimeChannel? _transactionsSubscription;
  RealtimeChannel? _inventorySubscription;
  RealtimeChannel? _staffSubscription;
  
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

  // ============================================
  // DAILY FILTERS (TODAY ONLY)
  // ============================================

  /// Filter transactions for today only
  List<Transaction> _getTodayTransactions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _transactions.where((t) {
      final transactionDate = DateTime.parse(t.date);
      return transactionDate.isAfter(today.subtract(const Duration(days: 1))) &&
          transactionDate.isBefore(tomorrow);
    }).toList();
  }

  // Public method to get today's transactions list
  List<Transaction> getTodayTransactionsList() => _getTodayTransactions();

  // Computed properties matching Next.js logic - NOW FILTERED TO TODAY
  List<Transaction> get revenueTransactions =>
      _getTodayTransactions().where((t) => t.type == TransactionType.revenue).toList();

  List<Transaction> get transactionList =>
      _getTodayTransactions().where((t) => t.type == TransactionType.transaction).toList();

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

  // ============================================
  // WEEKLY FILTERS
  // ============================================

  /// Filter transactions for the current week (Monday to Sunday)
  List<Transaction> _getWeekTransactions() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endDate = startDate.add(const Duration(days: 7));

    return _transactions.where((t) {
      final transactionDate = DateTime.parse(t.date);
      return transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          transactionDate.isBefore(endDate);
    }).toList();
  }

  List<Transaction> getWeeklyTransactionsList() => _getWeekTransactions();

  double getWeeklyRevenue() {
    final weekTransactions = _getWeekTransactions();
    return weekTransactions
        .where((t) => t.type == TransactionType.revenue)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getWeeklyTransactions() {
    final weekTransactions = _getWeekTransactions();
    return weekTransactions
        .where((t) => t.type == TransactionType.transaction)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getWeeklyBalance() => getWeeklyRevenue() - getWeeklyTransactions();

  Map<String, double> getWeeklyRevenueByMethod() {
    final weekTransactions = _getWeekTransactions();
    final weekRevenue = weekTransactions.where((t) => t.type == TransactionType.revenue).toList();

    return {
      RevenueCategories.cash: weekRevenue
          .where((t) => t.category == RevenueCategories.cash)
          .fold(0.0, (sum, t) => sum + t.amount),
      RevenueCategories.gcash: weekRevenue
          .where((t) => t.category == RevenueCategories.gcash)
          .fold(0.0, (sum, t) => sum + t.amount),
      RevenueCategories.grab: weekRevenue
          .where((t) => t.category == RevenueCategories.grab)
          .fold(0.0, (sum, t) => sum + t.amount),
      RevenueCategories.paymaya: weekRevenue
          .where((t) => t.category == RevenueCategories.paymaya)
          .fold(0.0, (sum, t) => sum + t.amount),
      RevenueCategories.others: weekRevenue
          .where((t) => t.category == RevenueCategories.others)
          .fold(0.0, (sum, t) => sum + t.amount),
    };
  }

  Map<String, double> getWeeklyTransactionsByCategory() {
    final weekTransactions = _getWeekTransactions();
    final weekExpenses = weekTransactions.where((t) => t.type == TransactionType.transaction).toList();

    return {
      TransactionCategories.supplies: weekExpenses
          .where((t) => t.category == TransactionCategories.supplies)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.pastries: weekExpenses
          .where((t) => t.category == TransactionCategories.pastries)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.rent: weekExpenses
          .where((t) => t.category == TransactionCategories.rent)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.utilities: weekExpenses
          .where((t) => t.category == TransactionCategories.utilities)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.manpower: weekExpenses
          .where((t) => t.category == TransactionCategories.manpower)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.marketing: weekExpenses
          .where((t) => t.category == TransactionCategories.marketing)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.others: weekExpenses
          .where((t) => t.category == TransactionCategories.others)
          .fold(0.0, (sum, t) => sum + t.amount),
    };
  }

  // ============================================
  // MONTHLY FILTERS
  // ============================================

  /// Filter transactions for the current month
  List<Transaction> _getMonthTransactions() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 1);

    return _transactions.where((t) {
      final transactionDate = DateTime.parse(t.date);
      return transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          transactionDate.isBefore(endDate);
    }).toList();
  }

  List<Transaction> getMonthlyTransactionsList() => _getMonthTransactions();

  double getMonthlyRevenue() {
    final monthTransactions = _getMonthTransactions();
    return monthTransactions
        .where((t) => t.type == TransactionType.revenue)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getMonthlyTransactions() {
    final monthTransactions = _getMonthTransactions();
    return monthTransactions
        .where((t) => t.type == TransactionType.transaction)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getMonthlyBalance() => getMonthlyRevenue() - getMonthlyTransactions();

  Map<String, double> getMonthlyRevenueByMethod() {
    final monthTransactions = _getMonthTransactions();
    final monthRevenue = monthTransactions.where((t) => t.type == TransactionType.revenue).toList();

    return {
      RevenueCategories.cash: monthRevenue
          .where((t) => t.category == RevenueCategories.cash)
          .fold(0.0, (sum, t) => sum + t.amount),
      RevenueCategories.gcash: monthRevenue
          .where((t) => t.category == RevenueCategories.gcash)
          .fold(0.0, (sum, t) => sum + t.amount),
      RevenueCategories.grab: monthRevenue
          .where((t) => t.category == RevenueCategories.grab)
          .fold(0.0, (sum, t) => sum + t.amount),
      RevenueCategories.paymaya: monthRevenue
          .where((t) => t.category == RevenueCategories.paymaya)
          .fold(0.0, (sum, t) => sum + t.amount),
      RevenueCategories.others: monthRevenue
          .where((t) => t.category == RevenueCategories.others)
          .fold(0.0, (sum, t) => sum + t.amount),
    };
  }

  Map<String, double> getMonthlyTransactionsByCategory() {
    final monthTransactions = _getMonthTransactions();
    final monthExpenses = monthTransactions.where((t) => t.type == TransactionType.transaction).toList();

    return {
      TransactionCategories.supplies: monthExpenses
          .where((t) => t.category == TransactionCategories.supplies)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.pastries: monthExpenses
          .where((t) => t.category == TransactionCategories.pastries)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.rent: monthExpenses
          .where((t) => t.category == TransactionCategories.rent)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.utilities: monthExpenses
          .where((t) => t.category == TransactionCategories.utilities)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.manpower: monthExpenses
          .where((t) => t.category == TransactionCategories.manpower)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.marketing: monthExpenses
          .where((t) => t.category == TransactionCategories.marketing)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.others: monthExpenses
          .where((t) => t.category == TransactionCategories.others)
          .fold(0.0, (sum, t) => sum + t.amount),
    };
  }

  // ============================================
  // CUSTOM DATE RANGE FILTERS
  // ============================================

  /// Filter transactions for a custom date range
  List<Transaction> _getCustomRangeTransactions(DateTime startDate, DateTime endDate) {
    return _transactions.where((t) {
      final transactionDate = DateTime.parse(t.date);
      return transactionDate.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
          transactionDate.isBefore(endDate.add(const Duration(milliseconds: 1)));
    }).toList();
  }

  List<Transaction> getCustomRangeTransactionsList(DateTime startDate, DateTime endDate) =>
      _getCustomRangeTransactions(startDate, endDate);

  double getCustomRangeRevenue(DateTime startDate, DateTime endDate) {
    final rangeTransactions = _getCustomRangeTransactions(startDate, endDate);
    return rangeTransactions
        .where((t) => t.type == TransactionType.revenue)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getCustomRangeTransactions(DateTime startDate, DateTime endDate) {
    final rangeTransactions = _getCustomRangeTransactions(startDate, endDate);
    return rangeTransactions
        .where((t) => t.type == TransactionType.transaction)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getCustomRangeBalance(DateTime startDate, DateTime endDate) =>
      getCustomRangeRevenue(startDate, endDate) - getCustomRangeTransactions(startDate, endDate);

  Map<String, double> getCustomRangeRevenueByMethod(DateTime startDate, DateTime endDate) {
    final rangeTransactions = _getCustomRangeTransactions(startDate, endDate);
    final rangeRevenue = rangeTransactions.where((t) => t.type == TransactionType.revenue).toList();

    return {
      RevenueCategories.cash: rangeRevenue
          .where((t) => t.category == RevenueCategories.cash)
          .fold(0.0, (sum, t) => sum + t.amount),
      RevenueCategories.gcash: rangeRevenue
          .where((t) => t.category == RevenueCategories.gcash)
          .fold(0.0, (sum, t) => sum + t.amount),
      RevenueCategories.grab: rangeRevenue
          .where((t) => t.category == RevenueCategories.grab)
          .fold(0.0, (sum, t) => sum + t.amount),
      RevenueCategories.paymaya: rangeRevenue
          .where((t) => t.category == RevenueCategories.paymaya)
          .fold(0.0, (sum, t) => sum + t.amount),
      RevenueCategories.others: rangeRevenue
          .where((t) => t.category == RevenueCategories.others)
          .fold(0.0, (sum, t) => sum + t.amount),
    };
  }

  Map<String, double> getCustomRangeTransactionsByCategory(DateTime startDate, DateTime endDate) {
    final rangeTransactions = _getCustomRangeTransactions(startDate, endDate);
    final rangeExpenses = rangeTransactions.where((t) => t.type == TransactionType.transaction).toList();

    return {
      TransactionCategories.supplies: rangeExpenses
          .where((t) => t.category == TransactionCategories.supplies)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.pastries: rangeExpenses
          .where((t) => t.category == TransactionCategories.pastries)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.rent: rangeExpenses
          .where((t) => t.category == TransactionCategories.rent)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.utilities: rangeExpenses
          .where((t) => t.category == TransactionCategories.utilities)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.manpower: rangeExpenses
          .where((t) => t.category == TransactionCategories.manpower)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.marketing: rangeExpenses
          .where((t) => t.category == TransactionCategories.marketing)
          .fold(0.0, (sum, t) => sum + t.amount),
      TransactionCategories.others: rangeExpenses
          .where((t) => t.category == TransactionCategories.others)
          .fold(0.0, (sum, t) => sum + t.amount),
    };
  }

  /// Get list of revenue transactions for custom date range
  List<Transaction> getCustomRangeRevenueList(DateTime startDate, DateTime endDate) {
    final rangeTransactions = _getCustomRangeTransactions(startDate, endDate);
    return rangeTransactions.where((t) => t.type == TransactionType.revenue).toList();
  }

  /// Get list of expense transactions for custom date range
  List<Transaction> getCustomRangeExpenseList(DateTime startDate, DateTime endDate) {
    final rangeTransactions = _getCustomRangeTransactions(startDate, endDate);
    return rangeTransactions.where((t) => t.type == TransactionType.transaction).toList();
  }

  /// Get transactions by category (returns lists of transactions per category) for custom date range
  Map<String, List<Transaction>> getCustomRangeExpensesByCategory(DateTime startDate, DateTime endDate) {
    final rangeTransactions = _getCustomRangeTransactions(startDate, endDate);
    final rangeExpenses = rangeTransactions.where((t) => t.type == TransactionType.transaction).toList();

    return {
      TransactionCategories.supplies: rangeExpenses
          .where((t) => t.category == TransactionCategories.supplies)
          .toList(),
      TransactionCategories.pastries: rangeExpenses
          .where((t) => t.category == TransactionCategories.pastries)
          .toList(),
      TransactionCategories.rent: rangeExpenses
          .where((t) => t.category == TransactionCategories.rent)
          .toList(),
      TransactionCategories.utilities: rangeExpenses
          .where((t) => t.category == TransactionCategories.utilities)
          .toList(),
      TransactionCategories.manpower: rangeExpenses
          .where((t) => t.category == TransactionCategories.manpower)
          .toList(),
      TransactionCategories.marketing: rangeExpenses
          .where((t) => t.category == TransactionCategories.marketing)
          .toList(),
      TransactionCategories.others: rangeExpenses
          .where((t) => t.category == TransactionCategories.others)
          .toList(),
    };
  }

  TransactionProvider() {
    _loadInitialData();
    _loadInventoryData();
    _loadStaffData();
    _loadKPISettings();
    _loadTaxSettings();
    _setupRealtimeSubscriptions();
    _setupAuthListener();
  }

  /// CRITICAL: Listen to auth state changes to clear cache on user switch
  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((authState) {
      if (authState.event == AuthChangeEvent.signedIn) {
        debugPrint('🔐 TransactionProvider: User signed in - force reloading data');
        // Force fresh data load on sign in
        forceReloadAllData();
      } else if (authState.event == AuthChangeEvent.signedOut) {
        debugPrint('🔐 TransactionProvider: User signed out - clearing data');
        // Clear all data on sign out
        clearAllLocalData();
      }
    });
  }

  /// Clear ALL local storage - CRITICAL for user switching
  Future<void> clearAllLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('transactions_data');
      await prefs.remove('inventory_data');
      await prefs.remove('staff_data');
      await prefs.remove('kpi_settings');
      await prefs.remove('tax_settings');
      
      _transactions = [];
      _inventory = [];
      _staff = [];
      _kpiSettings = {};
      _taxSettings = {};
      
      notifyListeners();
      debugPrint('🗑️ ALL local storage cleared - ready for new user');
    } catch (e) {
      debugPrint('Error clearing local storage: $e');
    }
  }

  /// Reload all data from Supabase (ignoring cache) - for user switching
  Future<void> forceReloadAllData() async {
    debugPrint('🔄 FORCE RELOAD: Fetching fresh data for current user');
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch fresh data from Supabase
      _transactions = await _supabaseService.fetchTransactions();
      _inventory = await _supabaseService.fetchInventory();
      _staff = await _supabaseService.fetchStaff();
      
      // Save to local storage
      await _saveToStorage();
      await _saveInventoryToStorage();
      await _saveStaffToStorage();
      
      debugPrint('✅ RELOAD COMPLETE:');
      debugPrint('   Transactions: ${_transactions.length}');
      debugPrint('   Inventory: ${_inventory.length}');
      debugPrint('   Staff: ${_staff.length}');
    } catch (e) {
      debugPrint('❌ Force reload failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Setup realtime subscriptions for live updates
  void _setupRealtimeSubscriptions() {
    try {
      // Subscribe to transactions changes
      _transactionsSubscription = _supabaseService.subscribeToTransactions(
        onInsert: (payload) {
          _handleRealtimeTransactionInsert(payload);
        },
        onUpdate: (payload) {
          _handleRealtimeTransactionUpdate(payload);
        },
        onDelete: (payload) {
          _handleRealtimeTransactionDelete(payload);
        },
      );

      // Subscribe to inventory changes
      _inventorySubscription = _supabaseService.subscribeToInventory(
        onInsert: (payload) {
          _handleRealtimeInventoryInsert(payload);
        },
        onUpdate: (payload) {
          _handleRealtimeInventoryUpdate(payload);
        },
        onDelete: (payload) {
          _handleRealtimeInventoryDelete(payload);
        },
      );

      // Subscribe to staff changes
      _staffSubscription = _supabaseService.subscribeToStaff(
        onInsert: (payload) {
          _handleRealtimeStaffInsert(payload);
        },
        onUpdate: (payload) {
          _handleRealtimeStaffUpdate(payload);
        },
        onDelete: (payload) {
          _handleRealtimeStaffDelete(payload);
        },
      );

      debugPrint('🔔 Realtime subscriptions active');
    } catch (e) {
      debugPrint('⚠️ Failed to setup realtime subscriptions: $e');
    }
  }

  /// Handle realtime transaction insert
  void _handleRealtimeTransactionInsert(Map<String, dynamic> payload) {
    try {
      final transaction = Transaction.fromJson({
        'id': payload['id'],
        'date': payload['date'],
        'type': payload['type'],
        'category': payload['category'],
        'description': payload['description'],
        'amount': (payload['amount'] as num).toDouble(),
        'paymentMethod': payload['payment_method'] ?? '',
        'transactionNumber': payload['transaction_number'] ?? '',
        'receiptNumber': payload['receipt_number'] ?? '',
        'tinNumber': payload['tin_number'] ?? '',
        'vat': payload['vat'] ?? 0,
        'supplierName': payload['supplier_name'] ?? '',
        'supplierAddress': payload['supplier_address'] ?? '',
      });

      // Check if already exists (prevent duplicates from our own inserts)
      if (!_transactions.any((t) => t.id == transaction.id)) {
        _transactions.insert(0, transaction);
        _saveToStorage();
        notifyListeners();
        debugPrint('🔔 Realtime: New transaction added');
      }
    } catch (e) {
      debugPrint('❌ Error handling realtime insert: $e');
    }
  }

  /// Handle realtime transaction update
  void _handleRealtimeTransactionUpdate(Map<String, dynamic> payload) {
    try {
      final transaction = Transaction.fromJson({
        'id': payload['id'],
        'date': payload['date'],
        'type': payload['type'],
        'category': payload['category'],
        'description': payload['description'],
        'amount': (payload['amount'] as num).toDouble(),
        'paymentMethod': payload['payment_method'] ?? '',
        'transactionNumber': payload['transaction_number'] ?? '',
        'receiptNumber': payload['receipt_number'] ?? '',
        'tinNumber': payload['tin_number'] ?? '',
        'vat': payload['vat'] ?? 0,
        'supplierName': payload['supplier_name'] ?? '',
        'supplierAddress': payload['supplier_address'] ?? '',
      });

      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        _saveToStorage();
        notifyListeners();
        debugPrint('🔔 Realtime: Transaction updated');
      }
    } catch (e) {
      debugPrint('❌ Error handling realtime update: $e');
    }
  }

  /// Handle realtime transaction delete
  void _handleRealtimeTransactionDelete(Map<String, dynamic> payload) {
    try {
      final id = payload['id'] as int;
      _transactions.removeWhere((t) => t.id == id);
      _saveToStorage();
      notifyListeners();
      debugPrint('🔔 Realtime: Transaction deleted');
    } catch (e) {
      debugPrint('❌ Error handling realtime delete: $e');
    }
  }

  /// Handle realtime inventory insert
  void _handleRealtimeInventoryInsert(Map<String, dynamic> payload) {
    if (!_inventory.any((item) => item['id'] == payload['id'])) {
      _inventory.insert(0, payload);
      _saveInventoryToStorage();
      notifyListeners();
      debugPrint('🔔 Realtime: New inventory item added');
    }
  }

  /// Handle realtime inventory update
  void _handleRealtimeInventoryUpdate(Map<String, dynamic> payload) {
    final index = _inventory.indexWhere((item) => item['id'] == payload['id']);
    if (index != -1) {
      _inventory[index] = payload;
      _saveInventoryToStorage();
      notifyListeners();
      debugPrint('🔔 Realtime: Inventory item updated');
    }
  }

  /// Handle realtime inventory delete
  void _handleRealtimeInventoryDelete(Map<String, dynamic> payload) {
    _inventory.removeWhere((item) => item['id'] == payload['id']);
    _saveInventoryToStorage();
    notifyListeners();
    debugPrint('🔔 Realtime: Inventory item deleted');
  }

  /// Handle realtime staff insert
  void _handleRealtimeStaffInsert(Map<String, dynamic> payload) {
    if (!_staff.any((member) => member['id'] == payload['id'])) {
      _staff.insert(0, payload);
      _saveStaffToStorage();
      notifyListeners();
      debugPrint('🔔 Realtime: New staff member added');
    }
  }

  /// Handle realtime staff update
  void _handleRealtimeStaffUpdate(Map<String, dynamic> payload) {
    final index = _staff.indexWhere((member) => member['id'] == payload['id']);
    if (index != -1) {
      _staff[index] = payload;
      _saveStaffToStorage();
      notifyListeners();
      debugPrint('🔔 Realtime: Staff member updated');
    }
  }

  /// Handle realtime staff delete
  void _handleRealtimeStaffDelete(Map<String, dynamic> payload) {
    _staff.removeWhere((member) => member['id'] == payload['id']);
    _saveStaffToStorage();
    notifyListeners();
    debugPrint('🔔 Realtime: Staff member deleted');
  }

  @override
  void dispose() {
    // Clean up realtime subscriptions
    _transactionsSubscription?.unsubscribe();
    _inventorySubscription?.unsubscribe();
    _staffSubscription?.unsubscribe();
    debugPrint('🔌 Realtime subscriptions closed');
    super.dispose();
  }

  /// Load initial inventory data - try Supabase first, then local storage
  Future<void> _loadInventoryData() async {
    try {
      // Try loading from Supabase first
      _inventory = await _supabaseService.fetchInventory();
      await _saveInventoryToStorage(); // Cache locally
      notifyListeners();
      debugPrint('✅ Loaded ${_inventory.length} inventory items from Supabase');
    } catch (e) {
      debugPrint('⚠️ Failed to load from Supabase, trying local storage: $e');
      // Fall back to local storage
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
  }

  /// Load initial staff data - try Supabase first, then local storage
  Future<void> _loadStaffData() async {
    try {
      // Try loading from Supabase first
      _staff = await _supabaseService.fetchStaff();
      await _saveStaffToStorage(); // Cache locally
      notifyListeners();
      debugPrint('✅ Loaded ${_staff.length} staff members from Supabase');
    } catch (e) {
      debugPrint('⚠️ Failed to load from Supabase, trying local storage: $e');
      // Fall back to local storage
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
  }

  /// Load initial data - try Supabase first, then local storage
  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try loading from Supabase first
      debugPrint('📥 Fetching transactions from Supabase cloud...');
      _transactions = await _supabaseService.fetchTransactions();
      await _saveToStorage(); // Cache locally
      debugPrint('✅ SUCCESS: Loaded ${_transactions.length} transactions from CLOUD');
    } catch (e) {
      debugPrint('❌ CLOUD FETCH FAILED: $e');
      debugPrint('⚠️ Loading from LOCAL storage instead');
      // Fall back to local storage
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
      }
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

  /// Add transaction - saves to Supabase AND local storage
  Future<void> addTransaction(Transaction transaction) async {
    try {
      // Save to Supabase first
      debugPrint('💾 Attempting to save transaction to Supabase...');
      final savedTransaction = await _supabaseService.addTransaction(transaction);
      
      // Don't add locally here - realtime subscription will handle it to prevent duplicates
      debugPrint('✅ SUCCESS: Transaction saved to CLOUD (Supabase ID: ${savedTransaction.id})');
      debugPrint('🔔 Waiting for realtime to sync...');
    } catch (e) {
      debugPrint('❌ CLOUD SAVE FAILED: $e');
      debugPrint('⚠️ Falling back to LOCAL-ONLY storage');
      // Fall back to local-only save
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
      debugPrint('✅ Transaction added to local storage only');
    }
  }

  /// Delete transaction - deletes from Supabase AND local storage
  Future<void> deleteTransaction(int id) async {
    try {
      // Delete from Supabase first
      await _supabaseService.deleteTransaction(id);
      
      // Don't remove locally here - realtime subscription will handle it to prevent race conditions
      debugPrint('✅ Transaction deleted from CLOUD (ID: $id)');
      debugPrint('🔔 Waiting for realtime to sync...');
    } catch (e) {
      debugPrint('⚠️ Failed to delete from Supabase, deleting locally only: $e');
      // Fall back to local-only delete
      _transactions.removeWhere((t) => t.id == id);
      await _saveToStorage();
      notifyListeners();
      debugPrint('✅ Transaction deleted from local storage only');
    }
  }

  /// Update transaction - updates in Supabase AND local storage
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      // Update in Supabase first
      await _supabaseService.updateTransaction(transaction);
      
      // Don't update locally here - realtime subscription will handle it
      debugPrint('✅ Transaction updated in CLOUD (ID: ${transaction.id})');
      debugPrint('🔔 Waiting for realtime to sync...');
    } catch (e) {
      debugPrint('⚠️ Failed to update in Supabase, updating locally only: $e');
      // Fall back to local-only update
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        await _saveToStorage();
        notifyListeners();
        debugPrint('✅ Transaction updated in local storage only');
      }
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
          // Daily targets
          'dailyRevenueTarget': 10000.0,
          'dailyTransactionsTarget': 50.0,
          'avgTransactionTarget': 200.0,
          'dailyExpensesTarget': 3000.0,
          // Weekly targets
          'weeklyRevenueTarget': 70000.0,
          'weeklyTransactionsTarget': 350.0,
          // Monthly targets
          'monthlyRevenueTarget': 300000.0,
          'monthlyTransactionsTarget': 1500.0,
          // Performance metrics
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

  /// Refresh all data from Supabase
  Future<void> refreshAllData() async {
    await _loadInitialData();
    await _loadInventoryData();
    await _loadStaffData();
    debugPrint('✅ All data refreshed from Supabase');
  }
}
