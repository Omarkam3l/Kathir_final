-- =====================================================
-- DETAILED PROFILES POLICIES ANALYSIS
-- Run this to see EXACTLY what's in profiles policies
-- =====================================================

-- Query 1: List all profiles policies with full details
SELECT 
  schemaname as "Schema",
  tablename as "Table",
  policyname as "Policy Name",
  cmd as "Command",
  roles as "Roles",
  qual as "USING Expression",
  with_check as "WITH CHECK Expression"
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY cmd, policyname;

-- Query 2: Check for is_admin() function usage
SELECT 
  policyname as "Policy Name",
  cmd as "Command",
  CASE 
    WHEN qual LIKE '%is_admin%' OR with_check LIKE '%is_admin%' THEN '❌ USES is_admin() - RECURSION RISK'
    ELSE '✅ No is_admin() call'
  END as "Status",
  COALESCE(qual, 'N/A') as "USING",
  COALESCE(with_check, 'N/A') as "WITH CHECK"
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY cmd, policyname;

-- Query 3: Check if is_admin() function exists
SELECT 
  proname as "Function Name",
  pg_get_functiondef(oid) as "Function Definition"
FROM pg_proc
WHERE proname = 'is_admin';

-- Query 4: Count policies
SELECT 
  COUNT(*) as "Total Policies",
  COUNT(CASE WHEN cmd = 'SELECT' THEN 1 END) as "SELECT",
  COUNT(CASE WHEN cmd = 'INSERT' THEN 1 END) as "INSERT",
  COUNT(CASE WHEN cmd = 'UPDATE' THEN 1 END) as "UPDATE",
  COUNT(CASE WHEN cmd = 'DELETE' THEN 1 END) as "DELETE"
FROM pg_policies
WHERE tablename = 'profiles';

-- Query 5: Check for any function calls in policies
SELECT 
  policyname as "Policy Name",
  cmd as "Command",
  CASE 
    WHEN qual ~ '\w+\(' OR with_check ~ '\w+\(' THEN '⚠️ Contains function call'
    ELSE '✅ Direct checks only'
  END as "Function Check",
  qual as "USING Expression"
FROM pg_policies
WHERE tablename = 'profiles'
AND (qual IS NOT NULL OR with_check IS NOT NULL)
ORDER BY cmd, policyname;
