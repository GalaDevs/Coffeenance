-- COPY THIS ENTIRE FILE AND RUN IN SUPABASE SQL EDITOR
-- This will fix the "developer role" error

ALTER TABLE public.user_profiles DROP CONSTRAINT IF EXISTS user_profiles_role_check;
ALTER TABLE public.user_profiles ADD CONSTRAINT user_profiles_role_check 
  CHECK (role IN ('admin', 'manager', 'staff', 'developer'));
