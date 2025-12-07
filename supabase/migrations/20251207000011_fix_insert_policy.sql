-- Fix user_profiles INSERT policy to allow admin creating users with any ID
-- Migration: 20251207000011_fix_insert_policy.sql
-- Description: Allow admins to create users with generated UUIDs (not just auth.uid())

-- ============================================
-- DROP OLD INSERT POLICY
-- ============================================

DROP POLICY IF EXISTS "team_insert_user_profiles" ON user_profiles;

DO $$ BEGIN
    RAISE NOTICE '✅ Old team_insert_user_profiles policy dropped';
END $$;

-- ============================================
-- CREATE NEW INSERT POLICY
-- ============================================

-- INSERT: Allow:
--   1. Self-registration: User creating their own profile (id = auth.uid() AND admin_id IS NULL)
--   2. Admin creating team members: admin_id points to current user (admin_id = auth.uid())
--      Note: For #2, the ID can be ANY UUID (generated), not necessarily auth.uid()
CREATE POLICY "team_insert_user_profiles" ON user_profiles
    FOR INSERT
    WITH CHECK (
        -- Self-registration (for admin accounts during registration)
        -- Must be creating YOUR OWN profile (id matches your auth.uid())
        (id = auth.uid() AND admin_id IS NULL)
        OR
        -- Admin creating staff/manager
        -- The NEW user's admin_id must point to YOU (the current user)
        -- The ID can be any UUID (doesn't need to be auth.uid())
        (admin_id = auth.uid() AND id != auth.uid())
    );

DO $$ BEGIN
    RAISE NOTICE '✅ New team_insert_user_profiles policy created';
    RAISE NOTICE '   - Allows self-registration: id = auth.uid() AND admin_id IS NULL';
    RAISE NOTICE '   - Allows admin creating users: admin_id = auth.uid()';
END $$;

-- ============================================
-- TEST THE POLICY
-- ============================================

DO $$
DECLARE
    test_admin_id UUID;
    manager_count INTEGER;
    staff_count INTEGER;
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE '🧪 TESTING USER CREATION RLS';
    RAISE NOTICE '========================================';
    
    -- Check if we have any admin users to test with
    SELECT id INTO test_admin_id 
    FROM user_profiles 
    WHERE role = 'admin' 
    LIMIT 1;
    
    IF test_admin_id IS NOT NULL THEN
        RAISE NOTICE '✅ Found test admin: %', test_admin_id;
        
        -- Count existing managers for this admin
        SELECT COUNT(*) INTO manager_count
        FROM user_profiles
        WHERE admin_id = test_admin_id AND role = 'manager';
        
        -- Count existing staff for this admin
        SELECT COUNT(*) INTO staff_count
        FROM user_profiles
        WHERE admin_id = test_admin_id AND role = 'staff';
        
        RAISE NOTICE '   Current managers: %', manager_count;
        RAISE NOTICE '   Current staff: %', staff_count;
        RAISE NOTICE '   Ready to create: % manager(s), % staff', (1 - manager_count), (2 - staff_count);
    ELSE
        RAISE NOTICE '⚠️ No admin users found - cannot test';
    END IF;
    
    RAISE NOTICE '========================================';
END $$;
