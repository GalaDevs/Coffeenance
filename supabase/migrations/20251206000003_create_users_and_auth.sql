-- Create Users Table with Role-Based Access Control
-- Created: 2025-12-06
-- Description: Authentication and user management for Coffeenance app

-- ============================================
-- USERS PROFILE TABLE
-- ============================================
-- This extends Supabase Auth with custom profile data
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'manager', 'staff')),
    created_by UUID REFERENCES auth.users(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_created_by ON public.user_profiles(created_by);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Admin can see all users
CREATE POLICY "Admin can view all users" ON public.user_profiles
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT
    USING (id = auth.uid());

-- Admin can insert users (create staff/manager accounts)
CREATE POLICY "Admin can create users" ON public.user_profiles
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Admin can update users
CREATE POLICY "Admin can update users" ON public.user_profiles
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Users can update their own profile (limited fields)
CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Admin can delete users
CREATE POLICY "Admin can delete users" ON public.user_profiles
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ============================================
-- FUNCTION: Auto-create profile on signup
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        COALESCE(NEW.raw_user_meta_data->>'role', 'staff')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create profile when user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- UPDATE TRANSACTIONS TABLE RLS
-- ============================================
-- Allow all authenticated users to view transactions
DROP POLICY IF EXISTS "Users can view transactions" ON public.transactions;
CREATE POLICY "Users can view transactions" ON public.transactions
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- Allow staff, manager, and admin to insert transactions
DROP POLICY IF EXISTS "Users can create transactions" ON public.transactions;
CREATE POLICY "Users can create transactions" ON public.transactions
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Allow admin and manager to update transactions
DROP POLICY IF EXISTS "Admin and Manager can update transactions" ON public.transactions;
CREATE POLICY "Admin and Manager can update transactions" ON public.transactions
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
    );

-- Allow only admin to delete transactions
DROP POLICY IF EXISTS "Admin can delete transactions" ON public.transactions;
CREATE POLICY "Admin can delete transactions" ON public.transactions
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- ============================================
-- UPDATE INVENTORY TABLE RLS
-- ============================================
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;

-- All authenticated users can view inventory
CREATE POLICY "Users can view inventory" ON public.inventory
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- Admin and Manager can manage inventory
CREATE POLICY "Admin and Manager can manage inventory" ON public.inventory
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
    );

-- ============================================
-- UPDATE STAFF TABLE RLS
-- ============================================
ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;

-- All authenticated users can view staff
CREATE POLICY "Users can view staff" ON public.staff
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- Admin and Manager can manage staff
CREATE POLICY "Admin and Manager can manage staff" ON public.staff
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
    );

-- ============================================
-- INITIAL ADMIN ACCOUNT SETUP
-- ============================================
-- Note: You need to create the first admin account manually through Supabase dashboard
-- Go to Authentication > Users > Add User
-- Email: your-admin@email.com
-- Password: your-secure-password
-- User Metadata: {"role": "admin", "full_name": "Admin User"}
-- 
-- Or use this SQL after creating the auth user:
-- UPDATE public.user_profiles SET role = 'admin' WHERE email = 'your-admin@email.com';
