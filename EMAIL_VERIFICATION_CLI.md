# 📧 Email Verification CLI Usage Guide

## ✅ Implementation Complete!

Email verification has been successfully integrated using CLI-ready scripts.

---

## 🚀 Quick Commands

### 1. Run App
```bash
./email_verify_cli.sh run
```

### 2. Test Deep Link
```bash
./email_verify_cli.sh test-link
```

### 3. Check Configuration
```bash
./email_verify_cli.sh check
```

### 4. Open Supabase Dashboard
```bash
./email_verify_cli.sh supabase
```

### 5. Manually Verify Email
```bash
./email_verify_cli.sh verify user@example.com
```

---

## 🧪 Full Test Script

Use the interactive test menu:

```bash
./test_email_verification.sh
```

Options:
1. 🚀 Run app on iOS Simulator
2. 🔗 Test deep link on iOS Simulator  
3. 📧 Verify Supabase email configuration
4. 🔍 Check deep link configuration
5. 📱 List available devices
6. 🧹 Clean and rebuild
7. 📦 Build release APK
8. 🏗️ Build iOS release
9. 🌐 Run on Chrome (web)

---

## 📱 Manual Commands

### Run on Specific Device
```bash
flutter run -d "iPhone 17"
flutter run -d chrome
flutter run -d macos
```

### Test Deep Link (iOS)
```bash
# Boot simulator
xcrun simctl boot "iPhone 17"

# Open deep link
xcrun simctl openurl booted "coffeenance://verify-email?token=test"
```

### Test Deep Link (Android)
```bash
adb shell am start -W -a android.intent.action.VIEW \
  -d "coffeenance://verify-email" com.example.coffeeflow
```

### Check Configuration
```bash
# Android manifest
grep -A 5 "coffeenance" android/app/src/main/AndroidManifest.xml

# iOS Info.plist
grep -A 5 "coffeenance" ios/Runner/Info.plist

# Package installed
grep "app_links" pubspec.yaml
```

---

## 🔧 Supabase Configuration (CLI)

### Step 1: Enable Email Confirmation

Open dashboard:
```bash
open "https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/providers"
```

Enable: ☑ **Confirm email**

### Step 2: Configure Redirect URLs

Open URL configuration:
```bash
open "https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/url-configuration"
```

Add these URLs:
- `coffeenance://verify-email`
- `coffeenance://**`
- `https://tpejvjznleoinsanrgut.supabase.co/**`

Site URL: `coffeenance://verify-email`

### Step 3: Manual Email Verification (SQL)

Open SQL Editor:
```bash
open "https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/sql/new"
```

Run:
```sql
UPDATE auth.users 
SET email_confirmed_at = NOW() 
WHERE email = 'user@example.com';
```

Or use the helper:
```bash
./email_verify_cli.sh verify user@example.com
```

---

## 🐛 Troubleshooting

### Issue: "No devices found"

**Check devices:**
```bash
flutter devices
```

**List iOS simulators:**
```bash
xcrun simctl list devices | grep iPhone
```

**Boot simulator:**
```bash
xcrun simctl boot "iPhone 17"
```

### Issue: "Deep link not opening"

**iOS:**
```bash
# Check if configured
./email_verify_cli.sh check

# Test manually
xcrun simctl openurl booted "coffeenance://verify-email"
```

**Android:**
```bash
# Verify intent filter
adb shell dumpsys package com.example.coffeeflow | grep coffeenance
```

### Issue: Build failures

**Clean and rebuild:**
```bash
flutter clean
flutter pub get
flutter run -d "iPhone 17"
```

**Or use the script:**
```bash
./test_email_verification.sh
# Select option 6: Clean and rebuild
```

---

## 📦 Build Release

### Android APK
```bash
flutter build apk --release

# Find at: build/app/outputs/flutter-apk/app-release.apk
```

### iOS
```bash
flutter build ios --release
```

---

## ✅ Testing Checklist

Run these commands to verify everything works:

```bash
# 1. Check configuration
./email_verify_cli.sh check

# 2. Run app
./email_verify_cli.sh run

# 3. Register a test user (in app)
# Use a real email address

# 4. Check email and click verification link

# 5. Test deep link manually (optional)
./email_verify_cli.sh test-link

# 6. Open Supabase to verify user
./email_verify_cli.sh supabase
```

---

## 📚 Documentation Files

- `EMAIL_VERIFICATION_APPLIED.md` - Summary of changes
- `docs/EMAIL_VERIFICATION_COMPLETE.md` - Full guide
- `EMAIL_VERIFICATION_QUICK_REF.md` - Quick reference
- `supabase/check_email_verification.sql` - SQL queries

---

## 🎯 Quick Start

```bash
# Make scripts executable
chmod +x email_verify_cli.sh
chmod +x test_email_verification.sh

# Run interactive test
./test_email_verification.sh

# Or use quick commands
./email_verify_cli.sh run
./email_verify_cli.sh test-link
./email_verify_cli.sh check
```

---

**Need Help?**

```bash
# Show commands
./email_verify_cli.sh

# Check configuration
./email_verify_cli.sh check

# Open Supabase dashboard
./email_verify_cli.sh supabase
```

✨ **Email verification is ready to use!**
