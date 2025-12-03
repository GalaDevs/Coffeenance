import 'package:flutter/material.dart';
import 'package:cafenance/services/firestore_service.dart';
import 'package:cafenance/models/transaction.dart';

/// Firebase Test Screen
/// Use this to test Firebase Firestore connection
class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _status = 'Not tested';
  bool _isLoading = false;

  Future<void> _testFirestore() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Firestore connection...';
    });

    try {
      // Test 1: Add a test transaction
      final testTransaction = Transaction(
        id: 999,
        date: DateTime.now().toIso8601String().split('T')[0],
        type: TransactionType.revenue,
        category: RevenueCategories.cash,
        description: 'Firebase Test Transaction',
        amount: 100.0,
        paymentMethod: 'Cash',
        transactionNumber: 'TEST001',
        receiptNumber: 'TEST-RCP001',
      );

      setState(() {
        _status = 'Adding test transaction...';
      });

      final docId = await _firestoreService.addTransaction(testTransaction);
      
      setState(() {
        _status = 'Transaction added! Doc ID: $docId\nFetching transactions...';
      });

      // Test 2: Fetch transactions
      final transactions = await _firestoreService.getTransactions();
      
      setState(() {
        _status = '✅ SUCCESS!\n\n'
            'Transaction added with ID: $docId\n'
            'Total transactions in Firestore: ${transactions.length}\n\n'
            'Deleting test transaction...';
      });

      // Test 3: Delete the test transaction
      await _firestoreService.deleteTransaction(docId);
      
      setState(() {
        _status = '✅ ALL TESTS PASSED!\n\n'
            'Firebase Firestore is working correctly!\n\n'
            '• Added transaction ✓\n'
            '• Fetched transactions ✓\n'
            '• Deleted transaction ✓';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ ERROR\n\n$e\n\n'
            'Make sure:\n'
            '1. Firestore is enabled in Firebase Console\n'
            '2. Security rules allow read/write\n'
            '3. You have internet connection';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.cloud_outlined,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Firebase Firestore Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testFirestore,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isLoading ? 'Testing...' : 'Run Firebase Test'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will:\n'
              '• Add a test transaction to Firestore\n'
              '• Fetch all transactions\n'
              '• Delete the test transaction\n',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
