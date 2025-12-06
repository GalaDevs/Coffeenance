-- Verification Script for Authentication System
-- Run this in Supabase SQL Editor to verify everything is set up correctly
-- URL: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/sql/new

-- ============================================
-- CHECK 1: Verify user_profiles table exists
-- ============================================
SELECT 'user_profiles table' AS check_name,
       CASE 
           WHEN EXISTS (
               SELECT FROM information_schema.tables 
               WHERE table_schema = 'public' 
               AND table_name = 'user_profiles'
           ) THEN '✅ EXISTS'
           ELSE '❌ MISSING'
       END AS status;

-- ============================================
-- CHECK 2: View all tables in public schema
-- ============================================
SELECT table_name, 
       'Table exists' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ============================================
-- CHECK 3: Check user_profiles structure
-- ============================================
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'user_profiles'
ORDER BY ordinal_position;

-- ============================================
-- CHECK 4: Check RLS is enabled
-- ============================================
SELECT tablename, 
       rowsecurity AS rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('user_profiles', 'transactions', 'inventory', 'staff');

-- ============================================
-- CHECK 5: View RLS policies
-- ============================================
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'user_profiles';

-- ============================================
-- CHECK 6: Count existing users by role
-- ============================================
SELECT 
    role,
    COUNT(*) as count,
    STRING_AGG(email, ', ') as emails
FROM user_profiles
GROUP BY role
ORDER BY 
    CASE role 
        WHEN 'admin' THEN 1 
        WHEN 'manager' THEN 2 
        WHEN 'staff' THEN 3 
    END;

-- ============================================
-- CHECK 7: View all users (if any exist)
-- ============================================
SELECT 
    email,
    full_name,
    role,
    is_active,
    created_at
FROM user_profiles
ORDER BY created_at DESC;

-- ============================================
-- RESULTS INTERPRETATION:
-- ============================================
-- ✅ user_profiles table should EXIST
-- ✅ RLS should be ENABLED (true) for user_profiles
-- ✅ Should see multiple policies for user_profiles
-- ⚠️  Users count will be 0 until you create your first admin
-- ℹ️  If any checks fail, run the migration again:
--    `supabase db push` in your terminal
