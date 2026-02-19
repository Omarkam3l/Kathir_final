-- =====================================================
-- TEST: Complete Orders Fix
-- Run this AFTER applying 20260212_COMPLETE_ORDERS_FIX.sql
-- =====================================================

-- Test 1: Check all policies are correct
SELECT 
  tablename,
  COUNT(*) as policy_count,
  COUNT(CASE WHEN qual LIKE '%EXISTS%' THEN 1 END) as exists_count,
  COUNT(CASE WHEN qual LIKE '%IN (%' THEN 1 END) as in_count
FROM pg_policies
WHERE tablename IN ('orders', 'order_items', 'order_status_history')
GROUP BY tablename
ORDER BY tablename;

-- Expected:
-- orders: 7 policies, 0 EXISTS, 0 IN (direct checks)
-- order_items: 4 policies, 0 EXISTS, 4 IN
-- order_status_history: 5 policies, 0 EXISTS, 5 IN

-- Test 2: List all order-related policies
SELECT 
  tablename,
  policyname,
  cmd as command,
  CASE 
    WHEN qual LIKE '%EXISTS%' THEN '❌ EXISTS (recursion risk)'
    WHEN qual LIKE '%IN (%' THEN '✅ IN (safe)'
    WHEN qual = 'true' THEN '⚠️ PERMISSIVE'
    ELSE '✅ DIRECT CHECK'
  END as pattern
FROM pg_policies
WHERE tablename IN ('orders', 'order_items', 'order_status_history')
ORDER BY tablename, cmd, policyname;

-- Test 3: Simulate restaurant dashboard query
-- (Replace 'YOUR_RESTAURANT_ID' with actual restaurant user ID)
EXPLAIN (ANALYZE, COSTS OFF)
SELECT 
  o.id,
  o.order_number,
  o.status,
  o.total_amount,
  o.created_at,
  json_agg(
    json_build_object(
      'id', oi.id,
      'quantity', oi.quantity,
      'meal_title', oi.meal_title
    )
  ) as items
FROM orders o
LEFT JOIN order_items oi ON o.id = oi.order_id
WHERE o.restaurant_id = auth.uid()
GROUP BY o.id
ORDER BY o.created_at DESC
LIMIT 10;

-- This should execute WITHOUT "stack depth limit exceeded" error

-- Test 4: Check specific problematic policies are fixed
SELECT 
  policyname,
  CASE 
    WHEN qual LIKE '%EXISTS%' THEN '❌ STILL BROKEN'
    WHEN qual LIKE '%IN (%' THEN '✅ FIXED'
    ELSE '⚠️ CHECK MANUALLY'
  END as status,
  qual
FROM pg_policies
WHERE tablename = 'order_items'
AND policyname IN (
  'NGOs can view their order items',
  'order_items_select_ngos'
)
UNION ALL
SELECT 
  policyname,
  CASE 
    WHEN qual LIKE '%EXISTS%' THEN '❌ STILL BROKEN'
    WHEN qual LIKE '%IN (%' THEN '✅ FIXED'
    ELSE '⚠️ CHECK MANUALLY'
  END as status,
  qual
FROM pg_policies
WHERE tablename = 'order_status_history'
AND policyname IN (
  'Restaurants can view their order history',
  'Users can view their order history',
  'order_status_history_select_restaurants',
  'order_status_history_select_users'
);

-- =====================================================
-- SUCCESS CRITERIA
-- =====================================================
-- ✅ All order_items policies use IN (not EXISTS)
-- ✅ All order_status_history policies use IN (not EXISTS)
-- ✅ Restaurant query executes without errors
-- ✅ Query completes in < 100ms
-- ✅ No "stack depth limit exceeded" errors
