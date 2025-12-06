-- Complete RLS Fix - Remove ALL policies and rebuild from scratch
-- This fixes the infinite recursion error completely

-- Step 1: Disable RLS temporarily
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop ALL existing policies (including any from previous migrations)
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'user_profiles' AND schemaname = 'public')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.user_profiles';
    END LOOP;
END $$;

-- Step 3: Re-enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Step 4: Create NEW simple policies that do NOT cause recursion
-- These policies use ONLY auth.uid() and do NOT reference the user_profiles table

-- Allow users to SELECT their own profile
CREATE POLICY "select_own_profile"
ON public.user_profiles
FOR SELECT
TO authenticated
USING (id = auth.uid());

-- Allow users to INSERT their own profile (needed for first-time login)
CREATE POLICY "insert_own_profile"
ON public.user_profiles
FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

-- Allow users to UPDATE their own profile
CREATE POLICY "update_own_profile"
ON public.user_profiles
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Allow service role full access (for admin operations via API)
CREATE POLICY "service_role_all"
ON public.user_profiles
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Step 5: Grant permissions
GRANT SELECT, INSERT, UPDATE ON public.user_profiles TO authenticated;
GRANT ALL ON public.user_profiles TO service_role;

-- Step 6: Ensure the admin user profile exists
-- This is safe because it uses ON CONFLICT
INSERT INTO public.user_profiles (id, email, role, full_name, created_at, updated_at)
SELECT 
  id,
  email,
  'admin',
  'The Yield Coffee Admin',
  now(),
  now()
FROM auth.users 
WHERE email = 'theyieldcoffee@admin.com'
ON CONFLICT (id) DO UPDATE SET
  role = 'admin',
  full_name = 'The Yield Coffee Admin',
  updated_at = now();
