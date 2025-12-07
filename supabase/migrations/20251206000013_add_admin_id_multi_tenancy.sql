-- Add multi-tenancy support - Each admin has isolated data
-- Migration: 20251206000013_add_admin_id_multi_tenancy.sql
-- Description: Add admin_id column to all tables for data isolation per admin

-- ============================================
-- ADD ADMIN_ID TO USER_PROFILES
-- ============================================
-- Add admin_id column (nullable for admins, required for manager/staff)
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS admin_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_admin_id ON user_profiles(admin_id);

-- Comment for documentation
COMMENT ON COLUMN user_profiles.admin_id IS 'Reference to the admin who owns this user. NULL for admin users, required for manager/staff';

-- ============================================
-- ADD ADMIN_ID TO TRANSACTIONS
-- ============================================
ALTER TABLE transactions
ADD COLUMN IF NOT EXISTS admin_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_transactions_admin_id ON transactions(admin_id);

COMMENT ON COLUMN transactions.admin_id IS 'Reference to the admin who owns this transaction data';

-- ============================================
-- ADD ADMIN_ID TO INVENTORY
-- ============================================
ALTER TABLE inventory
ADD COLUMN IF NOT EXISTS admin_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_inventory_admin_id ON inventory(admin_id);

COMMENT ON COLUMN inventory.admin_id IS 'Reference to the admin who owns this inventory data';

-- ============================================
-- ADD ADMIN_ID TO STAFF
-- ============================================
ALTER TABLE staff
ADD COLUMN IF NOT EXISTS admin_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_staff_admin_id ON staff(admin_id);

COMMENT ON COLUMN staff.admin_id IS 'Reference to the admin who owns this staff data';

-- ============================================
-- ADD ADMIN_ID TO KPI_SETTINGS
-- ============================================
ALTER TABLE kpi_settings
ADD COLUMN IF NOT EXISTS admin_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_kpi_settings_admin_id ON kpi_settings(admin_id);

COMMENT ON COLUMN kpi_settings.admin_id IS 'Reference to the admin who owns this KPI settings';

-- ============================================
-- ADD ADMIN_ID TO TAX_SETTINGS
-- ============================================
ALTER TABLE tax_settings
ADD COLUMN IF NOT EXISTS admin_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_tax_settings_admin_id ON tax_settings(admin_id);

COMMENT ON COLUMN tax_settings.admin_id IS 'Reference to the admin who owns this tax settings';

-- ============================================
-- UPDATE EXISTING DATA (Set admin_id for current data)
-- ============================================
-- Set admin_id for existing admin users to their own ID
UPDATE user_profiles 
SET admin_id = NULL 
WHERE role = 'admin';

-- Set admin_id for existing manager/staff to the first admin
DO $$
DECLARE
    first_admin_id UUID;
BEGIN
    -- Get the first admin user
    SELECT id INTO first_admin_id 
    FROM user_profiles 
    WHERE role = 'admin' 
    ORDER BY created_at ASC 
    LIMIT 1;
    
    -- Update manager/staff users
    IF first_admin_id IS NOT NULL THEN
        UPDATE user_profiles 
        SET admin_id = first_admin_id 
        WHERE role IN ('manager', 'staff') AND admin_id IS NULL;
        
        -- Update all data tables
        UPDATE transactions SET admin_id = first_admin_id WHERE admin_id IS NULL;
        UPDATE inventory SET admin_id = first_admin_id WHERE admin_id IS NULL;
        UPDATE staff SET admin_id = first_admin_id WHERE admin_id IS NULL;
        UPDATE kpi_settings SET admin_id = first_admin_id WHERE admin_id IS NULL;
        UPDATE tax_settings SET admin_id = first_admin_id WHERE admin_id IS NULL;
        
        RAISE NOTICE 'Updated existing data with admin_id: %', first_admin_id;
    END IF;
END $$;

-- ============================================
-- ROW LEVEL SECURITY POLICIES (Multi-tenancy)
-- ============================================

-- USER_PROFILES: Users can only see their admin and users under same admin
DROP POLICY IF EXISTS "Users can view user_profiles" ON user_profiles;
CREATE POLICY "Users can view user_profiles" ON user_profiles
    FOR SELECT
    USING (
        -- Admins see their own profile and their created users
        (auth.uid() = id) OR
        (admin_id = auth.uid()) OR
        -- Manager/Staff see their own profile, their admin, and colleagues
        (id IN (
            SELECT id FROM user_profiles WHERE admin_id = (
                SELECT admin_id FROM user_profiles WHERE id = auth.uid()
            )
        )) OR
        (id = (SELECT admin_id FROM user_profiles WHERE id = auth.uid()))
    );

-- USER_PROFILES: Only admins can create users (under their admin_id)
DROP POLICY IF EXISTS "Admins can create users" ON user_profiles;
CREATE POLICY "Admins can create users" ON user_profiles
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- TRANSACTIONS: Users can only see transactions under their admin
DROP POLICY IF EXISTS "Users can view transactions" ON transactions;
CREATE POLICY "Users can view transactions" ON transactions
    FOR SELECT
    USING (
        -- Admin sees their own data
        (admin_id = auth.uid()) OR
        -- Manager/Staff see data from their admin
        (admin_id = (SELECT admin_id FROM user_profiles WHERE id = auth.uid())) OR
        (admin_id = (SELECT id FROM user_profiles WHERE id = auth.uid() AND role = 'admin'))
    );

