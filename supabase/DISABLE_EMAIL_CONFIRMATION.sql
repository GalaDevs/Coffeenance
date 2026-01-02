-- ============================================
-- DISABLE EMAIL CONFIRMATION IN SUPABASE
-- ============================================
-- 
-- This needs to be done in the Supabase Dashboard:
-- 
-- 1. Go to: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/providers
-- 2. Click on "Email" provider settings
-- 3. Find "Confirm email" and TURN IT OFF
-- 4. Click Save
--
-- ============================================
-- OR: Auto-confirm existing users with this SQL:
-- ============================================

-- Auto-confirm ALL users who haven't confirmed their email yet
UPDATE auth.users 
SET email_confirmed_at = NOW(),
    updated_at = NOW()
WHERE email_confirmed_at IS NULL;

-- Verify the change
SELECT id, email, email_confirmed_at 
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 10;
