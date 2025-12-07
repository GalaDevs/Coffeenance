-- Fix admin_id for transactions that are missing it
-- Each transaction should have admin_id set to match the owner's admin_id (or owner_id if owner is admin)

UPDATE transactions t
SET admin_id = COALESCE(u.admin_id, u.id),
    updated_at = NOW()
FROM user_profiles u
WHERE t.owner_id = u.id
  AND t.admin_id IS NULL;

-- Verify the fix
SELECT 
  t.id,
  t.date,
  t.type,
  t.amount,
  u.email as owner_email,
  u.role as owner_role,
  t.owner_id,
  t.admin_id,
  CASE 
    WHEN u.role = 'admin' AND t.admin_id = u.id THEN '✅ Admin transaction'
    WHEN u.role IN ('manager', 'staff') AND t.admin_id = u.admin_id THEN '✅ Team transaction'
    WHEN t.admin_id IS NULL THEN '❌ Missing admin_id'
    ELSE '⚠️ Check admin_id'
  END as status
FROM transactions t
JOIN user_profiles u ON t.owner_id = u.id
ORDER BY t.date DESC, t.id;
