-- =====================================================
-- COMPREHENSIVE RLS POLICY FIX
-- Eliminates recursion, removes duplicates, optimizes performance
-- =====================================================

-- =====================================================
-- PART 1: FIX ORDER-RELATED CIRCULAR DEPENDENCIES
-- =====================================================

-- Drop ALL existing order_items policies
DROP POLICY IF EXISTS "Authenticated users can create order items" ON order_items;
DROP POLICY IF EXISTS "NGOs can view their order items" ON order_items;
DROP POLICY IF EXISTS "Restaurants can view their order items" ON order_items;
DROP POLICY IF EXISTS "Users can insert their order items" ON order_items;
DROP POLICY IF EXISTS "Users can view their order items" ON order_items;

-- Drop ALL existing order_status_history policies
DROP POLICY IF EXISTS "Allow status history inserts" ON order_status_history;
DROP POLICY IF EXISTS "Restaurants can insert status history for their orders" ON order_status_history;
DROP POLICY IF EXISTS "Restaurants can view their order history" ON order_status_history;
DROP POLICY IF EXISTS "Users can view their order history" ON order_status_history;

-- Drop ALL existing orders policies (we'll recreate clean ones)
DROP POLICY IF EXISTS "NGOs can view their orders" ON orders;
DROP POLICY IF EXISTS "Restaurants can update their orders" ON orders;
DROP POLICY IF EXISTS "Restaurants can view their orders" ON orders;
DROP POLICY IF EXISTS "Users can create orders" ON orders;
DROP POLICY IF EXISTS "Users can insert their own orders" ON orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
DROP POLICY IF EXISTS "Users can view their orders" ON orders;

-- =====================================================
-- ORDERS TABLE: Clean, non-recursive policies
-- =====================================================

CREATE POLICY "orders_insert_users"
ON orders FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "orders_select_users"
ON orders FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "orders_select_restaurants"
ON orders FOR SELECT
TO authenticated
USING (restaurant_id = auth.uid());

CREATE POLICY "orders_select_ngos"
ON orders FOR SELECT
TO authenticated
USING (ngo_id = auth.uid());

CREATE POLICY "orders_update_users"
ON orders FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "orders_update_restaurants"
ON orders FOR UPDATE
TO authenticated
USING (restaurant_id = auth.uid())
WITH CHECK (restaurant_id = auth.uid());

-- =====================================================
-- ORDER_ITEMS TABLE: Use IN subquery (not EXISTS)
-- This prevents recursion when orders table is queried with order_items
-- Note: NGOs policy already uses EXISTS but with alias 'o' - convert to IN for consistency
-- =====================================================

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
-- ORDER_STATUS_HISTORY TABLE: Use IN subquery
-- Note: "Allow status history inserts" policy allows all authenticated users - keep it
-- =====================================================

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

CREATE POLICY "order_status_history_insert_restaurants"
ON order_status_history FOR INSERT
TO authenticated
WITH CHECK (
  order_id IN (
    SELECT id FROM orders WHERE restaurant_id = auth.uid()
  )
);

-- =====================================================
-- PART 2: REMOVE DUPLICATE POLICIES
-- =====================================================

-- CART_ITEMS: Remove redundant policies (ALL policy covers everything)
-- The "ALL" policy makes the specific INSERT/SELECT/UPDATE/DELETE policies redundant
DROP POLICY IF EXISTS "Users can delete their own cart items" ON cart_items;
DROP POLICY IF EXISTS "Users can insert their own cart items" ON cart_items;
DROP POLICY IF EXISTS "Users can update their own cart items" ON cart_items;
DROP POLICY IF EXISTS "Users can view their own cart items" ON cart_items;
-- Keep only: "Users can manage own cart" (ALL command covers all operations)

-- USER_ADDRESSES: Remove duplicates
DROP POLICY IF EXISTS "Users can delete own addresses" ON user_addresses;
DROP POLICY IF EXISTS "Users can insert own addresses" ON user_addresses;
DROP POLICY IF EXISTS "Users can update own addresses" ON user_addresses;
DROP POLICY IF EXISTS "Users can view own addresses" ON user_addresses;
-- Keep only the authenticated versions

-- NGOS: Remove massive duplication (16 policies down to 4)
DROP POLICY IF EXISTS "NGO owners can insert own details" ON ngos;
DROP POLICY IF EXISTS "NGO owners can update own details" ON ngos;
DROP POLICY IF EXISTS "NGO owners can update own record" ON ngos;
DROP POLICY IF EXISTS "NGO owners can view own record" ON ngos;
DROP POLICY IF EXISTS "NGOs can update their own profile" ON ngos;
DROP POLICY IF EXISTS "NGOs can view their own profile" ON ngos;
DROP POLICY IF EXISTS "NGOs: select own" ON ngos;
DROP POLICY IF EXISTS "NGOs: update own" ON ngos;
DROP POLICY IF EXISTS "Public can view NGOs" ON ngos;
DROP POLICY IF EXISTS "Public can view ngos" ON ngos;
DROP POLICY IF EXISTS "Users can update own ngo" ON ngos;
DROP POLICY IF EXISTS "Users can view own ngo" ON ngos;
DROP POLICY IF EXISTS "NGOs: public browse approved" ON ngos;
DROP POLICY IF EXISTS "Public can view approved ngos" ON ngos;
-- Keep: "Service role can insert ngos", "System can insert ngos"

-- Recreate clean NGO policies (4 total)
CREATE POLICY "ngos_select_owner"
ON ngos FOR SELECT
TO authenticated
USING (profile_id = auth.uid() OR is_admin());

CREATE POLICY "ngos_select_public_approved"
ON ngos FOR SELECT
TO anon, authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = ngos.profile_id
    AND p.approval_status = 'approved'
  )
);

