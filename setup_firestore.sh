#!/bin/zsh

echo "🔥 Firebase Cloud Firestore Setup for Cafenance"
echo "================================================"
echo ""

PROJECT_ID="caffeenance-d0958"

echo "✅ Firebase Project: $PROJECT_ID"
echo ""

echo "📋 Configured Platforms:"
echo "   • Android: com.example.cafenance"
echo "   • iOS: com.example.coffeeflow"
echo "   • macOS: com.example.coffeeflow"  
echo "   • Web: cafenance (web)"
echo ""

echo "🗄️  Now you need to enable Cloud Firestore:"
echo ""
echo "1. Open this URL in your browser:"
echo "   https://console.firebase.google.com/project/$PROJECT_ID/firestore"
echo ""
echo "2. Click 'Create database' button"
echo ""
echo "3. Choose 'Start in test mode' for development:"
echo "   (This allows read/write access for 30 days - perfect for testing)"
echo ""
echo "4. Select location: asia-southeast1 (Singapore)"
echo "   (Closest to Philippines for best performance)"
echo ""
echo "5. Click 'Enable'"
echo ""

echo "📝 Security Rules (Test Mode):"
echo "rules_version = '2';"
echo "service cloud.firestore {"
echo "  match /databases/{database}/documents {"
echo "    match /{document=**} {"
echo "      allow read, write: if request.time < timestamp.date(2025, 12, 31);"
echo "    }"
echo "  }"
echo "}"
echo ""

echo "🚀 After enabling Firestore, test your connection:"
echo "   1. Run: flutter run"
echo "   2. Go to Settings in the app"
echo "   3. Look for 'Firebase Test' section"
echo "   4. Click 'Test Firebase Connection'"
echo ""

echo "📱 Or run the test screen directly:"
echo "   flutter run lib/screens/firebase_test_screen.dart"
echo ""

echo "✅ Firebase configuration files already created:"
echo "   • lib/firebase_options.dart"
echo "   • lib/services/firestore_service.dart"
echo "   • android/app/google-services.json (auto-downloaded)"
echo "   • ios/Runner/GoogleService-Info.plist (auto-downloaded)"
echo "   • macos/Runner/GoogleService-Info.plist (auto-downloaded)"
echo ""

echo "Press any key to open Firebase Console..."
read -k1 -s

# Open Firebase Console
open "https://console.firebase.google.com/project/$PROJECT_ID/firestore"

echo ""
echo "✨ Firebase Console opened in your browser!"
