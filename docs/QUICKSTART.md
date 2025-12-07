# 🚀 Quick Start Guide - CoffeeFlow Flutter

## ⚡ Get Running in 5 Minutes

### Step 1: Verify Flutter Installation
```bash
flutter doctor
```
✅ Should show Flutter 3.5.0+

### Step 2: Navigate to Project
```bash
cd "/Users/rheyvictormacayran/Downloads/code (6)/flutter_coffeeflow"
```

### Step 3: Get Dependencies
```bash
flutter pub get
```

### Step 4: Run the App

#### On Chrome (Fastest for testing)
```bash
flutter run -d chrome --web-port=8083
```
Then open: http://localhost:8083

#### On Android
```bash
flutter run -d android
```

#### On iOS (macOS only)
```bash
flutter run -d ios
```

---

## 🎮 Using the App

### 1. **Add a Transaction**
- Tap the **"+ Add"** button (floating button at bottom)
- Choose **Income** or **Expense**
- Select a **category**
- Enter **description** (e.g., "Morning coffee sales")
- Enter **amount** (e.g., 450)
- Tap **Save**

### 2. **View Dashboard**
- See your current balance
- View sales breakdown by payment method
- Check top expenses
- Review recent transactions

### 3. **Check Sales Report**
- Tap **💰 Sales** tab at bottom
- View total sales
- See payment method breakdown (Cash, GCash, Grab, PayMaya)
- Review all sales transactions

### 4. **Check Expenses**
- Tap **📉 Expenses** tab
- View total expenses
- See expense categories (Supplies, Rent, Utilities, etc.)
- Review all expense transactions

### 5. **Settings**
- Tap **⚙️ Settings** tab
- Toggle dark mode
- Clear all data (if needed)
- View app information

---

## 📱 Sample Data

The app comes with 3 sample transactions:
1. ✅ Cash sales - ₱450.00 (Income)
2. ✅ GCash payment - ₱280.00 (Income)
3. ✅ Coffee beans - ₱150.00 (Expense)

**Current Balance**: ₱580.00

---

## 🎨 Features to Try

### ✨ Animations
- Modal slides in from bottom when adding transaction
- Tab icons animate when selected
- Button press animations
- Progress bars animate

### 💾 Data Persistence
- Add transactions and close the app
- Reopen - your data is still there!
- Data saved automatically with SharedPreferences

### 🌙 Dark Mode
- Go to Settings
- Toggle "Dark Mode"
- Watch the entire app theme change!

### 📊 Real-time Calculations
- Add income - watch balance increase
- Add expense - watch balance decrease
- Percentages update automatically
- Charts update in real-time

---

## ⌨️ Hot Reload Commands

While the app is running in terminal:

| Key | Action |
|-----|--------|
| `r` | 🔥 Hot reload (fast update) |
| `R` | 🔄 Hot restart (full restart) |
| `h` | ❓ Help (show all commands) |
| `d` | 🔓 Detach (app keeps running) |
| `q` | ❌ Quit (stop app) |

---

## 🐛 Troubleshooting

### "No devices found"
```bash
# For Chrome
flutter devices
# Should show "Chrome" in the list

# If not, try:
flutter config --enable-web
```

### "Build failed"
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### "Package not found"
```bash
# Reinstall dependencies
flutter pub get
```

### App won't start
```bash
# Check Flutter doctor
flutter doctor -v

# Fix any issues it reports
```

---

## 📸 Screenshots

### Dashboard
- Balance card with gradient
- Tax summary (collapsible)
- Sales monitoring
- Sales breakdown
- Expense breakdown
- Recent transactions

### Sales Page
- Total sales card (amber gradient)
- Payment method breakdown
- Progress bars with percentages
- Recent sales list

### Expenses Page
- Total expenses card (red gradient)
- Category breakdown
- Progress bars with percentages
- Recent expenses list

### Add Transaction Modal
- Income/Expense toggle
- Category selection grid
- Description input
- Amount input with ₱ prefix
- Save/Cancel buttons

---

## 🎯 Test Scenarios

### Basic Flow
1. ✅ Open app
2. ✅ View dashboard
3. ✅ Tap "+ Add" button
4. ✅ Add an income transaction
5. ✅ See it appear in recent transactions
6. ✅ Check balance updated
7. ✅ Go to Sales tab
8. ✅ See new transaction there
9. ✅ Add an expense
10. ✅ See balance decrease

### Advanced Flow
1. ✅ Add multiple transactions
2. ✅ Switch between tabs
3. ✅ View different breakdowns
4. ✅ Go to Settings
5. ✅ Toggle dark mode
6. ✅ Close app
7. ✅ Reopen app
8. ✅ Verify data persisted

---

## 💻 Development Tips

### Enable Hot Reload
- Save your Dart files
- Press `r` in terminal
- Changes appear instantly (in <500ms)

### Debug Mode
- Press `p` to see performance overlay
- Press `i` to see widget inspector
- Open DevTools in browser

### Best Practices
```dart
// Use const constructors
const Text('Hello')

// Use Provider for state
context.watch<TransactionProvider>()

// Handle async properly
await provider.addTransaction(...)
```

---

## 🔗 Useful Links

- **Flutter Docs**: https://docs.flutter.dev
- **Provider Package**: https://pub.dev/packages/provider
- **Material Components**: https://m3.material.io
- **Stack Overflow**: https://stackoverflow.com/questions/tagged/flutter

---

## 📊 Performance Expectations

| Metric | Expected |
|--------|----------|
| App Start | < 1 second |
| Hot Reload | < 500ms |
| Add Transaction | < 50ms |
| Navigation | Instant |
| Animations | 60 FPS |

---

## ✅ Checklist Before Building for Production

- [ ] Test on physical Android device
- [ ] Test on physical iOS device
- [ ] Add app icons
- [ ] Update app name in pubspec.yaml
- [ ] Set proper version number
- [ ] Configure signing certificates
- [ ] Test data persistence
- [ ] Test all features
- [ ] Check animations
- [ ] Verify dark mode
- [ ] Test offline functionality

---

## 🎉 You're All Set!

The app is now running and fully functional. Try adding some transactions and exploring all the features!

**Need Help?**
- Check README.md for detailed documentation
- Check CONVERSION_SUMMARY.md for technical details
- Review the code comments
- Use Flutter DevTools for debugging

**Happy Coding! ☕**
