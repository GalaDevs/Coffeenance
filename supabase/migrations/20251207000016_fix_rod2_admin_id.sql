-- Fix rod2@gmail.com admin_id to link to rod@gmail.com
UPDATE user_profiles 
SET admin_id = '563943bb-cba6-41cd-958c-46c338ae92a5',
    updated_at = NOW()
WHERE email = 'rod2@gmail.com' 
  AND role = 'manager'
  AND admin_id IS NULL;

-- Verify the fix
SELECT 
  email,
  role,
  admin_id,
  CASE 
    WHEN admin_id IS NULL AND role = 'admin' THEN '✅ Admin (owns team)'
    WHEN admin_id = '563943bb-cba6-41cd-958c-46c338ae92a5' THEN '✅ Team member of rod@gmail.com'
    WHEN admin_id = 'd03278c0-1a4d-4ce7-bd57-212a9373077b' THEN '✅ Team member of rhey@gmail.com'
    WHEN admin_id IS NULL THEN '❌ Missing admin_id'
    ELSE '✅ Team member'
  END as status
FROM user_profiles
ORDER BY 
  CASE role 
    WHEN 'admin' THEN 1 
    WHEN 'manager' THEN 2 
    WHEN 'staff' THEN 3 
  END,
  email;
