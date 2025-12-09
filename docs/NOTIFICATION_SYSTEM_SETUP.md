# Transaction Management with Notifications - Setup Guide

## 🎯 Overview

This feature adds role-based transaction management with real-time notifications:

### Role Permissions:
- **Admin**: Full access - can edit and delete transactions immediately
- **Manager**: Can edit and delete, but deletions notify the admin
- **Staff**: Can request edits (requires approval), cannot delete

---

## 📋 Setup Instructions

### Step 1: Apply SQL Migration to Supabase

1. Open your Supabase Dashboard SQL Editor:
   ```
   https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/sql/new
   ```

2. Copy the entire contents of this file:
   ```
   /supabase/migrations/20251209000001_create_notification_system.sql
   ```

3. Paste into the SQL Editor and click **RUN**

4. Verify the tables were created:
   ```sql
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name IN ('notifications', 'pending_transaction_edits');
   ```

### Step 2: Rebuild the APK

Run the following commands to build a fresh APK with the new features:

```bash
cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance
flutter clean
flutter pub get
flutter build apk --release
```

The new APK will be at:
```
/Applications/XAMPP/xamppfiles/htdocs/Coffeenance/build/app/outputs/flutter-apk/app-release.apk
```

---

## ✨ Features Implemented

### 1. **Notification System**
- Real-time notification badge next to profile icon
- Notifications for:
  - Transaction deletions by managers
  - Edit requests from staff
  - Edit approvals/rejections
- Notification center with tabs for notifications and pending approvals

### 2. **Transaction Edit/Delete Actions**
Each transaction card now shows action buttons:

#### For Admin:
- **Edit** button - edits immediately
- **Delete** button - deletes immediately

#### For Manager:
- **Edit** button - edits immediately
- **Delete** button - deletes and notifies admin

#### For Staff:
- **Request Edit** button - creates pending edit for approval
- No delete button

### 3. **Pending Edits Dashboard** (Admin/Manager Only)
- View all pending edit requests
- See before/after comparison
- Approve or reject with optional reason
- Staff receives notifications of approval/rejection status

### 4. **Real-time Updates**
- Notifications appear instantly when created
- Pending edits update in real-time
- Badge count updates automatically

---

## 🎨 UI Components Added

### New Screens:
1. **NotificationsScreen** (`lib/screens/notifications_screen.dart`)
   - Tabbed interface for notifications and pending approvals
   - Mark as read functionality
   - Visual diff for edit requests

### Updated Screens:
1. **DashboardScreen** - Added notification badge icon
2. **TransactionsScreen** - Added edit/delete buttons to cards
3. **RevenueScreen** - Added edit/delete buttons to cards

### New Models:
1. **AppNotification** (`lib/models/notification.dart`)
2. **PendingTransactionEdit** (`lib/models/pending_transaction_edit.dart`)

### New Services:
1. **NotificationService** (`lib/services/notification_service.dart`)

### New Providers:
1. **NotificationProvider** (`lib/providers/notification_provider.dart`)

---

## 🔧 How It Works

### For Staff Members:
1. Staff member clicks **"Request Edit"** on a transaction
2. An edit dialog appears to modify the transaction details
3. Changes are saved as a pending edit (not applied yet)
4. Admin and managers receive a notification
5. Staff waits for approval/rejection
6. Upon approval, the transaction is updated; upon rejection, staff is notified

### For Managers:
1. Manager can edit transactions immediately (no approval needed)
2. Manager can delete transactions
3. When manager deletes a transaction, admin receives a notification with:
   - Transaction amount
   - Description
   - Date
   - Who deleted it

### For Admins:
1. Admin has full control - can edit and delete without restrictions
2. Admin receives notifications when:
   - Managers delete transactions
   - Staff request edits
3. Admin can approve or reject edit requests
4. Admin can view all pending edits in the notification center

---

## 📱 User Interface

### Notification Badge
Located next to the profile icon in the Dashboard:
- Shows total count of unread notifications + pending approvals
- Red badge for notifications
- Orange badge for pending approvals
- Tap to open notification center

