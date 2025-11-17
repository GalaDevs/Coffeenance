import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

/// TransactionProvider manages all transaction state
/// Replaces Next.js useState for transactions management
/// Persists to local storage (SharedPreferences) similar to localStorage
class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  // Getters
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;

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
  }

  /// Load initial sample data matching Next.js initial state
  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try to load from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? transactionsJson = prefs.getString('transactions');

      if (transactionsJson != null) {
        final List<dynamic> decoded = json.decode(transactionsJson);
        _transactions = decoded.map((json) => Transaction.fromJson(json)).toList();
      } else {
        // Load sample data matching Next.js initial state
        _transactions = [
          Transaction(
            id: 1,
            date: DateTime.now().toIso8601String().split('T')[0],
            type: TransactionType.revenue,
            category: RevenueCategories.cash,
            description: 'Cash sales',
            amount: 450.0,
            paymentMethod: 'Cash',
            transactionNumber: 'TXN001',
            receiptNumber: 'RCP001',
          ),
          Transaction(
            id: 2,
            date: DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0],
            type: TransactionType.revenue,
            category: RevenueCategories.gcash,
            description: 'GCash payment',
            amount: 280.0,
            paymentMethod: 'GCash',
            transactionNumber: 'TXN002',
            receiptNumber: 'RCP002',
          ),
          Transaction(
            id: 3,
            date: DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0],
            type: TransactionType.transaction,
            category: TransactionCategories.supplies,
            description: 'Coffee beans',
            amount: 150.0,
            paymentMethod: 'Cash',
            transactionNumber: 'TXN003',
            receiptNumber: 'RCP003',
            supplierName: 'Coffee Supplier Inc.',
            vat: 12,
          ),
        ];
        await _saveToStorage();
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add transaction (matching Next.js handleAddTransaction)
  Future<void> addTransaction(Transaction transaction) async {
    // Generate new ID
    final int newId = _transactions.isEmpty
        ? 1
        : _transactions.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;

    final newTransaction = transaction.copyWith(
      id: newId,
      date: DateTime.now().toIso8601String().split('T')[0],
    );

    // Add to beginning of list (matching Next.js behavior)
    _transactions.insert(0, newTransaction);
    notifyListeners();

    // Persist to storage
    await _saveToStorage();
  }

  /// Delete transaction
  Future<void> deleteTransaction(int id) async {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
    await _saveToStorage();
  }

  /// Update transaction
  Future<void> updateTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      notifyListeners();
      await _saveToStorage();
    }
  }

  /// Clear all transactions
  Future<void> clearAll() async {
    _transactions.clear();
    notifyListeners();
    await _saveToStorage();
  }

  /// Save transactions to SharedPreferences (localStorage equivalent)
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList =
          _transactions.map((t) => t.toJson()).toList();
      await prefs.setString('transactions', json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving transactions: $e');
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
}
