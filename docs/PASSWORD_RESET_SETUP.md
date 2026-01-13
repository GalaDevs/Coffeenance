# Password Reset Deep Link Setup

## ✅ Code Changes Made

The following files were updated to support password reset deep links:

### 1. Android Deep Links (`android/app/src/main/AndroidManifest.xml`)
- Added `coffeenance://reset-password` intent filter
- Added catch-all `coffeenance://` scheme handler
- Updated HTTPS handler with proper path prefix

### 2. iOS Deep Links (`ios/Runner/Info.plist`)
- Enabled `FlutterDeepLinkingEnabled`
- URL scheme `coffeenance://` already configured

### 3. Deep Link Handling (`lib/main.dart`)
- Added Supabase auth state listener for `passwordRecovery` event
- Improved deep link parsing for fragment parameters
- Added token handling for recovery flow

---

## 🔧 Supabase Dashboard Configuration (REQUIRED)

You need to configure the redirect URL in Supabase Dashboard:

### Step 1: Go to Supabase Dashboard
🔗 https://supabase.com/dashboard/project/tpejvjznleoinsanrgut

### Step 2: Configure Redirect URLs
1. Click **Authentication** in the left sidebar
2. Click **URL Configuration**
3. Add these URLs to **Redirect URLs**:

```
coffeenance://reset-password
coffeenance://verify-email
coffeenance://
```

### Step 3: Update Email Templates (Optional)
1. Go to **Authentication** → **Email Templates**
2. Click **Reset Password**
3. Make sure the `{{ .ConfirmationURL }}` is used in the template

The default template should work, but verify it contains a button/link with:
```html
<a href="{{ .ConfirmationURL }}">Reset Password</a>
```

---

## 📱 Testing Password Reset

### On iOS Simulator:
```bash
# Run the app
flutter run -d iPhone

# Test the deep link (in another terminal)
xcrun simctl openurl booted "coffeenance://reset-password"
```

### On Android Emulator:
```bash
# Run the app
flutter run -d android

# Test the deep link (in another terminal)
adb shell am start -W -a android.intent.action.VIEW -d "coffeenance://reset-password"
```

### Full Flow Test:
1. Open the app and go to login screen
2. Tap "Forgot Password"
3. Enter your email
4. Check your email inbox
5. Click the "Reset Password" button in the email
6. App should open to the Reset Password screen
7. Enter new password and confirm

---

## ⚠️ Troubleshooting

### Email link opens browser instead of app

**Cause**: Redirect URL not configured in Supabase

**Fix**: Add `coffeenance://reset-password` to Supabase → Authentication → URL Configuration → Redirect URLs

### "Session expired" error on reset screen

**Cause**: Token wasn't properly exchanged

**Fix**: Make sure you're clicking the link on the same device where the app is installed. The link should open the app directly.

### Link doesn't work at all

**Cause**: App not properly rebuilt after manifest changes

**Fix**: Run these commands:
```bash
cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance
flutter clean
flutter pub get
flutter run
```

---

## 🔍 Debug Logging

The app now logs detailed deep link information. Check the debug console for:
- `📩 Initial deep link:` - When app opens from a link
- `🔗 Processing deep link:` - When parsing the URL
- `🔐 Password reset deep link detected` - When reset flow is triggered
- `🔔 Auth state change: passwordRecovery` - When Supabase fires recovery event
