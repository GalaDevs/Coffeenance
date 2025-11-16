#!/bin/bash

# Script to run Flutter app on medium phone emulator

cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance/flutter_coffeeflow

echo "Checking for available emulators..."
flutter emulators

echo ""
echo "Listing Android Virtual Devices..."
emulator -list-avds

echo ""
echo "Starting medium phone emulator..."
# Common medium phone AVD names
AVD_NAME=$(emulator -list-avds | grep -i "medium\|pixel" | head -n 1)

if [ -z "$AVD_NAME" ]; then
    echo "No medium phone emulator found. Available devices:"
    emulator -list-avds
    echo ""
    echo "Creating a medium phone emulator (Pixel 5 API 34)..."
    echo "no" | avdmanager create avd -n "Medium_Phone_API_34" -k "system-images;android-34;google_apis;x86_64" -d "pixel_5"
    AVD_NAME="Medium_Phone_API_34"
fi

echo "Launching emulator: $AVD_NAME"
emulator -avd "$AVD_NAME" &

# Wait for emulator to boot
echo "Waiting for emulator to boot..."
adb wait-for-device

# Give it a bit more time to fully boot
sleep 10

echo "Running Flutter app..."
flutter run

