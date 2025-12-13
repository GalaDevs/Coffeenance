# Staff/Manager Data Sync Issue - Complete Fix

## 🔴 Problem
Staff and managers are **NOT seeing their admin's transactions**. Each user only sees their own data instead of the entire team's data.

## 🔍 Root Cause
The migration `20251209000004_nuclear_fix_owner_rls.sql` replaced team-based RLS policies with **owner-only policies**:

```sql
-- ❌ WRONG: Only owner can see
USING (owner_id = auth.uid())
```

This broke team data sharing. The correct approach is **team-based isolation using `admin_id`**:

```sql
-- ✅ CORRECT: Team members can see all team data
USING (admin_id = get_current_user_admin_id())
```

## 📋 How It Should Work

### Team Structure
```
Admin (rod@gmail.com)
├── admin_id: NULL (admins don't have an admin)
├── Creates transactions with admin_id = rod_uuid
│
├── Manager (john@manager.com)
│   ├── admin_id: rod_uuid
│   └── Creates transactions with admin_id = rod_uuid
│
└── Staff (jane@staff.com)
    ├── admin_id: rod_uuid
    └── Creates transactions with admin_id = rod_uuid
```

### Data Visibility
- **Admin** sees: All transactions where `admin_id = their own ID`
- **Manager** sees: All transactions where `admin_id = their admin's ID`
- **Staff** sees: All transactions where `admin_id = their admin's ID`

### Data Isolation
Different admins' data stays separate:
- `rod@gmail.com` team: `admin_id = rod_uuid`
- `rod2@gmail.com` team: `admin_id = rod2_uuid`
- These teams **cannot** see each other's data ✅

---

## 🔧 Fix Steps

### Step 1: Run the RLS Fix Migration
```bash
# Apply the team-based RLS fix
psql -f supabase/migrations/20251211000001_restore_team_based_rls.sql
```

Or in **Supabase Dashboard → SQL Editor**:
1. Open `/supabase/migrations/20251211000001_restore_team_based_rls.sql`
2. Copy entire contents
3. Paste into SQL Editor
4. Click **RUN**

### Step 2: Verify Team Structure
```bash
# Check if staff/managers have correct admin_id
psql -f supabase/verify_team_structure.sql
```

Or in **Supabase Dashboard → SQL Editor**:
1. Open `/supabase/verify_team_structure.sql`
2. Copy and run

Expected output:
```
✅ Admin (correct)
✅ Manager (has admin)
✅ Staff (has admin)
```

If you see:
```
❌ Manager missing admin_id!
❌ Staff missing admin_id!
```

Then run **Step 3**.

### Step 3: Fix Missing admin_id (If Needed)
If staff/managers are missing `admin_id`, update them:

```sql
-- Get the admin's ID first
SELECT id, email FROM user_profiles WHERE role = 'admin';

-- Update manager's admin_id
UPDATE user_profiles 
SET admin_id = '<ADMIN_UUID_HERE>'
WHERE email = 'manager@example.com';

-- Update staff's admin_id
UPDATE user_profiles 
SET admin_id = '<ADMIN_UUID_HERE>'
WHERE email = 'staff@example.com';
```

### Step 4: Fix Existing Transactions
All transactions need the correct `admin_id`:

```sql
-- Update transactions created by manager/staff
-- Set admin_id to their team's admin_id
UPDATE transactions
SET admin_id = (
    SELECT COALESCE(admin_id, id) 
    FROM user_profiles 
    WHERE user_profiles.id = transactions.owner_id
)
WHERE admin_id IS NULL OR admin_id != (
    SELECT COALESCE(admin_id, id) 
    FROM user_profiles 
    WHERE user_profiles.id = transactions.owner_id
);
```

### Step 5: Verify Fix Works
Test in the app:

1. **Login as Admin** → Should see ALL team transactions
2. **Login as Manager** → Should see ALL team transactions
3. **Login as Staff** → Should see ALL team transactions
4. **Login as Different Admin** → Should see ONLY their team's data

---

## 🔐 RLS Policy Explanation

