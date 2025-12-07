# 🚀 FIXED: Running CoffeeFlow on Medium Phone Emulator

## ⚡ SOLUTION - Use Flutter's Built-in Commands

Since the Android SDK emulator is not in your PATH, use Flutter's commands instead:

---

## Method 1: Quick Auto-Launch (RECOMMENDED)

```bash
cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance/flutter_coffeeflow
chmod +x run_simple.sh
./run_simple.sh
```

This script will automatically find and launch an emulator, then run your app.

---

## Method 2: Manual Steps (Most Reliable)

### Step 1: Check what emulators you have
```bash
cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance/flutter_coffeeflow
flutter emulators
```

You'll see output like:
```
2 available emulators:

• Pixel_5_API_34 • Pixel 5 API 34
• Medium_Phone • Medium Phone
```

### Step 2: Launch an emulator
Copy the emulator ID (e.g., `Pixel_5_API_34`) and run:

```bash
flutter emulators --launch Pixel_5_API_34
```

Replace `Pixel_5_API_34` with your actual emulator ID from step 1.

### Step 3: Wait for boot
Give it 30-60 seconds to fully boot up. You'll see the emulator window appear.

### Step 4: Run the app
```bash
flutter run
```

**Done!** ✅ Your app should now install and run on the emulator.

---

## Method 3: Let Flutter Auto-Detect

If you already have an emulator running:

```bash
cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance/flutter_coffeeflow
flutter run
```

Flutter will automatically find and use the running emulator.

---

## Method 4: Run on Chrome (Fastest for Testing)

If you just want to test the app quickly:

```bash
cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance/flutter_coffeeflow
flutter run -d chrome
```

This will open the app in your Chrome browser - much faster than waiting for an emulator!

---

## 🆘 Don't Have Any Emulators Yet?

### Create one in Android Studio:

1. Open **Android Studio**
2. Click **Tools** → **Device Manager**
3. Click the **"+"** button or **"Create Device"**
4. Choose **Phone** category
5. Select **Pixel 5** (medium phone)
6. Click **Next**
7. Select an **API level** (choose 33 or 34 if available)
8. Click **Next** → **Finish**

Now go back and run Method 2 above!

---

## 📝 Alternative Scripts I Created

1. **run_simple.sh** - Auto-launches first available emulator
2. **quick_start.sh** - Shows you the commands to run
3. **find_android_sdk.sh** - Helps locate your Android SDK

---

## 🎯 Recommended: Run These Commands Now

```bash
cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance/flutter_coffeeflow

# See what emulators you have
flutter emulators

# Launch one (replace with your emulator ID)
flutter emulators --launch <YOUR_EMULATOR_ID>

# Wait 30-60 seconds, then run
flutter run
```

---

## 💡 Pro Tip: Run on Chrome First

The fastest way to test:

```bash
cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance/flutter_coffeeflow
flutter run -d chrome --web-port=8083
```

Open: http://localhost:8083

No emulator needed! Perfect for UI testing.

---

## ✅ Quick Command Reference

```bash
# List emulators
flutter emulators

# Launch specific emulator
flutter emulators --launch <emulator_id>

# Run app (auto-detect device)
flutter run

# Run on Chrome
flutter run -d chrome

# List all connected devices
flutter devices

# Run on specific device
flutter run -d <device_id>
```

---

## What Went Wrong?

The `emulator` command wasn't in your system PATH. Instead of fixing the PATH, we're using Flutter's built-in emulator commands which work without requiring PATH configuration.

**Next steps:** Run the commands in Method 2 above! 🚀

