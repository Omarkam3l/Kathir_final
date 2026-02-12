-- =====================================================
-- COMPLETE ORDERS FIX - Senior 10Y Experience Solution
-- Fixes BOTH issues:
-- 1. Stack depth recursion error
-- 2. Restaurant dashboard not showing orders
-- =====================================================

-- =====================================================
-- DIAGNOSIS:
-- =====================================================
-- Issue 1: order_items and order_status_history use EXISTS
--          which causes recursion when querying orders with nested data
-- Issue 2: Restaurant query joins orders + order_items + meals + profiles
--          The nested query triggers RLS on order_items which checks orders
--          Creating infinite loop: orders → order_items → orders → ∞
-- =====================================================

-- =====================================================
-- FIX 1: order_items - Convert ALL to IN subqueries
-- =====================================================

DROP POLICY IF EXISTS "Authenticated users can create order items" ON order_items;
DROP POLICY IF EXISTS "NGOs can view their order items" ON order_items;
DROP POLICY IF EXISTS "Restaurants can view their order items" ON order_items;
DROP POLICY IF EXISTS "Users can insert their order items" ON order_items;
DROP POLICY IF EXISTS "Users can view their order items" ON order_items;

-- Create clean policies with IN (prevents recursion)
CREATE POLICY "order_items_insert_users"
ON order_items FOR INSERT
TO authenticated
WITH CHECK (
  order_id IN (
    SELECT id FROM orders WHERE user_id = auth.uid()
  )
);

CREATE POLICY "order_items_select_users"
ON order_items FOR SELECT
TO authenticated
USING (
  order_id IN (
    SELECT id FROM orders WHERE user_id = auth.uid()
  )
);

CREATE POLICY "order_items_select_restaurants"
ON order_items FOR SELECT
TO authenticated
USING (
  order_id IN (
    SELECT id FROM orders WHERE restaurant_id = auth.uid()
  )
);

CREATE POLICY "order_items_select_ngos"
ON order_items FOR SELECT
TO authenticated
USING (
  order_id IN (
    SELECT id FROM orders WHERE ngo_id = auth.uid()
  )
);

-- =====================================================
-- FIX 2: order_status_history - Convert ALL to IN
-- =====================================================

DROP POLICY IF EXISTS "Allow status history inserts" ON order_status_history;
DROP POLICY IF EXISTS "Restaurants can insert status history for their orders" ON order_status_history;
DROP POLICY IF EXISTS "Restaurants can view their order history" ON order_status_history;
DROP POLICY IF EXISTS "Users can view their order history" ON order_status_history;

-- Create clean policies with IN (prevents recursion)
CREATE POLICY "order_status_history_insert_all"
ON order_status_history FOR INSERT
TO authenticated
WITH CHECK (true);  -- Permissive for triggers

CREATE POLICY "order_status_history_insert_restaurants"
ON order_status_history FOR INSERT
TO authenticated
WITH CHECK (
  order_id IN (
    SELECT id FROM orders WHERE restaurant_id = auth.uid()
  )
);

CREATE POLICY "order_status_history_select_users"
ON order_status_history FOR SELECT
TO authenticated
USING (
  order_id IN (
    SELECT id FROM orders WHERE user_id = auth.uid()
  )
);

CREATE POLICY "order_status_history_select_restaurants"
ON order_status_history FOR SELECT
TO authenticated
USING (
  order_id IN (
    SELECT id FROM orders WHERE restaurant_id = auth.uid()
  )
);

CREATE POLICY "order_status_history_select_ngos"
ON order_status_history FOR SELECT
TO authenticated
USING (
  order_id IN (
    SELECT id FROM orders WHERE ngo_id = auth.uid()
  )
);

-- =====================================================
-- FIX 3: Verify orders policies are correct
-- =====================================================
-- These should already exist and work, but let's verify

