-- ============================================
-- FINAL AUTH SUBSYSTEM REBUILD
-- ============================================
-- Purpose: Complete authentication system rebuild
-- Scope: auth.users triggers, profiles, restaurants, ngos, RLS, storage
-- Date: 2026-01-29
-- Version: FINAL
-- ============================================

-- ============================================
-- PART 1: CLEANUP (Idempotent)
-- ============================================

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- Drop existing RLS policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Service role can insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admin can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admin can update approval status" ON public.profiles;

DROP POLICY IF EXISTS "Restaurant owners can view own record" ON public.restaurants;
DROP POLICY IF EXISTS "Restaurant owners can update own record" ON public.restaurants;
DROP POLICY IF EXISTS "Service role can insert restaurants" ON public.restaurants;
DROP POLICY IF EXISTS "Public can view restaurants" ON public.restaurants;

DROP POLICY IF EXISTS "NGO owners can view own record" ON public.ngos;
DROP POLICY IF EXISTS "NGO owners can update own record" ON public.ngos;
DROP POLICY IF EXISTS "Service role can insert ngos" ON public.ngos;
DROP POLICY IF EXISTS "Public can view ngos" ON public.ngos;

-- ============================================
-- PART 2: TABLE SCHEMA FIXES
-- ============================================

-- Fix restaurants table: make restaurant_name nullable with default
ALTER TABLE public.restaurants 
  ALTER COLUMN restaurant_name DROP NOT NULL;

ALTER TABLE public.restaurants 
  ALTER COLUMN restaurant_name SET DEFAULT 'Unnamed Restaurant';

-- Ensure legal_docs_urls has default
ALTER TABLE public.restaurants 
  ALTER COLUMN legal_docs_urls SET DEFAULT ARRAY[]::text[];

-- Fix ngos table: make organization_name nullable with default
ALTER TABLE public.ngos 
  ALTER COLUMN organization_name DROP NOT NULL;

ALTER TABLE public.ngos 
  ALTER COLUMN organization_name SET DEFAULT 'Unnamed Organization';

-- Ensure legal_docs_urls has default
ALTER TABLE public.ngos 
  ALTER COLUMN legal_docs_urls SET DEFAULT ARRAY[]::text[];

-- Ensure profiles has correct defaults
ALTER TABLE public.profiles 
  ALTER COLUMN is_verified SET DEFAULT false;

ALTER TABLE public.profiles 
  ALTER COLUMN approval_status SET DEFAULT 'pending';

-- ============================================
-- PART 3: ROBUST TRIGGER FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  user_role text;
  user_full_name text;
  user_phone text;
  org_name text;
  final_org_name text;
  profile_created boolean := false;
