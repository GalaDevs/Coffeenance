#!/bin/zsh

# Run Flutter app on iOS Simulator with full debug output in terminal
# This will show all logs, errors, and debug information in VSCode terminal

echo "🚀 Starting Flutter iOS Simulator with Full Debug Output"
echo "=========================================================="
echo ""

# Navigate to project directory
cd "$(dirname "$0")"

# Ensure we're using the right directory
PROJECT_DIR=$(pwd)
echo "📁 Project Directory: $PROJECT_DIR"
echo ""

# Check for iOS simulator
echo "📱 Checking for iOS Simulator..."
xcrun simctl list devices | grep "Booted"

if [ $? -ne 0 ]; then
    echo ""
    echo "⚠️  No simulator is currently running."
    echo "Starting a simulator..."
    open -a Simulator
    sleep 5
fi

echo ""
echo "🔍 Starting Flutter with MAXIMUM verbose debug output..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "All errors, warnings, and debug messages will appear below:"
echo ""

# Run Flutter with MAXIMUM debugging enabled
# -vv = extra verbose (shows all Flutter tool debug info)
# --verbose = verbose app output
# --debug = debug mode with hot reload
flutter run \
    -d ios \
    -vv \
    --verbose \
    --debug \
    2>&1 | tee flutter_debug_output.log

# The 2>&1 redirects stderr to stdout so you see ALL errors
# tee saves output to log file while also displaying it
