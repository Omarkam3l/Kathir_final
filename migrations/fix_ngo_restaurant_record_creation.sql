-- ============================================
-- Fix: NGO/Restaurant Record Creation Issue
-- Date: 2026-02-10
-- ============================================
-- Problem: When users sign up as NGO/Restaurant, the trigger creates
-- the profile but sometimes fails to create the NGO/restaurant record.
-- This causes "record not found" errors when uploading legal documents.
--
-- Solution: Update the append functions to auto-create missing records
-- ============================================

-- ============================================
-- Fix: append_ngo_legal_doc with auto-create
-- ============================================

CREATE OR REPLACE FUNCTION public.append_ngo_legal_doc(p_url text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_profile_id uuid;
  v_updated_urls text[];
  v_org_name text;
BEGIN
  -- Get current user ID
  v_profile_id := auth.uid();

  -- Validate user is authenticated
  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Validate URL is not empty
  IF p_url IS NULL OR btrim(p_url) = '' THEN
    RAISE EXCEPTION 'URL cannot be empty';
  END IF;

  -- ✅ NEW: Check if NGO record exists, create if not
  IF NOT EXISTS (SELECT 1 FROM public.ngos WHERE profile_id = v_profile_id) THEN
    RAISE NOTICE 'NGO record not found for user %, creating...', v_profile_id;
    
    -- Get organization name from profile
    SELECT full_name INTO v_org_name FROM public.profiles WHERE id = v_profile_id;
    
    -- Create NGO record
    INSERT INTO public.ngos (
      profile_id,
      organization_name,
      legal_docs_urls,
      created_at,
      updated_at
    )
    VALUES (
      v_profile_id,
      COALESCE(NULLIF(TRIM(v_org_name), ''), 'Organization ' || SUBSTRING(v_profile_id::text, 1, 8)),
      ARRAY[]::text[],
      NOW(),
      NOW()
    );
    
    RAISE NOTICE '✅ Created missing NGO record for user %', v_profile_id;
  END IF;

  -- Update NGO record (only if user owns it)
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
    RAISE EXCEPTION 'NGO record not found for user % after creation attempt', v_profile_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'profile_id', v_profile_id,
    'url', p_url,
    'legal_docs_urls', v_updated_urls
  );
END;
$$;

COMMENT ON FUNCTION public.append_ngo_legal_doc(p_url text) IS 
  'Atomically appends a legal document URL to ngos.legal_docs_urls array. Auto-creates NGO record if missing. Only the authenticated user can update their own record.';

-- ============================================
-- Fix: append_restaurant_legal_doc with auto-create
-- ============================================

CREATE OR REPLACE FUNCTION public.append_restaurant_legal_doc(p_url text)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_profile_id uuid;
  v_updated_urls text[];
  v_restaurant_name text;
BEGIN
  -- Get current user ID
  v_profile_id := auth.uid();

  -- Validate user is authenticated
  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Validate URL is not empty
  IF p_url IS NULL OR btrim(p_url) = '' THEN
    RAISE EXCEPTION 'URL cannot be empty';
  END IF;

  -- ✅ NEW: Check if restaurant record exists, create if not
  IF NOT EXISTS (SELECT 1 FROM public.restaurants WHERE profile_id = v_profile_id) THEN
    RAISE NOTICE 'Restaurant record not found for user %, creating...', v_profile_id;
    
    -- Get restaurant name from profile
    SELECT full_name INTO v_restaurant_name FROM public.profiles WHERE id = v_profile_id;
    
    -- Create restaurant record
    INSERT INTO public.restaurants (
      profile_id,
      restaurant_name,
      legal_docs_urls,
      rating,
      min_order_price,
      rush_hour_active,
      created_at,
      updated_at
    )
    VALUES (
      v_profile_id,
      COALESCE(NULLIF(TRIM(v_restaurant_name), ''), 'Restaurant ' || SUBSTRING(v_profile_id::text, 1, 8)),
      ARRAY[]::text[],
      0,
      0,
      false,
      NOW(),
      NOW()
    );
    
    RAISE NOTICE '✅ Created missing restaurant record for user %', v_profile_id;
  END IF;

  -- Update restaurant record (only if user owns it)
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
    RAISE EXCEPTION 'Restaurant record not found for user % after creation attempt', v_profile_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'profile_id', v_profile_id,
    'url', p_url,
    'legal_docs_urls', v_updated_urls
  );
END;
$$;

COMMENT ON FUNCTION public.append_restaurant_legal_doc(p_url text) IS 
  'Atomically appends a legal document URL to restaurants.legal_docs_urls array. Auto-creates restaurant record if missing. Only the authenticated user can update their own record.';

-- ============================================
-- Verification Queries
-- ============================================

-- Check for users with missing NGO records
DO $$
DECLARE
  missing_count integer;
BEGIN
  SELECT COUNT(*) INTO missing_count
  FROM profiles p
  LEFT JOIN ngos n ON p.id = n.profile_id
  WHERE p.role = 'ngo' AND n.profile_id IS NULL;
  
  IF missing_count > 0 THEN
    RAISE NOTICE '⚠️ Found % NGO profiles without NGO records', missing_count;
  ELSE
    RAISE NOTICE '✅ All NGO profiles have NGO records';
  END IF;
END $$;

-- Check for users with missing restaurant records
DO $$
DECLARE
  missing_count integer;
BEGIN
  SELECT COUNT(*) INTO missing_count
  FROM profiles p
  LEFT JOIN restaurants r ON p.id = r.profile_id
  WHERE p.role = 'restaurant' AND r.profile_id IS NULL;
  
  IF missing_count > 0 THEN
    RAISE NOTICE '⚠️ Found % restaurant profiles without restaurant records', missing_count;
  ELSE
    RAISE NOTICE '✅ All restaurant profiles have restaurant records';
  END IF;
END $$;

-- ============================================
-- Optional: Create missing records for existing users
-- ============================================
-- Uncomment to auto-create missing records for existing users

/*
-- Create missing NGO records
INSERT INTO public.ngos (profile_id, organization_name, legal_docs_urls, created_at, updated_at)
SELECT 
  p.id,
  COALESCE(NULLIF(TRIM(p.full_name), ''), 'Organization ' || SUBSTRING(p.id::text, 1, 8)),
  ARRAY[]::text[],
  NOW(),
  NOW()
FROM profiles p
LEFT JOIN ngos n ON p.id = n.profile_id
WHERE p.role = 'ngo' AND n.profile_id IS NULL;

-- Create missing restaurant records
INSERT INTO public.restaurants (profile_id, restaurant_name, legal_docs_urls, rating, min_order_price, rush_hour_active, created_at, updated_at)
SELECT 
  p.id,
  COALESCE(NULLIF(TRIM(p.full_name), ''), 'Restaurant ' || SUBSTRING(p.id::text, 1, 8)),
  ARRAY[]::text[],
  0,
  0,
  false,
  NOW(),
  NOW()
FROM profiles p
LEFT JOIN restaurants r ON p.id = r.profile_id
WHERE p.role = 'restaurant' AND r.profile_id IS NULL;
*/
