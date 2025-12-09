-- Quick diagnostic: Show current RLS policies
-- Run this FIRST to see what's causing the breach

-- 1. Show ALL current policies on transactions
SELECT 
    policyname as "Policy Name",
    cmd as "Command",
    CASE 
        WHEN qual LIKE '%owner_id%' AND qual NOT LIKE '%admin_id%' THEN '✅ owner_id only'
        WHEN qual LIKE '%admin_id%' THEN '❌ USES admin_id (THIS IS THE PROBLEM!)'
        WHEN qual LIKE '%user_id%' THEN '⚠️ uses user_id'
        ELSE '❓ other'
    END as "Policy Type",
    qual as "USING Clause",
    with_check as "WITH CHECK Clause"
FROM pg_policies 
WHERE tablename = 'transactions'
AND schemaname = 'public'
ORDER BY policyname;

-- 2. Show Transaction #140 details
SELECT 
    id,
    owner_id as "Owner ID (should be rod6)",
    admin_id as "Admin ID (shows rod - WRONG!)",
    (SELECT email FROM user_profiles WHERE id = owner_id) as "Owner Email",
    (SELECT email FROM user_profiles WHERE id = admin_id) as "Admin Email",
    description,
    created_at
FROM public.transactions
WHERE id = 140;

-- 3. Check if FORCE RLS is enabled
SELECT 
    schemaname,
    tablename,
    CASE WHEN rowsecurity THEN '✅ Enabled' ELSE '❌ Disabled' END as "RLS",
    CASE WHEN c.relforcerowsecurity THEN '✅ Forced' ELSE '❌ Not Forced' END as "FORCE RLS"
FROM pg_tables t
JOIN pg_class c ON c.relname = t.tablename
WHERE tablename = 'transactions';

-- 4. Test what the current user would see
-- (Run this while logged in as rod@gmail.com)
SELECT 
    COUNT(*) as "Total Visible Transactions",
    COUNT(CASE WHEN owner_id = auth.uid() THEN 1 END) as "Mine",
    COUNT(CASE WHEN owner_id != auth.uid() THEN 1 END) as "Others (BREACH!)"
FROM public.transactions;
