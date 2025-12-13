-- Verify Team Structure and Admin ID Assignments
-- Run this to check if staff/managers are properly linked to their admin

-- ============================================
-- CHECK 1: Show all users with their admin relationships
-- ============================================
SELECT 
    id,
    email,
    role,
    admin_id,
    (SELECT email FROM user_profiles WHERE id = user_profiles.admin_id) as admin_email,
    is_active,
    CASE 
        WHEN role = 'admin' AND admin_id IS NULL THEN '✅ Admin (correct)'
        WHEN role = 'manager' AND admin_id IS NOT NULL THEN '✅ Manager (has admin)'
        WHEN role = 'staff' AND admin_id IS NOT NULL THEN '✅ Staff (has admin)'
        WHEN role = 'manager' AND admin_id IS NULL THEN '❌ Manager missing admin_id!'
        WHEN role = 'staff' AND admin_id IS NULL THEN '❌ Staff missing admin_id!'
        WHEN role = 'admin' AND admin_id IS NOT NULL THEN '⚠️ Admin has admin_id (unusual)'
        ELSE '❓ Unknown state'
    END as status
FROM user_profiles
ORDER BY role, email;

-- ============================================
-- CHECK 2: Show teams grouped by admin
-- ============================================
SELECT 
    COALESCE(admin_id, id) as team_admin_id,
    (SELECT email FROM user_profiles WHERE id = COALESCE(user_profiles.admin_id, user_profiles.id)) as team_admin_email,
    COUNT(*) as team_size,
    STRING_AGG(email || ' (' || role || ')', ', ' ORDER BY 
        CASE role 
            WHEN 'admin' THEN 1 
            WHEN 'manager' THEN 2 
            WHEN 'staff' THEN 3 
        END
    ) as team_members
FROM user_profiles
WHERE is_active = true
GROUP BY COALESCE(admin_id, id)
ORDER BY team_size DESC;

-- ============================================
-- CHECK 3: Show transactions grouped by admin_id
-- ============================================
SELECT 
    admin_id,
    (SELECT email FROM user_profiles WHERE id = transactions.admin_id) as admin_email,
    COUNT(*) as total_transactions,
    COUNT(DISTINCT owner_id) as unique_owners,
    STRING_AGG(DISTINCT (SELECT email FROM user_profiles WHERE id = owner_id), ', ') as who_created
FROM transactions
GROUP BY admin_id
ORDER BY total_transactions DESC;

-- ============================================
-- CHECK 4: Find orphaned staff/managers (missing admin_id)
-- ============================================
SELECT 
    id,
    email,
    role,
    'Missing admin_id - this user cannot see team data!' as issue
FROM user_profiles
WHERE (role = 'manager' OR role = 'staff')
  AND admin_id IS NULL;

-- ============================================
-- CHECK 5: Verify RLS function works correctly
-- ============================================
-- Test what admin_id the function returns for each user
SELECT 
    id,
    email,
    role,
    admin_id as stored_admin_id,
    CASE 
        WHEN role = 'admin' THEN id
        ELSE admin_id
    END as expected_admin_id
FROM user_profiles
ORDER BY role, email;
