-- ============================================
-- QUICK FIX: Add Developer Role Support
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Update the role constraint
ALTER TABLE public.user_profiles DROP CONSTRAINT IF EXISTS user_profiles_role_check;
ALTER TABLE public.user_profiles ADD CONSTRAINT user_profiles_role_check 
  CHECK (role IN ('admin', 'manager', 'staff', 'developer'));

-- Step 2: Update RLS policies for developer access
-- User profiles: Allow developers same access as admins
DROP POLICY IF EXISTS "tenant_isolation_select_user_profiles" ON user_profiles;
CREATE POLICY "tenant_isolation_select_user_profiles" ON user_profiles
    FOR SELECT
    USING (
        (COALESCE(admin_id, id) = (
            SELECT COALESCE(admin_id, id) 
            FROM user_profiles 
            WHERE id = auth.uid()
        ))
        OR
        (current_user = 'service_role')
    );

-- Developers can create users (same as admins)
DROP POLICY IF EXISTS "tenant_isolation_insert_user_profiles" ON user_profiles;
CREATE POLICY "tenant_isolation_insert_user_profiles" ON user_profiles
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() 
            AND role IN ('admin', 'developer')
        )
        AND (
            admin_id = auth.uid()
            OR
            (role IN ('admin', 'developer') AND admin_id IS NULL)
        )
    );

-- Developers can update users (same as admins)
DROP POLICY IF EXISTS "tenant_isolation_update_user_profiles" ON user_profiles;
CREATE POLICY "tenant_isolation_update_user_profiles" ON user_profiles
    FOR UPDATE
    USING (
        COALESCE(admin_id, id) = (
            SELECT COALESCE(admin_id, id) 
            FROM user_profiles 
            WHERE id = auth.uid()
        )
        AND EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() 
            AND role IN ('admin', 'developer')
        )
    );

-- Developers can delete users (same as admins)
DROP POLICY IF EXISTS "tenant_isolation_delete_user_profiles" ON user_profiles;
CREATE POLICY "tenant_isolation_delete_user_profiles" ON user_profiles
    FOR DELETE
    USING (
        admin_id = auth.uid()
        AND id != auth.uid()
        AND EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() 
            AND role IN ('admin', 'developer')
        )
    );

-- Update helper function
CREATE OR REPLACE FUNCTION current_user_admin_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
    user_admin_id UUID;
    user_role TEXT;
BEGIN
    SELECT admin_id, role INTO user_admin_id, user_role
    FROM user_profiles
    WHERE id = auth.uid();
    
    IF user_role IN ('admin', 'developer') OR user_admin_id IS NULL THEN
        RETURN auth.uid();
    END IF;
    
    RETURN user_admin_id;
END;
$$;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Developer role support added successfully!';
    RAISE NOTICE 'You can now create developer accounts in the app.';
END $$;
