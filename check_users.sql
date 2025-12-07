-- Query to check all users in user_profiles table
SELECT 
  id,
  email,
  full_name,
  role,
  is_active,
  created_at,
  created_by
FROM user_profiles
ORDER BY created_at DESC;
