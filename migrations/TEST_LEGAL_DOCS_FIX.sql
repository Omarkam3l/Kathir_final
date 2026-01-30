-- ============================================
-- TEST SCRIPT: Legal Documents URL Append
-- ============================================
-- Purpose: Verify RPC functions work correctly
-- Run this AFTER deploying database-fix-legal-docs-append.sql
-- ============================================

-- ============================================
-- PART 1: VERIFY FUNCTIONS EXIST
-- ============================================

DO $
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'append_restaurant_legal_doc') THEN
    RAISE NOTICE '✅ Function append_restaurant_legal_doc exists';
  ELSE
    RAISE WARNING '❌ Function append_restaurant_legal_doc NOT FOUND';
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'append_ngo_legal_doc') THEN
    RAISE NOTICE '✅ Function append_ngo_legal_doc exists';
  ELSE
    RAISE WARNING '❌ Function append_ngo_legal_doc NOT FOUND';
  END IF;
END $;

-- ============================================
-- PART 2: CHECK CURRENT STATE
-- ============================================

-- Count restaurants with empty legal_docs_urls
SELECT 
  COUNT(*) as empty_count,
  'restaurants' as table_name
FROM restaurants 
WHERE legal_docs_urls = ARRAY[]::text[] 
   OR legal_docs_urls IS NULL;

-- Count NGOs with empty legal_docs_urls
SELECT 
  COUNT(*) as empty_count,
  'ngos' as table_name
FROM ngos 
WHERE legal_docs_urls = ARRAY[]::text[] 
   OR legal_docs_urls IS NULL;

-- Show restaurants with URLs (should be none before fix)
SELECT 
  r.profile_id,
  p.email,
  r.restaurant_name,
  r.legal_docs_urls,
  array_length(r.legal_docs_urls, 1) as url_count
FROM restaurants r
JOIN profiles p ON p.id = r.profile_id
WHERE r.legal_docs_urls IS NOT NULL 
  AND array_length(r.legal_docs_urls, 1) > 0
LIMIT 10;

-- Show NGOs with URLs (should be none before fix)
SELECT 
  n.profile_id,
  p.email,
  n.organization_name,
  n.legal_docs_urls,
  array_length(n.legal_docs_urls, 1) as url_count
FROM ngos n
JOIN profiles p ON p.id = n.profile_id
WHERE n.legal_docs_urls IS NOT NULL 
  AND array_length(n.legal_docs_urls, 1) > 0
LIMIT 10;

-- ============================================
-- PART 3: SIMULATE APPEND (Test Logic)
-- ============================================

-- This tests the array_append logic without actually calling the function
-- (since SQL Editor doesn't have auth.uid())

DO $
DECLARE
  test_array text[];
  test_url text := 'https://example.com/test.pdf';
BEGIN
  -- Test 1: Append to NULL array
  test_array := NULL;
  test_array := array_append(COALESCE(test_array, ARRAY[]::text[]), test_url);
  
  IF array_length(test_array, 1) = 1 AND test_array[1] = test_url THEN
    RAISE NOTICE '✅ Test 1 PASSED: Append to NULL array';
  ELSE
    RAISE WARNING '❌ Test 1 FAILED: Expected [%], got %', test_url, test_array;
  END IF;
  
  -- Test 2: Append to empty array
  test_array := ARRAY[]::text[];
  test_array := array_append(COALESCE(test_array, ARRAY[]::text[]), test_url);
  
  IF array_length(test_array, 1) = 1 AND test_array[1] = test_url THEN
    RAISE NOTICE '✅ Test 2 PASSED: Append to empty array';
  ELSE
    RAISE WARNING '❌ Test 2 FAILED: Expected [%], got %', test_url, test_array;
  END IF;
  
  -- Test 3: Append to existing array
  test_array := ARRAY['https://existing.pdf']::text[];
  test_array := array_append(COALESCE(test_array, ARRAY[]::text[]), test_url);
  
  IF array_length(test_array, 1) = 2 
     AND test_array[1] = 'https://existing.pdf' 
     AND test_array[2] = test_url THEN
    RAISE NOTICE '✅ Test 3 PASSED: Append to existing array';
  ELSE
    RAISE WARNING '❌ Test 3 FAILED: Expected 2 elements, got %', test_array;
  END IF;
  
  -- Test 4: Multiple appends
  test_array := ARRAY[]::text[];
  test_array := array_append(COALESCE(test_array, ARRAY[]::text[]), 'url1.pdf');
  test_array := array_append(COALESCE(test_array, ARRAY[]::text[]), 'url2.pdf');
  test_array := array_append(COALESCE(test_array, ARRAY[]::text[]), 'url3.pdf');
  
  IF array_length(test_array, 1) = 3 THEN
    RAISE NOTICE '✅ Test 4 PASSED: Multiple appends';
  ELSE
    RAISE WARNING '❌ Test 4 FAILED: Expected 3 elements, got %', array_length(test_array, 1);
  END IF;
END $;

-- ============================================
-- PART 4: CHECK PERMISSIONS
-- ============================================

-- Verify functions are executable by authenticated users
SELECT 
  proname as function_name,
  prosecdef as is_security_definer,
  proacl as permissions
FROM pg_proc 
WHERE proname IN ('append_restaurant_legal_doc', 'append_ngo_legal_doc');

-- ============================================
-- PART 5: MANUAL TEST INSTRUCTIONS
-- ============================================

DO $
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'MANUAL TEST INSTRUCTIONS';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE '1. Sign up as restaurant/NGO in Flutter app';
  RAISE NOTICE '2. Verify OTP';
  RAISE NOTICE '3. Upload legal document';
  RAISE NOTICE '4. Check logs for:';
  RAISE NOTICE '   - legalDoc.saved with updatedUrls';
  RAISE NOTICE '   - legalDoc.verified with urlCount=1';
  RAISE NOTICE '';
  RAISE NOTICE '5. Run this query to verify:';
  RAISE NOTICE '   SELECT legal_docs_urls FROM restaurants WHERE profile_id = ''YOUR_USER_ID'';';
  RAISE NOTICE '';
  RAISE NOTICE '6. Expected result: [''https://...'']';
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
END $;

-- ============================================
-- PART 6: CLEANUP TEST DATA (Optional)
-- ============================================

-- Uncomment to reset test data
-- WARNING: This will clear all legal_docs_urls!

-- UPDATE restaurants SET legal_docs_urls = ARRAY[]::text[];
-- UPDATE ngos SET legal_docs_urls = ARRAY[]::text[];

-- ============================================
-- END OF TEST SCRIPT
-- ============================================
