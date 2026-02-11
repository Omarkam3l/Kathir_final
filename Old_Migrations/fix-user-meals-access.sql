-- =====================================================
-- FIX: User Access to Meals
-- =====================================================
-- This fixes the issue where users cannot see meals on home screen

-- =====================================================
-- STEP 1: Update RLS Policies for Users
-- =====================================================

-- Drop the restrictive public policy
DROP POLICY IF EXISTS "Public can view active meals" ON meals;

-- Create a more permissive policy for authenticated users (not restaurants)
CREATE POLICY "Users can view all active meals"
ON meals
FOR SELECT
TO authenticated
USING (
  -- Allow if user is NOT a restaurant (regular users and NGOs)
  NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'restaurant'
  )
  AND status = 'active'
  AND quantity_available > 0
);

-- Also allow anonymous users to browse meals (optional, for public access)
CREATE POLICY "Anonymous can view active meals"
ON meals
FOR SELECT
TO anon
USING (
  status = 'active'
  AND quantity_available > 0
  AND expiry_date > NOW()
);

-- =====================================================
-- STEP 2: Fix Column Names in Meals Table
-- =====================================================

-- Check if we need to add missing columns
DO $$
BEGIN
  -- Add location column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'meals' AND column_name = 'location'
  ) THEN
    ALTER TABLE meals ADD COLUMN location text;
  END IF;

  -- Add donation_price column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'meals' AND column_name = 'donation_price'
  ) THEN
    ALTER TABLE meals ADD COLUMN donation_price decimal(12,2) DEFAULT 0;
  END IF;

  -- Add quantity column if it doesn't exist (different from quantity_available)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'meals' AND column_name = 'quantity'
  ) THEN
    ALTER TABLE meals ADD COLUMN quantity int;
    -- Copy from quantity_available if it exists
    UPDATE meals SET quantity = quantity_available WHERE quantity IS NULL;
  END IF;

  -- Add expiry column if it doesn't exist (different from expiry_date)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'meals' AND column_name = 'expiry'
  ) THEN
    ALTER TABLE meals ADD COLUMN expiry timestamptz;
    -- Copy from expiry_date if it exists
    UPDATE meals SET expiry = expiry_date WHERE expiry IS NULL;
  END IF;

  -- Add status column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'meals' AND column_name = 'status'
  ) THEN
    ALTER TABLE meals ADD COLUMN status text DEFAULT 'active';
  END IF;
END $$;

-- =====================================================
-- STEP 3: Verify Restaurants Table Structure
-- =====================================================

-- Check restaurants table columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'restaurants'
ORDER BY ordinal_position;

-- =====================================================
-- STEP 4: Create View for Easy Meal Access (Optional)
-- =====================================================

-- Drop existing view if it exists
DROP VIEW IF EXISTS meals_with_restaurant;

-- Create a view that joins meals with restaurants
CREATE OR REPLACE VIEW meals_with_restaurant AS
SELECT 
  m.id,
  m.title,
  m.description,
  m.category,
  m.image_url,
  m.original_price,
  m.discounted_price,
  COALESCE(m.donation_price, m.discounted_price) as donation_price,
  m.quantity_available,
  COALESCE(m.quantity, m.quantity_available) as quantity,
  m.expiry_date,
  COALESCE(m.expiry, m.expiry_date) as expiry,
  m.pickup_deadline,
  COALESCE(m.location, 'Pickup at restaurant') as location,
  COALESCE(m.status, 'active') as status,
  m.restaurant_id,
  m.created_at,
  -- Restaurant info
  r.restaurant_name as restaurant_name,
  r.rating as restaurant_rating,
  r.address as restaurant_address
FROM meals m
LEFT JOIN restaurants r ON m.restaurant_id = r.profile_id
WHERE m.status = 'active'
  AND m.quantity_available > 0
  AND m.expiry_date > NOW();

-- Grant access to the view
GRANT SELECT ON meals_with_restaurant TO authenticated, anon;

-- =====================================================
-- STEP 5: Test Queries
-- =====================================================

-- Test 1: Check if meals are visible to current user
SELECT COUNT(*) as total_active_meals
FROM meals
WHERE status = 'active'
  AND quantity_available > 0;

-- Test 2: Check meals with restaurant info
SELECT 
  m.id,
  m.title,
  m.category,
  m.original_price,
  m.discounted_price,
  m.quantity_available,
  r.restaurant_name
FROM meals m
LEFT JOIN restaurants r ON m.restaurant_id = r.profile_id
WHERE m.status = 'active'
  AND m.quantity_available > 0
LIMIT 5;

-- Test 3: Check RLS policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'meals'
ORDER BY policyname;

-- =====================================================
-- STEP 6: Update Orders Table RLS (if needed)
-- =====================================================

-- Enable RLS on orders table
ALTER TABLE IF EXISTS orders ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Users can insert their own orders" ON orders;
DROP POLICY IF EXISTS "Restaurants can view orders for their meals" ON orders;

-- Create policies for orders
CREATE POLICY "Users can view their own orders"
ON orders
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own orders"
ON orders
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Restaurants can view orders for their meals"
ON orders
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM meals m
    WHERE m.id = orders.meal_id
    AND m.restaurant_id = auth.uid()
  )
);

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Final check: List all policies
SELECT 
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename IN ('meals', 'orders', 'restaurants')
ORDER BY tablename, policyname;

-- Check column names
SELECT 
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name IN ('meals', 'restaurants', 'orders')
ORDER BY table_name, ordinal_position;
