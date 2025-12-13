-- Add Developer Role
-- Created: 2025-12-12
-- Description: Add developer role with full access permissions

-- ============================================
-- ADD DEVELOPER ROLE TO CHECK CONSTRAINT
-- ============================================

-- Drop existing check constraint
ALTER TABLE public.user_profiles DROP CONSTRAINT IF EXISTS user_profiles_role_check;

-- Add new check constraint with developer role
ALTER TABLE public.user_profiles ADD CONSTRAINT user_profiles_role_check 
  CHECK (role IN ('admin', 'manager', 'staff', 'developer'));

-- ============================================
-- UPDATE RLS POLICIES FOR DEVELOPER ROLE
-- ============================================

-- User profiles: Allow developers same access as admins
DROP POLICY IF EXISTS "tenant_isolation_select_user_profiles" ON user_profiles;
CREATE POLICY "tenant_isolation_select_user_profiles" ON user_profiles
    FOR SELECT
    USING (
        -- Admins and developers see their team
        (COALESCE(admin_id, id) = current_user_admin_id())
        OR
        -- Service role bypass
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
            -- Admins/developers can create users under their tenant
            admin_id = auth.uid()
            OR
            -- Or create their own admin/developer profile
            (role IN ('admin', 'developer') AND admin_id IS NULL)
        )
    );

-- Developers can update users (same as admins)
DROP POLICY IF EXISTS "tenant_isolation_update_user_profiles" ON user_profiles;
CREATE POLICY "tenant_isolation_update_user_profiles" ON user_profiles
    FOR UPDATE
    USING (
        COALESCE(admin_id, id) = current_user_admin_id()
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

-- ============================================
-- UPDATE TRANSACTION POLICIES FOR DEVELOPER
-- ============================================

-- Developers can manage transactions (same as admin/manager)
DROP POLICY IF EXISTS "tenant_isolation_update_transactions" ON transactions;
CREATE POLICY "tenant_isolation_update_transactions" ON transactions
    FOR UPDATE
    USING (
        admin_id = current_user_admin_id()
        AND EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager', 'developer')
        )
    );

DROP POLICY IF EXISTS "tenant_isolation_delete_transactions" ON transactions;
CREATE POLICY "tenant_isolation_delete_transactions" ON transactions
    FOR DELETE
    USING (
        admin_id = current_user_admin_id()
        AND EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() 
            AND role IN ('admin', 'developer')
        )
    );

-- ============================================
-- UPDATE SHOP SETTINGS POLICIES FOR DEVELOPER
-- ============================================

DROP POLICY IF EXISTS "Users can view their shop settings" ON shop_settings;
CREATE POLICY "Users can view their shop settings" ON shop_settings
    FOR SELECT
    USING (admin_id = current_user_admin_id());

DROP POLICY IF EXISTS "Admins can manage shop settings" ON shop_settings;
CREATE POLICY "Admins can manage shop settings" ON shop_settings
    FOR ALL
    USING (
        admin_id = current_user_admin_id()
        AND EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() 
            AND role IN ('admin', 'developer')
        )
    );

-- ============================================
-- UPDATE KPI TARGETS POLICIES FOR DEVELOPER
-- ============================================

DROP POLICY IF EXISTS "Users can view KPI targets" ON kpi_targets;
CREATE POLICY "Users can view KPI targets" ON kpi_targets
    FOR SELECT
    USING (admin_id = current_user_admin_id());

DROP POLICY IF EXISTS "Admins can manage KPI targets" ON kpi_targets;
CREATE POLICY "Admins can manage KPI targets" ON kpi_targets
    FOR ALL
    USING (
        admin_id = current_user_admin_id()
        AND EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() 
            AND role IN ('admin', 'developer')
        )
    );

-- ============================================
-- UPDATE INVENTORY POLICIES FOR DEVELOPER
-- ============================================

DROP POLICY IF EXISTS "tenant_isolation_update_inventory" ON inventory;
CREATE POLICY "tenant_isolation_update_inventory" ON inventory
    FOR UPDATE
    USING (
        admin_id = current_user_admin_id()
        AND EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager', 'developer')
        )
    );

DROP POLICY IF EXISTS "tenant_isolation_delete_inventory" ON inventory;
CREATE POLICY "tenant_isolation_delete_inventory" ON inventory
    FOR DELETE
    USING (
        admin_id = current_user_admin_id()
        AND EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager', 'developer')
        )
    );

-- ============================================
-- UPDATE STAFF POLICIES FOR DEVELOPER
-- ============================================

DROP POLICY IF EXISTS "tenant_isolation_update_staff" ON staff;
CREATE POLICY "tenant_isolation_update_staff" ON staff
    FOR UPDATE
    USING (
        admin_id = current_user_admin_id()
        AND EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager', 'developer')
        )
    );

DROP POLICY IF EXISTS "tenant_isolation_delete_staff" ON staff;
CREATE POLICY "tenant_isolation_delete_staff" ON staff
    FOR DELETE
    USING (
        admin_id = current_user_admin_id()
        AND EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager', 'developer')
        )
    );

-- ============================================
-- UPDATE NOTIFICATIONS POLICIES FOR DEVELOPER
-- ============================================

DROP POLICY IF EXISTS "Users can manage their own notifications" ON notifications;
CREATE POLICY "Users can manage their own notifications" ON notifications
    FOR ALL
    USING (user_id = auth.uid());

-- Developers can see all notifications in their tenant (same as admins)
DROP POLICY IF EXISTS "tenant_isolation_select_notifications" ON notifications;
CREATE POLICY "tenant_isolation_select_notifications" ON notifications
    FOR SELECT
    USING (
        user_id IN (
            SELECT id FROM user_profiles
            WHERE COALESCE(admin_id, id) = current_user_admin_id()
        )
    );

-- ============================================
-- UPDATE HELPER FUNCTION FOR DEVELOPER ROLE
-- ============================================

-- Update current_user_admin_id function to handle developer role
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
    -- Get user's admin_id and role
    SELECT admin_id, role INTO user_admin_id, user_role
    FROM user_profiles
    WHERE id = auth.uid();
    
    -- If user is admin or developer (admin_id is NULL), return their own ID
    IF user_role IN ('admin', 'developer') OR user_admin_id IS NULL THEN
        RETURN auth.uid();
    END IF;
    
    -- For manager/staff, return their admin_id
    RETURN user_admin_id;
END;
$$;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON COLUMN user_profiles.role IS 'User role: admin, manager, staff, or developer. Developer has full access like admin but maintains account exclusivity.';

-- Log migration
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Developer Role Migration Complete';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Added developer role with:';
    RAISE NOTICE '  - Full access to all features (like admin)';
    RAISE NOTICE '  - Account exclusivity maintained';
    RAISE NOTICE '  - Can create/manage users';
    RAISE NOTICE '  - Can manage all data in their tenant';
    RAISE NOTICE '  - No account limits';
    RAISE NOTICE '========================================';
END $$;
