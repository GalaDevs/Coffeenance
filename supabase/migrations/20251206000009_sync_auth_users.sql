-- Migration to sync Auth users to user_profiles table
-- This ensures users created in Supabase Auth dashboard also appear in user_profiles

-- Create or update user profiles for all auth users
DO $$
DECLARE
  auth_user RECORD;
BEGIN
  -- Loop through all users in auth.users that don't have a profile
  FOR auth_user IN 
    SELECT 
      au.id,
      au.email,
      au.raw_user_meta_data->>'full_name' as full_name,
      au.raw_user_meta_data->>'role' as role
    FROM auth.users au
    LEFT JOIN user_profiles up ON au.id = up.id
    WHERE up.id IS NULL
  LOOP
    -- Insert missing user profile
    INSERT INTO user_profiles (
      id,
      email,
      full_name,
      role,
      is_active,
      created_at
    ) VALUES (
      auth_user.id,
      auth_user.email,
      COALESCE(auth_user.full_name, split_part(auth_user.email, '@', 1)),
      COALESCE(auth_user.role, 'staff'), -- Default to staff if no role set
      true,
      NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    
    RAISE NOTICE 'Synced user: %', auth_user.email;
  END LOOP;
END $$;

-- Show all users after sync
SELECT 
  up.id,
  up.email,
  up.full_name,
  up.role,
  up.is_active,
  CASE 
    WHEN au.id IS NOT NULL THEN 'Has Auth Account'
    ELSE 'No Auth Account'
  END as auth_status
FROM user_profiles up
LEFT JOIN auth.users au ON up.id = au.id
ORDER BY up.created_at DESC;
