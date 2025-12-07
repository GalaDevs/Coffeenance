-- Fix handle_new_user() trigger - Remove ON CONFLICT to prevent duplicate key errors
-- The trigger should only insert if profile doesn't exist

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Updated trigger function that checks if profile exists first
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_admin_id uuid;
    v_profile_exists boolean;
BEGIN
    -- Check if profile already exists
    SELECT EXISTS(SELECT 1 FROM public.user_profiles WHERE id = NEW.id) INTO v_profile_exists;
    
    -- If profile already exists, skip insert (upsert will be done by app)
    IF v_profile_exists THEN
        RETURN NEW;
    END IF;

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

    -- Insert new profile
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
            v_admin_id,
            COALESCE(NEW.raw_user_meta_data->>'created_by', ''),
            true
        );
    EXCEPTION WHEN unique_violation THEN
        -- Profile was created between check and insert, ignore error
        NULL;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

SELECT '✅ Fixed handle_new_user() trigger to prevent duplicate errors' as status;
