-- ============================================
-- MIGRATION 003: Fix Storage RLS Policies
-- ============================================
-- Purpose: Allow authenticated users to upload to their own folder
-- Fixes: 403 "new row violates row-level security policy" on upload
-- Date: 2026-01-29
-- ============================================

-- ============================================
-- STORAGE BUCKET: legal-docs
-- ============================================

-- Create bucket if not exists (idempotent)
INSERT INTO storage.buckets (id, name, public)
VALUES ('legal-docs', 'legal-docs', false)
ON CONFLICT (id) DO NOTHING;

-- Drop existing policies
DROP POLICY IF EXISTS "Authenticated users can upload to own folder" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own legal docs" ON storage.objects;

-- Policy 1: Allow authenticated users to INSERT (upload) to their own folder
CREATE POLICY "Authenticated users can upload to own folder"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'legal-docs' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 2: Allow users to SELECT (view) their own files
CREATE POLICY "Users can view own legal docs"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'legal-docs' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 3: Allow users to UPDATE their own files
CREATE POLICY "Users can update own legal docs"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'legal-docs' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 4: Allow users to DELETE their own files
CREATE POLICY "Users can delete own legal docs"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'legal-docs' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================
-- VERIFICATION
-- ============================================

-- Check bucket exists
-- SELECT * FROM storage.buckets WHERE id = 'legal-docs';

-- Check policies
-- SELECT * FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects';

-- Test upload (should work for authenticated users)
-- Upload to: legal-docs/{user_id}/filename.pdf

-- ============================================
-- NOTES
-- ============================================

-- This fix ensures:
-- 1. Only authenticated users can upload
-- 2. Users can only upload to their own folder (/{user_id}/*)
-- 3. Users can only access their own files
-- 4. No global security weakening
-- 5. Path-scoped security (best practice)

-- IMPORTANT: Upload must happen AFTER OTP verification
-- when user has a valid session (authenticated)

