-- ============================================
-- Email Verification Setup for Supabase
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Create helper function to check if email is confirmed in auth.users
CREATE OR REPLACE FUNCTION public.check_email_confirmed(user_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    is_confirmed BOOLEAN;
BEGIN
    SELECT 
        CASE 
            WHEN email_confirmed_at IS NOT NULL THEN true 
            ELSE false 
        END INTO is_confirmed
    FROM auth.users
    WHERE email = LOWER(user_email);
    
    RETURN COALESCE(is_confirmed, false);
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.check_email_confirmed(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_email_confirmed(TEXT) TO anon;

-- Step 2: Ensure user_profiles has email_verified column
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false;

-- Step 3: Create index for faster email lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_email 
ON public.user_profiles(email);

-- Step 4: Sync existing verified users from auth.users to user_profiles
UPDATE public.user_profiles up
SET email_verified = true
FROM auth.users au
WHERE up.id = au.id 
  AND au.email_confirmed_at IS NOT NULL
  AND (up.email_verified IS NULL OR up.email_verified = false);

-- Verification: Check current verification status
SELECT 
    up.email,
    up.email_verified as profile_verified,
    au.email_confirmed_at IS NOT NULL as auth_verified
FROM public.user_profiles up
LEFT JOIN auth.users au ON up.id = au.id
LIMIT 10;