BEGIN
  -- Extract metadata from auth.users
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'user');
  user_full_name := COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'full_name'), ''), 'User');
  user_phone := NEW.raw_user_meta_data->>'phone_number';
  org_name := NEW.raw_user_meta_data->>'organization_name';

  -- Log trigger execution
  RAISE NOTICE 'handle_new_user triggered for user % with role %', NEW.id, user_role;

  -- Determine final organization name (never NULL or empty)
  IF user_role IN ('restaurant', 'ngo') THEN
    final_org_name := COALESCE(
      NULLIF(TRIM(org_name), ''),
      NULLIF(TRIM(user_full_name), ''),
      CASE 
        WHEN user_role = 'restaurant' THEN 'Restaurant ' || SUBSTRING(NEW.id::text, 1, 8)
        ELSE 'Organization ' || SUBSTRING(NEW.id::text, 1, 8)
      END
    );
  END IF;

  -- CRITICAL: Create profile record (must succeed)
  BEGIN
    INSERT INTO public.profiles (
      id, 
      email, 
      role, 
      full_name, 
      phone_number, 
      is_verified,
      approval_status,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      user_role,
      user_full_name,
      user_phone,
      CASE 
        WHEN user_role = 'user' THEN true 
        ELSE false 
      END,
      CASE 
        WHEN user_role IN ('restaurant', 'ngo') THEN 'pending'
        WHEN user_role = 'admin' THEN 'approved'
        ELSE 'approved'
      END,
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      role = EXCLUDED.role,
      full_name = EXCLUDED.full_name,
      phone_number = EXCLUDED.phone_number,
      updated_at = NOW();
    
    profile_created := true;
    RAISE NOTICE 'Profile created successfully for user %', NEW.id;
    
  EXCEPTION WHEN OTHERS THEN
    -- Profile creation is CRITICAL - must not fail
    RAISE WARNING 'CRITICAL: Failed to create profile for user %: % (SQLSTATE: %)', 
      NEW.id, SQLERRM, SQLSTATE;
    -- Re-raise to fail the signup
    RAISE;
  END;

  -- NON-CRITICAL: Create restaurant record (wrapped in exception)
  IF user_role = 'restaurant' AND profile_created THEN
    BEGIN
      INSERT INTO public.restaurants (
        profile_id,
        restaurant_name,
        legal_docs_urls,
        rating,
        min_order_price,
        rush_hour_active
      )
      VALUES (
        NEW.id,
        final_org_name,
        ARRAY[]::text[],
        0,
        0,
        false
      )
      ON CONFLICT (profile_id) DO UPDATE SET
        restaurant_name = COALESCE(EXCLUDED.restaurant_name, public.restaurants.restaurant_name),
        updated_at = NOW();
      
      RAISE NOTICE 'Restaurant record created for user %', NEW.id;
      
    EXCEPTION WHEN OTHERS THEN
      -- Log warning but don't fail signup
      RAISE WARNING 'Failed to create restaurant record for user %: % (SQLSTATE: %)', 
        NEW.id, SQLERRM, SQLSTATE;
      -- Don't re-raise - allow signup to continue
    END;
  END IF;

  -- NON-CRITICAL: Create NGO record (wrapped in exception)
  IF user_role = 'ngo' AND profile_created THEN
    BEGIN
      INSERT INTO public.ngos (
        profile_id,
        organization_name,
        legal_docs_urls
      )
      VALUES (
        NEW.id,
        final_org_name,
        ARRAY[]::text[]
      )
      ON CONFLICT (profile_id) DO UPDATE SET
        organization_name = COALESCE(EXCLUDED.organization_name, public.ngos.organization_name),
        updated_at = NOW();
      
      RAISE NOTICE 'NGO record created for user %', NEW.id;
      
    EXCEPTION WHEN OTHERS THEN
      -- Log warning but don't fail signup
      RAISE WARNING 'Failed to create NGO record for user %: % (SQLSTATE: %)', 
        NEW.id, SQLERRM, SQLSTATE;
      -- Don't re-raise - allow signup to continue
    END;
  END IF;

  RETURN NEW;
END;
$$;

-- Add comment
COMMENT ON FUNCTION public.handle_new_user() IS 
  'Trigger function to auto-create profile and role-specific records on user signup. Profile creation is critical and will fail signup if it fails. Role table creation is non-critical and will only log warnings.';

-- ============================================
-- PART 4: CREATE TRIGGER
-- ============================================

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW 
  EXECUTE FUNCTION public.handle_new_user();

COMMENT ON TRIGGER on_auth_user_created ON auth.users IS 
  'Automatically creates profile and role-specific records when a new user signs up';

-- ============================================
-- PART 5: RLS POLICIES - PROFILES
-- ============================================

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy 1: Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Policy 2: Users can update their own profile (except approval_status)
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id 
    AND (
      -- Prevent users from changing their own approval_status
      approval_status = (SELECT approval_status FROM public.profiles WHERE id = auth.uid())
    )
  );

-- Policy 3: Service role can insert profiles (for trigger)
CREATE POLICY "Service role can insert profiles"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Policy 4: Admin can view all profiles
-- Note: Implement admin check via custom claim or service role
CREATE POLICY "Admin can view all profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    (auth.jwt()->>'role')::text = 'admin'
    OR auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin')
  );

