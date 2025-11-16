#!/bin/bash

# Auto-fix script for IDE play button issues
# This script fixes common IDE configuration problems

echo "🔧 CoffeeFlow IDE Fix Script"
echo "=============================="
echo ""

# Navigate to project directory
cd "$(dirname "$0")"
PROJECT_DIR=$(pwd)

echo "📁 Project: $PROJECT_DIR"
echo ""

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo ""
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    echo "Or add Flutter to your PATH"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"
echo ""

# Step 1: Clean build artifacts
echo "🧹 Step 1: Cleaning build artifacts..."
flutter clean
echo "   ✓ Build cleaned"
echo ""

# Step 2: Get dependencies and generate plugin files
echo "📦 Step 2: Getting dependencies..."
flutter pub get
echo "   ✓ Dependencies installed"
echo ""

# Step 3: Verify plugin files were generated
echo "🔍 Step 3: Verifying plugin files..."
if [ -f ".flutter-plugins" ]; then
    echo "   ✓ .flutter-plugins exists"
else
    echo "   ⚠️  .flutter-plugins not found (this might be normal)"
fi

if [ -f ".flutter-plugins-dependencies" ]; then
    echo "   ✓ .flutter-plugins-dependencies exists"
else
    echo "   ⚠️  .flutter-plugins-dependencies not found"
fi
echo ""

# Step 4: Check IDE configuration files
echo "🔧 Step 4: Checking IDE configuration..."

# Check .vscode
if [ -f ".vscode/launch.json" ]; then
    echo "   ✓ VS Code launch.json exists"
else
    echo "   ⚠️  VS Code launch.json missing"
fi

# Check .idea
if [ -d ".idea" ]; then
    echo "   ✓ JetBrains .idea directory exists"

    if [ -f ".idea/runConfigurations/main_dart.xml" ]; then
        echo "   ✓ Run configuration exists"
    else
        echo "   ⚠️  Run configuration missing - will be regenerated on IDE start"
    fi
else
    echo "   ⚠️  .idea directory missing - will be created on IDE start"
fi
echo ""

# Step 5: Check for available devices
echo "📱 Step 5: Checking available devices..."
DEVICES=$(flutter devices --machine)
if [ $? -eq 0 ]; then
    echo "   ✓ Device check successful"
    echo ""
    echo "Available devices:"
    flutter devices
else
    echo "   ⚠️  Could not list devices"
fi
echo ""

# Step 6: Validate main.dart
echo "📝 Step 6: Validating main.dart..."
if [ -f "lib/main.dart" ]; then
    echo "   ✓ lib/main.dart exists"
else
    echo "   ❌ lib/main.dart missing!"
    exit 1
fi
echo ""

# Step 7: Run Flutter doctor
echo "🏥 Step 7: Running Flutter doctor..."
flutter doctor
echo ""

echo "=============================="
echo "✅ Fix script complete!"
echo ""
echo "Next steps:"
echo "1. Close your IDE completely (File → Exit)"
echo "2. Reopen the project"
echo "3. Wait for indexing to complete (see bottom status bar)"
echo "4. The play button should now work"
echo ""
echo "If still not working:"
echo "• File → Invalidate Caches / Restart"
echo "• Check Flutter SDK path in Settings → Languages & Frameworks → Flutter"
echo "• Read IDE_PLAYBUTTON_FIX.md for more solutions"
echo ""
echo "To test app from command line:"
echo "  flutter run -d chrome"
echo ""

