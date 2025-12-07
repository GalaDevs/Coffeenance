-- Reset all existing data for fresh start with proper tenant isolation
-- Migration: 20251207000002_reset_all_data.sql
-- Description: Delete all existing data to start clean with multi-tenancy

-- ============================================
-- DELETE ALL DATA FROM ALL TABLES
-- ============================================

-- Delete all transactions
DELETE FROM transactions;

-- Delete all inventory
DELETE FROM inventory;

-- Delete all staff
DELETE FROM staff;

-- Delete all KPI settings
DELETE FROM kpi_settings;

-- Delete all tax settings
DELETE FROM tax_settings;

-- Delete all user profiles
DELETE FROM user_profiles;

-- ============================================
-- RESET SEQUENCES (if any)
-- ============================================

-- Reset any auto-increment sequences if needed
-- (Currently not applicable as we use UUIDs)

-- ============================================
-- VERIFICATION
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '✅ All data deleted successfully';
    RAISE NOTICE '🔄 Database reset complete - ready for fresh tenant data';
    RAISE NOTICE '📝 Next: Register new coffee shops via the app';
    RAISE NOTICE '🏢 Each new registration will have completely isolated data';
END $$;