CREATE POLICY "ngos_update_owner"
ON ngos FOR UPDATE
TO authenticated
USING (profile_id = auth.uid() OR is_admin())
WITH CHECK (profile_id = auth.uid() OR is_admin());

-- RUSH_HOURS: Remove redundant policies (ALL policy covers everything)
DROP POLICY IF EXISTS "Restaurants can delete their own rush hours" ON rush_hours;
DROP POLICY IF EXISTS "Restaurants can insert their own rush hours" ON rush_hours;
DROP POLICY IF EXISTS "Restaurants can update their own rush hours" ON rush_hours;
DROP POLICY IF EXISTS "Restaurants can view their own rush hours" ON rush_hours;
-- Keep: "Restaurant owners can manage rush hours" (ALL command covers all operations)
-- Keep: "Public can view active rush hours" and "Public can view rush hours" for public access

-- RESTAURANTS: Remove massive duplication (15 policies down to 4)
DROP POLICY IF EXISTS "Restaurant owners can insert own details" ON restaurants;
DROP POLICY IF EXISTS "Restaurant owners can update own details" ON restaurants;
DROP POLICY IF EXISTS "Restaurant owners can update own record" ON restaurants;
DROP POLICY IF EXISTS "Restaurant owners can view own record" ON restaurants;
DROP POLICY IF EXISTS "Restaurants can update their own profile" ON restaurants;
DROP POLICY IF EXISTS "Restaurants can view their own profile" ON restaurants;
DROP POLICY IF EXISTS "Restaurants: select own" ON restaurants;
DROP POLICY IF EXISTS "Restaurants: update own" ON restaurants;
DROP POLICY IF EXISTS "Public can view restaurants" ON restaurants;
DROP POLICY IF EXISTS "Users can update own restaurant" ON restaurants;
DROP POLICY IF EXISTS "Users can view own restaurant" ON restaurants;
DROP POLICY IF EXISTS "Public can view approved restaurants" ON restaurants;
DROP POLICY IF EXISTS "Restaurants: public browse approved" ON restaurants;
-- Keep: "Service role can insert restaurants", "System can insert restaurants"

-- Recreate clean restaurant policies (3 total)
CREATE POLICY "restaurants_select_owner"
ON restaurants FOR SELECT
TO authenticated
USING (profile_id = auth.uid() OR is_admin());

CREATE POLICY "restaurants_select_public_approved"
ON restaurants FOR SELECT
TO anon, authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = restaurants.profile_id
    AND p.approval_status = 'approved'
  )
);

CREATE POLICY "restaurants_update_owner"
ON restaurants FOR UPDATE
TO authenticated
USING (profile_id = auth.uid() OR is_admin())
WITH CHECK (profile_id = auth.uid() OR is_admin());

-- =====================================================
-- PART 3: ADD PERFORMANCE INDEXES
-- =====================================================

-- Indexes for order-related queries (prevent full table scans in RLS)
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_restaurant_id ON orders(restaurant_id) WHERE restaurant_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_ngo_id ON orders(ngo_id) WHERE ngo_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(order_id);

-- Indexes for profile lookups
CREATE INDEX IF NOT EXISTS idx_profiles_approval_status ON profiles(approval_status) WHERE approval_status = 'approved';
CREATE INDEX IF NOT EXISTS idx_ngos_profile_id ON ngos(profile_id);
CREATE INDEX IF NOT EXISTS idx_restaurants_profile_id ON restaurants(profile_id);

-- =====================================================
-- PART 4: ADD HELPFUL COMMENTS
-- =====================================================

COMMENT ON POLICY "orders_select_users" ON orders IS 
'Users can view their own orders - direct column check, no recursion';

COMMENT ON POLICY "order_items_select_users" ON order_items IS 
'Users can view order items via IN subquery - prevents recursion when querying orders with nested order_items';

COMMENT ON POLICY "order_status_history_select_users" ON order_status_history IS 
'Users can view order history via IN subquery - prevents recursion';

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Count policies per table (should be much lower now)
DO $
BEGIN
  RAISE NOTICE 'Policy count after cleanup:';
  RAISE NOTICE 'orders: %', (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'orders');
  RAISE NOTICE 'order_items: %', (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'order_items');
  RAISE NOTICE 'order_status_history: %', (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'order_status_history');
  RAISE NOTICE 'ngos: %', (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'ngos');
  RAISE NOTICE 'restaurants: %', (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'restaurants');
  RAISE NOTICE 'cart_items: %', (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'cart_items');
  RAISE NOTICE 'user_addresses: %', (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'user_addresses');
END $;
