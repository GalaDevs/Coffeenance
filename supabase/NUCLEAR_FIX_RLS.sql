-- NUCLEAR FIX: Complete RLS Reset with owner_id only
-- This will fix Transaction #140 breach
-- Run this in Supabase SQL Editor NOW

BEGIN;

-- ============================================
-- STEP 1: DROP EVERY SINGLE POLICY
-- ============================================
DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Drop all policies on transactions table
    FOR r IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'transactions' 
        AND schemaname = 'public'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON public.transactions';
        RAISE NOTICE 'Dropped policy: %', r.policyname;
    END LOOP;
END $$;

-- ============================================
-- STEP 2: Enable FORCE RLS
-- ============================================
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions FORCE ROW LEVEL SECURITY;

-- ============================================
-- STEP 3: Fix Transaction #140 Data Issue
-- ============================================
-- TX #140 has owner_id=rod6 but admin_id=rod
-- This is the source of the breach
-- The owner_id is CORRECT, the issue is a policy using admin_id

-- Let's verify what's in TX #140
DO $$
DECLARE
    tx_owner_id UUID;
    tx_admin_id UUID;
BEGIN
    SELECT owner_id, admin_id INTO tx_owner_id, tx_admin_id
    FROM public.transactions 
    WHERE id = 140;
    
    RAISE NOTICE 'TX #140 - owner_id: %, admin_id: %', tx_owner_id, tx_admin_id;
    
    -- If admin_id doesn't match owner_id, this is the problem
    IF tx_admin_id IS DISTINCT FROM tx_owner_id THEN
        RAISE NOTICE '⚠️ TX #140 has mismatched admin_id and owner_id';
        RAISE NOTICE 'This transaction belongs to owner_id: %', tx_owner_id;
    END IF;
END $$;

-- ============================================
-- STEP 4: Create ONLY owner_id policies
-- ============================================
-- CRITICAL: These policies MUST use owner_id ONLY
-- NO admin_id, NO user_id, ONLY owner_id

CREATE POLICY "strict_owner_select"
ON public.transactions
FOR SELECT
USING (
    owner_id = auth.uid()
);

CREATE POLICY "strict_owner_insert"
ON public.transactions
FOR INSERT
WITH CHECK (
    owner_id = auth.uid()
);

CREATE POLICY "strict_owner_update"
ON public.transactions
FOR UPDATE
USING (
    owner_id = auth.uid()
)
WITH CHECK (
    owner_id = auth.uid()
);

CREATE POLICY "strict_owner_delete"
ON public.transactions
FOR DELETE
USING (
    owner_id = auth.uid()
);

-- ============================================
-- STEP 5: Verify Fix
-- ============================================
-- Check that only owner_id policies exist
SELECT 
    policyname,
    CASE 
        WHEN qual LIKE '%owner_id%' THEN '✅ Uses owner_id'
        WHEN qual LIKE '%admin_id%' THEN '❌ Uses admin_id (BAD!)'
        ELSE '⚠️ Unknown'
    END as policy_check,
    qual as using_clause
FROM pg_policies 
WHERE tablename = 'transactions'
ORDER BY policyname;

-- Count records by owner
SELECT 
    owner_id,
    (SELECT email FROM user_profiles WHERE id = owner_id) as owner_email,
    COUNT(*) as transaction_count
FROM public.transactions
GROUP BY owner_id
ORDER BY transaction_count DESC;

COMMIT;

-- ============================================
-- STEP 6: Test Query
-- ============================================
-- This should ONLY return transactions where owner_id matches auth.uid()
-- TX #140 should NOT appear for rod@gmail.com anymore
SELECT 
    id,
    owner_id,
    admin_id,
    description,
    CASE 
        WHEN owner_id = auth.uid() THEN '✅ Mine'
        ELSE '❌ NOT MINE (BREACH!)'
    END as ownership
FROM public.transactions
ORDER BY id DESC
LIMIT 20;
