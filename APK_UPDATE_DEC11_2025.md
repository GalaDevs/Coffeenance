# APK Update - December 11, 2025

## 🔄 What's New in This Release

### ✅ Team-Based Data Sync Fix (Major Update)

**Issue Fixed**: Staff and managers can now see their admin's transactions in real-time.

**Root Cause**: Previous migration (`20251209000004_nuclear_fix_owner_rls.sql`) used owner-only RLS policies that prevented team data sharing.

**Solution Applied**: Restored team-based isolation using `admin_id` policies via migration `20251211000001_restore_team_based_rls.sql`.

---

## 📱 APK Details

**File Name**: `app-release.apk`
**Location**: `/build/app/outputs/flutter-apk/app-release.apk`
**Version**: 1.0.0+2
**Build Date**: December 11, 2025

---

## 🔐 How Team-Based RLS Works Now

### Team Structure
```
Admin (admin@example.com)
├── admin_id: NULL
├── Creates transactions with admin_id = their own UUID
│
├── Manager (manager@example.com)
│   ├── admin_id: admin's UUID
│   └── Creates transactions with admin_id = admin's UUID
│
└── Staff (staff@example.com)
    ├── admin_id: admin's UUID
    └── Creates transactions with admin_id = admin's UUID
```

### Data Visibility (After This Update)
- ✅ **Admin** sees: ALL team transactions (where `admin_id` = their UUID)
- ✅ **Manager** sees: ALL team transactions (where `admin_id` = their admin's UUID)
- ✅ **Staff** sees: ALL team transactions (where `admin_id` = their admin's UUID)
- ✅ **Different admins**: Cannot see each other's team data

### RLS Policy Logic
```sql
-- SELECT: All team members can see team data
CREATE POLICY "team_select_transactions"
ON transactions FOR SELECT
USING (admin_id = get_current_user_admin_id());

-- Helper function returns:
-- - For admin: their own UUID
-- - For manager/staff: their admin_id field value
```

---

## 🚀 Installation Instructions

### Method 1: Direct APK Install (Recommended)
1. Build completes → APK saved to `build/app/outputs/flutter-apk/app-release.apk`
2. Transfer APK to your Android device
3. Enable "Install from Unknown Sources" in device settings
4. Tap the APK to install
5. Accept permissions

### Method 2: ADB Install
```bash
# Connect Android device via USB
adb devices

# Install APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Or force reinstall if already installed
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## ✅ Testing the Fix

### Test Scenario 1: Admin Creates Transaction
1. Login as admin
2. Create a new transaction
3. Expected: Transaction appears in admin's list ✅

### Test Scenario 2: Manager Sees Admin's Data
1. Login as manager (who belongs to admin's team)
2. View transactions list
3. Expected: See ALL transactions created by admin + other team members ✅

### Test Scenario 3: Staff Sees Admin's Data
1. Login as staff (who belongs to admin's team)
2. View transactions list
3. Expected: See ALL transactions created by admin + other team members ✅

### Test Scenario 4: Different Admin (Isolation Test)
1. Login as a different admin (rod2@gmail.com)
2. View transactions list
3. Expected: See ONLY their own team's transactions, NOT rod@gmail.com's team ✅

### Test Scenario 5: Realtime Sync
1. Have 2 devices: one as admin, one as staff
2. Admin creates transaction
3. Expected: Staff device shows new transaction immediately ✅

---

## 🔧 Technical Changes Included

### Database Migration
- **Applied**: `20251211000001_restore_team_based_rls.sql`
- **Dropped policies**: `strict_owner_*` (4 policies)
- **Created policies**: `team_*_transactions` (4 policies using `admin_id`)
- **Helper function**: `get_current_user_admin_id()` recreated

### RLS Policies
```sql
✅ team_select_transactions    - SELECT using admin_id
✅ team_insert_transactions    - INSERT with admin_id validation
✅ team_update_transactions    - UPDATE using admin_id
✅ team_delete_transactions    - DELETE using admin_id
```

### App Code
- No code changes required
- Supabase service automatically uses new RLS policies
- Realtime subscriptions work with team-based policies

---

## 📊 Performance Impact

- **Query Performance**: Improved (uses indexed `admin_id` column)
- **Realtime Updates**: No change (still instant)
- **Data Transfer**: No change (same amount of data)
- **Battery Usage**: No change

---

## 🐛 Known Issues (Fixed)

### Before This Update
- ❌ Staff only sees their own transactions
- ❌ Manager only sees their own transactions
- ❌ Admin sees all team data (working)
- ❌ Realtime updates only for own transactions

### After This Update
- ✅ Staff sees all team transactions
- ✅ Manager sees all team transactions
- ✅ Admin sees all team data
- ✅ Realtime updates for all team transactions

---

## 🆘 Troubleshooting

### Issue: "Still seeing only my own transactions"

**Possible Cause**: Staff/manager missing `admin_id` field

**Solution**: Update in Supabase Dashboard
```sql
-- Find admin's UUID
SELECT id, email FROM user_profiles WHERE role = 'admin';

-- Update staff/manager
UPDATE user_profiles 
SET admin_id = '<ADMIN_UUID_HERE>'
WHERE email = 'staff@example.com';
```

### Issue: "Permission denied when creating transaction"

**Possible Cause**: RLS policies not applied

**Solution**: Re-run migration
```bash
cd /Applications/XAMPP/xamppfiles/htdocs/Coffeenance
supabase db push
```

### Issue: "Seeing other admin's transactions"

**Possible Cause**: Incorrect `admin_id` on transactions

**Solution**: Fix transaction data
```sql
UPDATE transactions
SET admin_id = (
    SELECT COALESCE(admin_id, id) 
    FROM user_profiles 
    WHERE user_profiles.id = transactions.owner_id
);
```

---

## 📝 Changelog

### Version 1.0.0+2 (December 11, 2025)

**Added**:
- Team-based data synchronization for staff and managers

**Fixed**:
- Staff and managers can now see admin's transactions
- Realtime updates now work for entire team
- Data isolation between different admin teams maintained

**Changed**:
- RLS policies from owner-only to team-based using `admin_id`
- Helper function `get_current_user_admin_id()` recreated

**Technical**:
- Migration `20251211000001_restore_team_based_rls.sql` applied
- 4 new team-based RLS policies created
- 4 old owner-only policies removed

---

## 📚 Related Documentation

- `/docs/TEAM_DATA_SYNC_FIX.md` - Complete fix explanation
- `/docs/RLS_FIX_COMPLETE_DEC11.md` - Applied changes summary
- `/supabase/migrations/20251211000001_restore_team_based_rls.sql` - Migration file
- `/supabase/verify_team_structure.sql` - Verification queries

---

## ✅ Build Information

**Build Command**: `flutter build apk --release`
**Clean Build**: Yes (ran `flutter clean` before build)
**Dependencies Updated**: Yes (ran `flutter pub get`)
**Build Type**: Release (optimized, signed)
**Target Platform**: Android (ARM64, ARMv7, x86_64)

---

## 🎉 Success Indicators

After installing this APK, you should see:

✅ Staff login → See all team transactions
✅ Manager login → See all team transactions
✅ Admin login → See all team transactions
✅ Different admin login → See only their team's data
✅ Create transaction → All team sees it immediately
✅ Realtime updates working for entire team
✅ No permission errors
✅ Data stays isolated between different admin teams

---

**Enjoy the updated app with full team collaboration! 🚀**
