-- =====================================================
-- FIX MISSING LOYALTY PROFILE
-- =====================================================
-- This creates your loyalty profile and awards points for past orders

-- Step 1: Create your loyalty profile if it doesn't exist
INSERT INTO user_loyalty (user_id)
SELECT auth.uid()
WHERE NOT EXISTS (
  SELECT 1 FROM user_loyalty WHERE user_id = auth.uid()
)
AND EXISTS (
  SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'user'
);

-- Step 2: Verify profile was created
SELECT 
  user_id,
  total_points,
  available_points,
  current_tier,
  total_orders,
  created_at
FROM user_loyalty 
WHERE user_id = auth.uid();

-- Step 3: Check all your orders (regardless of status)
SELECT 
  id,
  order_number,
  status,
  total_amount,
  delivery_type,
  ngo_id,
  created_at,
  CASE 
    WHEN status = 'completed' THEN '✓ Can award points'
    WHEN status = 'pending' THEN '⏳ Waiting for completion'
    ELSE '✗ Cannot award points'
  END as points_eligibility
FROM orders
WHERE user_id = auth.uid()
ORDER BY created_at DESC;

-- Step 4: Complete your pending order (if you've received it)
-- UNCOMMENT and replace 'your-order-id' with your actual order ID
-- UPDATE orders 
-- SET status = 'completed' 
-- WHERE id = 'your-order-id' 
--   AND user_id = auth.uid()
--   AND status = 'pending';

-- Step 5: After completing the order, check if points were awarded
SELECT 
  lt.points,
  lt.transaction_type,
  lt.source,
  lt.description,
  lt.created_at,
  o.order_number
FROM loyalty_transactions lt
LEFT JOIN orders o ON o.id = lt.order_id
WHERE lt.user_id = auth.uid()
ORDER BY lt.created_at DESC;

-- Step 6: Check updated loyalty profile
SELECT 
  total_points,
  available_points,
  lifetime_points,
  current_tier,
  total_orders,
  total_donations
FROM user_loyalty
WHERE user_id = auth.uid();
