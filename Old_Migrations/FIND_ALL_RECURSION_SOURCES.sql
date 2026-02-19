-- =====================================================
-- DIAGNOSTIC: Find ALL Recursion Sources
-- Run this to see ALL policies causing recursion
-- =====================================================

-- Find ALL policies that reference 'orders' table with EXISTS
SELECT 
  tablename as "Table",
  policyname as "Policy Name",
  cmd as "Command",
  '❌ RECURSION RISK' as "Status",
  qual as "Expression"
FROM pg_policies
WHERE schemaname = 'public'
AND qual LIKE '%EXISTS%'
AND qual LIKE '%orders%'
AND tablename != 'orders'  -- Don't check orders table itself
ORDER BY tablename, policyname;

-- Summary count
SELECT 
  '=== RECURSION RISK SUMMARY ===' as "Report";

SELECT 
  tablename as "Table",
  COUNT(*) as "Policies with EXISTS on orders"
FROM pg_policies
WHERE schemaname = 'public'
AND qual LIKE '%EXISTS%'
AND qual LIKE '%orders%'
AND tablename != 'orders'
GROUP BY tablename
ORDER BY tablename;

-- Expected BEFORE fix:
-- order_items: 1-2 policies
-- order_status_history: 2 policies
-- payments: 1 policy
-- TOTAL: 4-5 policies causing recursion

-- Expected AFTER fix:
-- ZERO policies with EXISTS on orders
