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
  List<Transaction> get incomeTransactions =>
      _transactions.where((t) => t.type == TransactionType.income).toList();

  List<Transaction> get expenseTransactions =>
      _transactions.where((t) => t.type == TransactionType.expense).toList();

  double get totalIncome =>
      incomeTransactions.fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense =>
      expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  /// Get sales breakdown by payment method (matching Next.js salesByMethod)
  Map<String, double> get salesByMethod {
    return {
      IncomeCategories.cash: incomeTransactions
          .where((t) => t.category == IncomeCategories.cash)
          .fold(0.0, (sum, t) => sum + t.amount),
      IncomeCategories.gcash: incomeTransactions
          .where((t) => t.category == IncomeCategories.gcash)
          .fold(0.0, (sum, t) => sum + t.amount),
      IncomeCategories.grab: incomeTransactions
          .where((t) => t.category == IncomeCategories.grab)
          .fold(0.0, (sum, t) => sum + t.amount),
      IncomeCategories.paymaya: incomeTransactions
          .where((t) => t.category == IncomeCategories.paymaya)
          .fold(0.0, (sum, t) => sum + t.amount),
    };
  }

  /// Get expenses breakdown by category
  Map<String, double> get expensesByCategory {
    return {
      ExpenseCategories.supplies: expenseTransactions
          .where((t) => t.category == ExpenseCategories.supplies)
          .fold(0.0, (sum, t) => sum + t.amount),
      ExpenseCategories.pastries: expenseTransactions
          .where((t) => t.category == ExpenseCategories.pastries)
          .fold(0.0, (sum, t) => sum + t.amount),
      ExpenseCategories.rent: expenseTransactions
          .where((t) => t.category == ExpenseCategories.rent)
          .fold(0.0, (sum, t) => sum + t.amount),
      ExpenseCategories.utilities: expenseTransactions
          .where((t) => t.category == ExpenseCategories.utilities)
          .fold(0.0, (sum, t) => sum + t.amount),
      ExpenseCategories.manpower: expenseTransactions
          .where((t) => t.category == ExpenseCategories.manpower)
          .fold(0.0, (sum, t) => sum + t.amount),
      ExpenseCategories.marketing: expenseTransactions
          .where((t) => t.category == ExpenseCategories.marketing)
          .fold(0.0, (sum, t) => sum + t.amount),
      ExpenseCategories.others: expenseTransactions
          .where((t) => t.category == ExpenseCategories.others)
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
            type: TransactionType.income,
            category: IncomeCategories.cash,
            description: 'Cash sales',
            amount: 450.0,
          ),
          Transaction(
            id: 2,
            date: DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0],
            type: TransactionType.income,
            category: IncomeCategories.gcash,
            description: 'GCash payment',
            amount: 280.0,
          ),
          Transaction(
            id: 3,
            date: DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0],
            type: TransactionType.expense,
            category: ExpenseCategories.supplies,
            description: 'Coffee beans',
            amount: 150.0,
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
