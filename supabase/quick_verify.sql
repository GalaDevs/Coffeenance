-- Quick verification - Check 1: User roles and admin relationships
SELECT 
    email,
    role,
    CASE 
        WHEN role = 'admin' AND admin_id IS NULL THEN '✅ Admin (correct)'
        WHEN role = 'manager' AND admin_id IS NOT NULL THEN '✅ Manager (has admin)'
        WHEN role = 'staff' AND admin_id IS NOT NULL THEN '✅ Staff (has admin)'
        WHEN role = 'manager' AND admin_id IS NULL THEN '❌ Manager missing admin_id!'
        WHEN role = 'staff' AND admin_id IS NULL THEN '❌ Staff missing admin_id!'
        ELSE '❓ Unknown'
    END as status,
    (SELECT email FROM user_profiles WHERE id = user_profiles.admin_id) as admin_email
FROM user_profiles
ORDER BY role, email;
