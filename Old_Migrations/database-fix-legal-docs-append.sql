-- ============================================
-- FIX: Legal Documents URL Append Functions
-- ============================================
-- Purpose: Atomically append URLs to legal_docs_urls arrays
-- Issue: Current code overwrites array instead of appending
-- Solution: RPC functions with array_append
-- ============================================

-- ============================================
-- PART 1: DROP EXISTING FUNCTIONS (Idempotent)
-- ============================================

DROP FUNCTION IF EXISTS public.append_restaurant_legal_doc(text);
DROP FUNCTION IF EXISTS public.append_ngo_legal_doc(text);

-- ============================================
-- PART 2: CREATE APPEND FUNCTIONS
-- ============================================

-- Function: Append URL to restaurant legal_docs_urls
CREATE OR REPLACE FUNCTION public.append_restaurant_legal_doc(p_url text)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $
DECLARE
  v_profile_id uuid;
  v_updated_urls text[];
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
  
  -- Check if update succeeded
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Restaurant record not found for user %', v_profile_id;
  END IF;
  
  -- Return success with updated URLs
  RETURN jsonb_build_object(
    'success', true,
    'profile_id', v_profile_id,
    'url', p_url,
    'legal_docs_urls', v_updated_urls
  );
END;
$;

-- Function: Append URL to NGO legal_docs_urls
CREATE OR REPLACE FUNCTION public.append_ngo_legal_doc(p_url text)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $
DECLARE
  v_profile_id uuid;
  v_updated_urls text[];
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
  
  -- Check if update succeeded
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NGO record not found for user %', v_profile_id;
  END IF;
  
  -- Return success with updated URLs
  RETURN jsonb_build_object(
    'success', true,
    'profile_id', v_profile_id,
    'url', p_url,
    'legal_docs_urls', v_updated_urls
  );
END;
$;

-- ============================================
-- PART 3: ADD COMMENTS
-- ============================================

COMMENT ON FUNCTION public.append_restaurant_legal_doc(text) IS 
  'Atomically appends a legal document URL to restaurants.legal_docs_urls array. Only the authenticated user can update their own record.';

COMMENT ON FUNCTION public.append_ngo_legal_doc(text) IS 
  'Atomically appends a legal document URL to ngos.legal_docs_urls array. Only the authenticated user can update their own record.';

-- ============================================
-- PART 4: GRANT PERMISSIONS
-- ============================================

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.append_restaurant_legal_doc(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.append_ngo_legal_doc(text) TO authenticated;

-- ============================================
-- PART 5: VERIFICATION
-- ============================================

-- Test restaurant function
DO $
DECLARE
  test_result jsonb;
BEGIN
  -- This will fail with "Not authenticated" which is expected
  -- Real test must be done from authenticated session
  RAISE NOTICE 'Functions created successfully';
  RAISE NOTICE 'Test from authenticated session: SELECT append_restaurant_legal_doc(''https://example.com/doc.pdf'')';
END $;

-- ============================================
-- NOTES
-- ============================================

-- Security:
-- - SECURITY DEFINER allows function to bypass RLS
-- - But function validates auth.uid() = profile_id
-- - Users can only update their own records
-- - Empty URLs are rejected

-- Atomicity:
-- - array_append is atomic (no race conditions)
-- - COALESCE handles NULL arrays
-- - Returns updated array for verification

-- Usage from Flutter:
-- await client.rpc('append_restaurant_legal_doc', params: {'p_url': url});
-- await client.rpc('append_ngo_legal_doc', params: {'p_url': url});

-- ============================================
-- END OF MIGRATION
-- ============================================
