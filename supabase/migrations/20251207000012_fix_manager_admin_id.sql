-- Fix admin_id for manager/staff accounts that have NULL admin_id
-- Manager/Staff should have admin_id pointing to their admin

-- Update rhey1@gmail.com to link to rhey@gmail.com
UPDATE user_profiles 
SET admin_id = 'd03278c0-1a4d-4ce7-bd57-212a9373077b',
    updated_at = NOW()
WHERE email = 'rhey1@gmail.com' 
  AND role = 'manager'
  AND admin_id IS NULL;

-- Display current state
SELECT 
  email,
  role,
  admin_id,
  CASE 
    WHEN admin_id IS NULL AND role = 'admin' THEN '✅ Admin (no admin_id needed)'
    WHEN admin_id IS NOT NULL AND role IN ('manager', 'staff') THEN '✅ Team member (linked to admin)'
    ELSE '❌ Missing admin_id'
  END as status
FROM user_profiles
ORDER BY role, email;
