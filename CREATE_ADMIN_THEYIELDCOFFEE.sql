-- Create Admin Account for TheYieldCoffee
-- Run this in Supabase SQL Editor
-- URL: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/sql/new

-- ============================================
-- STEP 1: First create the user via Supabase Dashboard
-- ============================================
-- Go to: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/users
-- Click "Add User"
-- Email: theyieldcoffee@admin.com
-- Password: Yield@2025
-- Auto Confirm User: ✅ YES
-- Click "Create User"

-- ============================================
-- STEP 2: Then run this SQL to make them admin
-- ============================================

-- Update the auth.users metadata
UPDATE auth.users 
SET raw_user_meta_data = jsonb_build_object(
    'role', 'admin',
    'full_name', 'TheYieldCoffee'
)
WHERE email = 'theyieldcoffee@admin.com';

-- Insert or update the user profile
INSERT INTO user_profiles (id, email, full_name, role, is_active)
SELECT 
    id,
    email,
    'TheYieldCoffee',
    'admin',
    true
FROM auth.users
WHERE email = 'theyieldcoffee@admin.com'
ON CONFLICT (id) DO UPDATE
SET role = 'admin',
    full_name = 'TheYieldCoffee',
    is_active = true;

-- ============================================
-- STEP 3: Verify the admin was created
-- ============================================

SELECT 
    email,
    full_name,
    role,
    is_active,
    created_at
FROM user_profiles
WHERE email = 'theyieldcoffee@admin.com';

-- You should see:
-- email: theyieldcoffee@admin.com
-- full_name: TheYieldCoffee
-- role: admin
-- is_active: true

-- ============================================
-- LOGIN CREDENTIALS:
-- ============================================
-- Username (Email): theyieldcoffee@admin.com
-- Password: Yield@2025
-- Role: Admin (full access)
