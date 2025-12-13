-- ==========================================
-- FIX ORPHANED AUTH USER
-- ==========================================
-- This script fixes the issue where a user exists in auth.users
-- but is missing their profile in public.user_profiles
--
-- Issue: galadevs@gmail.com exists in auth but has no profile
-- Solution: Delete the orphaned auth user so it can be recreated properly
--
-- Run this in Supabase Dashboard → SQL Editor
-- ==========================================

-- OPTION 1: Delete the orphaned auth user (RECOMMENDED)
-- This allows you to recreate the user properly through the app
DELETE FROM auth.users 
WHERE email = 'galadevs@gmail.com';

-- After running this, you can create the user again in the app
-- and both auth record + profile will be created together


-- ==========================================
-- OPTION 2: Create the missing profile manually
-- Only use this if you want to keep the existing auth user
-- ==========================================
/*
-- First, get the auth user ID
SELECT id, email, created_at 
FROM auth.users 
WHERE email = 'galadevs@gmail.com';

-- Then insert the profile (replace USER_ID_FROM_ABOVE)
INSERT INTO public.user_profiles (
  id,
  email,
  full_name,
  role,
  created_by,
  admin_id,
  is_active,
  created_at,
  updated_at
)
VALUES (
  'USER_ID_FROM_ABOVE',  -- Replace with actual user ID
  'galadevs@gmail.com',
  'galadevs',
  'staff',
  '563943bb-cba6-41cd-958c-46c338ae92a5',  -- rod@gmail.com (admin)
  '563943bb-cba6-41cd-958c-46c338ae92a5',  -- admin_id for multi-tenancy
  true,
  NOW(),
  NOW()
);
*/

-- ==========================================
-- VERIFICATION
-- ==========================================
-- Check if auth user exists
SELECT id, email, created_at, confirmed_at
FROM auth.users 
WHERE email = 'galadevs@gmail.com';

-- Check if profile exists
SELECT id, email, full_name, role, admin_id, is_active
FROM public.user_profiles
WHERE email = 'galadevs@gmail.com';
