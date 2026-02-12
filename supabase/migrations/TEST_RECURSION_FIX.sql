-- =====================================================
-- TEST SCRIPT: Verify Recursion Fix
-- Run this AFTER applying 20260211_fix_orders_recursion_only.sql
-- =====================================================

-- Test 1: Check policy counts
SELECT 
  'order_items' as table_name,
  COUNT(*) as policy_count,
  STRING_AGG(policyname, ', ') as policies
FROM pg_policies 
WHERE tablename = 'order_items'
GROUP BY tablename

UNION ALL

SELECT 
  'order_status_history' as table_name,
  COUNT(*) as policy_count,
  STRING_AGG(policyname, ', ') as policies
FROM pg_policies 
WHERE tablename = 'order_status_history'
GROUP BY tablename

UNION ALL

SELECT 
  'orders' as table_name,
  COUNT(*) as policy_count,
  STRING_AGG(policyname, ', ') as policies
FROM pg_policies 
WHERE tablename = 'orders'
GROUP BY tablename;

-- Test 2: Verify all policies use IN (not EXISTS)
SELECT 
  tablename,
  policyname,
  CASE 
    WHEN qual LIKE '%EXISTS%' THEN '❌ USES EXISTS (may cause recursion)'
    WHEN qual LIKE '%IN (%' THEN '✅ USES IN (safe)'
    ELSE '⚠️ OTHER PATTERN'
  END as pattern_check,
  qual as using_expression
FROM pg_policies
WHERE tablename IN ('order_items', 'order_status_history')
AND cmd = 'SELECT'
ORDER BY tablename, policyname;

-- Test 3: Check indexes exist
SELECT 
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename IN ('orders', 'order_items', 'order_status_history')
AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

-- Test 4: Simulate the query that was causing recursion
-- (This won't actually run with your data, but shows the pattern)
EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
  o.id,
  o.order_number,
  o.status,
  o.total_amount,
  COUNT(oi.id) as item_count
FROM orders o
LEFT JOIN order_items oi ON o.id = oi.order_id
WHERE o.user_id = auth.uid()
GROUP BY o.id
LIMIT 10;

-- Expected results:
-- ✅ order_items: 4 policies (all using IN)
-- ✅ order_status_history: 4 policies (all using IN)
-- ✅ orders: 7 policies (unchanged)
-- ✅ All indexes created
-- ✅ Query executes without "stack depth limit exceeded" error