### Transaction Cards
Each transaction now has action buttons at the bottom:
- **Edit/Request Edit** button (blue)
- **Delete** button (red, admin/manager only)

### Notification Center
Two tabs:
1. **Notifications** - All notifications with timestamps
2. **Pending Approvals** - Edit requests with before/after comparison

---

## 🔐 Database Structure

### Tables Created:
1. **notifications**
   - Stores all user notifications
   - Types: transaction_deleted, edit_request, edit_approved, edit_rejected
   - Has `is_read` flag for tracking read status

2. **pending_transaction_edits**
   - Stores pending edit requests from staff
   - Contains original and edited data in JSONB format
   - Status: pending, approved, rejected
   - Tracks who reviewed and when

### Security:
- Row Level Security (RLS) policies enforce data isolation
- Users can only see notifications meant for them
- Admins/managers can only approve edits for their organization
- All operations respect the multi-tenant owner_id structure

---

## 🚀 Testing the Feature

### Test as Staff:
1. Login as a staff user
2. Go to Transactions or Revenue screen
3. Click **"Request Edit"** on any transaction
4. Modify some fields and save
5. Check that you see a success message: "Edit request sent for approval"

### Test as Manager:
1. Login as a manager
2. Go to Dashboard and click the notification bell (if there's a badge)
3. Click "Pending Approvals" tab
4. Approve or reject the staff's edit request
5. Try deleting a transaction - confirm admin is notified

### Test as Admin:
1. Login as admin
2. Check notification badge - you should see the manager's deletion notification
3. Click notification bell to view details
4. Also check Pending Approvals tab for any staff edit requests
5. Test approving/rejecting edit requests

---

## 📊 Notification Types

| Type | Trigger | Recipient | Icon |
|------|---------|-----------|------|
| `transaction_deleted` | Manager deletes transaction | Admin | 🗑️ Red |
| `edit_request` | Staff requests edit | Admin + Managers | ✏️ Orange |
| `edit_approved` | Admin/Manager approves edit | Staff member | ✅ Green |
| `edit_rejected` | Admin/Manager rejects edit | Staff member | ❌ Red |

---

## 🎯 Next Steps

1. **Apply the SQL migration** to create the notification tables
2. **Rebuild the APK** with the new features
3. **Test thoroughly** with different user roles
4. **Monitor** the notification system in production

---

## 💡 Tips

- Notifications are stored permanently until manually deleted (future enhancement)
- The badge count is updated in real-time via Supabase realtime subscriptions
- Pending edits show a visual diff (red for removed, green for added)
- All operations are logged for audit purposes
- The system gracefully handles offline scenarios

---

## 🐛 Troubleshooting

### Notifications not appearing?
- Check that Supabase migration was applied successfully
- Verify realtime subscriptions are working
- Check RLS policies allow the current user to access notifications

### Badge count not updating?
- Ensure NotificationProvider is initialized in main.dart
- Check that realtime subscriptions are active
- Verify network connectivity

### Edit requests not working for staff?
- Confirm user role is correctly set in user_profiles table
- Check pending_transaction_edits table RLS policies
- Verify owner_id is correctly set for the user

---

## 📝 Files Modified/Created

### Created:
- `lib/models/notification.dart`
- `lib/models/pending_transaction_edit.dart`
- `lib/services/notification_service.dart`
- `lib/providers/notification_provider.dart`
- `lib/screens/notifications_screen.dart`
- `supabase/migrations/20251209000001_create_notification_system.sql`

### Modified:
- `lib/main.dart` - Added NotificationProvider
- `lib/providers/transaction_provider.dart` - Added role-based methods
- `lib/screens/dashboard_screen.dart` - Added notification badge
- `lib/screens/transactions_screen.dart` - Added edit/delete buttons
- `lib/screens/revenue_screen.dart` - Added edit/delete buttons

---

✅ **Setup Complete!** Your notification system is ready to use.
