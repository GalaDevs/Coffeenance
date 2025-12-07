-- Disable email confirmation for auto-created accounts
-- This allows newly created users to login immediately without email verification

-- Note: This SQL affects the auth.config table which may not be directly accessible
-- You need to configure this in Supabase Dashboard instead:
-- 1. Go to: Authentication → Email Auth → Confirm email
-- 2. Disable "Confirm email" toggle

-- Alternative: We'll ensure users are auto-confirmed when created
-- by setting their email_confirmed_at timestamp

-- This is a placeholder migration to document the requirement
-- The actual configuration must be done in Supabase Dashboard:
-- https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/providers

SELECT 'Email confirmation should be disabled in Supabase Dashboard' as note;
