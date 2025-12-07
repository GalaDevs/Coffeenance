-- Fix RLS policy to allow registration (self-signup for admin accounts)
-- Problem: During registration, signUp() creates auth user first, then tries to insert profile
-- But INSERT policy requires existing admin, which blocks registration

-- Drop existing INSERT policy
DROP POLICY IF EXISTS "tenant_isolation_insert_user_profiles" ON user_profiles;

-- New INSERT policy: Allow registration for admin accounts OR admin creating users
CREATE POLICY "tenant_isolation_insert_user_profiles" ON user_profiles
    FOR INSERT
    WITH CHECK (
        -- Case 1: Self-registration for admin (admin_id is NULL and role is 'admin')
        (role = 'admin' AND admin_id IS NULL AND id = auth.uid())
        OR
        -- Case 2: Existing admin creating manager/staff users
        (
            EXISTS (
                SELECT 1 FROM user_profiles
                WHERE id = auth.uid() AND role = 'admin'
            )
            AND
            -- New user must belong to the creating admin's tenant
            admin_id = auth.uid()
        )
    );

-- Add notice for successful migration
DO $$ 
BEGIN 
    RAISE NOTICE '✅ Registration RLS policy fixed';
    RAISE NOTICE '📝 Admin accounts can now self-register via signUp()';
    RAISE NOTICE '🔐 Existing admins can still create manager/staff accounts';
END $$;
