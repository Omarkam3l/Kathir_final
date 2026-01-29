-- ============================================
-- MIGRATION 001: Fix Profile Creation & Email Verification
-- ============================================
-- Purpose: Auto-create profiles, restaurants, and NGO records when users sign up
-- Fixes: Missing trigger causing OTP emails to fail for restaurant/NGO signups
-- Date: 2026-01-29
-- ============================================

-- ============================================
-- STEP 1: Create trigger function
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
BEGIN
  -- Extract metadata from auth.users
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'user');
  user_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', '');
  user_phone := NEW.raw_user_meta_data->>'phone_number';
  org_name := NEW.raw_user_meta_data->>'organization_name';

  -- Create profile record
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

  -- Create restaurant record if role is restaurant
  IF user_role = 'restaurant' THEN
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
      COALESCE(org_name, user_full_name, 'Unnamed Restaurant'),
      ARRAY[]::text[],
      0,
      0,
      false
    )
    ON CONFLICT (profile_id) DO NOTHING;
  END IF;

  -- Create NGO record if role is ngo
  IF user_role = 'ngo' THEN
    INSERT INTO public.ngos (
      profile_id,
      organization_name,
      legal_docs_urls
    )
    VALUES (
      NEW.id,
      COALESCE(org_name, user_full_name, 'Unnamed Organization'),
      ARRAY[]::text[]
    )
    ON CONFLICT (profile_id) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;

-- ============================================
-- STEP 2: Create trigger
-- ============================================

-- Drop trigger if exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW 
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- STEP 3: Enable RLS and create policies
-- ============================================

-- Enable RLS on profiles table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Service role can insert profiles" ON public.profiles;

-- Allow users to read their own profile
CREATE POLICY "Users can view own profile"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id);

-- Allow service role to insert profiles (for trigger)
CREATE POLICY "Service role can insert profiles"
  ON public.profiles
  FOR INSERT
  WITH CHECK (true);

-- Enable RLS on restaurants table
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Restaurant owners can view own record" ON public.restaurants;
DROP POLICY IF EXISTS "Restaurant owners can update own record" ON public.restaurants;
DROP POLICY IF EXISTS "Service role can insert restaurants" ON public.restaurants;
DROP POLICY IF EXISTS "Public can view restaurants" ON public.restaurants;

-- Allow restaurant owners to view their own record
CREATE POLICY "Restaurant owners can view own record"
  ON public.restaurants
  FOR SELECT
  USING (auth.uid() = profile_id);

-- Allow restaurant owners to update their own record
CREATE POLICY "Restaurant owners can update own record"
  ON public.restaurants
  FOR UPDATE
  USING (auth.uid() = profile_id);

-- Allow service role to insert restaurants (for trigger)
CREATE POLICY "Service role can insert restaurants"
  ON public.restaurants
  FOR INSERT
  WITH CHECK (true);

-- Allow public to view approved restaurants (for browsing)
CREATE POLICY "Public can view restaurants"
  ON public.restaurants
  FOR SELECT
  USING (true);

-- Enable RLS on ngos table
ALTER TABLE public.ngos ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "NGO owners can view own record" ON public.ngos;
DROP POLICY IF EXISTS "NGO owners can update own record" ON public.ngos;
DROP POLICY IF EXISTS "Service role can insert ngos" ON public.ngos;
DROP POLICY IF EXISTS "Public can view ngos" ON public.ngos;

-- Allow NGO owners to view their own record
CREATE POLICY "NGO owners can view own record"
  ON public.ngos
  FOR SELECT
  USING (auth.uid() = profile_id);

-- Allow NGO owners to update their own record
CREATE POLICY "NGO owners can update own record"
  ON public.ngos
  FOR UPDATE
  USING (auth.uid() = profile_id);

-- Allow service role to insert NGOs (for trigger)
CREATE POLICY "Service role can insert ngos"
  ON public.ngos
  FOR INSERT
  WITH CHECK (true);

-- Allow public to view approved NGOs (for browsing)
CREATE POLICY "Public can view ngos"
  ON public.ngos
  FOR SELECT
  USING (true);

-- ============================================
-- STEP 4: Backfill existing users (if any)
-- ============================================

-- This will create profiles for any existing auth.users that don't have profiles
-- Run this carefully in production!

DO $$
DECLARE
  user_record RECORD;
BEGIN
  FOR user_record IN 
    SELECT 
      au.id,
      au.email,
      au.raw_user_meta_data
    FROM auth.users au
    LEFT JOIN public.profiles p ON au.id = p.id
    WHERE p.id IS NULL
  LOOP
    -- Call the trigger function manually for existing users
    INSERT INTO public.profiles (
      id,
      email,
      role,
      full_name,
      phone_number,
      is_verified,
      approval_status
    )
    VALUES (
      user_record.id,
      user_record.email,
      COALESCE(user_record.raw_user_meta_data->>'role', 'user'),
      COALESCE(user_record.raw_user_meta_data->>'full_name', ''),
      user_record.raw_user_meta_data->>'phone_number',
      true, -- Assume existing users are verified
      'approved'
    )
    ON CONFLICT (id) DO NOTHING;
  END LOOP;
END $$;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check if trigger exists
-- SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';

-- Check if function exists
-- SELECT proname FROM pg_proc WHERE proname = 'handle_new_user';

-- Check RLS is enabled
-- SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('profiles', 'restaurants', 'ngos');

-- Check policies
-- SELECT tablename, policyname FROM pg_policies WHERE schemaname = 'public';

-- ============================================
-- ROLLBACK (if needed)
-- ============================================

-- DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
-- DROP FUNCTION IF EXISTS public.handle_new_user();
-- DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
-- DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
-- DROP POLICY IF EXISTS "Service role can insert profiles" ON public.profiles;
-- ... (drop all policies)
