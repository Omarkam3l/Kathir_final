-- =====================================================
-- FINAL RLS POLICIES - Matching Actual Schema
-- =====================================================
-- This file creates RLS policies for the ACTUAL database schema

-- =====================================================
-- STEP 1: Enable RLS on all tables
-- =====================================================

ALTER TABLE meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE ngos ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 2: Drop all existing policies (clean slate)
-- =====================================================

-- Meals policies
DROP POLICY IF EXISTS "Restaurants can view their own meals" ON meals;
DROP POLICY IF EXISTS "Restaurants can insert their own meals" ON meals;
DROP POLICY IF EXISTS "Restaurants can update their own meals" ON meals;
DROP POLICY IF EXISTS "Restaurants can delete their own meals" ON meals;
DROP POLICY IF EXISTS "Public can view active meals" ON meals;
DROP POLICY IF EXISTS "Users can view all active meals" ON meals;
DROP POLICY IF EXISTS "Anonymous can view active meals" ON meals;
DROP POLICY IF EXISTS "NGOs can view available meals" ON meals;

-- Restaurants policies
DROP POLICY IF EXISTS "Restaurants can view their own profile" ON restaurants;
DROP POLICY IF EXISTS "Restaurants can update their own profile" ON restaurants;
DROP POLICY IF EXISTS "Public can view restaurants" ON restaurants;

-- Orders policies
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Users can insert their own orders" ON orders;
DROP POLICY IF EXISTS "Restaurants can view orders for their meals" ON orders;
DROP POLICY IF EXISTS "NGOs can view their orders" ON orders;

-- Profiles policies
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Public can view approved profiles" ON profiles;

-- =====================================================
-- STEP 3: MEALS TABLE POLICIES
-- =====================================================

-- Policy 1: Restaurants can view their own meals
CREATE POLICY "Restaurants can view their own meals"
ON meals
FOR SELECT
TO authenticated
USING (
  restaurant_id = auth.uid()
);

-- Policy 2: Restaurants can insert their own meals
CREATE POLICY "Restaurants can insert their own meals"
ON meals
FOR INSERT
TO authenticated
WITH CHECK (
  restaurant_id = auth.uid()
);

-- Policy 3: Restaurants can update their own meals
CREATE POLICY "Restaurants can update their own meals"
ON meals
FOR UPDATE
TO authenticated
USING (restaurant_id = auth.uid())
WITH CHECK (restaurant_id = auth.uid());

-- Policy 4: Restaurants can delete their own meals
CREATE POLICY "Restaurants can delete their own meals"
ON meals
FOR DELETE
TO authenticated
USING (restaurant_id = auth.uid());

-- Policy 5: Users and NGOs can view active meals
CREATE POLICY "Users can view active meals"
ON meals
FOR SELECT
TO authenticated
USING (
  -- Allow if status is active OR status is null (for backward compatibility)
  (status = 'active' OR status IS NULL)
  AND quantity_available > 0
  AND expiry_date > NOW()
);

-- Policy 6: Anonymous users can browse meals
CREATE POLICY "Anonymous can view active meals"
ON meals
FOR SELECT
TO anon
USING (
  (status = 'active' OR status IS NULL)
  AND quantity_available > 0
  AND expiry_date > NOW()
);

-- =====================================================
-- STEP 4: RESTAURANTS TABLE POLICIES
-- =====================================================

-- Policy 1: Restaurants can view their own profile
CREATE POLICY "Restaurants can view their own profile"
ON restaurants
FOR SELECT
TO authenticated
USING (profile_id = auth.uid());

-- Policy 2: Restaurants can update their own profile
CREATE POLICY "Restaurants can update their own profile"
ON restaurants
FOR UPDATE
TO authenticated
USING (profile_id = auth.uid())
WITH CHECK (profile_id = auth.uid());

-- Policy 3: Everyone can view restaurant info (for meal listings)
CREATE POLICY "Public can view restaurants"
ON restaurants
FOR SELECT
TO authenticated, anon
USING (true);

-- =====================================================
-- STEP 5: ORDERS TABLE POLICIES
-- =====================================================

