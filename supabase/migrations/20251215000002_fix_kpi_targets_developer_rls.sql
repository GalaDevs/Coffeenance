-- Fix KPI targets RLS to support developer role
-- Developers should have full access to their own KPI targets

BEGIN;

-- ============================================
-- STEP 1: Update helper function for KPI targets
-- ============================================
CREATE OR REPLACE FUNCTION get_kpi_targets_admin_id()
RETURNS UUID AS $$
DECLARE
    user_admin_id UUID;
    user_role TEXT;
BEGIN
    SELECT admin_id, role INTO user_admin_id, user_role
    FROM user_profiles
    WHERE id = auth.uid();
    
    -- If user is admin or developer, return their own id
    -- Developers are essentially their own admin
    IF user_role IN ('admin', 'developer') THEN
        RETURN auth.uid();
    END IF;
    
    -- If admin_id is null (shouldn't happen but safety check)
    IF user_admin_id IS NULL THEN
        RETURN auth.uid();
    END IF;
    
    -- If user is staff/manager, return their admin_id
    RETURN user_admin_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================
-- STEP 2: Drop and recreate policies to include developer
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "team_insert_kpi_targets" ON kpi_targets;
DROP POLICY IF EXISTS "team_update_kpi_targets" ON kpi_targets;
DROP POLICY IF EXISTS "team_delete_kpi_targets" ON kpi_targets;

-- Recreate with developer role included
CREATE POLICY "team_insert_kpi_targets"
    ON kpi_targets FOR INSERT
    WITH CHECK (
        shop_id = get_kpi_targets_admin_id()
        AND EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager', 'developer')
        )
    );

CREATE POLICY "team_update_kpi_targets"
    ON kpi_targets FOR UPDATE
    USING (
        shop_id = get_kpi_targets_admin_id()
        AND EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager', 'developer')
        )
    );

CREATE POLICY "team_delete_kpi_targets"
    ON kpi_targets FOR DELETE
    USING (
        shop_id = get_kpi_targets_admin_id()
        AND EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'developer')
        )
    );

-- ============================================
-- STEP 3: Verify policies
-- ============================================
SELECT 
    policyname,
    cmd as operation,
    qual as using_clause,
    with_check as check_clause
FROM pg_policies 
WHERE tablename = 'kpi_targets'
ORDER BY policyname;

COMMIT;