### The Helper Function
```sql
CREATE OR REPLACE FUNCTION get_current_user_admin_id()
RETURNS UUID AS $$
DECLARE
    user_admin_id UUID;
    user_role TEXT;
BEGIN
    -- Get current user's role and admin_id
    SELECT role, admin_id INTO user_role, user_admin_id
    FROM user_profiles
    WHERE id = auth.uid();
    
    -- If user is admin, return their own ID
    IF user_role = 'admin' THEN
        RETURN auth.uid();
    END IF;
    
    -- If user is manager/staff, return their admin_id
    RETURN user_admin_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**What it does:**
- For **admin**: Returns their own ID
- For **manager/staff**: Returns their `admin_id`

### The SELECT Policy
```sql
CREATE POLICY "team_select_transactions"
ON public.transactions
FOR SELECT
USING (
    admin_id = get_current_user_admin_id()
);
```

**How it works:**
- **Admin (rod@gmail.com)**:
  - Function returns: `rod_uuid`
  - Query: `WHERE admin_id = rod_uuid`
  - Result: Sees ALL transactions with `admin_id = rod_uuid` ✅
  
- **Manager (john@manager.com, admin_id = rod_uuid)**:
  - Function returns: `rod_uuid` (from their `admin_id` field)
  - Query: `WHERE admin_id = rod_uuid`
  - Result: Sees ALL transactions with `admin_id = rod_uuid` ✅
  
- **Different Admin (rod2@gmail.com)**:
  - Function returns: `rod2_uuid`
  - Query: `WHERE admin_id = rod2_uuid`
  - Result: Sees ONLY `rod2_uuid` team transactions ✅

---

## 🧪 Testing the Fix

### Test 1: Check Policies
```sql
SELECT policyname, cmd, qual 
FROM pg_policies 
WHERE tablename = 'transactions';
```

Should show:
- `team_select_transactions`: `admin_id = get_current_user_admin_id()`
- `team_insert_transactions`: `owner_id = auth.uid() AND admin_id = get_current_user_admin_id()`
- `team_update_transactions`: `admin_id = get_current_user_admin_id()`
- `team_delete_transactions`: `admin_id = get_current_user_admin_id()`

### Test 2: Check Transactions
```sql
-- As admin
SELECT COUNT(*) FROM transactions; -- Should see all team transactions

-- As manager
SELECT COUNT(*) FROM transactions; -- Should see all team transactions

-- As staff
SELECT COUNT(*) FROM transactions; -- Should see all team transactions
```

### Test 3: Verify Isolation
```sql
-- Check that different admins see different data
SELECT 
    admin_id,
    (SELECT email FROM user_profiles WHERE id = admin_id) as admin_email,
    COUNT(*) as transaction_count
FROM transactions
GROUP BY admin_id;
```

---

## 📱 App Behavior After Fix

### Before Fix
- Admin creates transaction → Sees it ✅
- Manager creates transaction → Sees ONLY theirs ❌
- Staff creates transaction → Sees ONLY theirs ❌

### After Fix
- Admin creates transaction → All team sees it ✅
- Manager creates transaction → All team sees it ✅
- Staff creates transaction → All team sees it ✅
- Different admin → Cannot see other team's data ✅

---

## 🚨 Common Issues

### Issue 1: Staff still can't see admin's data
**Cause:** Staff's `admin_id` is NULL or incorrect

**Fix:**
```sql
UPDATE user_profiles 
SET admin_id = '<ADMIN_UUID>'
WHERE email = 'staff@example.com';
```

### Issue 2: Transactions show duplicate data
**Cause:** Multiple policies or incorrect realtime subscriptions

**Fix:**
```sql
-- Verify only 4 policies exist
SELECT COUNT(*) FROM pg_policies WHERE tablename = 'transactions';
-- Should return: 4 (select, insert, update, delete)
```

### Issue 3: Permission denied errors
**Cause:** RLS not properly enabled or function missing

**Fix:**
```sql
-- Re-enable RLS
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions FORCE ROW LEVEL SECURITY;

-- Recreate function
-- (Copy from migration file)
```

---

## 📚 Related Files

1. **Migration:** `/supabase/migrations/20251211000001_restore_team_based_rls.sql`
2. **Verification:** `/supabase/verify_team_structure.sql`
3. **App Logic:** `/lib/services/supabase_service.dart` (line 155-170)
4. **Old (Broken) Migration:** `/supabase/migrations/20251209000004_nuclear_fix_owner_rls.sql`

---

## ✅ Success Criteria

After applying the fix:
- [ ] All policies use `admin_id` for team sharing
- [ ] Staff/managers have correct `admin_id` set
- [ ] All transactions have correct `admin_id` set
- [ ] Admin sees all team transactions
- [ ] Manager sees all team transactions
- [ ] Staff sees all team transactions
- [ ] Different admins see only their team's data
- [ ] Realtime updates work for all team members
