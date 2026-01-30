-- ============================================
-- DIAGNOSTIC QUERIES
-- ============================================
-- Run these to diagnose the signup failure
-- ============================================

-- 1. Check if trigger exists
SELECT 
  tgname as trigger_name,
  tgenabled as enabled,
  pg_get_triggerdef(oid) as definition
FROM pg_trigger 
WHERE tgname = 'on_auth_user_created';

-- Expected: 1 row with trigger definition

-- ============================================

-- 2. Check trigger function source
SELECT 
  proname as function_name,
  prosrc as source_code
FROM pg_proc 
WHERE proname = 'handle_new_user';

-- Expected: Function with exception blocks and NULLIF logic

-- ============================================

-- 3. Check recent auth.users records
SELECT 
  id,
  email,
  email_confirmed_at,
  raw_user_meta_data->>'role' as role,
  raw_user_meta_data->>'full_name' as full_name,
  raw_user_meta_data->>'organization_name' as org_name,
  created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;

-- Check if user was created in auth.users

-- ============================================

-- 4. Check if profile was created
SELECT 
  p.id,
  p.email,
  p.role,
  p.full_name,
  p.approval_status,
  p.created_at
FROM public.profiles p
WHERE p.email = 'mohamedelekhnawy324@gmail.com';

-- Expected: 1 row if trigger worked

-- ============================================

-- 5. Check if restaurant record was created
SELECT 
  r.profile_id,
  r.restaurant_name,
  r.legal_docs_urls,
  p.email
FROM public.restaurants r
JOIN public.profiles p ON r.profile_id = p.id
WHERE p.email = 'mohamedelekhnawy324@gmail.com';

-- Expected: 1 row if trigger worked

-- ============================================

-- 6. Check Postgres logs for warnings
-- (Run in psql or check Supabase logs dashboard)
SELECT 
  message,
  detail,
  hint
FROM pg_stat_statements
WHERE query LIKE '%handle_new_user%'
ORDER BY calls DESC
LIMIT 10;

-- Look for WARNING messages from trigger

-- ============================================

-- 7. Test trigger manually (SAFE - won't affect real data)
DO $$
DECLARE
  test_user_id uuid := gen_random_uuid();
  test_email text := 'test-' || test_user_id::text || '@example.com';
BEGIN
  -- Simulate what happens during signup
  RAISE NOTICE 'Testing trigger with user_id: %', test_user_id;
  
  -- This would normally be done by auth.signUp
  -- We're just testing the trigger logic
  
  -- Check if trigger function exists
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_new_user') THEN
    RAISE EXCEPTION 'Trigger function handle_new_user does not exist!';
  END IF;
  
  RAISE NOTICE 'Trigger function exists';
END $$;

-- ============================================

-- 8. Check RLS policies on profiles
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
WHERE schemaname = 'public' 
  AND tablename IN ('profiles', 'restaurants', 'ngos')
ORDER BY tablename, policyname;

-- Expected: Policies allowing service role to insert

-- ============================================

-- 9. Check if email already exists (duplicate signup)
SELECT 
  id,
  email,
  created_at
FROM auth.users
WHERE email = 'mohamedelekhnawy324@gmail.com';

-- If returns row: Email already registered

-- ============================================

-- 10. Check Supabase auth settings
-- Go to: Supabase Dashboard → Authentication → Settings
-- Verify:
-- - Email confirmation is enabled
-- - Email templates are configured
-- - SMTP is configured (or using Supabase default)

-- ============================================
-- COMMON ISSUES & FIXES
-- ============================================

-- Issue 1: Trigger not deployed
-- Fix: Run database-migrations-002-fix-trigger-robustness.sql

-- Issue 2: Email already exists
-- Fix: Use different email or delete existing user:
-- DELETE FROM auth.users WHERE email = 'mohamedelekhnawy324@gmail.com';

-- Issue 3: RLS blocking inserts
-- Fix: Check policies allow service role to insert

-- Issue 4: Trigger function has syntax error
-- Fix: Check function source in query #2 above

-- Issue 5: Organization name is NULL
-- Fix: Trigger should handle this with NULLIF and auto-generation

-- ============================================
-- NEXT STEPS
-- ============================================

-- 1. Run queries 1-5 above
-- 2. Share results
-- 3. Check Supabase logs dashboard for detailed error
-- 4. If trigger not updated, run migration 002
