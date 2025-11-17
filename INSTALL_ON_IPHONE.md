# 📱 Installing Coffeenance on Your iPhone

## ⚠️ Current Issue

Your iPhone "Rhey" is running **iOS 26.1**, but Xcode needs the iOS 26.1 platform components installed.

**Error Message:**
```
iOS 26.1 is not installed. Please download and install the platform 
from Xcode > Settings > Components.
```

---

## 🔧 Solution: Install iOS 26.1 Platform in Xcode

### Method 1: Via Xcode Settings (RECOMMENDED)

1. **Open Xcode**
2. Go to **Xcode** → **Settings** (or press `⌘ + ,`)
3. Click on the **Platforms** tab (or **Components** in older Xcode versions)
4. Look for **iOS 26.1** in the list
5. Click the **Download** or **Get** button next to it
6. Wait for the download to complete (this can take 10-30 minutes depending on your internet speed)
7. Once installed, close Xcode Settings

### Method 2: Via Command Line

```bash
# Install iOS 26.1 platform
xcodebuild -downloadPlatform iOS
```

---

## 🚀 After Installing iOS 26.1 Platform

Once the iOS platform is installed, run this command to install the app on your iPhone:

```bash
cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance
flutter run -d "00008130-000A60402E62001C" --release
```

Or use the simplified version:

```bash
cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance
flutter run -d Rhey --release
```

---

## 📋 Alternative: Use Debug Mode

If you want to test quickly without waiting for the platform download, you can try debug mode (but it may still require the platform):

```bash
cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance
flutter run -d Rhey
```

---

## 🔍 Verify Your Setup

Before installing, check what's available:

```bash
# Check connected devices
flutter devices

# Check iOS setup
flutter doctor -v

# Check Xcode installed platforms
xcodebuild -showsdks
```

---

## 📱 Trust the Developer Certificate on iPhone

**IMPORTANT:** After the app installs, you need to trust the developer certificate on your iPhone:

1. On your iPhone, go to **Settings** → **General** → **VPN & Device Management**
2. Find **"Apple Development: rheysehmac@gmail.com"**
3. Tap on it
4. Tap **"Trust"**
5. Confirm by tapping **"Trust"** again

Without this step, the app won't open on your iPhone!

---

## ✅ Expected Installation Process

Once the platform is installed, you'll see:

```
Launching lib/main.dart on Rhey in release mode...
Developer identity "Apple Development: rheysehmac@gmail.com" selected
Running Xcode build...
Xcode build done.                                            XX.Xs
Installing and launching...                                   X.Xs
🎉 Application installed successfully!
```

The app will automatically launch on your iPhone!

---

## 🐛 Troubleshooting

### "Could not find iPhone" Error
- Make sure your iPhone is unlocked
- Make sure you trust this computer on your iPhone
- Reconnect the USB cable

### "Failed to install" Error
- Check that your iPhone has enough storage space
- Try restarting your iPhone
- Try restarting Xcode

### "Unable to verify app" on iPhone
- You need to trust the developer certificate (see instructions above)

### Build Takes Too Long
- Use `--release` flag for faster builds
- Close other apps on your Mac
- Make sure you have at least 10GB free disk space

---

## 🎉 Once Installed

Your Coffeenance app will appear on your iPhone home screen with the coffee cup icon! 

**Features you can use:**
- ✅ Track revenue and expenses
- ✅ View dashboard with balance
- ✅ Monitor sales by payment method
- ✅ Add transactions with the + button
- ✅ View transaction history
- ✅ Dark mode support
- ✅ All data stored locally on your iPhone

---

## 📚 Next Steps

After successful installation:

1. **Test the app** - Add some sample transactions
2. **Check all screens** - Dashboard, Revenue, Transactions, Settings
3. **Test offline** - The app works without internet
4. **Enable Dark Mode** - Go to Settings tab → toggle theme

---

## 💡 Tips

- The app will remain on your iPhone even after disconnecting from your Mac
- Data is stored locally using SharedPreferences
- To update the app, simply run the flutter command again
- For production release, you'll need to distribute via App Store or TestFlight

---

**Need help?** Check `flutter doctor` for any configuration issues.