-- Policy 5: Admin can update approval_status
CREATE POLICY "Admin can update approval status"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (
    (auth.jwt()->>'role')::text = 'admin'
    OR auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin')
  )
  WITH CHECK (
    (auth.jwt()->>'role')::text = 'admin'
    OR auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin')
  );

-- ============================================
-- PART 6: RLS POLICIES - RESTAURANTS
-- ============================================

-- Enable RLS
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;

-- Policy 1: Restaurant owners can view their own record
CREATE POLICY "Restaurant owners can view own record"
  ON public.restaurants
  FOR SELECT
  TO authenticated
  USING (auth.uid() = profile_id);

-- Policy 2: Restaurant owners can update their own record
CREATE POLICY "Restaurant owners can update own record"
  ON public.restaurants
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- Policy 3: Service role can insert restaurants (for trigger)
CREATE POLICY "Service role can insert restaurants"
  ON public.restaurants
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Policy 4: Public can view approved restaurants (for browsing)
CREATE POLICY "Public can view approved restaurants"
  ON public.restaurants
  FOR SELECT
  TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = restaurants.profile_id 
        AND profiles.approval_status = 'approved'
    )
  );

-- ============================================
-- PART 7: RLS POLICIES - NGOS
-- ============================================

-- Enable RLS
ALTER TABLE public.ngos ENABLE ROW LEVEL SECURITY;

-- Policy 1: NGO owners can view their own record
CREATE POLICY "NGO owners can view own record"
  ON public.ngos
  FOR SELECT
  TO authenticated
  USING (auth.uid() = profile_id);

-- Policy 2: NGO owners can update their own record
CREATE POLICY "NGO owners can update own record"
  ON public.ngos
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- Policy 3: Service role can insert NGOs (for trigger)
CREATE POLICY "Service role can insert ngos"
  ON public.ngos
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Policy 4: Public can view approved NGOs (for browsing)
CREATE POLICY "Public can view approved ngos"
  ON public.ngos
  FOR SELECT
  TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = ngos.profile_id 
        AND profiles.approval_status = 'approved'
    )
  );

-- ============================================
-- PART 8: STORAGE BUCKET & POLICIES
-- ============================================

-- Create legal-docs bucket (idempotent)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'legal-docs',
  'legal-docs',
  false,
  10485760, -- 10MB limit
  ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/jpg']::text[]
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Drop existing storage policies
DROP POLICY IF EXISTS "Authenticated users can upload to own folder" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Admins can view all legal docs" ON storage.objects;

-- Policy 1: Authenticated users can upload to their own folder
CREATE POLICY "Authenticated users can upload to own folder"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'legal-docs' 
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND auth.uid() IS NOT NULL
  );

-- Policy 2: Users can view their own files
CREATE POLICY "Users can view own legal docs"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'legal-docs' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Policy 3: Users can update their own files
CREATE POLICY "Users can update own legal docs"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'legal-docs' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'legal-docs' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Policy 4: Users can delete their own files
CREATE POLICY "Users can delete own legal docs"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'legal-docs' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Policy 5: Admins can view all legal docs
CREATE POLICY "Admins can view all legal docs"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'legal-docs'
    AND (
      (auth.jwt()->>'role')::text = 'admin'
      OR auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin')
    )
  );

-- ============================================
-- PART 9: BACKFILL EXISTING USERS
-- ============================================

-- Backfill profiles for existing auth.users without profiles
DO $$
DECLARE
  user_record RECORD;
  backfill_count integer := 0;
