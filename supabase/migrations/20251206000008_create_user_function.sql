-- Create a function to add users to user_profiles table
-- This allows creating user records without triggering auth state changes

-- First, create a function that the admin can call to create user profiles
CREATE OR REPLACE FUNCTION create_user_profile(
  p_email TEXT,
  p_full_name TEXT,
  p_role TEXT,
  p_created_by UUID
)
RETURNS TABLE(
  id UUID,
  email TEXT,
  full_name TEXT,
  role TEXT,
  is_active BOOLEAN,
  created_at TIMESTAMPTZ
) 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_new_user_id UUID;
  v_admin_role TEXT;
BEGIN
  -- Verify the creator is an admin
  SELECT user_profiles.role INTO v_admin_role
  FROM user_profiles
  WHERE user_profiles.id = p_created_by;
  
  IF v_admin_role != 'admin' THEN
    RAISE EXCEPTION 'Only admins can create users';
  END IF;
  
  -- Validate role
  IF p_role NOT IN ('manager', 'staff') THEN
    RAISE EXCEPTION 'Invalid role. Must be manager or staff';
  END IF;
  
  -- Check account limits
  IF p_role = 'manager' THEN
    IF (SELECT COUNT(*) FROM user_profiles WHERE role = 'manager' AND is_active = true) >= 1 THEN
      RAISE EXCEPTION 'Maximum 1 manager account allowed';
    END IF;
  END IF;
  
  IF p_role = 'staff' THEN
    IF (SELECT COUNT(*) FROM user_profiles WHERE role = 'staff' AND is_active = true) >= 2 THEN
      RAISE EXCEPTION 'Maximum 2 staff accounts allowed';
    END IF;
  END IF;
  
  -- Generate a new UUID for the user
  v_new_user_id := gen_random_uuid();
  
  -- Insert the user profile (password will be set later when they first login)
  INSERT INTO user_profiles (id, email, full_name, role, created_by, is_active)
  VALUES (v_new_user_id, p_email, p_full_name, p_role, p_created_by, true);
  
  -- Return the created user profile
  RETURN QUERY
  SELECT 
    user_profiles.id,
    user_profiles.email,
    user_profiles.full_name,
    user_profiles.role,
    user_profiles.is_active,
    user_profiles.created_at
  FROM user_profiles
  WHERE user_profiles.id = v_new_user_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_user_profile(TEXT, TEXT, TEXT, UUID) TO authenticated;

COMMENT ON FUNCTION create_user_profile IS 'Creates a user profile record without triggering auth state changes. Used by admin to create manager/staff accounts. Users must set their password through Supabase Auth separately.';
