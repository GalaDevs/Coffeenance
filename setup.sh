#!/bin/bash

echo "🚀 Setting up Flutter project..."

# Navigate to project directory
cd "$(dirname "$0")"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter found"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Generate any necessary code
echo "🔨 Running code generation..."
flutter pub run build_runner build --delete-conflicting-outputs

# Check for connected devices
echo "📱 Checking for connected devices..."
flutter devices

echo ""
echo "✅ Setup complete!"
echo ""
echo "To run the app:"
echo "  1. Make sure you have a device/emulator connected"
echo "  2. Run: flutter run"
echo "  3. Or use the play button in your IDE"
echo ""

