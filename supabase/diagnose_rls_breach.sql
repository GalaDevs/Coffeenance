-- Diagnostic query to find the RLS breach cause
-- Run this in Supabase SQL Editor while logged in as rod@gmail.com

-- 1. Check current policies on transactions table
SELECT 
  policyname,
  cmd,
  qual as "USING clause",
  with_check as "WITH CHECK clause"
FROM pg_policies 
WHERE tablename = 'transactions'
ORDER BY policyname;

-- 2. Find the problematic transaction
SELECT 
  id,
  owner_id,
  admin_id,
  user_id,
  description,
  created_at,
  (SELECT email FROM user_profiles WHERE id = owner_id) as owner_email,
  (SELECT email FROM user_profiles WHERE id = admin_id) as admin_email
FROM transactions 
WHERE id = 140;

-- 3. Check if any policies use admin_id (THIS IS THE PROBLEM)
SELECT 
  policyname,
  qual
FROM pg_policies 
WHERE tablename = 'transactions'
AND (qual LIKE '%admin_id%' OR with_check LIKE '%admin_id%');

-- 4. Check for helper functions that might be interfering
SELECT 
  routine_name,
  routine_definition
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name LIKE '%admin%';

-- 5. Test the query that should work
-- This should return 0 rows for rod@gmail.com since owner_id doesn't match
SELECT COUNT(*) 
FROM transactions 
WHERE id = 140 
AND owner_id = auth.uid();

-- 6. Check if FORCE RLS is enabled
SELECT 
  tablename,
  rowsecurity as "RLS Enabled",
  relforcerowsecurity as "FORCE RLS"
FROM pg_tables t
JOIN pg_class c ON c.relname = t.tablename
WHERE tablename = 'transactions';
