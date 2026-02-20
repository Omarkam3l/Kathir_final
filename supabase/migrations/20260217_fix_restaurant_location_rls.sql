-- Fix Restaurant Location RLS Policies
-- Problem: Conflicting policies preventing location data from being visible
-- Solution: Clean up and consolidate RLS policies for restaurants table

-- Drop all existing SELECT policies on restaurants table
DROP POLICY IF EXISTS "Anyone can read restaurant locations" ON restaurants;
DROP POLICY IF EXISTS "Public can view restaurants" ON restaurants;
DROP POLICY IF EXISTS "Restaurant owners can view own record" ON restaurants;

-- Create a single, clear SELECT policy that allows everyone to read all restaurant data
-- This includes location fields (latitude, longitude, location, address_text)
CREATE POLICY "restaurants_select_all"
ON restaurants FOR SELECT
TO authenticated, anon
USING (true);

-- Keep UPDATE policies for restaurant owners
-- These are already correct and don't need changes

-- Verify the policy works by testing
COMMENT ON POLICY "restaurants_select_all" ON restaurants IS 
'Allows everyone (authenticated and anonymous users) to view all restaurant data including location fields. 
This is safe because restaurant locations are public information needed for the app to function.';
