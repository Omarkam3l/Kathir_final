-- ============================================
-- MIGRATION: Fix Role Mismatch 'rest' → 'restaurant'
-- ============================================
-- Purpose: Update existing users with role='rest' to role='restaurant'
-- Issue: Flutter was sending 'rest' but database expects 'restaurant'
-- Impact: Restaurant records not created, legal docs not saved
-- ============================================

-- ============================================
-- PART 1: CHECK CURRENT STATE
-- ============================================

DO $
DECLARE
  rest_count_auth integer;
  rest_count_profiles integer;
BEGIN
  -- Count users with role='rest' in auth.users
  SELECT COUNT(*) INTO rest_count_auth
  FROM auth.users 
  WHERE raw_user_meta_data->>'role' = 'rest';
  
  -- Count users with role='rest' in profiles
  SELECT COUNT(*) INTO rest_count_profiles
  FROM public.profiles 
  WHERE role = 'rest';
  
  RAISE NOTICE 'Found % users with role=''rest'' in auth.users', rest_count_auth;
  RAISE NOTICE 'Found % users with role=''rest'' in profiles', rest_count_profiles;
  
  IF rest_count_auth = 0 AND rest_count_profiles = 0 THEN
    RAISE NOTICE '✅ No migration needed - no users with role=''rest''';
  ELSE
    RAISE NOTICE '⚠️  Migration needed - will update % total users', rest_count_auth + rest_count_profiles;
  END IF;
END $;

-- ============================================
-- PART 2: BACKUP CURRENT DATA (Optional but Recommended)
-- ============================================

-- Create backup table for auth.users metadata
CREATE TABLE IF NOT EXISTS public.backup_auth_users_metadata (
  id uuid PRIMARY KEY,
  email text,
  raw_user_meta_data jsonb,
  backed_up_at timestamp with time zone DEFAULT NOW()
);

-- Backup users with role='rest'
INSERT INTO public.backup_auth_users_metadata (id, email, raw_user_meta_data)
SELECT 
  id, 
  email, 
  raw_user_meta_data
FROM auth.users 
WHERE raw_user_meta_data->>'role' = 'rest'
ON CONFLICT (id) DO NOTHING;

-- Create backup table for profiles
CREATE TABLE IF NOT EXISTS public.backup_profiles_role (
  id uuid PRIMARY KEY,
  email text,
  role text,
  backed_up_at timestamp with time zone DEFAULT NOW()
);

-- Backup profiles with role='rest'
INSERT INTO public.backup_profiles_role (id, email, role)
SELECT 
  id, 
  email, 
  role
FROM public.profiles 
WHERE role = 'rest'
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- PART 3: UPDATE auth.users
-- ============================================

DO $
DECLARE
  updated_count integer;
BEGIN
  -- Update raw_user_meta_data.role from 'rest' to 'restaurant'
  WITH updated AS (
    UPDATE auth.users 
    SET raw_user_meta_data = jsonb_set(
      raw_user_meta_data, 
      '{role}', 
      '"restaurant"'
    )
    WHERE raw_user_meta_data->>'role' = 'rest'
    RETURNING id
  )
  SELECT COUNT(*) INTO updated_count FROM updated;
  
  RAISE NOTICE '✅ Updated % users in auth.users (rest → restaurant)', updated_count;
END $;

-- ============================================
-- PART 4: UPDATE profiles
-- ============================================

DO $
DECLARE
  updated_count integer;
BEGIN
  -- Update profiles.role from 'rest' to 'restaurant'
  WITH updated AS (
    UPDATE public.profiles 
    SET 
      role = 'restaurant',
      updated_at = NOW()
    WHERE role = 'rest'
    RETURNING id
  )
  SELECT COUNT(*) INTO updated_count FROM updated;
  
  RAISE NOTICE '✅ Updated % users in profiles (rest → restaurant)', updated_count;
END $;

-- ============================================
-- PART 5: CREATE MISSING RESTAURANT RECORDS
-- ============================================

-- For users who signed up with role='rest', the trigger didn't create restaurant records
-- We need to create them now

DO $
DECLARE
  created_count integer;
  user_record RECORD;
