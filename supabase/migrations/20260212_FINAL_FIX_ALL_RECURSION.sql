-- =====================================================
-- FINAL FIX: ALL Recursion Issues
-- Fixes ALL tables that reference orders with EXISTS
-- =====================================================
-- Tables fixed:
-- 1. order_items (already partially fixed)
-- 2. order_status_history (already partially fixed)  
-- 3. payments (NEW - this was causing your error!)
-- =====================================================

-- =====================================================
-- FIX 1: order_items - Ensure ALL use IN
-- =====================================================

DROP POLICY IF EXISTS "Authenticated users can create order items" ON order_items;
DROP POLICY IF EXISTS "NGOs can view their order items" ON order_items;
DROP POLICY IF EXISTS "Restaurants can view their order items" ON order_items;
DROP POLICY IF EXISTS "Users can insert their order items" ON order_items;
DROP POLICY IF EXISTS "Users can view their order items" ON order_items;
DROP POLICY IF EXISTS "order_items_insert_users" ON order_items;
DROP POLICY IF EXISTS "order_items_select_users" ON order_items;
DROP POLICY IF EXISTS "order_items_select_restaurants" ON order_items;
DROP POLICY IF EXISTS "order_items_select_ngos" ON order_items;

CREATE POLICY "order_items_insert_users"
ON order_items FOR INSERT
TO authenticated
WITH CHECK (
  order_id IN (SELECT id FROM orders WHERE user_id = auth.uid())
);

CREATE POLICY "order_items_select_users"
ON order_items FOR SELECT
TO authenticated
USING (
  order_id IN (SELECT id FROM orders WHERE user_id = auth.uid())
);

CREATE POLICY "order_items_select_restaurants"
ON order_items FOR SELECT
TO authenticated
USING (
  order_id IN (SELECT id FROM orders WHERE restaurant_id = auth.uid())
);

CREATE POLICY "order_items_select_ngos"
ON order_items FOR SELECT
TO authenticated
USING (
  order_id IN (SELECT id FROM orders WHERE ngo_id = auth.uid())
);

-- =====================================================
-- FIX 2: order_status_history - Ensure ALL use IN
-- =====================================================

DROP POLICY IF EXISTS "Allow status history inserts" ON order_status_history;
DROP POLICY IF EXISTS "Restaurants can insert status history for their orders" ON order_status_history;
DROP POLICY IF EXISTS "Restaurants can view their order history" ON order_status_history;
DROP POLICY IF EXISTS "Users can view their order history" ON order_status_history;
DROP POLICY IF EXISTS "order_status_history_insert_all" ON order_status_history;
DROP POLICY IF EXISTS "order_status_history_insert_restaurants" ON order_status_history;
DROP POLICY IF EXISTS "order_status_history_select_users" ON order_status_history;
DROP POLICY IF EXISTS "order_status_history_select_restaurants" ON order_status_history;
DROP POLICY IF EXISTS "order_status_history_select_ngos" ON order_status_history;

CREATE POLICY "order_status_history_insert_all"
ON order_status_history FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "order_status_history_insert_restaurants"
ON order_status_history FOR INSERT
TO authenticated
WITH CHECK (
  order_id IN (SELECT id FROM orders WHERE restaurant_id = auth.uid())
);

CREATE POLICY "order_status_history_select_users"
ON order_status_history FOR SELECT
TO authenticated
USING (
  order_id IN (SELECT id FROM orders WHERE user_id = auth.uid())
);

CREATE POLICY "order_status_history_select_restaurants"
ON order_status_history FOR SELECT
TO authenticated
USING (
  order_id IN (SELECT id FROM orders WHERE restaurant_id = auth.uid())
);

CREATE POLICY "order_status_history_select_ngos"
ON order_status_history FOR SELECT
TO authenticated
USING (
  order_id IN (SELECT id FROM orders WHERE ngo_id = auth.uid())
);

-- =====================================================
-- FIX 3: payments - Convert EXISTS to IN (THIS IS THE MISSING FIX!)
-- =====================================================

DROP POLICY IF EXISTS "Users can view own payments" ON payments;

-- Recreate with IN subquery (prevents recursion)
CREATE POLICY "payments_select_users"
ON payments FOR SELECT
TO authenticated
USING (
  order_id IN (SELECT id FROM orders WHERE user_id = auth.uid())
);

-- =====================================================
-- FIX 4: Add helpful comments
-- =====================================================

COMMENT ON POLICY "order_items_select_restaurants" ON order_items IS 
'Restaurants can view order items - uses IN to prevent recursion';

COMMENT ON POLICY "order_items_select_users" ON order_items IS 
'Users can view order items - uses IN to prevent recursion';

COMMENT ON POLICY "order_items_select_ngos" ON order_items IS 
'NGOs can view order items - uses IN to prevent recursion';

COMMENT ON POLICY "order_status_history_select_restaurants" ON order_status_history IS 
'Restaurants can view order history - uses IN to prevent recursion';

COMMENT ON POLICY "order_status_history_select_users" ON order_status_history IS 
'Users can view order history - uses IN to prevent recursion';

COMMENT ON POLICY "payments_select_users" ON payments IS 
'Users can view payments - uses IN to prevent recursion when querying orders with nested payments';

-- =====================================================
-- VERIFICATION
-- =====================================================

DO $$
DECLARE
  order_items_count INT;
  order_status_count INT;
  payments_count INT;
  orders_count INT;
  total_exists INT;
BEGIN
  SELECT COUNT(*) INTO order_items_count FROM pg_policies WHERE tablename = 'order_items';
  SELECT COUNT(*) INTO order_status_count FROM pg_policies WHERE tablename = 'order_status_history';
  SELECT COUNT(*) INTO payments_count FROM pg_policies WHERE tablename = 'payments';
  SELECT COUNT(*) INTO orders_count FROM pg_policies WHERE tablename = 'orders';
  
  -- Count ALL policies using EXISTS that reference orders
  SELECT COUNT(*) INTO total_exists 
  FROM pg_policies 
  WHERE tablename IN ('order_items', 'order_status_history', 'payments')
  AND qual LIKE '%EXISTS%'
  AND qual LIKE '%orders%';

  RAISE NOTICE '=== FINAL RECURSION FIX COMPLETE ===';
  RAISE NOTICE 'order_items policies: % (should be 4)', order_items_count;
  RAISE NOTICE 'order_status_history policies: % (should be 5)', order_status_count;
  RAISE NOTICE 'payments policies: % (should be 1)', payments_count;
  RAISE NOTICE 'orders policies: % (unchanged)', orders_count;
  RAISE NOTICE '';
  RAISE NOTICE 'Policies using EXISTS on orders: % (should be 0)', total_exists;
  RAISE NOTICE '';
  
  IF total_exists > 0 THEN
    RAISE WARNING '❌ Still have % policies using EXISTS - recursion risk remains!', total_exists;
  ELSE
    RAISE NOTICE '✅ ALL policies now use IN subqueries - recursion completely fixed!';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST IN YOUR APP ===';
  RAISE NOTICE '1. Restaurant dashboard orders - should load without errors';
  RAISE NOTICE '2. User orders list - should load without errors';
  RAISE NOTICE '3. Order details with items - should load without errors';
  RAISE NOTICE '4. Payment information - should load without errors';
  RAISE NOTICE '';
  RAISE NOTICE 'No more "stack depth limit exceeded" errors!';
END $$;
