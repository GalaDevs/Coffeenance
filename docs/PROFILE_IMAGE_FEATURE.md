# Profile Image Upload Feature

## Overview

Users can now upload a profile picture (up to 5MB) during account registration. The profile image replaces the default coffee icon in the dashboard.

## Features

### 1. Image Upload During Registration ✅
- **Optional** profile picture upload
- **Maximum size**: 5MB
- **Format**: JPG, PNG (automatically converted to JPG)
- **Resolution**: Automatically resized to 1024x1024 for optimal performance
- Image preview before registration

### 2. Profile Image Display ✅
- Shows uploaded image in dashboard header
- Falls back to default icon if no image uploaded
- Falls back gracefully if image fails to load
- Circular display with consistent sizing

### 3. Storage & Security ✅
- Images stored in Supabase Storage (`profiles` bucket)
- Public read access for profile images
- Users can only upload/modify their own images
- URL stored in `user_profiles.profile_image_url` column

## How It Works

### User Flow

1. **Registration**:
   - User clicks "Create Account" on login screen
   - Fills in coffee shop name, name, email, and password
   - **Optional**: Tap the circular placeholder to select image from gallery
   - Image must be under 5MB
   - Preview image before submitting
   - Can remove image before submitting
   - Click "Register"

2. **Image Upload**:
   - Image is uploaded to Supabase Storage
   - File named: `{user_id}_{timestamp}.jpg`
   - Stored in: `profiles/profile_images/` folder
   - Public URL generated and saved to database

3. **Display**:
   - Dashboard shows profile image in top-right
   - Circular avatar format (48x48 pixels)
   - Seamless fallback to default icon

## Implementation Details

### Files Modified

1. **`lib/models/user_profile.dart`**
   - Added `profileImageUrl` field
   - Updated `fromJson`, `toJson`, and `copyWith` methods

2. **`lib/services/auth_service.dart`**
   - Added `uploadProfileImage()` method
   - Updated `createUser()` to accept `File? profileImage`
   - Handles image upload during registration

3. **`lib/providers/auth_provider.dart`**
   - Updated `createUser()` to accept `File? profileImage`
   - Added import for `dart:io`

4. **`lib/screens/login_screen.dart`**
   - Integrated new `RegisterDialog` widget
   - Removed old inline registration form

5. **`lib/screens/dashboard_screen.dart`**
   - Updated avatar to display profile image
   - Falls back to default icon
   - Uses `Consumer<AuthProvider>` for reactive updates

### Files Created

6. **`lib/widgets/register_dialog.dart`** (NEW)
   - Full registration dialog with image picker
   - Image selection from gallery
   - 5MB size validation
   - Image preview
   - Remove image option
   - Clean, modern UI

7. **`supabase/migrations/20251208000002_add_profile_image_url.sql`** (NEW)
   - Adds `profile_image_url` column to `user_profiles` table
   - Creates `profiles` storage bucket
   - Sets up RLS policies for image access

### Dependencies Added

```yaml
image_picker: ^1.0.7           # Image selection from gallery/camera
cached_network_image: ^3.3.1   # Efficient image loading with caching
```

### Platform Configuration

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to upload your profile picture.</string>
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take your profile picture.</string>
```

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
```

## Database Schema

### `user_profiles` Table Update

```sql
ALTER TABLE user_profiles
ADD COLUMN profile_image_url TEXT;
```

**Field Details**:
- **Type**: TEXT (nullable)
- **Purpose**: Stores the public URL of the user's profile image
- **Format**: `https://{supabase-url}/storage/v1/object/public/profiles/profile_images/{user_id}_{timestamp}.jpg`
- **Optional**: Can be NULL if user didn't upload an image

### Supabase Storage

**Bucket**: `profiles`
- **Public**: Yes (images are publicly accessible via URL)
- **Path**: `profile_images/{user_id}_{timestamp}.jpg`

**RLS Policies**:
- ✅ Anyone can view profile images (public read)
- ✅ Users can only upload to their own folder
- ✅ Users can only update/delete their own images

## Usage Examples

### Registering with Profile Image

```dart
// User taps "Create Account"
// Fills in form
// Taps image placeholder -> selects image from gallery
// Submits registration

// Behind the scenes:
1. Image validated (< 5MB)
2. User account created in Supabase Auth
3. Image uploaded to Storage
4. Profile created with image URL
5. User sees success message
```

### Dashboard Display

```dart
// Dashboard automatically shows profile image
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    final hasImage = authProvider.currentUser?.profileImageUrl != null;
    
    return CircleAvatar(
      backgroundImage: hasImage
          ? NetworkImage(authProvider.currentUser!.profileImageUrl!)
          : AssetImage('assets/icon.png'),
    );
  },
)
```

## Testing

### Test Scenarios

1. **Register without image**:
   - ✅ Should create account successfully
   - ✅ Dashboard shows default icon

2. **Register with image**:
   - ✅ Image under 5MB → Upload succeeds
   - ✅ Dashboard shows uploaded image

3. **Image too large**:
   - ✅ Shows error: "Image must be less than 5MB"
   - ✅ Prevents registration until valid image selected

4. **Network error during upload**:
   - ✅ Account still created
   - ✅ Image upload fails gracefully
   - ✅ User sees default icon

5. **Image load failure**:
   - ✅ Falls back to default icon
   - ✅ No crashes or errors

## Run Migration

To apply the database migration:

```bash
# If using Supabase CLI
supabase db push

# Or manually in Supabase Dashboard:
# 1. Go to SQL Editor
# 2. Paste content of 20251208000002_add_profile_image_url.sql
# 3. Run query
```

## Future Enhancements

Possible improvements:

1. **Edit Profile Image**
   - Allow users to change profile image in Settings
   - Delete old image when uploading new one

2. **Camera Support**
   - Add option to take photo with camera
   - Current implementation only uses gallery

3. **Image Cropping**
   - Add image cropper for better framing
   - Let users adjust image before upload

4. **Compression**
   - Further compress images to reduce storage
   - Optimize for mobile networks

5. **Multiple Sizes**
   - Generate thumbnail versions
   - Different sizes for different UI contexts

## Troubleshooting

### Image not showing in dashboard
- Check Supabase Storage bucket exists
- Verify RLS policies are set correctly
- Check profile_image_url in database
- Verify network connection

### Upload fails
- Check file size (must be < 5MB)
- Verify Supabase Storage is configured
- Check network connection
- Review console logs for errors

### Permission errors (iOS)
- Ensure Info.plist has required usage descriptions
- User must grant photo library access

### Permission errors (Android)
- Ensure AndroidManifest.xml has required permissions
- User must grant storage/camera access

## Notes

- Image upload is **optional** - users can skip it
- Default icon still used if no image uploaded
- Images are **public** - anyone with URL can view
- Old images are **not automatically deleted** when user is removed
- Consider implementing image cleanup job for deleted accounts
