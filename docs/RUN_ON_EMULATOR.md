# 📱 Running CoffeeFlow on Medium Phone Emulator

## Quick Start (Choose One Method)

### Method 1: Automated Script (Recommended)
Open your Terminal and run:

```bash
cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance/flutter_coffeeflow
chmod +x run_medium_phone.sh
./run_medium_phone.sh
```

This script will:
- Find available Android emulators
- Launch a suitable medium phone emulator
- Wait for it to boot
- Run the Flutter app automatically

---

### Method 2: Manual Steps

#### Step 1: Check Available Emulators
```bash
cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance/flutter_coffeeflow
flutter emulators
```

Or:
```bash
emulator -list-avds
```

#### Step 2: Launch an Emulator
If you see a medium phone emulator in the list:
```bash
flutter emulators --launch <emulator_id>
```

Or use the Android emulator command:
```bash
emulator -avd <emulator_name>
```

#### Step 3: Run the App
Wait for the emulator to fully boot (30-60 seconds), then:
```bash
flutter run
```

---

### Method 3: Use Android Studio
1. Open Android Studio
2. Click **Tools** → **Device Manager**
3. Find or create a medium phone (e.g., Pixel 5, Medium Phone)
4. Click the **Play** button to start it
5. In Terminal, run:
   ```bash
   cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance/flutter_coffeeflow
   flutter run
   ```

---

## Creating a New Medium Phone Emulator

If you don't have a medium phone emulator:

### Option A: Using Android Studio (GUI)
1. Open Android Studio
2. Tools → Device Manager
3. Click "+" or "Create Device"
4. Select **Phone** category
5. Choose **Pixel 5** or **Medium Phone**
6. Click **Next**
7. Select an API level (recommended: **API 33** or **API 34**)
8. Click **Next** and then **Finish**

### Option B: Using Command Line
```bash
# List available system images
sdkmanager --list | grep system-images

# Download a system image (if needed)
sdkmanager "system-images;android-34;google_apis;x86_64"

# Create AVD
avdmanager create avd -n Medium_Phone_API_34 \
  -k "system-images;android-34;google_apis;x86_64" \
  -d "pixel_5"
```

---

## Troubleshooting

### Emulator not found?
Make sure Android SDK is installed and in your PATH:
```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

Add these to your `~/.zshrc` file to make them permanent.

### Flutter not finding the device?
```bash
# Check connected devices
flutter devices

# Check ADB devices
adb devices

# Restart ADB if needed
adb kill-server
adb start-server
```

### App not installing?
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

---

## Quick Command Reference

```bash
# Navigate to project
cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance/flutter_coffeeflow

# List emulators
flutter emulators

# Launch specific emulator
flutter emulators --launch <emulator_id>

# List AVDs
emulator -list-avds

# Start AVD
emulator -avd <avd_name>

# Run app
flutter run

# Run on specific device
flutter run -d <device_id>

# Run in debug mode (default)
flutter run

# Run in release mode (faster)
flutter run --release
```

