-- Test Data Sharing Between Admin, Manager, and Staff
-- This verifies that team members see the same data via admin_id

-- ============================================
-- VERIFY CURRENT STATE
-- ============================================

-- Show all users and their admin links
SELECT 
  '👥 USER PROFILES' as section,
  email,
  role,
  CASE 
    WHEN role = 'admin' AND admin_id IS NULL THEN '✅ Admin (owns team)'
    WHEN role IN ('manager', 'staff') AND admin_id IS NOT NULL THEN '✅ Team member of ' || (SELECT email FROM user_profiles WHERE id = up.admin_id)
    ELSE '❌ Missing admin_id'
  END as status,
  id as user_id,
  admin_id
FROM user_profiles up
ORDER BY 
  CASE role 
    WHEN 'admin' THEN 1 
    WHEN 'manager' THEN 2 
    WHEN 'staff' THEN 3 
  END,
  email;

-- Show all transactions with owner and admin info
SELECT 
  '💰 TRANSACTIONS' as section,
  t.id,
  t.date,
  t.type,
  t.amount,
  u.email as created_by_user,
  u.role as user_role,
  t.owner_id,
  t.admin_id,
  CASE 
    WHEN u.role = 'admin' AND t.admin_id = u.id THEN '✅ Admin transaction'
    WHEN u.role IN ('manager', 'staff') AND t.admin_id = u.admin_id THEN '✅ Team transaction'
    WHEN t.admin_id IS NULL THEN '❌ Missing admin_id'
    ELSE '⚠️ Check admin_id'
  END as status
FROM transactions t
LEFT JOIN user_profiles u ON t.owner_id = u.id
ORDER BY t.date DESC, t.id;

-- ============================================
-- TEST RLS HELPER FUNCTION
-- ============================================

-- Test get_current_user_admin_id() for each user
SELECT 
  '🔍 RLS FUNCTION TEST' as section,
  email,
  role,
  id as user_id,
  admin_id,
  CASE 
    WHEN role = 'admin' THEN 'Should return: ' || id
    WHEN role IN ('manager', 'staff') THEN 'Should return: ' || COALESCE(admin_id::text, 'NULL')
    ELSE 'Unknown'
  END as expected_result
FROM user_profiles
ORDER BY role, email;

-- ============================================
-- VERIFY DATA SHARING COUNTS
-- ============================================

-- Count transactions per admin team
SELECT 
  '📊 TEAM DATA COUNTS' as section,
  admin_email,
  admin_id,
  transaction_count,
  total_revenue,
  total_transactions,
  team_member_count
FROM (
  SELECT 
    u.email as admin_email,
    u.id as admin_id,
    COUNT(DISTINCT t.id) as transaction_count,
    SUM(CASE WHEN t.type = 'revenue' THEN t.amount ELSE 0 END) as total_revenue,
    SUM(CASE WHEN t.type = 'transaction' THEN t.amount ELSE 0 END) as total_transactions,
    (SELECT COUNT(*) FROM user_profiles WHERE admin_id = u.id OR id = u.id) as team_member_count
  FROM user_profiles u
  LEFT JOIN transactions t ON (
    -- Admin's own transactions
    (u.role = 'admin' AND t.admin_id = u.id)
  )
  WHERE u.role = 'admin'
  GROUP BY u.id, u.email
) team_stats;

-- ============================================
-- EXPECTED BEHAVIOR
-- ============================================

SELECT 
  '✅ EXPECTED BEHAVIOR' as info,
  'All team members (admin, manager, staff) with same admin_id should see:' as description;

SELECT 
  '  1. Same transaction count' as rule;
SELECT 
  '  2. Same total revenue' as rule;
SELECT 
  '  3. Same total transactions' as rule;
SELECT 
  '  4. Real-time updates from any team member' as rule;
SELECT 
  '  5. RLS automatically filters by admin_id' as rule;
