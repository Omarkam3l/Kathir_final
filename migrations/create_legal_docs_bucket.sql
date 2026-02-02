-- ============================================
-- CREATE: legal_docs_bucket Storage Bucket
-- ============================================
-- Purpose: Create a new storage bucket for legal documents
-- with proper RLS policies for NGOs and Restaurants
-- ============================================

-- ============================================
-- PART 1: CREATE BUCKET
-- ============================================

-- Create the bucket (run this in Supabase SQL Editor)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'legal_docs_bucket',
  'legal_docs_bucket',
  true,  -- Public bucket so URLs can be accessed
  10485760,  -- 10MB file size limit
  ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/gif', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 10485760;

-- ============================================
-- PART 2: DROP EXISTING POLICIES (if any)
-- ============================================

DROP POLICY IF EXISTS "Allow authenticated uploads to legal_docs_bucket" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to read own legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read of legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to update own legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete own legal docs" ON storage.objects;

-- ============================================
-- PART 3: CREATE STORAGE POLICIES
-- ============================================

-- Policy 1: Allow authenticated users to upload files to their own folder
CREATE POLICY "Allow authenticated uploads to legal_docs_bucket"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'legal_docs_bucket'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 2: Allow authenticated users to read their own files
CREATE POLICY "Allow users to read own legal docs"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'legal_docs_bucket'
  AND (storage.foldername(name))[1] = auth.uid()::text
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
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 5: Allow users to delete their own files
CREATE POLICY "Allow users to delete own legal docs"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'legal_docs_bucket'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================
-- PART 4: VERIFICATION
-- ============================================

DO $$
BEGIN
  RAISE NOTICE 'legal_docs_bucket created successfully!';
  RAISE NOTICE 'Policies created:';
  RAISE NOTICE '  - Allow authenticated uploads to legal_docs_bucket';
  RAISE NOTICE '  - Allow users to read own legal docs';
  RAISE NOTICE '  - Allow public read of legal docs';
  RAISE NOTICE '  - Allow users to update own legal docs';
  RAISE NOTICE '  - Allow users to delete own legal docs';
END $$;

-- ============================================
-- VERIFICATION QUERIES (run separately to check)
-- ============================================

-- Check bucket exists:
-- SELECT * FROM storage.buckets WHERE id = 'legal_docs_bucket';

-- Check policies:
-- SELECT policyname, cmd FROM pg_policies 
-- WHERE tablename = 'objects' AND schemaname = 'storage'
-- AND policyname LIKE '%legal%';