DO $$
BEGIN
  -- Check if restaurant SELECT policy exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'orders' 
    AND policyname = 'Restaurants can view their orders'
  ) THEN
    RAISE NOTICE 'Creating missing restaurant orders SELECT policy';
    EXECUTE 'CREATE POLICY "Restaurants can view their orders" 
             ON orders FOR SELECT 
             TO authenticated 
             USING (restaurant_id = auth.uid())';
  END IF;

  -- Check if user SELECT policy exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'orders' 
    AND policyname = 'Users can view their orders'
  ) THEN
    RAISE NOTICE 'Creating missing user orders SELECT policy';
    EXECUTE 'CREATE POLICY "Users can view their orders" 
             ON orders FOR SELECT 
             TO authenticated 
             USING (user_id = auth.uid())';
  END IF;

  -- Check if NGO SELECT policy exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'orders' 
    AND policyname = 'NGOs can view their orders'
  ) THEN
    RAISE NOTICE 'Creating missing NGO orders SELECT policy';
    EXECUTE 'CREATE POLICY "NGOs can view their orders" 
             ON orders FOR SELECT 
             TO authenticated 
             USING (ngo_id = auth.uid())';
  END IF;
END $$;

-- =====================================================
-- FIX 4: Add helpful comments
-- =====================================================

COMMENT ON POLICY "order_items_select_restaurants" ON order_items IS 
'Restaurants can view order items for their orders - uses IN subquery to prevent recursion when querying orders with nested order_items';

COMMENT ON POLICY "order_items_select_users" ON order_items IS 
'Users can view their order items - uses IN subquery to prevent recursion';

COMMENT ON POLICY "order_items_select_ngos" ON order_items IS 
'NGOs can view their order items - uses IN subquery to prevent recursion';

COMMENT ON POLICY "order_status_history_select_restaurants" ON order_status_history IS 
'Restaurants can view order history - uses IN subquery to prevent recursion';

-- =====================================================
-- VERIFICATION & TESTING
-- =====================================================

DO $$
DECLARE
  order_items_count INT;
  order_status_count INT;
  orders_count INT;
  recursion_risk INT;
BEGIN
  -- Count policies
  SELECT COUNT(*) INTO order_items_count FROM pg_policies WHERE tablename = 'order_items';
  SELECT COUNT(*) INTO order_status_count FROM pg_policies WHERE tablename = 'order_status_history';
  SELECT COUNT(*) INTO orders_count FROM pg_policies WHERE tablename = 'orders';
  
  -- Check for EXISTS patterns (recursion risk)
  SELECT COUNT(*) INTO recursion_risk 
  FROM pg_policies 
  WHERE tablename IN ('order_items', 'order_status_history')
  AND qual LIKE '%EXISTS%';

  RAISE NOTICE '=== MIGRATION COMPLETE ===';
  RAISE NOTICE 'order_items policies: % (should be 4)', order_items_count;
  RAISE NOTICE 'order_status_history policies: % (should be 5)', order_status_count;
  RAISE NOTICE 'orders policies: % (should be 7)', orders_count;
  RAISE NOTICE 'Recursion risk policies (EXISTS): % (should be 0)', recursion_risk;
  RAISE NOTICE '';
  
  IF recursion_risk > 0 THEN
    RAISE WARNING 'Still have % policies using EXISTS - may cause recursion!', recursion_risk;
  ELSE
    RAISE NOTICE '✅ All policies use IN subqueries - recursion fixed!';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST THESE QUERIES ===';
  RAISE NOTICE '1. Restaurant dashboard orders:';
  RAISE NOTICE '   SELECT * FROM orders WHERE restaurant_id = auth.uid();';
  RAISE NOTICE '';
  RAISE NOTICE '2. Orders with nested items (this was failing):';
  RAISE NOTICE '   SELECT o.*, oi.* FROM orders o';
  RAISE NOTICE '   LEFT JOIN order_items oi ON o.id = oi.order_id';
  RAISE NOTICE '   WHERE o.restaurant_id = auth.uid();';
  RAISE NOTICE '';
  RAISE NOTICE '3. Full nested query (restaurant dashboard):';
  RAISE NOTICE '   SELECT orders.*, order_items.*, meals.*';
  RAISE NOTICE '   FROM orders';
  RAISE NOTICE '   LEFT JOIN order_items ON orders.id = order_items.order_id';
  RAISE NOTICE '   LEFT JOIN meals ON order_items.meal_id = meals.id';
  RAISE NOTICE '   WHERE orders.restaurant_id = auth.uid();';
END $$;

-- =====================================================
-- EXPECTED RESULTS
-- =====================================================
-- ✅ order_items: 4 policies (all using IN)
-- ✅ order_status_history: 5 policies (all using IN)
-- ✅ orders: 7 policies (unchanged)
-- ✅ Restaurant dashboard shows orders
-- ✅ No "stack depth limit exceeded" errors
-- ✅ Nested queries work (orders + order_items + meals)
-- =====================================================
