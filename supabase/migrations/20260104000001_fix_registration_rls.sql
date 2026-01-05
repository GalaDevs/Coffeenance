-- Fix RLS policy for user registration
-- Migration: 20260104000001_fix_registration_rls.sql
-- Problem: New users can't insert their own profile after signUp
-- Solution: Allow authenticated users to insert their own profile

-- ============================================
-- DROP OLD INSERT POLICY
-- ============================================

DROP POLICY IF EXISTS "team_insert_user_profiles" ON user_profiles;

-- ============================================
-- CREATE NEW INSERT POLICY
-- ============================================

-- INSERT: Allow:
--   1. Self-registration: User inserting their own profile (id = auth.uid())
--   2. Admin creating team members (admin_id = auth.uid())
CREATE POLICY "team_insert_user_profiles" ON user_profiles
    FOR INSERT
    WITH CHECK (
        -- Self-registration: User can insert their own profile
        id = auth.uid()
        OR
        -- Admin creating staff/manager (admin_id must be current user)
        admin_id = auth.uid()
    );

DO $$ BEGIN
    RAISE NOTICE '✅ Fixed RLS policy for user registration';
END $$;