DROP POLICY IF EXISTS "Users can create transactions" ON transactions;
CREATE POLICY "Users can create transactions" ON transactions
    FOR INSERT
    WITH CHECK (
        -- Must belong to user's admin
        (admin_id = auth.uid()) OR
        (admin_id = (SELECT admin_id FROM user_profiles WHERE id = auth.uid())) OR
        (admin_id = (SELECT id FROM user_profiles WHERE id = auth.uid() AND role = 'admin'))
    );

DROP POLICY IF EXISTS "Admin and Manager can update transactions" ON transactions;
CREATE POLICY "Admin and Manager can update transactions" ON transactions
    FOR UPDATE
    USING (
        (admin_id = auth.uid()) OR
        (admin_id = (SELECT admin_id FROM user_profiles WHERE id = auth.uid() AND role IN ('admin', 'manager')))
    );

DROP POLICY IF EXISTS "Admin can delete transactions" ON transactions;
CREATE POLICY "Admin can delete transactions" ON transactions
    FOR DELETE
    USING (
        (admin_id = auth.uid()) OR
        (admin_id = (SELECT id FROM user_profiles WHERE id = auth.uid() AND role = 'admin'))
    );

-- INVENTORY: Same pattern
DROP POLICY IF EXISTS "Users can view inventory" ON inventory;
CREATE POLICY "Users can view inventory" ON inventory
    FOR SELECT
    USING (
        (admin_id = auth.uid()) OR
        (admin_id = (SELECT admin_id FROM user_profiles WHERE id = auth.uid())) OR
        (admin_id = (SELECT id FROM user_profiles WHERE id = auth.uid() AND role = 'admin'))
    );

DROP POLICY IF EXISTS "Admin and Manager can manage inventory" ON inventory;
CREATE POLICY "Admin and Manager can manage inventory" ON inventory
    FOR ALL
    USING (
        (admin_id = auth.uid()) OR
        (admin_id = (SELECT admin_id FROM user_profiles WHERE id = auth.uid() AND role IN ('admin', 'manager')))
    );

-- STAFF: Same pattern
DROP POLICY IF EXISTS "Users can view staff" ON staff;
CREATE POLICY "Users can view staff" ON staff
    FOR SELECT
    USING (
        (admin_id = auth.uid()) OR
        (admin_id = (SELECT admin_id FROM user_profiles WHERE id = auth.uid())) OR
        (admin_id = (SELECT id FROM user_profiles WHERE id = auth.uid() AND role = 'admin'))
    );

DROP POLICY IF EXISTS "Admin and Manager can manage staff" ON staff;
CREATE POLICY "Admin and Manager can manage staff" ON staff
    FOR ALL
    USING (
        (admin_id = auth.uid()) OR
        (admin_id = (SELECT admin_id FROM user_profiles WHERE id = auth.uid() AND role IN ('admin', 'manager')))
    );

-- KPI_SETTINGS: Same pattern
DROP POLICY IF EXISTS "Users can view kpi_settings" ON kpi_settings;
CREATE POLICY "Users can view kpi_settings" ON kpi_settings
    FOR SELECT
    USING (
        (admin_id = auth.uid()) OR
        (admin_id = (SELECT admin_id FROM user_profiles WHERE id = auth.uid())) OR
        (admin_id = (SELECT id FROM user_profiles WHERE id = auth.uid() AND role = 'admin'))
    );

DROP POLICY IF EXISTS "Admin can manage kpi_settings" ON kpi_settings;
CREATE POLICY "Admin can manage kpi_settings" ON kpi_settings
    FOR ALL
    USING (
        (admin_id = auth.uid()) OR
        (admin_id = (SELECT id FROM user_profiles WHERE id = auth.uid() AND role = 'admin'))
    );

-- TAX_SETTINGS: Same pattern
DROP POLICY IF EXISTS "Users can view tax_settings" ON tax_settings;
CREATE POLICY "Users can view tax_settings" ON tax_settings
    FOR SELECT
    USING (
        (admin_id = auth.uid()) OR
        (admin_id = (SELECT admin_id FROM user_profiles WHERE id = auth.uid())) OR
        (admin_id = (SELECT id FROM user_profiles WHERE id = auth.uid() AND role = 'admin'))
    );

DROP POLICY IF EXISTS "Admin can manage tax_settings" ON tax_settings;
CREATE POLICY "Admin can manage tax_settings" ON tax_settings
    FOR ALL
    USING (
        (admin_id = auth.uid()) OR
        (admin_id = (SELECT id FROM user_profiles WHERE id = auth.uid() AND role = 'admin'))
    );

-- ============================================
-- HELPER FUNCTION: Get user's admin ID
-- ============================================
CREATE OR REPLACE FUNCTION get_user_admin_id(user_id UUID)
RETURNS UUID AS $$
DECLARE
    user_admin_id UUID;
    user_role TEXT;
BEGIN
    SELECT admin_id, role INTO user_admin_id, user_role
    FROM user_profiles
    WHERE id = user_id;
    
    -- If user is admin, return their own ID
    IF user_role = 'admin' THEN
        RETURN user_id;
    END IF;
    
    -- Otherwise return their admin_id
    RETURN user_admin_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_user_admin_id IS 'Returns the admin ID for a given user. For admins, returns their own ID. For manager/staff, returns their admin_id.';
