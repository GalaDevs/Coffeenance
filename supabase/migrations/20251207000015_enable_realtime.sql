-- Enable realtime replication for all data tables
-- This ensures team members get instant updates when any team member adds/updates data

-- Safely add tables to realtime publication (skip if already exists)
DO $$
BEGIN
    -- Enable realtime for transactions
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE transactions;
        RAISE NOTICE '✅ Added transactions to realtime';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE '⚠️ transactions already in realtime';
    END;

    -- Enable realtime for inventory
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE inventory;
        RAISE NOTICE '✅ Added inventory to realtime';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE '⚠️ inventory already in realtime';
    END;

    -- Enable realtime for staff
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE staff;
        RAISE NOTICE '✅ Added staff to realtime';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE '⚠️ staff already in realtime';
    END;

    -- Enable realtime for user_profiles (for user management updates)
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE user_profiles;
        RAISE NOTICE '✅ Added user_profiles to realtime';
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE '⚠️ user_profiles already in realtime';
    END;
END $$;

-- Verify realtime is enabled
SELECT 
  '🔔 REALTIME ENABLED FOR:' as info,
  schemaname,
  tablename
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;
