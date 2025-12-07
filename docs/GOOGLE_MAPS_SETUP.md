# Google Maps Setup Guide

This guide will help you set up Google Maps for the location picker feature in the Settings screen.

## Features Added

1. **Editable Shop Name** ✅
   - Tap "Shop Name" in Settings → Business Information
   - Enter your coffee shop's name
   - Saves to database automatically

2. **Location Setting Options** ✅
   - **Pick on Map** 🗺️ - Interactive map with drag-and-drop pin (NEW!)
   - **Use Current Location** 📍 - Get GPS coordinates automatically
   - **Enter Address** ✍️ - Type location manually
   - **Open in Maps** 🧭 - View location in external map app

## Setup Instructions

### Step 1: Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Geocoding API** (for address lookup)
4. Create credentials:
   - Go to **APIs & Services → Credentials**
   - Click **Create Credentials → API Key**
   - Copy your API key

### Step 2: Restrict Your API Key (Important for Security)

1. Click on your API key to edit it
2. Under "Application restrictions":
   - For Android: Select "Android apps" and add your package name
   - For iOS: Select "iOS apps" and add your bundle identifier
3. Under "API restrictions":
   - Select "Restrict key"
   - Choose: Maps SDK for Android, Maps SDK for iOS, Geocoding API
4. Save changes

### Step 3: Configure Android

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE"/>
```

Replace `YOUR_ACTUAL_API_KEY_HERE` with your actual API key.

### Step 4: Configure iOS

1. Open `ios/Runner/AppDelegate.swift`
2. Add this import at the top:
   ```swift
   import GoogleMaps
   ```
3. Add this line inside `application(_:didFinishLaunchingWithOptions:)`:
   ```swift
   GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
   ```

**Complete example:**
```swift
import UIKit
import Flutter
import GoogleMaps  // Add this

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")  // Add this
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Step 5: Test the Feature

1. Run the app: `flutter run`
2. Go to **Settings** screen
3. Under **Business Information**, tap **Location**
4. Choose **Pick on Map**
5. You should see an interactive map where you can:
   - Tap anywhere to place a pin
   - Drag the pin to move it
   - Tap the location button (bottom right) to use current GPS location
   - See the address automatically resolve
   - Tap **CONFIRM** to save

## Alternative: Use Without API Key (Limited Functionality)

If you don't want to set up Google Maps right now, the other location options still work:

1. **Use Current Location** - Works with device GPS (no API key needed)
2. **Enter Address** - Manual entry (no API key needed)

The map picker will show an error without an API key, but the other options remain functional.

## Troubleshooting

### Map Shows Gray Screen
- Check that your API key is correctly added
- Verify that Maps SDK is enabled in Google Cloud Console
- Check that your API key has the correct restrictions

### Location Permission Issues
- Make sure you've granted location permissions to the app
- On iOS: Settings → Privacy → Location Services
- On Android: Settings → Apps → Coffeenance → Permissions

### Address Not Resolving
- Enable the Geocoding API in Google Cloud Console
- Check your internet connection

## Cost Information

- Google Maps offers **$200 free credit per month**
- For a small coffee shop app, this is typically more than enough
- Map loads and geocoding requests count toward usage
- See [Google Maps Pricing](https://cloud.google.com/maps-platform/pricing) for details

## Privacy Note

Location data is:
- Only used when you explicitly set your shop's location
- Stored securely in Supabase
- Not shared with third parties
- Can be viewed/edited anytime in Settings
