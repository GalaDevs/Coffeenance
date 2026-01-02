-- Add Developer Role
-- Created: 2025-12-12
-- Description: Add developer role with full access permissions

-- Drop existing check constraint
ALTER TABLE public.user_profiles DROP CONSTRAINT IF EXISTS user_profiles_role_check;

-- Add new check constraint with developer role
ALTER TABLE public.user_profiles ADD CONSTRAINT user_profiles_role_check 
  CHECK (role IN ('admin', 'manager', 'staff', 'developer'));
