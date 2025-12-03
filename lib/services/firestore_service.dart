import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart' as models;

/// Firestore Service - Handles all Cloud Firestore operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _transactions => _firestore.collection('transactions');
  CollectionReference get _inventory => _firestore.collection('inventory');
  CollectionReference get _staff => _firestore.collection('staff');

  /// ===== TRANSACTION OPERATIONS =====

  /// Get all transactions as a stream
  Stream<List<models.Transaction>> getTransactionsStream() {
    return _transactions
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => models.Transaction.fromJson({
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                }))
            .toList());
  }

  /// Get all transactions as a future
  Future<List<models.Transaction>> getTransactions() async {
    try {
      final snapshot = await _transactions.orderBy('date', descending: true).get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Add firestoreId to the transaction data
            data['firestoreId'] = doc.id;
            return models.Transaction.fromJson(data);
          })
          .toList();
    } catch (e) {
      // Return empty list if there's an error (e.g., no data yet)
      return [];
    }
  }

  /// Add a new transaction
  Future<String> addTransaction(models.Transaction transaction) async {
    final docRef = await _transactions.add(transaction.toJson());
    return docRef.id;
  }

  /// Update an existing transaction
  Future<void> updateTransaction(String id, models.Transaction transaction) async {
    await _transactions.doc(id).update(transaction.toJson());
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    await _transactions.doc(id).delete();
  }

  /// ===== INVENTORY OPERATIONS =====

  /// Get inventory items as a stream
  Stream<List<Map<String, dynamic>>> getInventoryStream() {
    return _inventory.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList());
  }

  /// Add inventory item
  Future<String> addInventoryItem(Map<String, dynamic> item) async {
    final docRef = await _inventory.add(item);
    return docRef.id;
  }

  /// Update inventory item
  Future<void> updateInventoryItem(String id, Map<String, dynamic> item) async {
    await _inventory.doc(id).update(item);
  }

  /// Delete inventory item
  Future<void> deleteInventoryItem(String id) async {
    await _inventory.doc(id).delete();
  }

  /// ===== STAFF/PAYROLL OPERATIONS =====

  /// Get staff members as a stream
  Stream<List<Map<String, dynamic>>> getStaffStream() {
    return _staff.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList());
  }

  /// Add staff member
  Future<String> addStaffMember(Map<String, dynamic> staff) async {
    final docRef = await _staff.add(staff);
    return docRef.id;
  }

  /// Update staff member
  Future<void> updateStaffMember(String id, Map<String, dynamic> staff) async {
    await _staff.doc(id).update(staff);
  }

  /// Delete staff member
  Future<void> deleteStaffMember(String id) async {
    await _staff.doc(id).delete();
  }

  /// ===== BULK OPERATIONS =====

  /// Batch write multiple transactions
  Future<void> batchAddTransactions(List<models.Transaction> transactions) async {
    final batch = _firestore.batch();
    for (var transaction in transactions) {
      final docRef = _transactions.doc();
      batch.set(docRef, transaction.toJson());
    }
    await batch.commit();
  }

  /// Clear all data (use with caution!)
  Future<void> clearAllData() async {
    final batch = _firestore.batch();
    
    // Clear transactions
    final transactionDocs = await _transactions.get();
    for (var doc in transactionDocs.docs) {
      batch.delete(doc.reference);
    }
    
    // Clear inventory
    final inventoryDocs = await _inventory.get();
    for (var doc in inventoryDocs.docs) {
      batch.delete(doc.reference);
    }
    
    // Clear staff
    final staffDocs = await _staff.get();
    for (var doc in staffDocs.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}
