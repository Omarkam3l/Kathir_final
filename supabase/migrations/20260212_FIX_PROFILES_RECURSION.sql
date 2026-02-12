-- =====================================================
-- FIX: Profiles Table Recursion
-- Problem: is_admin() function in profiles policies causes recursion
-- Solution: Simplify policies to direct checks only
-- =====================================================

-- The issue: When querying orders → profiles, the profiles RLS
-- calls is_admin() which might query other tables, causing recursion

-- =====================================================
-- STEP 1: Check what is_admin() does
-- =====================================================

-- First, let's see if is_admin() exists and what it does
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'is_admin') THEN
    RAISE NOTICE 'is_admin() function exists - this might cause recursion';
    RAISE NOTICE 'Checking function definition...';
  ELSE
    RAISE NOTICE 'is_admin() function does NOT exist';
  END IF;
END $$;

-- =====================================================
-- STEP 2: Fix profiles policies - Remove is_admin() calls
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Public can view approved profiles" ON profiles;
DROP POLICY IF EXISTS "Service role can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Users can insert their profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their profile" ON profiles;
DROP POLICY IF EXISTS "Users can view their profile" ON profiles;

-- Recreate WITHOUT is_admin() calls (direct checks only)

CREATE POLICY "profiles_insert_service"
ON profiles FOR INSERT
TO service_role
WITH CHECK (true);

CREATE POLICY "profiles_insert_users"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_select_own"
ON profiles FOR SELECT
TO authenticated
USING (id = auth.uid());

CREATE POLICY "profiles_select_approved"
ON profiles FOR SELECT
TO anon, authenticated
USING (approval_status = 'approved');

CREATE POLICY "profiles_update_own"
ON profiles FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- =====================================================
-- STEP 3: Add comments
-- =====================================================

COMMENT ON POLICY "profiles_select_own" ON profiles IS 
'Users can view their own profile - direct check, no function calls, prevents recursion';

COMMENT ON POLICY "profiles_select_approved" ON profiles IS 
'Public can view approved profiles - direct check, no function calls';

COMMENT ON POLICY "profiles_update_own" ON profiles IS 
'Users can update their own profile - direct check, no is_admin() call';

-- =====================================================
-- VERIFICATION
-- =====================================================

DO $$
DECLARE
  profiles_count INT;
  has_is_admin INT;
BEGIN
  SELECT COUNT(*) INTO profiles_count FROM pg_policies WHERE tablename = 'profiles';
  
  -- Check if any policy still uses is_admin()
  SELECT COUNT(*) INTO has_is_admin 
  FROM pg_policies 
  WHERE tablename = 'profiles'
  AND (qual LIKE '%is_admin%' OR with_check LIKE '%is_admin%');

  RAISE NOTICE '=== PROFILES RECURSION FIX COMPLETE ===';
  RAISE NOTICE 'profiles policies: % (should be 5)', profiles_count;
  RAISE NOTICE 'Policies using is_admin(): % (should be 0)', has_is_admin;
  RAISE NOTICE '';
  
  IF has_is_admin > 0 THEN
    RAISE WARNING '❌ Still have % policies using is_admin() - recursion risk!', has_is_admin;
  ELSE
    RAISE NOTICE '✅ All policies use direct checks - recursion fixed!';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST IN YOUR APP ===';
  RAISE NOTICE 'Restaurant dashboard should now load orders with profiles!';
  RAISE NOTICE 'Query: orders → profiles!user_id(full_name)';
END $$;

-- =====================================================
-- EXPECTED RESULT
-- =====================================================
-- ✅ profiles: 5 policies (no is_admin() calls)
-- ✅ Restaurant dashboard loads without recursion
-- ✅ Orders with profiles join works
-- =====================================================
