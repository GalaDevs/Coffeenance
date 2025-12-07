-- Fix user_profiles RLS to allow admins to create staff/manager accounts
-- Migration: 20251207000010_fix_user_creation_rls.sql
-- Description: Allow admins to create users where admin_id = current user

-- ============================================
-- DROP OLD RESTRICTIVE POLICIES
-- ============================================

DROP POLICY IF EXISTS "owner_select_user_profiles" ON user_profiles;
DROP POLICY IF EXISTS "owner_insert_user_profiles" ON user_profiles;
DROP POLICY IF EXISTS "owner_update_user_profiles" ON user_profiles;

DO $$ BEGIN
    RAISE NOTICE '✅ Old user_profiles policies dropped';
END $$;

-- ============================================
-- CREATE NEW POLICIES FOR TEAM-BASED ACCESS
-- ============================================

-- SELECT: Users can see:
--   1. Their own profile (id = auth.uid())
--   2. Their team members (admin_id = auth.uid() - if they're admin)
--   3. Their admin (if they're staff/manager, they can see their admin's profile)
CREATE POLICY "team_select_user_profiles" ON user_profiles
    FOR SELECT
    USING (
        id = auth.uid()  -- Own profile
        OR admin_id = auth.uid()  -- Team members (if current user is admin)
        OR id = admin_id  -- Can see own admin's profile
    );

-- INSERT: Allow:
--   1. Self-registration (id = auth.uid() AND admin_id IS NULL for admins)
--   2. Admin creating team members (admin_id = auth.uid())
CREATE POLICY "team_insert_user_profiles" ON user_profiles
    FOR INSERT
    WITH CHECK (
        -- Self-registration (for admin accounts)
        (id = auth.uid() AND admin_id IS NULL)
        OR
        -- Admin creating staff/manager (admin_id must be current user)
        (admin_id = auth.uid())
    );

-- UPDATE: Users can update:
--   1. Their own profile
--   2. Their team members (if they're admin)
CREATE POLICY "team_update_user_profiles" ON user_profiles
    FOR UPDATE
    USING (
        id = auth.uid()  -- Own profile
        OR admin_id = auth.uid()  -- Team members
    )
    WITH CHECK (
        id = auth.uid()  -- Can only change to own profile
        OR admin_id = auth.uid()  -- Or team members
    );

-- DELETE: Only admins can delete their team members
CREATE POLICY "team_delete_user_profiles" ON user_profiles
    FOR DELETE
    USING (admin_id = auth.uid());

DO $$ BEGIN
    RAISE NOTICE '✅ New team-based RLS policies created for user_profiles';
END $$;

-- ============================================
-- UPDATE OTHER TABLES TO USE TEAM-BASED ACCESS
-- ============================================

-- DROP old owner_id-only policies for data tables
DROP POLICY IF EXISTS "owner_select_transactions" ON transactions;
DROP POLICY IF EXISTS "owner_insert_transactions" ON transactions;
DROP POLICY IF EXISTS "owner_update_transactions" ON transactions;
DROP POLICY IF EXISTS "owner_delete_transactions" ON transactions;

DROP POLICY IF EXISTS "owner_select_inventory" ON inventory;
DROP POLICY IF EXISTS "owner_insert_inventory" ON inventory;
DROP POLICY IF EXISTS "owner_update_inventory" ON inventory;
DROP POLICY IF EXISTS "owner_delete_inventory" ON inventory;

DROP POLICY IF EXISTS "owner_select_staff" ON staff;
DROP POLICY IF EXISTS "owner_insert_staff" ON staff;
DROP POLICY IF EXISTS "owner_update_staff" ON staff;
DROP POLICY IF EXISTS "owner_delete_staff" ON staff;

DO $$ BEGIN
    RAISE NOTICE '✅ Old owner_id policies dropped from data tables';
END $$;

-- ============================================
-- HELPER FUNCTION: Get current user's admin_id
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

DO $$ BEGIN
    RAISE NOTICE '✅ Helper function get_current_user_admin_id() created';
END $$;

-- ============================================
-- TRANSACTIONS: TEAM-BASED ACCESS
-- ============================================

-- Team members (admin + their manager/staff) share data via admin_id
CREATE POLICY "team_select_transactions" ON transactions
    FOR SELECT
    USING (
        owner_id = auth.uid()  -- Own transactions
        OR admin_id = get_current_user_admin_id()  -- Team's transactions
    );

CREATE POLICY "team_insert_transactions" ON transactions
    FOR INSERT
    WITH CHECK (
        owner_id = auth.uid()  -- Must set owner to self
        AND admin_id = get_current_user_admin_id()  -- Must set admin correctly
    );

CREATE POLICY "team_update_transactions" ON transactions
    FOR UPDATE
    USING (
        owner_id = auth.uid()  -- Can only update own
        OR admin_id = get_current_user_admin_id()  -- Or team's
    )
    WITH CHECK (
        owner_id = auth.uid()  -- Must keep owner as self
        AND admin_id = get_current_user_admin_id()
    );

CREATE POLICY "team_delete_transactions" ON transactions
    FOR DELETE
    USING (
        owner_id = auth.uid()
        OR admin_id = get_current_user_admin_id()
    );

DO $$ BEGIN
    RAISE NOTICE '✅ Team-based RLS policies created for transactions';
END $$;

-- ============================================
-- INVENTORY: TEAM-BASED ACCESS
-- ============================================

CREATE POLICY "team_select_inventory" ON inventory
    FOR SELECT
    USING (
        owner_id = auth.uid()
        OR admin_id = get_current_user_admin_id()
    );

CREATE POLICY "team_insert_inventory" ON inventory
    FOR INSERT
    WITH CHECK (
        owner_id = auth.uid()
        AND admin_id = get_current_user_admin_id()
    );

CREATE POLICY "team_update_inventory" ON inventory
    FOR UPDATE
    USING (
        owner_id = auth.uid()
        OR admin_id = get_current_user_admin_id()
    )
    WITH CHECK (
        owner_id = auth.uid()
        AND admin_id = get_current_user_admin_id()
    );

CREATE POLICY "team_delete_inventory" ON inventory
    FOR DELETE
    USING (
        owner_id = auth.uid()
        OR admin_id = get_current_user_admin_id()
    );

DO $$ BEGIN
    RAISE NOTICE '✅ Team-based RLS policies created for inventory';
END $$;

-- ============================================
-- STAFF: TEAM-BASED ACCESS
-- ============================================

CREATE POLICY "team_select_staff" ON staff
    FOR SELECT
    USING (
        owner_id = auth.uid()
        OR admin_id = get_current_user_admin_id()
    );

CREATE POLICY "team_insert_staff" ON staff
    FOR INSERT
    WITH CHECK (
        owner_id = auth.uid()
        AND admin_id = get_current_user_admin_id()
    );

CREATE POLICY "team_update_staff" ON staff
    FOR UPDATE
    USING (
        owner_id = auth.uid()
        OR admin_id = get_current_user_admin_id()
    )
    WITH CHECK (
        owner_id = auth.uid()
        AND admin_id = get_current_user_admin_id()
    );

CREATE POLICY "team_delete_staff" ON staff
    FOR DELETE
    USING (
        owner_id = auth.uid()
        OR admin_id = get_current_user_admin_id()
    );

DO $$ BEGIN
    RAISE NOTICE '✅ Team-based RLS policies created for staff';
END $$;

-- ============================================
-- SUMMARY
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ TEAM-BASED RLS MIGRATION COMPLETE';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Data Access Model:';
    RAISE NOTICE '  - Each ADMIN has 1 manager + 2 staff max';
    RAISE NOTICE '  - Team members share data (admin_id links them)';
    RAISE NOTICE '  - Admins can create user accounts for their team';
    RAISE NOTICE '  - Staff/Manager can see team data but not other admins';
    RAISE NOTICE '========================================';
END $$;
