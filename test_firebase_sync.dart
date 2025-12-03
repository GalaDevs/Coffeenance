import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'lib/services/firestore_service.dart';
import 'lib/models/transaction.dart';

/// Test script to verify Firebase Cloud Firestore connection
/// Run with: dart run test_firebase_sync.dart
void main() async {
  print('🔥 Testing Firebase Cloud Firestore Connection...\n');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized\n');

  // Create Firestore service
  final firestoreService = FirestoreService();
  print('✅ Firestore service created\n');

  // Create a test transaction
  final testTransaction = Transaction(
    id: 999,
    date: DateTime.now().toIso8601String().split('T')[0],
    type: TransactionType.revenue,
    category: RevenueCategories.cash,
    description: 'CLI Test - Firebase Sync Verification',
    amount: 777.77,
    paymentMethod: 'Cash',
    transactionNumber: 'CLI-TEST-001',
    receiptNumber: 'RCP-CLI-001',
  );

  print('📝 Test transaction created:');
  print('   Description: ${testTransaction.description}');
  print('   Amount: ₱${testTransaction.amount}');
  print('   Date: ${testTransaction.date}\n');

  try {
    // Add to Firestore
    print('⏳ Uploading to Firebase Cloud Firestore...');
    final docId = await firestoreService.addTransaction(testTransaction);
    print('✅ SUCCESS! Transaction synced to Firebase!');
    print('   Document ID: $docId\n');

    print('🎉 Firebase Cloud Database is working!\n');
    print('📊 Verify in Firebase Console:');
    print('   https://console.firebase.google.com/project/caffeenance-d0958/firestore/databases/-default-/data\n');
    print('You should see a new document in the "transactions" collection!');
    
  } catch (e) {
    print('❌ ERROR: Failed to sync to Firebase');
    print('   Error: $e\n');
    print('⚠️  Make sure:');
    print('   1. Firestore is enabled in Firebase Console');
    print('   2. Security rules allow writes');
    print('   3. Internet connection is active');
  }
}