-- Policy 1: Users can view their own orders
CREATE POLICY "Users can view their own orders"
ON orders
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Policy 2: Users can insert their own orders
CREATE POLICY "Users can insert their own orders"
ON orders
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Policy 3: Users can update their own orders (for cancellation)
CREATE POLICY "Users can update their own orders"
ON orders
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Policy 4: Restaurants can view orders for their restaurant
CREATE POLICY "Restaurants can view their orders"
ON orders
FOR SELECT
TO authenticated
USING (restaurant_id = auth.uid());

-- Policy 5: Restaurants can update orders (status changes)
CREATE POLICY "Restaurants can update their orders"
ON orders
FOR UPDATE
TO authenticated
USING (restaurant_id = auth.uid())
WITH CHECK (restaurant_id = auth.uid());

-- Policy 6: NGOs can view their orders
CREATE POLICY "NGOs can view their orders"
ON orders
FOR SELECT
TO authenticated
USING (ngo_id = auth.uid());

-- =====================================================
-- STEP 6: ORDER_ITEMS TABLE POLICIES
-- =====================================================

-- Policy 1: Users can view order items for their orders
CREATE POLICY "Users can view their order items"
ON order_items
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = order_items.order_id
    AND orders.user_id = auth.uid()
  )
);

-- Policy 2: Users can insert order items for their orders
CREATE POLICY "Users can insert their order items"
ON order_items
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = order_items.order_id
    AND orders.user_id = auth.uid()
  )
);

-- Policy 3: Restaurants can view order items for their orders
CREATE POLICY "Restaurants can view order items"
ON order_items
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = order_items.order_id
    AND orders.restaurant_id = auth.uid()
  )
);

-- =====================================================
-- STEP 7: NGOS TABLE POLICIES
-- =====================================================

-- Policy 1: NGOs can view their own profile
CREATE POLICY "NGOs can view their own profile"
ON ngos
FOR SELECT
TO authenticated
USING (profile_id = auth.uid());

-- Policy 2: NGOs can update their own profile
CREATE POLICY "NGOs can update their own profile"
ON ngos
FOR UPDATE
TO authenticated
USING (profile_id = auth.uid())
WITH CHECK (profile_id = auth.uid());

-- Policy 3: Public can view NGO info
CREATE POLICY "Public can view NGOs"
ON ngos
FOR SELECT
TO authenticated, anon
USING (true);

-- =====================================================
-- STEP 8: PROFILES TABLE POLICIES
-- =====================================================

-- Policy 1: Users can view their own profile
CREATE POLICY "Users can view their own profile"
ON profiles
FOR SELECT
TO authenticated
USING (id = auth.uid());

-- Policy 2: Users can update their own profile
CREATE POLICY "Users can update their own profile"
ON profiles
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Policy 3: Public can view approved profiles (for restaurant/NGO listings)
CREATE POLICY "Public can view approved profiles"
ON profiles
FOR SELECT
TO authenticated, anon
USING (approval_status = 'approved');

-- =====================================================
-- STEP 9: Verification Queries
-- =====================================================

-- Check all policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename IN ('meals', 'restaurants', 'orders', 'order_items', 'ngos', 'profiles')
ORDER BY tablename, policyname;

-- Test meals query
SELECT 
  m.id,
  m.title,
  m.category,
  m.original_price,
  m.discounted_price,
  m.quantity_available,
  m.status,
  r.restaurant_name
FROM meals m
LEFT JOIN restaurants r ON m.restaurant_id = r.profile_id
WHERE (m.status = 'active' OR m.status IS NULL)
  AND m.quantity_available > 0
LIMIT 5;

-- Count active meals
SELECT COUNT(*) as total_active_meals
FROM meals
WHERE (status = 'active' OR status IS NULL)
  AND quantity_available > 0;

-- =====================================================
-- Success Message
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '✅ All RLS policies have been created successfully!';
  RAISE NOTICE '✅ Meals table: 6 policies';
  RAISE NOTICE '✅ Restaurants table: 3 policies';
  RAISE NOTICE '✅ Orders table: 6 policies';
  RAISE NOTICE '✅ Order_items table: 3 policies';
  RAISE NOTICE '✅ NGOs table: 3 policies';
  RAISE NOTICE '✅ Profiles table: 3 policies';
  RAISE NOTICE '';
  RAISE NOTICE '📋 Next steps:';
  RAISE NOTICE '1. Run add-missing-columns.sql to add missing columns';
  RAISE NOTICE '2. Restart your Flutter app';
  RAISE NOTICE '3. Test all functionality';
END $$;
