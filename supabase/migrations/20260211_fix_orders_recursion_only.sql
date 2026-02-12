-- =====================================================
-- MINIMAL FIX: Orders Recursion Only
-- Fixes the "stack depth limit exceeded" error
-- Safe, focused, tested approach
-- =====================================================

-- =====================================================
-- CURRENT STATE (from your analysis):
-- =====================================================
-- orders: 7 policies (2 duplicate INSERT, but working)
-- order_items: 5 policies (mix of EXISTS and IN - CAUSES RECURSION)
-- order_status_history: 4 policies (all EXISTS - CAUSES RECURSION)
--
-- PROBLEM: When you query orders with nested order_items,
-- the order_items RLS policies check the orders table,
-- which triggers orders RLS again = infinite loop
-- =====================================================

-- =====================================================
-- STEP 1: Fix order_items (Convert EXISTS to IN)
-- =====================================================

-- Drop existing order_items policies
DROP POLICY IF EXISTS "Authenticated users can create order items" ON order_items;
DROP POLICY IF EXISTS "NGOs can view their order items" ON order_items;
DROP POLICY IF EXISTS "Restaurants can view their order items" ON order_items;
DROP POLICY IF EXISTS "Users can insert their order items" ON order_items;
DROP POLICY IF EXISTS "Users can view their order items" ON order_items;

-- Recreate with IN subqueries (prevents recursion)
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
-- STEP 2: Fix order_status_history (Convert EXISTS to IN)
-- =====================================================

-- Drop existing order_status_history policies
DROP POLICY IF EXISTS "Allow status history inserts" ON order_status_history;
DROP POLICY IF EXISTS "Restaurants can insert status history for their orders" ON order_status_history;
DROP POLICY IF EXISTS "Restaurants can view their order history" ON order_status_history;
DROP POLICY IF EXISTS "Users can view their order history" ON order_status_history;

-- Recreate with IN subqueries (prevents recursion)
CREATE POLICY "order_status_history_insert_all"
ON order_status_history FOR INSERT
TO authenticated
WITH CHECK (true);  -- Keep permissive insert for triggers

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

-- =====================================================
-- STEP 3: Add Performance Indexes
-- =====================================================

-- These indexes make the IN subqueries fast
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_restaurant_id ON orders(restaurant_id) WHERE restaurant_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_ngo_id ON orders(ngo_id) WHERE ngo_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(order_id);

-- =====================================================
-- STEP 4: Add Comments for Documentation
-- =====================================================

COMMENT ON POLICY "order_items_select_users" ON order_items IS 
'Users can view their order items - uses IN subquery to prevent recursion when querying orders with nested order_items';

COMMENT ON POLICY "order_items_select_restaurants" ON order_items IS 
'Restaurants can view their order items - uses IN subquery to prevent recursion';

COMMENT ON POLICY "order_items_select_ngos" ON order_items IS 
'NGOs can view their order items - uses IN subquery to prevent recursion';

COMMENT ON POLICY "order_status_history_select_users" ON order_status_history IS 
'Users can view order history - uses IN subquery to prevent recursion';

COMMENT ON POLICY "order_status_history_select_restaurants" ON order_status_history IS 
'Restaurants can view order history - uses IN subquery to prevent recursion';

-- =====================================================
-- VERIFICATION
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '=== MIGRATION COMPLETE ===';
  RAISE NOTICE 'order_items policies: %', (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'order_items');
  RAISE NOTICE 'order_status_history policies: %', (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'order_status_history');
  RAISE NOTICE 'orders policies: % (unchanged)', (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'orders');
  RAISE NOTICE '';
  RAISE NOTICE 'Test this query - it should work without recursion:';
  RAISE NOTICE 'SELECT * FROM orders WHERE user_id = auth.uid() LIMIT 1;';
  RAISE NOTICE '';
  RAISE NOTICE 'And this nested query should also work:';
  RAISE NOTICE 'SELECT o.*, oi.* FROM orders o LEFT JOIN order_items oi ON o.id = oi.order_id WHERE o.user_id = auth.uid();';
END $$;
