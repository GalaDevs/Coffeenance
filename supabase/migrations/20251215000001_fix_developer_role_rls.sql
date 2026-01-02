-- Fix RLS policies to support developer role
-- Developers should be treated like admins (they own their own data)

BEGIN;

-- ============================================
-- STEP 1: Update helper function to handle developer role
-- ============================================
CREATE OR REPLACE FUNCTION get_current_user_admin_id()
RETURNS UUID AS $$
DECLARE
    user_admin_id UUID;
    user_role TEXT;
BEGIN
    -- Get current user's role and admin_id
    SELECT role, admin_id INTO user_role, user_admin_id
    FROM user_profiles
    WHERE id = auth.uid();
    
    -- If user is admin OR developer, return their own ID
    -- Developers are essentially their own admin (they have full access to their own data)
    IF user_role IN ('admin', 'developer') THEN
        RETURN auth.uid();
    END IF;
    
    -- If user is manager/staff, return their admin_id
    RETURN user_admin_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- STEP 2: Ensure developer profile has correct admin_id
-- ============================================
-- Developers should have admin_id = their own ID (they are their own admin)
UPDATE user_profiles
SET admin_id = id,
    updated_at = NOW()
WHERE role = 'developer' 
  AND (admin_id IS NULL OR admin_id != id);

-- ============================================
-- STEP 3: Verify the fix
-- ============================================
SELECT 
    id,
    email,
    role,
    admin_id,
    CASE 
        WHEN role = 'admin' AND admin_id IS NULL THEN '✅ Admin (no admin_id needed)'
        WHEN role = 'developer' AND admin_id = id THEN '✅ Developer (self-admin)'
        WHEN role IN ('manager', 'staff') AND admin_id IS NOT NULL THEN '✅ Team member with admin'
        WHEN role = 'developer' AND admin_id IS NULL THEN '⚠️ Developer needs admin_id = self'
        ELSE '❓ Check config'
    END as status
FROM user_profiles
ORDER BY role, email;

COMMIT;
