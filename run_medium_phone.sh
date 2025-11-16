#!/bin/zsh

# CoffeeFlow - Launch on Medium Phone Emulator

cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance/flutter_coffeeflow

echo "🚀 CoffeeFlow - Medium Phone Launcher"
echo "======================================"
echo ""

# Find Android SDK
echo "🔍 Looking for Android SDK..."
ANDROID_SDK=""

# Common Android SDK locations on macOS
POSSIBLE_LOCATIONS=(
    "$HOME/Library/Android/sdk"
    "$HOME/Android/Sdk"
    "/usr/local/android-sdk"
    "/opt/android-sdk"
)

for location in "${POSSIBLE_LOCATIONS[@]}"; do
    if [ -d "$location/emulator" ]; then
        ANDROID_SDK=$location
        echo "✅ Found Android SDK at: $ANDROID_SDK"
        break
    fi
done

# If not found, try to get from flutter
if [ -z "$ANDROID_SDK" ]; then
    echo "🔍 Checking Flutter for Android SDK location..."
    SDK_FROM_FLUTTER=$(flutter doctor -v 2>/dev/null | grep "Android SDK at" | sed 's/.*Android SDK at //' | tr -d '\n')
    if [ -n "$SDK_FROM_FLUTTER" ]; then
        ANDROID_SDK=$SDK_FROM_FLUTTER
        echo "✅ Found Android SDK from Flutter: $ANDROID_SDK"
    fi
fi

# Check if we found it
if [ -z "$ANDROID_SDK" ]; then
    echo "❌ Android SDK not found!"
    echo ""
    echo "💡 Please use one of these alternatives:"
    echo ""
    echo "METHOD 1 - Use Flutter directly:"
    echo "  flutter emulators"
    echo "  flutter emulators --launch <emulator_id>"
    echo "  flutter run"
    echo ""
    echo "METHOD 2 - Use Android Studio:"
    echo "  1. Open Android Studio → Tools → Device Manager"
    echo "  2. Start a medium phone emulator (Pixel 5, Pixel 6, etc.)"
    echo "  3. Then run: flutter run"
    echo ""
    exit 1
fi

# Set up environment
export ANDROID_HOME="$ANDROID_SDK"
export PATH="$PATH:$ANDROID_SDK/emulator"
export PATH="$PATH:$ANDROID_SDK/platform-tools"
export PATH="$PATH:$ANDROID_SDK/tools"
export PATH="$PATH:$ANDROID_SDK/tools/bin"

EMULATOR_CMD="$ANDROID_SDK/emulator/emulator"
ADB_CMD="$ANDROID_SDK/platform-tools/adb"

# Check if emulator exists
if [ ! -f "$EMULATOR_CMD" ]; then
    echo "❌ Emulator not found at: $EMULATOR_CMD"
    echo ""
    echo "💡 Please use Flutter's emulator command instead:"
    echo "  flutter emulators"
    echo "  flutter emulators --launch <emulator_id>"
    echo "  flutter run"
    exit 1
fi

echo ""
echo "📋 Available Android Virtual Devices:"
"$EMULATOR_CMD" -list-avds

echo ""
echo "🔍 Looking for a suitable medium phone emulator..."

# Get list of AVDs
AVDS=$("$EMULATOR_CMD" -list-avds)

# Try to find a medium phone emulator
MEDIUM_AVD=""

# Common medium phone names to look for
for avd in $(echo "$AVDS"); do
    if [[ "$avd" =~ (Medium|medium|Pixel|pixel|API) ]]; then
        MEDIUM_AVD=$avd
        break
    fi
done

if [ -z "$MEDIUM_AVD" ]; then
    echo "⚠️  No medium phone emulator found automatically."
    echo ""
    echo "📱 Available emulators:"
    echo "$AVDS"
    echo ""

    # Take the first available AVD
    FIRST_AVD=$(echo "$AVDS" | head -n 1)

    if [ -z "$FIRST_AVD" ]; then
        echo "❌ No emulators found!"
        echo ""
        echo "💡 Please create one using Android Studio:"
        echo "   Tools → Device Manager → Create Device"
        echo "   Then select a medium phone like 'Pixel 5' with API 33 or 34"
        exit 1
    fi

    echo "🎯 Using first available emulator: $FIRST_AVD"
    MEDIUM_AVD=$FIRST_AVD
else
    echo "✅ Found suitable emulator: $MEDIUM_AVD"
fi

echo ""
echo "🚀 Starting emulator: $MEDIUM_AVD"
echo "⏳ This may take 30-60 seconds..."
echo ""

# Start emulator in background
"$EMULATOR_CMD" -avd "$MEDIUM_AVD" > /dev/null 2>&1 &
EMULATOR_PID=$!

echo "⏳ Waiting for device to boot..."
"$ADB_CMD" wait-for-device

# Wait a bit more for the system to fully boot
echo "⏳ Waiting for system to fully boot..."
sleep 15

# Check if emulator is actually running
if ! ps -p $EMULATOR_PID > /dev/null 2>&1; then
    echo "⚠️  Emulator may have failed to start"
fi

echo ""
echo "📱 Connected devices:"
flutter devices

echo ""
echo "🎨 Running CoffeeFlow app..."
echo ""

# Run the Flutter app
flutter run