BEGIN
  created_count := 0;
  
  -- Find profiles with role='restaurant' but no restaurant record
  FOR user_record IN 
    SELECT 
      p.id,
      p.email,
      p.full_name,
      au.raw_user_meta_data->>'organization_name' as org_name
    FROM public.profiles p
    LEFT JOIN public.restaurants r ON r.profile_id = p.id
    LEFT JOIN auth.users au ON au.id = p.id
    WHERE p.role = 'restaurant' 
      AND r.profile_id IS NULL
  LOOP
    BEGIN
      -- Create restaurant record
      INSERT INTO public.restaurants (
        profile_id,
        restaurant_name,
        legal_docs_urls,
        rating,
        min_order_price,
        rush_hour_active
      )
      VALUES (
        user_record.id,
        COALESCE(
          NULLIF(TRIM(user_record.org_name), ''),
          NULLIF(TRIM(user_record.full_name), ''),
          'Restaurant ' || SUBSTRING(user_record.id::text, 1, 8)
        ),
        ARRAY[]::text[],
        0,
        0,
        false
      )
      ON CONFLICT (profile_id) DO NOTHING;
      
      created_count := created_count + 1;
      RAISE NOTICE 'Created restaurant record for user % (%)', user_record.id, user_record.email;
      
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Failed to create restaurant record for user %: %', user_record.id, SQLERRM;
    END;
  END LOOP;
  
  RAISE NOTICE '✅ Created % missing restaurant records', created_count;
END $;

-- ============================================
-- PART 6: VERIFICATION
-- ============================================

-- Verify no more 'rest' in auth.users
DO $
DECLARE
  rest_count integer;
BEGIN
  SELECT COUNT(*) INTO rest_count
  FROM auth.users 
  WHERE raw_user_meta_data->>'role' = 'rest';
  
  IF rest_count = 0 THEN
    RAISE NOTICE '✅ VERIFIED: No users with role=''rest'' in auth.users';
  ELSE
    RAISE WARNING '❌ FAILED: Still found % users with role=''rest'' in auth.users', rest_count;
  END IF;
END $;

-- Verify no more 'rest' in profiles
DO $
DECLARE
  rest_count integer;
BEGIN
  SELECT COUNT(*) INTO rest_count
  FROM public.profiles 
  WHERE role = 'rest';
  
  IF rest_count = 0 THEN
    RAISE NOTICE '✅ VERIFIED: No users with role=''rest'' in profiles';
  ELSE
    RAISE WARNING '❌ FAILED: Still found % users with role=''rest'' in profiles', rest_count;
  END IF;
END $;

-- Verify all restaurant profiles have restaurant records
DO $
DECLARE
  missing_count integer;
BEGIN
  SELECT COUNT(*) INTO missing_count
  FROM public.profiles p
  LEFT JOIN public.restaurants r ON r.profile_id = p.id
  WHERE p.role = 'restaurant' 
    AND r.profile_id IS NULL;
  
  IF missing_count = 0 THEN
    RAISE NOTICE '✅ VERIFIED: All restaurant profiles have restaurant records';
  ELSE
    RAISE WARNING '❌ FAILED: Found % restaurant profiles without restaurant records', missing_count;
  END IF;
END $;

-- ============================================
-- PART 7: SUMMARY REPORT
-- ============================================

SELECT 
  'Migration Summary' as report_type,
  (SELECT COUNT(*) FROM public.backup_auth_users_metadata) as backed_up_auth_users,
  (SELECT COUNT(*) FROM public.backup_profiles_role) as backed_up_profiles,
  (SELECT COUNT(*) FROM auth.users WHERE raw_user_meta_data->>'role' = 'restaurant') as restaurant_users_auth,
  (SELECT COUNT(*) FROM public.profiles WHERE role = 'restaurant') as restaurant_users_profiles,
  (SELECT COUNT(*) FROM public.restaurants) as restaurant_records,
  (SELECT COUNT(*) FROM auth.users WHERE raw_user_meta_data->>'role' = 'rest') as remaining_rest_auth,
  (SELECT COUNT(*) FROM public.profiles WHERE role = 'rest') as remaining_rest_profiles;

-- ============================================
-- PART 8: CLEANUP (Optional - Run After Verification)
-- ============================================

-- Uncomment to drop backup tables after successful migration
-- DROP TABLE IF EXISTS public.backup_auth_users_metadata;
-- DROP TABLE IF EXISTS public.backup_profiles_role;

-- ============================================
-- NOTES
-- ============================================

-- This migration:
-- 1. ✅ Backs up existing data
-- 2. ✅ Updates auth.users.raw_user_meta_data.role from 'rest' to 'restaurant'
-- 3. ✅ Updates profiles.role from 'rest' to 'restaurant'
-- 4. ✅ Creates missing restaurant records for affected users
-- 5. ✅ Verifies no more 'rest' roles exist
-- 6. ✅ Provides summary report

-- Safe to run multiple times (idempotent)
-- Backup tables preserved for rollback if needed

-- ============================================
-- END OF MIGRATION
-- ============================================
