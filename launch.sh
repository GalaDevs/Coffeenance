#!/bin/zsh

# Navigate to project directory
cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance/flutter_coffeeflow

echo "🚀 CoffeeFlow Flutter Launcher"
echo "=============================="
echo ""

# Check Flutter
echo "📱 Checking Flutter installation..."
flutter --version

echo ""
echo "📋 Listing available devices..."
flutter devices

echo ""
echo "🔍 Checking for Android emulators..."
flutter emulators

echo ""
echo "🎯 Starting app on connected/available device..."
echo ""

# Run the app
flutter run

