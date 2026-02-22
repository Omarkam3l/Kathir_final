-- ============================================
-- FINAL DATABASE SCHEMA
-- ============================================
-- Complete schema for authentication system
-- Includes: Tables, Triggers, RPC Functions, RLS Policies, Storage
-- Date: 2026-01-29
-- ============================================

-- ============================================
-- PART 1: TABLES
-- ============================================

-- Profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('user', 'restaurant', 'ngo', 'admin')),
  email text UNIQUE NOT NULL,
  full_name text,
  phone_number text,
  avatar_url text,
  is_verified boolean DEFAULT false,
  approval_status text DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Restaurants table
CREATE TABLE IF NOT EXISTS public.restaurants (
  profile_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  restaurant_name text DEFAULT 'Unnamed Restaurant',
  address_text text,
  legal_docs_urls text[] DEFAULT ARRAY[]::text[],
  rating numeric DEFAULT 0,
  min_order_price numeric DEFAULT 0,
  rush_hour_active boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- NGOs table
CREATE TABLE IF NOT EXISTS public.ngos (
  profile_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  organization_name text DEFAULT 'Unnamed Organization',
  address_text text,
  legal_docs_urls text[] DEFAULT ARRAY[]::text[],
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================
-- PART 2: INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_approval_status ON public.profiles(approval_status);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role_approval ON public.profiles(role, approval_status);

-- ============================================
-- PART 3: TRIGGER FUNCTION
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
    
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'CRITICAL: Failed to create profile for user %: % (SQLSTATE: %)', 
      NEW.id, SQLERRM, SQLSTATE;
    RAISE;
  END;

  -- NON-CRITICAL: Create restaurant record
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
      
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Failed to create restaurant record for user %: % (SQLSTATE: %)', 
        NEW.id, SQLERRM, SQLSTATE;
    END;
  END IF;

  -- NON-CRITICAL: Create NGO record
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
      
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Failed to create NGO record for user %: % (SQLSTATE: %)', 
        NEW.id, SQLERRM, SQLSTATE;
    END;
  END IF;

  RETURN NEW;
END;
$$;

-- ============================================
-- PART 4: TRIGGER
-- ============================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW 
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- PART 5: RPC FUNCTIONS
-- ============================================

-- Append URL to restaurant legal_docs_urls
CREATE OR REPLACE FUNCTION public.append_restaurant_legal_doc(p_url text)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_profile_id uuid;
  v_updated_urls text[];
BEGIN
  v_profile_id := auth.uid();
  
  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  IF p_url IS NULL OR TRIM(p_url) = '' THEN
    RAISE EXCEPTION 'URL cannot be empty';
  END IF;
  
  UPDATE public.restaurants
  SET 
    legal_docs_urls = array_append(
      COALESCE(legal_docs_urls, ARRAY[]::text[]),
      p_url
    ),
    updated_at = NOW()
  WHERE profile_id = v_profile_id
  RETURNING legal_docs_urls INTO v_updated_urls;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Restaurant record not found for user %', v_profile_id;
  END IF;
  
  RETURN jsonb_build_object(
    'success', true,
    'profile_id', v_profile_id,
    'url', p_url,
    'legal_docs_urls', v_updated_urls
  );
END;
$$;

-- Append URL to NGO legal_docs_urls
CREATE OR REPLACE FUNCTION public.append_ngo_legal_doc(p_url text)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_profile_id uuid;
  v_updated_urls text[];
BEGIN
  v_profile_id := auth.uid();
  
  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  IF p_url IS NULL OR TRIM(p_url) = '' THEN
    RAISE EXCEPTION 'URL cannot be empty';
  END IF;
  
  UPDATE public.ngos
  SET 
    legal_docs_urls = array_append(
      COALESCE(legal_docs_urls, ARRAY[]::text[]),
      p_url
    ),
    updated_at = NOW()
  WHERE profile_id = v_profile_id
  RETURNING legal_docs_urls INTO v_updated_urls;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NGO record not found for user %', v_profile_id;
  END IF;
  
  RETURN jsonb_build_object(
    'success', true,
    'profile_id', v_profile_id,
    'url', p_url,
    'legal_docs_urls', v_updated_urls
  );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.append_restaurant_legal_doc(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.append_ngo_legal_doc(text) TO authenticated;

-- ============================================
-- PART 6: RLS POLICIES - PROFILES
-- ============================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Service role can insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admin can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admin can update approval status" ON public.profiles;

CREATE POLICY "Users can view own profile"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id 
    AND approval_status = (SELECT approval_status FROM public.profiles WHERE id = auth.uid())
  );

CREATE POLICY "Service role can insert profiles"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Admin can view all profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    (auth.jwt()->>'role')::text = 'admin'
    OR auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin')
  );

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
-- PART 7: RLS POLICIES - RESTAURANTS
-- ============================================

ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Restaurant owners can view own record" ON public.restaurants;
DROP POLICY IF EXISTS "Restaurant owners can update own record" ON public.restaurants;
DROP POLICY IF EXISTS "Service role can insert restaurants" ON public.restaurants;
DROP POLICY IF EXISTS "Public can view approved restaurants" ON public.restaurants;

CREATE POLICY "Restaurant owners can view own record"
  ON public.restaurants
  FOR SELECT
  TO authenticated
  USING (auth.uid() = profile_id);

CREATE POLICY "Restaurant owners can update own record"
  ON public.restaurants
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Service role can insert restaurants"
  ON public.restaurants
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

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
-- PART 8: RLS POLICIES - NGOS
-- ============================================

ALTER TABLE public.ngos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "NGO owners can view own record" ON public.ngos;
DROP POLICY IF EXISTS "NGO owners can update own record" ON public.ngos;
DROP POLICY IF EXISTS "Service role can insert ngos" ON public.ngos;
DROP POLICY IF EXISTS "Public can view approved ngos" ON public.ngos;

CREATE POLICY "NGO owners can view own record"
  ON public.ngos
  FOR SELECT
  TO authenticated
  USING (auth.uid() = profile_id);

CREATE POLICY "NGO owners can update own record"
  ON public.ngos
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Service role can insert ngos"
  ON public.ngos
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

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
-- PART 9: STORAGE BUCKET
-- ============================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'legal-docs',
  'legal-docs',
  false,
  10485760,
  ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/jpg']::text[]
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ============================================
-- PART 10: STORAGE POLICIES
-- ============================================

DROP POLICY IF EXISTS "Authenticated users can upload to own folder" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Admins can view all legal docs" ON storage.objects;

CREATE POLICY "Authenticated users can upload to own folder"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'legal-docs' 
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND auth.uid() IS NOT NULL
  );

CREATE POLICY "Users can view own legal docs"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'legal-docs' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

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

CREATE POLICY "Users can delete own legal docs"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'legal-docs' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

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
-- END OF SCHEMA
-- ============================================
