-- ============================================
-- Migration 005: Add RLS Policy for NGO Meal Access
-- Date: 2026-02-11
-- Author: System Fix
-- ============================================
-- PROBLEM:
-- NGO users cannot view meals due to missing RLS policy
-- SQL queries work in SQL editor but fail in app
-- ============================================

-- Check existing policies
DO $
DECLARE
  policy_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'meals' 
    AND policyname = 'NGOs can view donation meals'
  ) INTO policy_exists;
  
  IF policy_exists THEN
    RAISE NOTICE '✓ Policy already exists, dropping to recreate...';
    DROP POLICY IF EXISTS "NGOs can view donation meals" ON public.meals;
  END IF;
END $;

-- Allow NGOs to view all active donation meals
CREATE POLICY "NGOs can view donation meals"
ON public.meals FOR SELECT
TO authenticated
USING (
  is_donation_available = true 
  AND status = 'active'
  AND EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'ngo'
    AND profiles.approval_status = 'approved'
  )
);

COMMENT ON POLICY "NGOs can view donation meals" ON public.meals IS 
  'Allows approved NGO users to view all active meals available for donation';

-- Also ensure restaurants table is readable by NGOs (for joins)
DO $
DECLARE
  policy_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'restaurants' 
    AND policyname = 'NGOs can view restaurant info'
  ) INTO policy_exists;
  
  IF NOT policy_exists THEN
    CREATE POLICY "NGOs can view restaurant info"
    ON public.restaurants FOR SELECT
    TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'ngo'
      )
    );
    
    RAISE NOTICE '✅ Created policy for NGOs to view restaurants';
  ELSE
    RAISE NOTICE '✓ Restaurant view policy already exists';
  END IF;
END $;

-- Verification
DO $
DECLARE
  meal_count integer;
  restaurant_count integer;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'RLS Policy Verification:';
  RAISE NOTICE '========================================';
  
  -- Count meals available for donation
  SELECT COUNT(*) INTO meal_count
  FROM meals
  WHERE is_donation_available = true 
    AND status = 'active'
    AND quantity_available > 0;
  
  RAISE NOTICE 'Meals available for donation: %', meal_count;
  
  -- Count restaurants
  SELECT COUNT(*) INTO restaurant_count
  FROM restaurants;
  
  RAISE NOTICE 'Total restaurants: %', restaurant_count;
  
  -- List policies
  RAISE NOTICE '';
  RAISE NOTICE 'Active policies on meals table:';
  FOR policy_rec IN 
    SELECT policyname, cmd 
    FROM pg_policies 
    WHERE tablename = 'meals'
    ORDER BY policyname
  LOOP
    RAISE NOTICE '  - % (%)', policy_rec.policyname, policy_rec.cmd;
  END LOOP;
  
  RAISE NOTICE '========================================';
END $;

-- Summary
DO $
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ Migration 005 applied successfully';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'NGO users can now view:';
  RAISE NOTICE '1. All active donation meals';
  RAISE NOTICE '2. Restaurant information for joins';
  RAISE NOTICE '';
  RAISE NOTICE 'Test with NGO user to verify data loads';
  RAISE NOTICE '========================================';
END $;
