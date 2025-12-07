-- Remove foreign key constraint that blocks user creation
-- This allows creating user_profiles without requiring auth.users entry first

-- Drop the foreign key constraint
ALTER TABLE public.user_profiles 
DROP CONSTRAINT IF EXISTS user_profiles_id_fkey;

-- User profiles can now be created independently
-- The id field remains UUID but is not linked to auth.users
