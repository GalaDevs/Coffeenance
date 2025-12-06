-- Create admin user: theyieldcoffee@admin.com / Yield@2025
-- This creates the user in Supabase Auth

-- First, create the user profile (this is safe to run multiple times)
INSERT INTO public.user_profiles (id, email, role, full_name, created_at, updated_at)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  'theyieldcoffee@admin.com',
  'admin',
  'The Yield Coffee Admin',
  now(),
  now()
)
ON CONFLICT (email) DO UPDATE SET
  role = 'admin',
  full_name = 'The Yield Coffee Admin',
  updated_at = now();

-- Note: You need to create the actual auth user through the Supabase dashboard
-- Go to: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/users
-- Click "Add user" and create:
--   Email: theyieldcoffee@admin.com
--   Password: Yield@2025
--   Auto Confirm: Yes
