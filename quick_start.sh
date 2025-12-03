#!/bin/zsh

# Ultra-Simple: Just list emulators and run flutter
# You manually choose which emulator to launch

cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance/flutter_coffeeflow

echo "🚀 CoffeeFlow - Quick Start"
echo "============================"
echo ""

echo "Step 1: Here are your available emulators:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
flutter emulators
echo ""

echo "Step 2: Copy one of the emulator IDs above (the word after the bullet •)"
echo ""
echo "Step 3: Launch it with this command:"
echo "  flutter emulators --launch <EMULATOR_ID>"
echo ""
echo "Step 4: Wait 30-60 seconds for it to boot, then run:"
echo "  flutter run"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "OR - Just run flutter and let it auto-detect:"
echo "  flutter run"
echo ""
echo "OR - Run on Chrome browser (fastest for testing):"
echo "  flutter run -d chrome"
echo ""

