-- Enable Email Verification for Account Security
-- This migration configures email confirmation/verification for new signups
-- Users must verify their email via a code/link before accessing the app

-- Note: This SQL script documents the configuration requirements
-- The actual settings must be configured in Supabase Dashboard:
-- 
-- 1. Go to: Authentication → Providers → Email
-- 2. Enable "Confirm email" toggle
-- 3. Optional: Customize email templates in Authentication → Email Templates
--
-- Dashboard URL: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/providers

-- Create a function to check if email is confirmed
CREATE OR REPLACE FUNCTION check_email_confirmed()
RETURNS TRIGGER AS $$
BEGIN
  -- Only allow login if email is confirmed
  IF NEW.email_confirmed_at IS NULL THEN
    RAISE EXCEPTION 'Email not confirmed. Please verify your email first.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add notice for successful migration
DO $$ 
BEGIN 
    RAISE NOTICE '✅ Email verification migration created';
    RAISE NOTICE '📧 MANUAL ACTION REQUIRED:';
    RAISE NOTICE '   1. Go to Supabase Dashboard → Authentication → Providers';
    RAISE NOTICE '   2. Click on "Email" provider';
    RAISE NOTICE '   3. Enable "Confirm email" toggle';
    RAISE NOTICE '   4. Save changes';
    RAISE NOTICE '';
    RAISE NOTICE '📝 Optional Email Template Customization:';
    RAISE NOTICE '   Go to Authentication → Email Templates';
    RAISE NOTICE '   Customize "Confirm signup" template';
    RAISE NOTICE '';
    RAISE NOTICE '🔐 Users will now need to verify their email before logging in';
END $$;
