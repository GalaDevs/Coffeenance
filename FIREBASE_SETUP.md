# 🔥 Firebase Cloud Firestore Setup Complete

## ✅ Setup Summary

Your Flutter app is now connected to Firebase with Cloud Firestore enabled!

**Firebase Project**: `caffeenance-d0958`
**Project Console**: https://console.firebase.google.com/project/caffeenance-d0958

---

## 📱 Platforms Configured

✅ **Android**: `com.example.cafenance`
✅ **iOS**: `com.example.coffeeflow`
✅ **macOS**: `com.example.coffeeflow`
✅ **Web**: `cafenance (web)`

---

## 🗄️ Firestore Database Structure

### Collections

#### 1. **transactions**
Stores all revenue and transaction records.

```javascript
{
  "id": 1,
  "date": "2025-12-03",
  "type": "revenue",  // or "transaction"
  "category": "Cash", // Payment method for revenue, expense category for transactions
  "description": "Cash sales",
  "amount": 450.00,
  "paymentMethod": "Cash",
  "transactionNumber": "TXN001",
  "receiptNumber": "RCP001",
  "tinNumber": "",
  "vat": 0,  // 0 or 12
  "supplierName": "",
  "supplierAddress": ""
}
```

#### 2. **inventory**
Stores inventory/stock items.

```javascript
{
  "item": "Coffee Beans",
  "stock": 45,
  "unit": "kg",
  "status": "good",  // good, warning, critical
  "reorder": 30
}
```

#### 3. **staff**
Stores staff/payroll information.

```javascript
{
  "id": 1,
  "name": "Maria Santos",
  "position": "Manager",
  "salary": 25000.00,
  "status": "Full-time",
  "startDate": "2023-01"
}
```

---

## 🛠️ How to Enable Firestore in Firebase Console

### Step 1: Go to Firestore Database
1. Open https://console.firebase.google.com/project/caffeenance-d0958
2. Click on **Firestore Database** in the left sidebar
3. Click **Create database**

### Step 2: Choose Security Rules
Select one of the following:

#### Option A: Test Mode (Development Only - NOT for production!)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```
⚠️ **Warning**: This allows anyone to read/write your database. Only use for development!

#### Option B: Production Mode (Recommended)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /transactions/{document} {
      allow read, write: if request.auth != null;
    }
    match /inventory/{document} {
      allow read, write: if request.auth != null;
    }
    match /staff/{document} {
      allow read, write: if request.auth != null;
    }
  }
}
```
📝 This requires user authentication. You'll need to set up Firebase Authentication.

### Step 3: Choose Location
Select a location close to your users:
- **asia-southeast1** (Singapore) - Recommended for Philippines
- **asia-east1** (Taiwan)
- **us-central** (Iowa)

### Step 4: Create Initial Collections

Once Firestore is created, you can add collections manually or let the app create them automatically when you add your first transaction.

---

## 🚀 Usage in Your App

### FirestoreService

The app includes a `FirestoreService` class (`lib/services/firestore_service.dart`) with methods for:

#### Transactions
- `getTransactionsStream()` - Real-time listener for all transactions
- `getTransactions()` - One-time fetch of all transactions
- `addTransaction(transaction)` - Add a new transaction
- `updateTransaction(id, transaction)` - Update existing transaction
- `deleteTransaction(id)` - Delete a transaction

#### Inventory
- `getInventoryStream()` - Real-time listener for inventory
- `addInventoryItem(item)` - Add inventory item
- `updateInventoryItem(id, item)` - Update inventory item
- `deleteInventoryItem(id)` - Delete inventory item

#### Staff
- `getStaffStream()` - Real-time listener for staff
- `addStaffMember(staff)` - Add staff member
- `updateStaffMember(id, staff)` - Update staff member
- `deleteStaffMember(id)` - Delete staff member

### Example Usage

```dart
import 'package:cafenance/services/firestore_service.dart';

final firestoreService = FirestoreService();

// Add a transaction
await firestoreService.addTransaction(transaction);

// Listen to transactions in real-time
firestoreService.getTransactionsStream().listen((transactions) {
  print('Transactions updated: ${transactions.length}');
});
```

---

## 🔄 Hybrid Mode: Local + Cloud

Your app currently uses **SharedPreferences** for local storage. The TransactionProvider has been prepared to support **hybrid mode**:

- **Local-first**: Data saves to SharedPreferences immediately
- **Cloud sync**: Optionally sync to Firestore for backup and multi-device access
- **Offline support**: Works without internet, syncs when online

---

## 📝 Next Steps

1. **Enable Firestore in Firebase Console** (see Step 1-4 above)
2. **Choose your security rules** (Test Mode for development, Production Mode for release)
3. **Optional: Set up Firebase Authentication** if using production security rules
4. **Test the connection**: Run the app and add a transaction

---

## 🔒 Security Best Practices

Before launching to production:

1. ✅ Enable Firebase Authentication
2. ✅ Set up proper Firestore Security Rules
3. ✅ Limit read/write access to authenticated users only
4. ✅ Add data validation rules
5. ✅ Enable App Check to prevent abuse

---

## 📚 Resources

- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Flutter + Firestore Guide](https://firebase.flutter.dev/docs/firestore/overview)
- [Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Console](https://console.firebase.google.com/)

---

## ❓ Troubleshooting

### Issue: "Missing or insufficient permissions"
**Solution**: Check your Firestore Security Rules. In development, use Test Mode rules.

### Issue: "firebase_core plugin not found"
**Solution**: Run `flutter pub get` to install Firebase dependencies.

### Issue: "Cloud Firestore is not enabled"
**Solution**: Enable Firestore Database in Firebase Console (see steps above).

---

Your app is ready to use Firebase Cloud Firestore! 🎉
