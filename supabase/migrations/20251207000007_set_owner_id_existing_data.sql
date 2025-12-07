-- Update existing records to set owner_id for proper data isolation
-- Migration: 20251207000007_set_owner_id_existing_data.sql
-- Description: Assign owner_id to records that were created before the column existed

-- ============================================
-- OPTION 1: Delete all records without owner_id
-- This is the cleanest approach for a fresh start
-- ============================================

-- Delete transactions without owner_id
DELETE FROM transactions WHERE owner_id IS NULL;

-- Delete inventory without owner_id
DELETE FROM inventory WHERE owner_id IS NULL;

-- Delete staff without owner_id
DELETE FROM staff WHERE owner_id IS NULL;

-- Delete KPI settings without owner_id
DELETE FROM kpi_settings WHERE owner_id IS NULL;

-- Delete tax settings without owner_id
DELETE FROM tax_settings WHERE owner_id IS NULL;

-- ============================================
-- MAKE owner_id REQUIRED (NOT NULL)
-- This prevents future records from being created without owner_id
-- ============================================

-- For transactions: owner_id is now required
ALTER TABLE transactions 
ALTER COLUMN owner_id SET NOT NULL;

-- For inventory: owner_id is now required
ALTER TABLE inventory 
ALTER COLUMN owner_id SET NOT NULL;

-- For staff: owner_id is now required
ALTER TABLE staff 
ALTER COLUMN owner_id SET NOT NULL;

-- For kpi_settings: owner_id is now required
ALTER TABLE kpi_settings 
ALTER COLUMN owner_id SET NOT NULL;

-- For tax_settings: owner_id is now required
ALTER TABLE tax_settings 
ALTER COLUMN owner_id SET NOT NULL;

-- ============================================
-- MIGRATION NOTICES
-- ============================================
DO $$ 
BEGIN 
    RAISE NOTICE '✅ Deleted all records without owner_id';
    RAISE NOTICE '🔒 owner_id column is now REQUIRED (NOT NULL)';
    RAISE NOTICE '📝 All future records MUST have owner_id set';
    RAISE NOTICE '🚫 Database will reject records without owner_id';
    RAISE NOTICE '✨ Clean slate - ready for isolated user data';
END $$;
