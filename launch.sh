#!/bin/zsh

# Enable debug mode
set -x  # Print commands before executing
set -e  # Exit on error

# Navigate to project directory
cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance/flutter_coffeeflow

echo "🚀 CoffeeFlow Flutter Launcher (DEBUG MODE)"
echo "=============================="
echo ""
echo "📝 Debug output enabled - all commands will be shown"
echo ""

# Check Flutter with verbose output
echo "📱 Checking Flutter installation..."
flutter --version --verbose

echo ""
echo "📋 Listing available devices..."
flutter devices --verbose

echo ""
echo "🔍 Checking for Android emulators..."
flutter emulators --verbose

echo ""
echo "🎯 Starting app in debug mode with verbose output..."
echo ""

# Run the app in debug mode with verbose logging
flutter run --debug --verbose

