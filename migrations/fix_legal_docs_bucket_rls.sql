-- ============================================
-- FIX: Legal Documents Bucket RLS Policies
-- ============================================
-- Purpose: Allow uploads to 'pending/' folder during signup
-- Issue: Current policy requires auth.uid() folder, but signup uses 'pending/'
-- Solution: Allow uploads to 'pending/' folder for authenticated users
-- ============================================

-- ============================================
-- PART 1: DROP EXISTING POLICIES
-- ============================================

DROP POLICY IF EXISTS "Allow authenticated uploads to legal_docs_bucket" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to read own legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read of legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to update own legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete own legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Allow pending uploads during signup" ON storage.objects;

-- ============================================
-- PART 2: CREATE NEW POLICIES
-- ============================================

-- Policy 1: Allow authenticated users to upload to their own folder OR pending folder
CREATE POLICY "Allow authenticated uploads to legal_docs_bucket"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'legal_docs_bucket'
  AND (
    -- Allow uploads to user's own folder
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    -- Allow uploads to pending folder during signup
    (storage.foldername(name))[1] = 'pending'
  )
);

-- Policy 2: Allow authenticated users to read their own files AND pending files
CREATE POLICY "Allow users to read own legal docs"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'legal_docs_bucket'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    (storage.foldername(name))[1] = 'pending'
  )
);

-- Policy 3: Allow public read access (since bucket is public)
CREATE POLICY "Allow public read of legal docs"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'legal_docs_bucket');

-- Policy 4: Allow users to update their own files
CREATE POLICY "Allow users to update own legal docs"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'legal_docs_bucket'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    (storage.foldername(name))[1] = 'pending'
  )
);

-- Policy 5: Allow users to delete their own files
CREATE POLICY "Allow users to delete own legal docs"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'legal_docs_bucket'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    (storage.foldername(name))[1] = 'pending'
  )
);

-- ============================================
-- PART 3: VERIFICATION
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '✅ Legal docs bucket RLS policies updated!';
  RAISE NOTICE '';
  RAISE NOTICE 'Policies now allow:';
  RAISE NOTICE '  1. Uploads to user folder: {user_id}/filename';
  RAISE NOTICE '  2. Uploads to pending folder: pending/timestamp_filename';
  RAISE NOTICE '';
  RAISE NOTICE 'This fixes the "new row violates row-level security" error during signup.';
END $$;

-- ============================================
-- VERIFICATION QUERIES (run separately)
-- ============================================

-- Check policies exist:
-- SELECT policyname, cmd, qual::text 
-- FROM pg_policies 
-- WHERE tablename = 'objects' 
-- AND schemaname = 'storage'
-- AND policyname LIKE '%legal%';

-- Test upload to pending folder (should work):
-- This will be tested from Flutter app during signup

-- ============================================
-- NOTES
-- ============================================

-- Why 'pending/' folder?
-- - During signup, user is authenticated but doesn't have profile_id yet
-- - Files are uploaded to pending/{timestamp}_{filename}
-- - After OTP verification, URL is saved to database
-- - Files can be moved to user folder later if needed

-- Security:
-- - Only authenticated users can upload (prevents spam)
-- - Public can read (for displaying documents)
-- - Users can manage their own files and pending files

-- ============================================
-- END OF MIGRATION
-- ============================================
