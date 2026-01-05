-- ============================================
-- Email Verification Configuration for Supabase
-- Run these queries in Supabase SQL Editor
-- ============================================

-- Step 1: Verify current email confirmation settings
-- Check if email confirmation is required
SELECT 
    name, 
    value 
FROM 
    auth.config 
WHERE 
    name IN ('MAILER_AUTOCONFIRM', 'SITE_URL', 'EXTERNAL_EMAIL_ENABLED');

-- Step 2: Check existing users' email confirmation status
-- See which users have verified their emails
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    CASE 
        WHEN email_confirmed_at IS NULL THEN '❌ Not Verified'
        ELSE '✅ Verified'
    END as status
FROM 
    auth.users
ORDER BY 
    created_at DESC
LIMIT 10;

-- Step 3: Manually confirm a user's email (if needed for testing)
-- Replace 'user@example.com' with the actual email
UPDATE auth.users 
SET 
    email_confirmed_at = NOW(),
    updated_at = NOW()
WHERE 
    email = 'user@example.com'
    AND email_confirmed_at IS NULL;

-- Verify the update
SELECT 
    email,
    email_confirmed_at,
    '✅ Email verified' as status
FROM 
    auth.users
WHERE 
    email = 'user@example.com';

-- Step 4: Check for users who registered but never verified
-- These users will be blocked from logging in
SELECT 
    email,
    created_at,
    EXTRACT(DAY FROM (NOW() - created_at)) as days_ago
FROM 
    auth.users
WHERE 
    email_confirmed_at IS NULL
ORDER BY 
    created_at DESC;

-- Step 5: Clean up old unverified accounts (optional)
-- Delete unverified accounts older than 7 days
-- CAUTION: This will permanently delete accounts
/*
DELETE FROM auth.users
WHERE 
    email_confirmed_at IS NULL
    AND created_at < NOW() - INTERVAL '7 days';
*/

-- Step 6: Check email rate limits (if you're hitting limits)
SELECT 
    email,
    COUNT(*) as email_count,
    MAX(created_at) as last_sent
FROM 
    auth.audit_log_entries
WHERE 
    action = 'user_signedup'
    AND created_at > NOW() - INTERVAL '1 hour'
GROUP BY 
    email
ORDER BY 
    email_count DESC;

-- ============================================
-- NOTES:
-- ============================================
-- 1. Email confirmation must be enabled in Supabase Dashboard:
--    Authentication → Providers → Email → Enable "Confirm email"
--
-- 2. Configure redirect URLs in Dashboard:
--    Authentication → URL Configuration
--    Add: coffeenance://verify-email
--
-- 3. For production, set up custom SMTP:
--    Project Settings → Authentication → SMTP Settings
--
-- 4. Email verification links expire after 24 hours by default
--
-- 5. Users cannot login until email is verified (when enabled)
-- ============================================
