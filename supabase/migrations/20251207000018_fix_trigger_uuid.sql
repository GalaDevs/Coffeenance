-- Fix handle_new_user() trigger - admin_id type conversion issue
-- The trigger was trying to insert string as UUID

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Updated trigger function with proper UUID handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_admin_id uuid;
BEGIN
    -- Safely convert admin_id from metadata to UUID
    BEGIN
        IF NEW.raw_user_meta_data->>'admin_id' IS NOT NULL AND NEW.raw_user_meta_data->>'admin_id' != '' THEN
            v_admin_id := (NEW.raw_user_meta_data->>'admin_id')::uuid;
        ELSE
            v_admin_id := NULL;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        -- If conversion fails, set to NULL
        v_admin_id := NULL;
    END;

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
        v_admin_id,
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

SELECT '✅ Fixed handle_new_user() trigger with proper UUID handling' as status;
