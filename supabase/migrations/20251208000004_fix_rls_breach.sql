-- Fix RLS Breach: Ensure strict owner_id isolation
-- Transaction #82 is leaking between users

-- Drop ALL existing policies
DROP POLICY IF EXISTS "transactions_select_policy" ON public.transactions;
DROP POLICY IF EXISTS "transactions_insert_policy" ON public.transactions;
DROP POLICY IF EXISTS "transactions_update_policy" ON public.transactions;
DROP POLICY IF EXISTS "transactions_delete_policy" ON public.transactions;
DROP POLICY IF EXISTS "Users can view their own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can insert their own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can update their own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can delete their own transactions" ON public.transactions;

-- Enable RLS
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Force RLS even for table owner
ALTER TABLE public.transactions FORCE ROW LEVEL SECURITY;

-- Create strict owner_id based policies
CREATE POLICY "select_own_transactions"
ON public.transactions
FOR SELECT
USING (owner_id = auth.uid());

CREATE POLICY "insert_own_transactions"
ON public.transactions
FOR INSERT
WITH CHECK (owner_id = auth.uid());

CREATE POLICY "update_own_transactions"
ON public.transactions
FOR UPDATE
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

CREATE POLICY "delete_own_transactions"
ON public.transactions
FOR DELETE
USING (owner_id = auth.uid());

-- Fix transaction #82 owner_id (belongs to rod6 but showing for rod)
UPDATE public.transactions
SET owner_id = admin_id
WHERE id = 82 AND owner_id != admin_id;

-- Verify all transactions have correct owner_id
UPDATE public.transactions
SET owner_id = COALESCE(owner_id, admin_id, user_id)
WHERE owner_id IS NULL;
