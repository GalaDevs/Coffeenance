-- Quick Admin Setup Script
-- Run this in Supabase SQL Editor AFTER creating a user via the Dashboard

-- ============================================
-- STEP 1: Create User via Supabase Dashboard
-- ============================================
-- Go to: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut/auth/users
-- Click "Add User"
-- Email: admin@coffeenance.com
-- Password: YourSecurePassword123
-- Auto Confirm: YES
-- Then run the SQL below

-- ============================================
-- STEP 2: Make User an Admin
-- ============================================

-- Update the auth.users metadata
UPDATE auth.users 
SET raw_user_meta_data = jsonb_build_object(
    'role', 'admin',
    'full_name', 'Admin User'
)
WHERE email = 'admin@coffeenance.com';  -- Change to your admin email

-- Update or insert into user_profiles
INSERT INTO user_profiles (id, email, full_name, role, is_active)
SELECT 
    id,
    email,
    'Admin User',  -- Change to desired name
    'admin',
    true
FROM auth.users
WHERE email = 'admin@coffeenance.com'  -- Change to your admin email
ON CONFLICT (id) DO UPDATE
SET role = 'admin',
    full_name = 'Admin User',
    is_active = true;

-- ============================================
-- STEP 3: Verify Admin Was Created
-- ============================================

SELECT 
    up.email,
    up.full_name,
    up.role,
    up.is_active,
    up.created_at
FROM user_profiles up
WHERE up.role = 'admin';

-- You should see your admin user listed above
-- If not, check the email matches and try again

-- ============================================
-- OPTIONAL: Create Test Manager Account
-- ============================================
-- First create the user via Dashboard, then run:

/*
UPDATE auth.users 
SET raw_user_meta_data = jsonb_build_object(
    'role', 'manager',
    'full_name', 'Manager User'
)
WHERE email = 'manager@coffeenance.com';

INSERT INTO user_profiles (id, email, full_name, role, is_active, created_by)
SELECT 
    id,
    email,
    'Manager User',
    'manager',
    true,
    (SELECT id FROM user_profiles WHERE role = 'admin' LIMIT 1)
FROM auth.users
WHERE email = 'manager@coffeenance.com'
ON CONFLICT (id) DO UPDATE
SET role = 'manager',
    full_name = 'Manager User',
    is_active = true;
*/

-- ============================================
-- OPTIONAL: Create Test Staff Account
-- ============================================
-- First create the user via Dashboard, then run:

/*
UPDATE auth.users 
SET raw_user_meta_data = jsonb_build_object(
    'role', 'staff',
    'full_name', 'Staff User'
)
WHERE email = 'staff@coffeenance.com';

INSERT INTO user_profiles (id, email, full_name, role, is_active, created_by)
SELECT 
    id,
    email,
    'Staff User',
    'staff',
    true,
    (SELECT id FROM user_profiles WHERE role = 'admin' LIMIT 1)
FROM auth.users
WHERE email = 'staff@coffeenance.com'
ON CONFLICT (id) DO UPDATE
SET role = 'staff',
    full_name = 'Staff User',
    is_active = true;
*/

-- ============================================
-- View All Users
-- ============================================

SELECT 
    up.email,
    up.full_name,
    up.role,
    up.is_active,
    creator.email as created_by_email,
    up.created_at
FROM user_profiles up
LEFT JOIN user_profiles creator ON up.created_by = creator.id
ORDER BY 
    CASE up.role 
        WHEN 'admin' THEN 1 
        WHEN 'manager' THEN 2 
        WHEN 'staff' THEN 3 
    END,
    up.created_at;
