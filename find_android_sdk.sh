#!/bin/zsh

echo "🔍 Searching for Android SDK..."
echo ""

# Common Android SDK locations on macOS
POSSIBLE_LOCATIONS=(
    "$HOME/Library/Android/sdk"
    "$HOME/Android/Sdk"
    "/usr/local/android-sdk"
    "/opt/android-sdk"
)

SDK_FOUND=""

for location in "${POSSIBLE_LOCATIONS[@]}"; do
    if [ -d "$location" ]; then
        echo "✅ Found Android SDK at: $location"
        SDK_FOUND=$location

        # Check for emulator
        if [ -f "$location/emulator/emulator" ]; then
            echo "✅ Emulator found at: $location/emulator/emulator"
        fi

        # Check for platform-tools
        if [ -f "$location/platform-tools/adb" ]; then
            echo "✅ ADB found at: $location/platform-tools/adb"
        fi

        echo ""
    fi
done

if [ -z "$SDK_FOUND" ]; then
    echo "❌ Android SDK not found in common locations"
    echo ""
    echo "Looking for flutter's Android SDK path..."
    flutter doctor -v | grep "Android SDK"
else
    echo "📝 To add to PATH, add these lines to your ~/.zshrc:"
    echo ""
    echo "export ANDROID_HOME=\"$SDK_FOUND\""
    echo "export PATH=\"\$PATH:\$ANDROID_HOME/emulator\""
    echo "export PATH=\"\$PATH:\$ANDROID_HOME/platform-tools\""
    echo "export PATH=\"\$PATH:\$ANDROID_HOME/tools\""
    echo "export PATH=\"\$PATH:\$ANDROID_HOME/tools/bin\""
fi

echo ""
echo "🔍 Checking Flutter doctor..."
flutter doctor -v

