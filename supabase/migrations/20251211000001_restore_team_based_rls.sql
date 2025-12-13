-- Restore Team-Based RLS for Staff/Manager Data Sync
-- This fixes the issue where the nuclear_fix broke team data sharing
-- Staff and managers MUST see their admin's transactions via admin_id

BEGIN;

-- ============================================
-- STEP 1: Drop the owner-only policies
-- ============================================
DROP POLICY IF EXISTS "strict_owner_select" ON public.transactions;
DROP POLICY IF EXISTS "strict_owner_insert" ON public.transactions;
DROP POLICY IF EXISTS "strict_owner_update" ON public.transactions;
DROP POLICY IF EXISTS "strict_owner_delete" ON public.transactions;

-- ============================================
-- STEP 2: Recreate helper function for team isolation
-- ============================================
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

-- ============================================
-- STEP 3: Create TEAM-BASED policies using admin_id
-- ============================================

-- SELECT: Users can see their own transactions + all team transactions via admin_id
CREATE POLICY "team_select_transactions"
ON public.transactions
FOR SELECT
USING (
    admin_id = get_current_user_admin_id()  -- Team's transactions via admin_id
);

-- INSERT: Must set correct owner_id and admin_id
CREATE POLICY "team_insert_transactions"
ON public.transactions
FOR INSERT
WITH CHECK (
    owner_id = auth.uid()  -- Must set owner to self
    AND admin_id = get_current_user_admin_id()  -- Must set correct admin_id
);

-- UPDATE: Can update team's transactions
CREATE POLICY "team_update_transactions"
ON public.transactions
FOR UPDATE
USING (
    admin_id = get_current_user_admin_id()  -- Can update team's transactions
)
WITH CHECK (
    admin_id = get_current_user_admin_id()  -- Must keep correct admin_id
);

-- DELETE: Can delete team's transactions
CREATE POLICY "team_delete_transactions"
ON public.transactions
FOR DELETE
USING (
    admin_id = get_current_user_admin_id()  -- Can delete team's transactions
);

-- ============================================
-- STEP 4: Verify the fix
-- ============================================

-- Show current policies
SELECT 
    policyname,
    cmd as operation,
    CASE 
        WHEN qual LIKE '%admin_id%' OR with_check LIKE '%admin_id%' THEN '✅ Uses admin_id (team-based)'
        WHEN qual LIKE '%owner_id%' OR with_check LIKE '%owner_id%' THEN '⚠️ Uses owner_id only'
        ELSE '❓ Unknown'
    END as policy_type
FROM pg_policies 
WHERE tablename = 'transactions'
ORDER BY policyname;

-- ============================================
-- STEP 5: Verify data isolation still works
-- ============================================

-- Show transaction counts by admin
SELECT 
    admin_id,
    (SELECT email FROM user_profiles WHERE id = transactions.admin_id) as admin_email,
    COUNT(*) as transaction_count,
    STRING_AGG(DISTINCT (SELECT email FROM user_profiles WHERE id = owner_id), ', ') as team_members
FROM public.transactions
GROUP BY admin_id
ORDER BY transaction_count DESC;

COMMIT;

-- ============================================
-- EXPLANATION
-- ============================================
-- The nuclear_fix used owner_id ONLY, which breaks team data sharing.
-- This migration restores the correct team-based isolation:
-- 
-- 1. Admin creates transactions with admin_id = their own ID
-- 2. Manager/Staff create transactions with admin_id = their admin's ID
-- 3. ALL team members can see ALL transactions with their admin_id
-- 4. This allows staff/managers to sync data with their admin
-- 
-- Example:
-- - Admin (rod@gmail.com) creates TX with admin_id=rod_uuid
-- - Manager (john@manager.com, admin_id=rod_uuid) can see ALL TXs with admin_id=rod_uuid
-- - Staff (jane@staff.com, admin_id=rod_uuid) can see ALL TXs with admin_id=rod_uuid
-- 
-- But rod2@gmail.com (different admin) CANNOT see rod's team transactions!
