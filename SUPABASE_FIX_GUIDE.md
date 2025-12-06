# Supabase Connection Fix Guide

## Issue
The app is saving data locally instead of to Supabase cloud because the **anon key** in the configuration is a placeholder.

## Fix Steps

### 1. Get Your Real Anon Key

1. Open your browser and go to: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut
2. Click on **Settings** (gear icon in sidebar)
3. Click on **API** in the settings menu
4. Under **Project API keys**, find the **anon/public** key
5. Click the **Copy** button next to the `anon` key (it starts with `eyJ...`)

### 2. Update the Configuration File

1. Open `lib/config/supabase_config.dart`
2. Replace the fake anon key with your real one:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://tpejvjznleoinsanrgut.supabase.co';
  static const String supabaseAnonKey = 'YOUR_REAL_ANON_KEY_HERE'; // Replace this!
}
```

### 3. Rebuild and Test

```bash
# Build and install to your iPhone
flutter build ios --release && flutter install -d 00008130-000A60402E62001C --release
```

### 4. Verify Connection

1. Open the app on your iPhone
2. Go to **Settings** tab
3. Tap **"Connection Diagnostics"**
4. You should see all green checkmarks ✅

## What to Look For

### Success Messages:
- ✅ Database query successful!
- ✅ Found X transactions in cloud
- ✅ INSERT successful!
- 🎉 ALL TESTS PASSED! Cloud connection working!

### Error Messages to Fix:
- ❌ Error: Invalid API key
- ❌ Error: JWT expired
- ❌ Network error

## Quick Test

After fixing the anon key, try adding a transaction:
1. Go to **Revenue** or **Transactions** tab
2. Add a new entry
3. Check the debug output - you should see:
   - `💾 Attempting to save transaction to Supabase...`
   - `✅ SUCCESS: Transaction saved to CLOUD (Supabase ID: 123)`

Instead of:
   - `❌ CLOUD SAVE FAILED`
   - `⚠️ Falling back to LOCAL-ONLY storage`

## Alternative: Use Environment Variable

For better security, you can use an environment variable instead:

1. Create `.env` file in project root:
```
SUPABASE_URL=https://tpejvjznleoinsanrgut.supabase.co
SUPABASE_ANON_KEY=your_real_anon_key_here
```

2. Add flutter_dotenv to pubspec.yaml
3. Load it in main.dart

But for now, the simple fix above will work!
