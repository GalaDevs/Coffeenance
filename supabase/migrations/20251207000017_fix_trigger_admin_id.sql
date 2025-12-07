-- Fix handle_new_user() trigger to include admin_id from metadata
-- This ensures when signUp() is called with admin_id in metadata, it's stored in the profile

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Updated trigger function that includes admin_id and created_by from metadata
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (
        id, 
        email, 
        full_name, 
        role,
        admin_id,
        created_by,
        is_active
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        COALESCE(NEW.raw_user_meta_data->>'role', 'staff'),
        -- Extract admin_id from metadata (will be NULL for admin accounts)
        CASE 
            WHEN NEW.raw_user_meta_data->>'admin_id' IS NOT NULL 
            THEN (NEW.raw_user_meta_data->>'admin_id')::uuid
            ELSE NULL
        END,
        -- Extract created_by from metadata
        COALESCE(NEW.raw_user_meta_data->>'created_by', ''),
        true
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        role = EXCLUDED.role,
        admin_id = EXCLUDED.admin_id,
        created_by = EXCLUDED.created_by,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Test the function
SELECT '✅ Updated handle_new_user() trigger to include admin_id from metadata' as status;
