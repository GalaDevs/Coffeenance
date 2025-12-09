-- Fix RLS to properly isolate data by owner_id
-- Run this in Supabase SQL Editor

-- 1. Drop ALL existing policies on transactions
DROP POLICY IF EXISTS "Users can view their own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can insert their own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can update their own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can delete their own transactions" ON transactions;
DROP POLICY IF EXISTS "Admins can view all organization transactions" ON transactions;
DROP POLICY IF EXISTS "Managers can view all organization transactions" ON transactions;
DROP POLICY IF EXISTS "Staff can view own transactions" ON transactions;
DROP POLICY IF EXISTS "Users view own data" ON transactions;
DROP POLICY IF EXISTS "Users insert own data" ON transactions;
DROP POLICY IF EXISTS "Users update own data" ON transactions;
DROP POLICY IF EXISTS "Users delete own data" ON transactions;

-- 2. Ensure RLS is enabled with FORCE
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions FORCE ROW LEVEL SECURITY;

-- 3. Create simple, strict owner_id-based policies
-- SELECT: Users can ONLY see their own data (owner_id match)
CREATE POLICY "strict_select_by_owner"
ON transactions FOR SELECT
USING (owner_id = auth.uid());

-- INSERT: Automatically set owner_id to current user
CREATE POLICY "strict_insert_with_owner"
ON transactions FOR INSERT
WITH CHECK (owner_id = auth.uid());

-- UPDATE: Users can only update their own data
CREATE POLICY "strict_update_own_data"
ON transactions FOR UPDATE
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

-- DELETE: Users can only delete their own data
CREATE POLICY "strict_delete_own_data"
ON transactions FOR DELETE
USING (owner_id = auth.uid());

-- 4. Fix the one problematic transaction
-- TX #140 has owner_id = 55ed739b-ac41-4a2d-8f83-ef528a71541f but admin_id = 563943bb...
-- This should belong to rod6@gmail.com, not rod@gmail.com
-- The owner_id is correct, the issue is it's showing up for the wrong user

-- Let's verify the data
SELECT 
  id,
  owner_id,
  admin_id,
  user_id,
  description,
  (SELECT email FROM user_profiles WHERE id = owner_id) as owner_email
FROM transactions 
WHERE id = 140;

-- 5. Apply same strict policies to other tables
-- inventory table
DROP POLICY IF EXISTS "Users can view own inventory" ON inventory;
DROP POLICY IF EXISTS "Users can insert own inventory" ON inventory;
DROP POLICY IF EXISTS "Users can update own inventory" ON inventory;
DROP POLICY IF EXISTS "Users can delete own inventory" ON inventory;

ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory FORCE ROW LEVEL SECURITY;

CREATE POLICY "strict_select_inventory" ON inventory FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "strict_insert_inventory" ON inventory FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "strict_update_inventory" ON inventory FOR UPDATE USING (owner_id = auth.uid());
CREATE POLICY "strict_delete_inventory" ON inventory FOR DELETE USING (owner_id = auth.uid());

-- user_profiles table
DROP POLICY IF EXISTS "Users can view their team" ON user_profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can create users" ON user_profiles;
DROP POLICY IF EXISTS "Admins can manage team" ON user_profiles;

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles FORCE ROW LEVEL SECURITY;

-- Users can see themselves and users they created
CREATE POLICY "view_self_and_created_users" ON user_profiles FOR SELECT
USING (
  id = auth.uid() OR 
  created_by = auth.uid() OR
  admin_id = auth.uid()
);

-- Users can update only their own profile
CREATE POLICY "update_own_profile" ON user_profiles FOR UPDATE
USING (id = auth.uid());

-- Only admins can create new users (checked via trigger)
CREATE POLICY "admins_create_users" ON user_profiles FOR INSERT
WITH CHECK (
  (SELECT role FROM user_profiles WHERE id = auth.uid()) = 'admin'
);

-- 6. Verify policies are working
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename IN ('transactions', 'inventory', 'user_profiles')
ORDER BY tablename, policyname;

COMMENT ON POLICY "strict_select_by_owner" ON transactions IS 'Users can ONLY see records where owner_id matches their auth.uid()';
COMMENT ON POLICY "strict_insert_with_owner" ON transactions IS 'New records must have owner_id set to current user';
COMMENT ON POLICY "strict_update_own_data" ON transactions IS 'Users can only update their own records';
COMMENT ON POLICY "strict_delete_own_data" ON transactions IS 'Users can only delete their own records';
