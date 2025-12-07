-- Add owner_id column and enforce strict RLS for complete data isolation
-- Migration: 20251207000005_add_owner_id_rls.sql
-- Description: Each user can ONLY see/modify their own records (owner_id = auth.uid())

-- ============================================
-- ADD OWNER_ID TO ALL DATA TABLES
-- ============================================

-- Add owner_id to transactions
ALTER TABLE transactions 
ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add owner_id to inventory
ALTER TABLE inventory 
ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add owner_id to staff
ALTER TABLE staff 
ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add owner_id to kpi_settings
ALTER TABLE kpi_settings 
ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add owner_id to tax_settings
ALTER TABLE tax_settings 
ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_transactions_owner ON transactions(owner_id);
CREATE INDEX IF NOT EXISTS idx_inventory_owner ON inventory(owner_id);
CREATE INDEX IF NOT EXISTS idx_staff_owner ON staff(owner_id);
CREATE INDEX IF NOT EXISTS idx_kpi_settings_owner ON kpi_settings(owner_id);
CREATE INDEX IF NOT EXISTS idx_tax_settings_owner ON tax_settings(owner_id);

-- ============================================
-- DROP ALL EXISTING RLS POLICIES
-- ============================================

-- Transactions
DROP POLICY IF EXISTS "tenant_isolation_select_transactions" ON transactions;
DROP POLICY IF EXISTS "tenant_isolation_insert_transactions" ON transactions;
DROP POLICY IF EXISTS "tenant_isolation_update_transactions" ON transactions;
DROP POLICY IF EXISTS "tenant_isolation_delete_transactions" ON transactions;

-- Inventory
DROP POLICY IF EXISTS "tenant_isolation_select_inventory" ON inventory;
DROP POLICY IF EXISTS "tenant_isolation_insert_inventory" ON inventory;
DROP POLICY IF EXISTS "tenant_isolation_update_inventory" ON inventory;
DROP POLICY IF EXISTS "tenant_isolation_delete_inventory" ON inventory;

-- Staff
DROP POLICY IF EXISTS "tenant_isolation_select_staff" ON staff;
DROP POLICY IF EXISTS "tenant_isolation_insert_staff" ON staff;
DROP POLICY IF EXISTS "tenant_isolation_update_staff" ON staff;
DROP POLICY IF EXISTS "tenant_isolation_delete_staff" ON staff;

-- KPI Settings
DROP POLICY IF EXISTS "tenant_isolation_select_kpi_settings" ON kpi_settings;
DROP POLICY IF EXISTS "tenant_isolation_insert_kpi_settings" ON kpi_settings;
DROP POLICY IF EXISTS "tenant_isolation_update_kpi_settings" ON kpi_settings;
DROP POLICY IF EXISTS "tenant_isolation_delete_kpi_settings" ON kpi_settings;

-- Tax Settings
DROP POLICY IF EXISTS "tenant_isolation_select_tax_settings" ON tax_settings;
DROP POLICY IF EXISTS "tenant_isolation_insert_tax_settings" ON tax_settings;
DROP POLICY IF EXISTS "tenant_isolation_update_tax_settings" ON tax_settings;
DROP POLICY IF EXISTS "tenant_isolation_delete_tax_settings" ON tax_settings;

-- ============================================
-- ENABLE RLS ON ALL TABLES
-- ============================================
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE kpi_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_settings ENABLE ROW LEVEL SECURITY;

-- ============================================
-- TRANSACTIONS - STRICT OWNER-ONLY POLICIES
-- ============================================

CREATE POLICY "owner_select_transactions" ON transactions
    FOR SELECT
    USING (owner_id = auth.uid());

CREATE POLICY "owner_insert_transactions" ON transactions
    FOR INSERT
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY "owner_update_transactions" ON transactions
    FOR UPDATE
    USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY "owner_delete_transactions" ON transactions
    FOR DELETE
    USING (owner_id = auth.uid());

-- ============================================
-- INVENTORY - STRICT OWNER-ONLY POLICIES
-- ============================================

CREATE POLICY "owner_select_inventory" ON inventory
    FOR SELECT
    USING (owner_id = auth.uid());

CREATE POLICY "owner_insert_inventory" ON inventory
    FOR INSERT
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY "owner_update_inventory" ON inventory
    FOR UPDATE
    USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY "owner_delete_inventory" ON inventory
    FOR DELETE
    USING (owner_id = auth.uid());

-- ============================================
-- STAFF - STRICT OWNER-ONLY POLICIES
-- ============================================

CREATE POLICY "owner_select_staff" ON staff
    FOR SELECT
    USING (owner_id = auth.uid());

CREATE POLICY "owner_insert_staff" ON staff
    FOR INSERT
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY "owner_update_staff" ON staff
    FOR UPDATE
    USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY "owner_delete_staff" ON staff
    FOR DELETE
    USING (owner_id = auth.uid());

-- ============================================
-- KPI_SETTINGS - STRICT OWNER-ONLY POLICIES
-- ============================================

CREATE POLICY "owner_select_kpi_settings" ON kpi_settings
    FOR SELECT
    USING (owner_id = auth.uid());

CREATE POLICY "owner_insert_kpi_settings" ON kpi_settings
    FOR INSERT
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY "owner_update_kpi_settings" ON kpi_settings
    FOR UPDATE
    USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY "owner_delete_kpi_settings" ON kpi_settings
    FOR DELETE
    USING (owner_id = auth.uid());

-- ============================================
-- TAX_SETTINGS - STRICT OWNER-ONLY POLICIES
-- ============================================

CREATE POLICY "owner_select_tax_settings" ON tax_settings
    FOR SELECT
    USING (owner_id = auth.uid());

CREATE POLICY "owner_insert_tax_settings" ON tax_settings
    FOR INSERT
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY "owner_update_tax_settings" ON tax_settings
    FOR UPDATE
    USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY "owner_delete_tax_settings" ON tax_settings
    FOR DELETE
    USING (owner_id = auth.uid());

-- ============================================
-- MIGRATION NOTICES
-- ============================================
DO $$ 
BEGIN 
    RAISE NOTICE '✅ owner_id column added to all tables';
    RAISE NOTICE '🔒 Strict RLS policies enforced: owner_id = auth.uid()';
    RAISE NOTICE '⚠️  IMPORTANT: Update existing records to set owner_id';
    RAISE NOTICE '📝 Each user can ONLY access their own data';
    RAISE NOTICE '🚫 Cross-user data leakage prevented';
END $$;
