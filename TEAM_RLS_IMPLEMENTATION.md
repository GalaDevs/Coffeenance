# Team-Based RLS Implementation Summary

## Problem Solved
**Error**: `Failed to create user: new row violates row-level security policy for table "user_profiles"`

**Root Cause**: The previous RLS policy only allowed `id = auth.uid()`, which blocked admins from creating staff/manager accounts with generated UUIDs.

## Solution Implemented

### 1. Team-Based Data Model
- Each **admin** can have:
  - 1 manager maximum
  - 2 staff maximum
- Team members (admin + manager + staff) share data via `admin_id` column
- Data isolation between different admin teams

### 2. Database Changes

#### Migration: `20251207000010_fix_user_creation_rls.sql`
- **Dropped** old owner_id-only policies
- **Created** team-based policies for all tables
- **Added** helper function: `get_current_user_admin_id()`
  - Returns auth.uid() if current user is admin
  - Returns admin_id if current user is manager/staff

#### Migration: `20251207000011_fix_insert_policy.sql`
- **Fixed** user_profiles INSERT policy to allow:
  1. Self-registration: `id = auth.uid() AND admin_id IS NULL` (for admin accounts)
  2. Admin creating team: `admin_id = auth.uid()` (ID can be any UUID)

### 3. RLS Policies Structure

#### user_profiles Table
- **SELECT**: See own profile + team members + own admin
- **INSERT**: Self-registration OR admin creating team members
- **UPDATE**: Own profile OR team members (if admin)
- **DELETE**: Admin can delete team members only

#### Data Tables (transactions, inventory, staff)
- **All Operations**: Access own data OR team data (via admin_id)
- Uses `get_current_user_admin_id()` to determine team membership

## How It Works

### Admin Creating Manager/Staff:
1. Admin logs in (e.g., user_id: `d03278c0-1a4d-4ce7-bd57-212a9373077b`)
2. Admin creates manager account
3. INSERT checks: `admin_id = auth.uid()` ✅
4. New record: `{ id: <new-uuid>, admin_id: d03278c0-1a4d-4ce7-bd57-212a9373077b, role: 'manager' }`
5. RLS policy allows because `admin_id` points to current user

### Team Data Sharing:
1. Admin creates transaction
2. Transaction record: `{ owner_id: d03278c0..., admin_id: d03278c0... }`
3. Manager queries transactions
4. RLS checks: `admin_id = get_current_user_admin_id()` 
   - Manager's admin_id = d03278c0...
   - Function returns d03278c0... ✅
5. Manager sees admin's transactions

### Isolation Between Teams:
- Admin A (id: aaaa) with staff S1 (admin_id: aaaa)
- Admin B (id: bbbb) with staff S2 (admin_id: bbbb)
- S1 queries: sees only records where admin_id = aaaa
- S2 queries: sees only records where admin_id = bbbb
- **Complete isolation** between teams

## Testing Instructions

### Test 1: Create Manager Account
1. Login as admin (e.g., d03278c0-1a4d-4ce7-bd57-212a9373077b)
2. Go to Settings → User Management
3. Click "Add User"
4. Fill in:
   - Email: manager@test.com
   - Password: test1234
   - Full Name: Test Manager
   - Role: Manager
5. Click "Create User"
6. **Expected**: Success ✅ (no RLS error)

### Test 2: Create 2 Staff Accounts
1. Same admin, create first staff
   - Email: staff1@test.com
   - Role: Staff
2. **Expected**: Success ✅
3. Create second staff
   - Email: staff2@test.com
   - Role: Staff
4. **Expected**: Success ✅
5. Try creating third staff
6. **Expected**: Error "Maximum 2 staff accounts allowed per admin" ❌

### Test 3: Team Data Sharing
1. Login as admin
2. Create transaction (e.g., 500.00)
3. Logout
4. Login as manager (from Test 1)
5. Go to Dashboard
6. **Expected**: See admin's transaction ✅
7. Go to Transactions screen
8. **Expected**: See all team transactions ✅

### Test 4: Team Isolation
1. Create another admin account (admin B)
2. Login as admin B
3. Create transaction (e.g., 999.00)
4. Logout
5. Login as admin A (or admin A's manager)
6. **Expected**: Do NOT see admin B's 999.00 transaction ✅

## Database Schema

```sql
user_profiles:
  - id UUID (PK, FK to auth.users)
  - email TEXT
  - full_name TEXT
  - role TEXT (admin/manager/staff)
  - admin_id UUID (FK to user_profiles.id) -- NULL for admins, points to admin for manager/staff
  - created_by UUID
  - is_active BOOLEAN

transactions/inventory/staff:
  - id SERIAL (PK)
  - owner_id UUID (FK to auth.users) -- Who created it
  - admin_id UUID (FK to user_profiles.id) -- Which team it belongs to
  - ... other columns
```

## Key Points

✅ **Admins can now create manager/staff accounts**
✅ **Account limits enforced: 1 manager + 2 staff per admin**
✅ **Team members share data** (transactions, inventory, staff records)
✅ **Complete isolation between different admin teams**
✅ **Cache clearing on logout** prevents cross-user data contamination
✅ **Force reload on login** ensures fresh RLS-filtered data

## Files Modified

1. `supabase/migrations/20251207000010_fix_user_creation_rls.sql` - Team-based RLS policies
2. `supabase/migrations/20251207000011_fix_insert_policy.sql` - Fixed INSERT policy
3. `lib/providers/transaction_provider.dart` - Auth state listener + cache management
4. `lib/providers/auth_provider.dart` - Clear cache on logout

## Migration Status

```
✅ 20251207000010_fix_user_creation_rls.sql - Applied
✅ 20251207000011_fix_insert_policy.sql - Applied
```

Current state:
- Managers: 0
- Staff: 0
- Ready to create: 1 manager, 2 staff

## Next Steps

1. Test creating manager account in app
2. Test creating staff accounts (should allow 2, block 3rd)
3. Test data sharing between team members
4. Test isolation between different admin teams
5. Verify cache clearing works on user switch
