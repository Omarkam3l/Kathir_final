-- =====================================================
-- FIX: Meals Table RLS Policies
-- =====================================================
-- This fixes the RLS policy error when restaurants try to:
-- 1. View their own meals
-- 2. Add new meals
-- 3. Update their meals
-- 4. Delete their meals

-- Enable RLS on meals table (if not already enabled)
ALTER TABLE meals ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Restaurants can view their own meals" ON meals;
DROP POLICY IF EXISTS "Restaurants can insert their own meals" ON meals;
DROP POLICY IF EXISTS "Restaurants can update their own meals" ON meals;
DROP POLICY IF EXISTS "Restaurants can delete their own meals" ON meals;
DROP POLICY IF EXISTS "Public can view active meals" ON meals;
DROP POLICY IF EXISTS "NGOs can view available meals" ON meals;

-- =====================================================
-- POLICY 1: Restaurants can view their own meals
-- =====================================================
CREATE POLICY "Restaurants can view their own meals"
ON meals
FOR SELECT
TO authenticated
USING (
  restaurant_id = auth.uid()
  OR
  restaurant_id IN (
    SELECT profile_id 
    FROM restaurants 
    WHERE profile_id = auth.uid()
  )
);

-- =====================================================
-- POLICY 2: Restaurants can insert their own meals
-- =====================================================
CREATE POLICY "Restaurants can insert their own meals"
ON meals
FOR INSERT
TO authenticated
WITH CHECK (
  restaurant_id = auth.uid()
  OR
  restaurant_id IN (
    SELECT profile_id 
    FROM restaurants 
    WHERE profile_id = auth.uid()
  )
);

-- =====================================================
-- POLICY 3: Restaurants can update their own meals
-- =====================================================
CREATE POLICY "Restaurants can update their own meals"
ON meals
FOR UPDATE
TO authenticated
USING (
  restaurant_id = auth.uid()
  OR
  restaurant_id IN (
    SELECT profile_id 
    FROM restaurants 
    WHERE profile_id = auth.uid()
  )
)
WITH CHECK (
  restaurant_id = auth.uid()
  OR
  restaurant_id IN (
    SELECT profile_id 
    FROM restaurants 
    WHERE profile_id = auth.uid()
  )
);

-- =====================================================
-- POLICY 4: Restaurants can delete their own meals
-- =====================================================
CREATE POLICY "Restaurants can delete their own meals"
ON meals
FOR DELETE
TO authenticated
USING (
  restaurant_id = auth.uid()
  OR
  restaurant_id IN (
    SELECT profile_id 
    FROM restaurants 
    WHERE profile_id = auth.uid()
  )
);

-- =====================================================
-- POLICY 5: Public can view active meals (for users/NGOs)
-- =====================================================
CREATE POLICY "Public can view active meals"
ON meals
FOR SELECT
TO authenticated
USING (
  status = 'active'
  AND quantity_available > 0
  AND expiry_date > NOW()
);

-- =====================================================
-- POLICY 6: NGOs can view available meals
-- =====================================================
CREATE POLICY "NGOs can view available meals"
ON meals
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'ngo'
  )
  AND status = 'active'
);

-- =====================================================
-- Verify policies are created
-- =====================================================
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'meals'
ORDER BY policyname;

-- =====================================================
-- Test query (run this to verify)
-- =====================================================
-- SELECT * FROM meals WHERE restaurant_id = auth.uid();