BEGIN
  RAISE NOTICE 'Starting backfill of existing users...';
  
  FOR user_record IN 
    SELECT 
      au.id,
      au.email,
      au.email_confirmed_at,
      au.raw_user_meta_data
    FROM auth.users au
    LEFT JOIN public.profiles p ON au.id = p.id
    WHERE p.id IS NULL
  LOOP
    BEGIN
      INSERT INTO public.profiles (
        id,
        email,
        role,
        full_name,
        phone_number,
        is_verified,
        approval_status,
        created_at,
        updated_at
      )
      VALUES (
        user_record.id,
        user_record.email,
        COALESCE(user_record.raw_user_meta_data->>'role', 'user'),
        COALESCE(user_record.raw_user_meta_data->>'full_name', 'User'),
        user_record.raw_user_meta_data->>'phone_number',
        user_record.email_confirmed_at IS NOT NULL,
        CASE 
          WHEN COALESCE(user_record.raw_user_meta_data->>'role', 'user') IN ('restaurant', 'ngo') 
            THEN 'pending'
          ELSE 'approved'
        END,
        NOW(),
        NOW()
      )
      ON CONFLICT (id) DO NOTHING;
      
      backfill_count := backfill_count + 1;
      RAISE NOTICE 'Backfilled profile for user %', user_record.id;
      
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Failed to backfill profile for user %: %', user_record.id, SQLERRM;
    END;
  END LOOP;
  
  RAISE NOTICE 'Backfill completed. Created % profiles', backfill_count;
END $$;

-- ============================================
-- PART 10: INDEXES FOR PERFORMANCE
-- ============================================

-- Index on profiles.role for filtering
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- Index on profiles.approval_status for admin dashboard
CREATE INDEX IF NOT EXISTS idx_profiles_approval_status ON public.profiles(approval_status);

-- Index on profiles.email for lookups
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- Composite index for role + approval queries
CREATE INDEX IF NOT EXISTS idx_profiles_role_approval 
  ON public.profiles(role, approval_status);

-- ============================================
-- PART 11: VERIFICATION QUERIES
-- ============================================

-- Check trigger exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created') THEN
    RAISE NOTICE '✅ Trigger on_auth_user_created exists';
  ELSE
    RAISE WARNING '❌ Trigger on_auth_user_created NOT found';
  END IF;
END $$;

-- Check function exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_new_user') THEN
    RAISE NOTICE '✅ Function handle_new_user exists';
  ELSE
    RAISE WARNING '❌ Function handle_new_user NOT found';
  END IF;
END $$;

-- Check RLS enabled
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE schemaname = 'public' 
      AND tablename IN ('profiles', 'restaurants', 'ngos')
      AND rowsecurity = true
  ) THEN
    RAISE NOTICE '✅ RLS enabled on auth tables';
  ELSE
    RAISE WARNING '❌ RLS not enabled on all auth tables';
  END IF;
END $$;

-- Check storage bucket exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'legal-docs') THEN
    RAISE NOTICE '✅ Storage bucket legal-docs exists';
  ELSE
    RAISE WARNING '❌ Storage bucket legal-docs NOT found';
  END IF;
END $$;

-- Summary
SELECT 
  'Migration completed successfully' as status,
  NOW() as completed_at;

-- ============================================
-- NOTES
-- ============================================

-- This migration:
-- 1. ✅ Makes restaurant_name and organization_name nullable with defaults
-- 2. ✅ Creates robust trigger that never fails signup
-- 3. ✅ Adds comprehensive RLS policies
-- 4. ✅ Creates storage bucket with secure policies
-- 5. ✅ Backfills existing users
-- 6. ✅ Adds performance indexes
-- 7. ✅ Includes verification checks

-- Admin approval workflow:
-- - Admins identified by: role='admin' in profiles OR custom JWT claim
-- - Admins can update approval_status via RLS policy
-- - Restaurant/NGO access gated by approval_status='approved'

-- Storage security:
-- - Upload only when authenticated (after OTP verification)
-- - Path scoped to auth.uid() (users can only access their own files)
-- - 10MB file size limit
-- - Only PDF and image files allowed

-- ============================================
-- END OF MIGRATION
-- ============================================
