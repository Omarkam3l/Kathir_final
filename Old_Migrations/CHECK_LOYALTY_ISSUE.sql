-- =====================================================
-- DIAGNOSE LOYALTY POINTS ISSUE
-- =====================================================
-- Run this to check why you didn't receive points

-- 1. Check your recent orders and their status
SELECT 
  o.id,
  o.order_number,
  o.status,
  o.total_amount,
  o.delivery_type,
  o.created_at,
  o.user_id,
  p.role as user_role
FROM orders o
JOIN profiles p ON p.id = o.user_id
WHERE o.user_id = auth.uid()
ORDER BY o.created_at DESC
LIMIT 5;

-- 2. Check if you have a loyalty profile
SELECT * FROM user_loyalty WHERE user_id = auth.uid();

-- 3. Check your loyalty transactions
SELECT 
  lt.id,
  lt.points,
  lt.transaction_type,
  lt.source,
  lt.description,
  lt.created_at,
  o.order_number,
  o.status as order_status
FROM loyalty_transactions lt
LEFT JOIN orders o ON o.id = lt.order_id
WHERE lt.user_id = auth.uid()
ORDER BY lt.created_at DESC
LIMIT 10;

-- 4. Check if trigger exists and is enabled
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement,
  action_timing
FROM information_schema.triggers
WHERE trigger_name = 'trigger_award_order_points';

-- 5. Find orders that should have awarded points but didn't
SELECT 
  o.id,
  o.order_number,
  o.status,
  o.total_amount,
  o.delivery_type,
  o.created_at,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM loyalty_transactions lt 
      WHERE lt.order_id = o.id
    ) THEN 'Points Awarded ✓'
    ELSE 'No Points ✗'
  END as points_status
FROM orders o
WHERE o.user_id = auth.uid()
  AND o.status = 'completed'
ORDER BY o.created_at DESC;
