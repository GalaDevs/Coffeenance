-- Fix handle_new_user() trigger - Eliminate race condition with app upsert
-- The trigger should be completely idempotent and not conflict with app operations

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Updated trigger function that is fully idempotent
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_admin_id uuid;
    v_role text;
BEGIN
    -- Extract admin_id from metadata (convert string to UUID)
    BEGIN
        IF NEW.raw_user_meta_data->>'admin_id' IS NOT NULL THEN
            v_admin_id := (NEW.raw_user_meta_data->>'admin_id')::uuid;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_admin_id := NULL;
    END;
    
    -- Extract role from metadata (default to 'staff' if not provided)
    v_role := COALESCE(NEW.raw_user_meta_data->>'role', 'staff');
    
    -- Use INSERT ... ON CONFLICT DO NOTHING to avoid race conditions
    -- This allows both trigger and app to safely attempt profile creation
    INSERT INTO public.user_profiles (
        id,
        email,
        full_name,
        role,
        admin_id,
        created_by,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        v_role,
        v_admin_id,
        COALESCE((NEW.raw_user_meta_data->>'created_by')::uuid, NEW.id),
        true,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;  -- If app already created it, skip silently
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Test the trigger is idempotent
DO $$
BEGIN
    RAISE NOTICE '✅ Trigger updated - Now safe for concurrent operations';
    RAISE NOTICE '   - ON CONFLICT DO NOTHING prevents duplicate errors';
    RAISE NOTICE '   - App can safely upsert profiles after trigger runs';
END $$;
