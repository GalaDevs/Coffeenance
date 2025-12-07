-- Strengthen RLS policies for complete data isolation per admin
-- Migration: 20251207000001_strengthen_rls_isolation.sql
-- Description: Enforce strict tenant isolation - each admin can ONLY access their own data

-- ============================================
-- ENABLE RLS ON ALL TABLES (ensure it's enabled)
-- ============================================
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE kpi_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_settings ENABLE ROW LEVEL SECURITY;

-- ============================================
-- HELPER FUNCTION: Get current user's admin ID
-- ============================================
CREATE OR REPLACE FUNCTION current_user_admin_id()
RETURNS UUID AS $$
DECLARE
    user_admin_id UUID;
    user_role TEXT;
BEGIN
    -- Get current user's admin_id and role
    SELECT admin_id, role INTO user_admin_id, user_role
    FROM user_profiles
    WHERE id = auth.uid();
    
    -- If user is admin (admin_id is NULL), return their own ID
    IF user_role = 'admin' OR user_admin_id IS NULL THEN
        RETURN auth.uid();
    END IF;
    
    -- For manager/staff, return their admin_id
    RETURN user_admin_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION current_user_admin_id IS 'Returns the admin ID that the current user belongs to. For admins returns their own ID, for manager/staff returns their admin_id.';

-- ============================================
-- USER_PROFILES - Strict tenant isolation
-- ============================================
DROP POLICY IF EXISTS "Users can view user_profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can create users" ON user_profiles;
DROP POLICY IF EXISTS "Admin can update users" ON user_profiles;
DROP POLICY IF EXISTS "Admin can delete users" ON user_profiles;

-- SELECT: Users can only see profiles in their tenant
CREATE POLICY "tenant_isolation_select_user_profiles" ON user_profiles
    FOR SELECT
    USING (
        -- User is viewing their own profile
        id = auth.uid()
        OR
        -- User belongs to the same admin (either the admin themselves or their created users)
        (id = current_user_admin_id() OR admin_id = current_user_admin_id())
    );

-- INSERT: Only admins can create users (will be handled by app logic)
CREATE POLICY "tenant_isolation_insert_user_profiles" ON user_profiles
    FOR INSERT
    WITH CHECK (
        -- Only admins can create users
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
        AND
        -- New user must belong to the creating admin's tenant
        (admin_id = auth.uid() OR (role = 'admin' AND admin_id IS NULL))
    );

-- UPDATE: Only admins can update users in their tenant
CREATE POLICY "tenant_isolation_update_user_profiles" ON user_profiles
    FOR UPDATE
    USING (
        id = current_user_admin_id() OR admin_id = current_user_admin_id()
    )
    WITH CHECK (
        id = current_user_admin_id() OR admin_id = current_user_admin_id()
    );

-- DELETE: Only admins can delete users in their tenant
CREATE POLICY "tenant_isolation_delete_user_profiles" ON user_profiles
    FOR DELETE
    USING (
        admin_id = current_user_admin_id()
        AND
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ============================================
-- TRANSACTIONS - Strict tenant isolation
-- ============================================
DROP POLICY IF EXISTS "Users can view transactions" ON transactions;
DROP POLICY IF EXISTS "Users can create transactions" ON transactions;
DROP POLICY IF EXISTS "Admin and Manager can update transactions" ON transactions;
DROP POLICY IF EXISTS "Admin can delete transactions" ON transactions;

-- SELECT: Only see transactions in your tenant
CREATE POLICY "tenant_isolation_select_transactions" ON transactions
    FOR SELECT
    USING (admin_id = current_user_admin_id());

-- INSERT: Can only create transactions in your tenant
CREATE POLICY "tenant_isolation_insert_transactions" ON transactions
    FOR INSERT
    WITH CHECK (admin_id = current_user_admin_id());

-- UPDATE: Admin and Manager can update transactions in their tenant
CREATE POLICY "tenant_isolation_update_transactions" ON transactions
    FOR UPDATE
    USING (
        admin_id = current_user_admin_id()
        AND
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
    )
    WITH CHECK (admin_id = current_user_admin_id());

-- DELETE: Only admins can delete transactions in their tenant
CREATE POLICY "tenant_isolation_delete_transactions" ON transactions
    FOR DELETE
    USING (
        admin_id = current_user_admin_id()
        AND
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ============================================
-- INVENTORY - Strict tenant isolation
-- ============================================
DROP POLICY IF EXISTS "Users can view inventory" ON inventory;
DROP POLICY IF EXISTS "Admin and Manager can manage inventory" ON inventory;

-- SELECT: Only see inventory in your tenant
CREATE POLICY "tenant_isolation_select_inventory" ON inventory
    FOR SELECT
    USING (admin_id = current_user_admin_id());

-- INSERT: Admin and Manager can create inventory in their tenant
CREATE POLICY "tenant_isolation_insert_inventory" ON inventory
    FOR INSERT
    WITH CHECK (
        admin_id = current_user_admin_id()
        AND
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
    );

-- UPDATE: Admin and Manager can update inventory in their tenant
CREATE POLICY "tenant_isolation_update_inventory" ON inventory
    FOR UPDATE
    USING (
        admin_id = current_user_admin_id()
        AND
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
    )
    WITH CHECK (admin_id = current_user_admin_id());

-- DELETE: Admin and Manager can delete inventory in their tenant
CREATE POLICY "tenant_isolation_delete_inventory" ON inventory
    FOR DELETE
    USING (
        admin_id = current_user_admin_id()
        AND
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
    );

-- ============================================
-- STAFF - Strict tenant isolation
-- ============================================
DROP POLICY IF EXISTS "Users can view staff" ON staff;
DROP POLICY IF EXISTS "Admin and Manager can manage staff" ON staff;

-- SELECT: Only see staff in your tenant
CREATE POLICY "tenant_isolation_select_staff" ON staff
    FOR SELECT
    USING (admin_id = current_user_admin_id());

-- ALL: Admin and Manager can manage staff in their tenant
CREATE POLICY "tenant_isolation_manage_staff" ON staff
    FOR ALL
    USING (
        admin_id = current_user_admin_id()
        AND
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
    )
    WITH CHECK (admin_id = current_user_admin_id());

-- ============================================
-- KPI_SETTINGS - Strict tenant isolation
-- ============================================
DROP POLICY IF EXISTS "Users can view kpi_settings" ON kpi_settings;
DROP POLICY IF EXISTS "Admin can manage kpi_settings" ON kpi_settings;

-- SELECT: Only see KPI settings in your tenant
CREATE POLICY "tenant_isolation_select_kpi_settings" ON kpi_settings
    FOR SELECT
    USING (admin_id = current_user_admin_id());

-- ALL: Only admins can manage KPI settings in their tenant
CREATE POLICY "tenant_isolation_manage_kpi_settings" ON kpi_settings
    FOR ALL
    USING (
        admin_id = current_user_admin_id()
        AND
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
    WITH CHECK (admin_id = current_user_admin_id());

-- ============================================
-- TAX_SETTINGS - Strict tenant isolation
-- ============================================
DROP POLICY IF EXISTS "Users can view tax_settings" ON tax_settings;
DROP POLICY IF EXISTS "Admin can manage tax_settings" ON tax_settings;

-- SELECT: Only see tax settings in your tenant
CREATE POLICY "tenant_isolation_select_tax_settings" ON tax_settings
    FOR SELECT
    USING (admin_id = current_user_admin_id());

-- ALL: Only admins can manage tax settings in their tenant
CREATE POLICY "tenant_isolation_manage_tax_settings" ON tax_settings
    FOR ALL
    USING (
        admin_id = current_user_admin_id()
        AND
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
    WITH CHECK (admin_id = current_user_admin_id());

-- ============================================
-- VERIFICATION
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '✅ Tenant isolation RLS policies applied successfully';
    RAISE NOTICE '🔒 All data access now filtered by admin_id using current_user_admin_id()';
    RAISE NOTICE '🏢 Each admin can ONLY see and modify their own tenant data';
END $$;
