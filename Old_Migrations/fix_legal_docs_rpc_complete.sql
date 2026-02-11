-- ============================================
-- COMPLETE FIX: Legal Documents RPC Functions
-- ============================================
-- Purpose: Create RPC functions to atomically append
-- legal document URLs to restaurants and ngos tables
-- ============================================

-- ============================================
-- PART 1: DROP EXISTING FUNCTIONS
-- ============================================

DROP FUNCTION IF EXISTS public.append_restaurant_legal_doc(text);
DROP FUNCTION IF EXISTS public.append_ngo_legal_doc(text);

-- ============================================
-- PART 2: CREATE RESTAURANT FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION public.append_restaurant_legal_doc(p_url text)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_profile_id uuid;
  v_updated_urls text[];
  v_current_urls text[];
BEGIN
  -- Get current user ID
  v_profile_id := auth.uid();
  
  -- Validate user is authenticated
  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Validate URL is not empty
  IF p_url IS NULL OR TRIM(p_url) = '' THEN
    RAISE EXCEPTION 'URL cannot be empty';
  END IF;
  
  -- Get current URLs first
  SELECT legal_docs_urls INTO v_current_urls
  FROM public.restaurants
  WHERE profile_id = v_profile_id;
  
  -- Check if record exists
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Restaurant record not found for user %', v_profile_id;
  END IF;
  
  -- Handle NULL or empty array
  IF v_current_urls IS NULL THEN
    v_current_urls := ARRAY[]::text[];
  END IF;
  
  -- Append the new URL
  v_updated_urls := array_append(v_current_urls, p_url);
  
  -- Update the record
  UPDATE public.restaurants
  SET legal_docs_urls = v_updated_urls
  WHERE profile_id = v_profile_id;
  
  -- Return success with updated URLs
  RETURN jsonb_build_object(
    'success', true,
    'profile_id', v_profile_id,
    'url', p_url,
    'legal_docs_urls', to_jsonb(v_updated_urls)
  );
END;
$$;

-- ============================================
-- PART 3: CREATE NGO FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION public.append_ngo_legal_doc(p_url text)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_profile_id uuid;
  v_updated_urls text[];
  v_current_urls text[];
BEGIN
  -- Get current user ID
  v_profile_id := auth.uid();
  
  -- Validate user is authenticated
  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Validate URL is not empty
  IF p_url IS NULL OR TRIM(p_url) = '' THEN
    RAISE EXCEPTION 'URL cannot be empty';
  END IF;
  
  -- Get current URLs first
  SELECT legal_docs_urls INTO v_current_urls
  FROM public.ngos
  WHERE profile_id = v_profile_id;
  
  -- Check if record exists
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NGO record not found for user %', v_profile_id;
  END IF;
  
  -- Handle NULL or empty array
  IF v_current_urls IS NULL THEN
    v_current_urls := ARRAY[]::text[];
  END IF;
  
  -- Append the new URL
  v_updated_urls := array_append(v_current_urls, p_url);
  
  -- Update the record
  UPDATE public.ngos
  SET legal_docs_urls = v_updated_urls
  WHERE profile_id = v_profile_id;
  
  -- Return success with updated URLs
  RETURN jsonb_build_object(
    'success', true,
    'profile_id', v_profile_id,
    'url', p_url,
    'legal_docs_urls', to_jsonb(v_updated_urls)
  );
END;
$$;

-- ============================================
-- PART 4: GRANT PERMISSIONS
-- ============================================

GRANT EXECUTE ON FUNCTION public.append_restaurant_legal_doc(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.append_ngo_legal_doc(text) TO authenticated;

-- ============================================
-- PART 5: ADD COMMENTS
-- ============================================

COMMENT ON FUNCTION public.append_restaurant_legal_doc(text) IS 
  'Atomically appends a legal document URL to restaurants.legal_docs_urls array';

COMMENT ON FUNCTION public.append_ngo_legal_doc(text) IS 
  'Atomically appends a legal document URL to ngos.legal_docs_urls array';

-- ============================================
-- PART 6: VERIFICATION
-- ============================================

DO $$
BEGIN
  RAISE NOTICE 'RPC Functions created successfully!';
  RAISE NOTICE 'Functions:';
  RAISE NOTICE '  - append_restaurant_legal_doc(p_url text)';
  RAISE NOTICE '  - append_ngo_legal_doc(p_url text)';
  RAISE NOTICE '';
  RAISE NOTICE 'Usage from Flutter:';
  RAISE NOTICE '  await client.rpc(''append_restaurant_legal_doc'', params: {''p_url'': url});';
  RAISE NOTICE '  await client.rpc(''append_ngo_legal_doc'', params: {''p_url'': url});';
END $$;

-- ============================================
-- VERIFICATION QUERIES (run separately)
-- ============================================

-- Check functions exist:
-- SELECT proname FROM pg_proc 
-- WHERE proname IN ('append_restaurant_legal_doc', 'append_ngo_legal_doc');

-- Test with authenticated user (will fail without auth):
-- SELECT append_restaurant_legal_doc('https://example.com/doc.pdf');
