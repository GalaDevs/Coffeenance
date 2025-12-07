-- FORCE complete owner_id isolation - Remove ALL conflicting policies
-- Migration: 20251207000008_force_owner_id_rls.sql
-- Description: Nuclear option - Drop ALL RLS policies and recreate with strict owner_id = auth.uid()

-- ============================================
-- DROP ALL EXISTING POLICIES (NUCLEAR CLEAN)
-- ============================================

-- Drop helper function from previous migration that uses admin_id
DROP FUNCTION IF EXISTS current_user_admin_id() CASCADE;

-- USER_PROFILES - Drop all policies
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'user_profiles') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON user_profiles', r.policyname);
    END LOOP;
END $$;

-- TRANSACTIONS - Drop all policies
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'transactions') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON transactions', r.policyname);
    END LOOP;
END $$;

-- INVENTORY - Drop all policies
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'inventory') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON inventory', r.policyname);
    END LOOP;
END $$;

-- STAFF - Drop all policies
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'staff') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON staff', r.policyname);
    END LOOP;
END $$;

-- KPI_SETTINGS - Drop all policies
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'kpi_settings') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON kpi_settings', r.policyname);
    END LOOP;
END $$;

-- TAX_SETTINGS - Drop all policies
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'tax_settings') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON tax_settings', r.policyname);
    END LOOP;
END $$;

-- ============================================
-- FORCE ENABLE RLS
-- ============================================
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE kpi_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_settings ENABLE ROW LEVEL SECURITY;

-- Force RLS for table owners too (no bypass)
ALTER TABLE user_profiles FORCE ROW LEVEL SECURITY;
ALTER TABLE transactions FORCE ROW LEVEL SECURITY;
ALTER TABLE inventory FORCE ROW LEVEL SECURITY;
ALTER TABLE staff FORCE ROW LEVEL SECURITY;
ALTER TABLE kpi_settings FORCE ROW LEVEL SECURITY;
ALTER TABLE tax_settings FORCE ROW LEVEL SECURITY;

-- ============================================
-- USER_PROFILES - Allow users to see own profile and register
-- ============================================

CREATE POLICY "owner_select_user_profiles" ON user_profiles
    FOR SELECT
    USING (id = auth.uid());

CREATE POLICY "owner_insert_user_profiles" ON user_profiles
    FOR INSERT
    WITH CHECK (id = auth.uid());

CREATE POLICY "owner_update_user_profiles" ON user_profiles
    FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Note: No DELETE policy for user_profiles (prevent self-deletion)

-- ============================================
-- TRANSACTIONS - ABSOLUTE STRICT owner_id ISOLATION
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
-- INVENTORY - ABSOLUTE STRICT owner_id ISOLATION
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
-- STAFF - ABSOLUTE STRICT owner_id ISOLATION
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
-- KPI_SETTINGS - ABSOLUTE STRICT owner_id ISOLATION
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
-- TAX_SETTINGS - ABSOLUTE STRICT owner_id ISOLATION
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
-- VERIFICATION & NOTICES
-- ============================================
DO $$ 
BEGIN 
    RAISE NOTICE '';
    RAISE NOTICE '🔥 ============================================';
    RAISE NOTICE '🔥 NUCLEAR RLS RESET COMPLETE';
    RAISE NOTICE '🔥 ============================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ ALL old policies DROPPED';
    RAISE NOTICE '✅ Helper functions REMOVED';
    RAISE NOTICE '✅ FORCE ROW LEVEL SECURITY enabled';
    RAISE NOTICE '✅ NEW policies created: owner_id = auth.uid()';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 ISOLATION RULES:';
    RAISE NOTICE '   • Each user sees ONLY their owner_id records';
    RAISE NOTICE '   • auth.uid() = current session user ID';
    RAISE NOTICE '   • No admin_id logic - pure owner_id isolation';
    RAISE NOTICE '   • No cross-user data access possible';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  IMPORTANT: Test with DataIsolationTestScreen';
    RAISE NOTICE '';
END $$;
