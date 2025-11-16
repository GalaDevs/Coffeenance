#!/bin/zsh

# Simple Flutter Emulator Launcher using Flutter's built-in commands

cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance/flutter_coffeeflow

echo "🚀 CoffeeFlow - Simple Launcher"
echo "================================"
echo ""

echo "📱 Checking Flutter setup..."
flutter doctor

echo ""
echo "📋 Available emulators:"
flutter emulators

echo ""
echo "🎯 Looking for a suitable emulator to launch..."

# Get list of emulators from flutter
EMULATOR_LIST=$(flutter emulators 2>&1)

# Parse the first emulator ID (they appear after bullet points)
EMULATOR_ID=$(echo "$EMULATOR_LIST" | grep "•" | head -n 1 | sed 's/.*• //' | awk '{print $1}')

if [ -z "$EMULATOR_ID" ]; then
    echo "❌ No emulators found!"
    echo ""
    echo "📝 To create an emulator:"
    echo "  1. Open Android Studio"
    echo "  2. Tools → Device Manager"
    echo "  3. Click 'Create Device'"
    echo "  4. Select 'Pixel 5' or any medium phone"
    echo "  5. Choose API 33 or 34"
    echo "  6. Click Finish"
    echo ""
    echo "Or run the app on Chrome for quick testing:"
    echo "  flutter run -d chrome"
    exit 1
fi

echo "✅ Found emulator: $EMULATOR_ID"
echo ""
echo "🚀 Launching emulator..."
flutter emulators --launch "$EMULATOR_ID" &

echo "⏳ Waiting for emulator to boot (this takes 30-60 seconds)..."
sleep 30

echo ""
echo "📱 Available devices:"
flutter devices

echo ""
echo "🎨 Running CoffeeFlow app..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run the app
flutter run

