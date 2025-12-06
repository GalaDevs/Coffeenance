# APK Supabase Connection Fix

## Issue
The APK shows: `Failed host lookup: 'tpejvjznleoinsanrgut.supabase.co'`

## ✅ Fixed
1. **Internet Permissions** - Added to AndroidManifest.xml
2. **APK Rebuilt** - Located at `build/app/outputs/flutter-apk/app-release.apk`

## ⚠️ Still Need to Fix: Supabase Anon Key

Your current anon key looks incorrect:
```
sb_publishable_91ARAF5ONwbPSAdtqa7Emg_seW4F75r
```

**Valid Supabase anon keys should:**
- Start with `eyJ`
- Be much longer (JWT token format)
- Look like: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3...` (example)

## How to Get the Correct Anon Key

1. **Go to Supabase Dashboard:**
   ```
   https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/settings/api
   ```

2. **Copy the "anon public" key** from the "Project API keys" section

3. **Update the key in:**
   ```
   lib/config/supabase_config.dart
   ```
   
   Replace:
   ```dart
   static const String supabaseAnonKey = 'sb_publishable_91ARAF5ONwbPSAdtqa7Emg_seW4F75r';
   ```
   
   With:
   ```dart
   static const String supabaseAnonKey = 'eyJhb...YOUR_REAL_KEY...';
   ```

4. **Rebuild the APK:**
   ```bash
   flutter build apk --release
   ```

## Test Connection

After updating the key and rebuilding, the app should connect successfully to Supabase without the hostname lookup error.

## Current APK Location
```
/Applications/XAMPP/xamppfiles/htdocs/Coffeenance/build/app/outputs/flutter-apk/app-release.apk
```

Size: 55.3 MB
