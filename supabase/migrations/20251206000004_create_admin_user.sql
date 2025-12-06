-- Create admin user profile
-- This migration creates the user profile for theyieldcoffee@admin.com

-- Insert or update the admin user profile
-- The user must already exist in auth.users (created via Supabase dashboard)
INSERT INTO public.user_profiles (id, email, role, full_name, created_at, updated_at)
SELECT 
  au.id,
  'theyieldcoffee@admin.com',
  'admin',
  'The Yield Coffee Admin',
  now(),
  now()
FROM auth.users au
WHERE au.email = 'theyieldcoffee@admin.com'
ON CONFLICT (id) DO UPDATE SET
  role = 'admin',
  full_name = 'The Yield Coffee Admin',
  updated_at = now();

-- Also update by email if exists
UPDATE public.user_profiles 
SET role = 'admin', 
    full_name = 'The Yield Coffee Admin',
    updated_at = now()
WHERE email = 'theyieldcoffee@admin.com';
