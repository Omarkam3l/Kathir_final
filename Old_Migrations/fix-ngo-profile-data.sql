-- Fix NGO Profile Data Issues
-- Run this in Supabase SQL Editor if you're having issues with NGO profile

-- =====================================================
-- 1. CHECK CURRENT STATE
-- =====================================================

-- Check if profile-images bucket exists
SELECT 
  id, 
  name, 
  public, 
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id = 'profile-images';

-- Check NGO records
SELECT 
  profile_id,
  organization_name,
  address_text,
  created_at,
  updated_at
FROM ngos
ORDER BY created_at DESC
LIMIT 10;

-- Check profiles with images
SELECT 
  id,
  full_name,
  role,
  avatar_url
FROM profiles
WHERE role = 'ngo'
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================
-- 2. CREATE MISSING NGO RECORDS
-- =====================================================

-- This will create NGO records for any NGO users that don't have one
INSERT INTO ngos (profile_id, organization_name, address_text)
SELECT 
  p.id,
  COALESCE(p.full_name, 'Unnamed Organization'),
  'Cairo, Egypt'
FROM profiles p
WHERE p.role = 'ngo'
  AND NOT EXISTS (
    SELECT 1 FROM ngos n WHERE n.profile_id = p.id
  )
ON CONFLICT (profile_id) DO NOTHING;

-- =====================================================
-- 3. UPDATE EXISTING NGO RECORDS WITH PROFILE NAMES
-- =====================================================

-- Update NGO organization names from profile full_name if they're still "Unnamed Organization"
UPDATE ngos n
SET organization_name = p.full_name
FROM profiles p
WHERE n.profile_id = p.id
  AND p.full_name IS NOT NULL
  AND p.full_name != ''
  AND (n.organization_name = 'Unnamed Organization' OR n.organization_name IS NULL);

-- =====================================================
-- 4. VERIFY STORAGE BUCKET SETUP
-- =====================================================

-- Create profile-images bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-images',
  'profile-images',
  true,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE
SET public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif'];

-- =====================================================
-- 5. CREATE/UPDATE STORAGE POLICIES
-- =====================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public can view profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile images" ON storage.objects;

-- Policy 1: Public read access
CREATE POLICY "Public can view profile images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-images');

-- Policy 2: Authenticated users can upload to their own folder
CREATE POLICY "Users can upload their own profile images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 3: Authenticated users can update their own images
CREATE POLICY "Users can update their own profile images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'profile-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 4: Authenticated users can delete their own images
CREATE POLICY "Users can delete their own profile images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- =====================================================
-- 6. VERIFY FINAL STATE
-- =====================================================

-- Check NGO records again
SELECT 
  profile_id,
  organization_name,
  address_text,
  created_at,
  updated_at
FROM ngos
ORDER BY created_at DESC
LIMIT 10;

-- Check storage policies
SELECT 
  policyname,
  cmd,
  qual
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
  AND policyname LIKE '%profile%';

-- Count NGO users vs NGO records
SELECT 
  'NGO Users' as type,
  COUNT(*) as count
FROM profiles
WHERE role = 'ngo'
UNION ALL
SELECT 
  'NGO Records' as type,
  COUNT(*) as count
FROM ngos;

-- =====================================================
-- 7. MANUAL FIX FOR SPECIFIC USER (OPTIONAL)
-- =====================================================

-- Replace 'YOUR_USER_ID' with actual user ID if needed
/*
INSERT INTO ngos (profile_id, organization_name, address_text)
VALUES (
  'YOUR_USER_ID',
  'Your Organization Name',
  'Your Address'
)
ON CONFLICT (profile_id) DO UPDATE
SET 
  organization_name = EXCLUDED.organization_name,
  address_text = EXCLUDED.address_text,
  updated_at = NOW();
*/

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '✅ NGO Profile Fix Script Completed!';
  RAISE NOTICE '';
  RAISE NOTICE 'Next Steps:';
  RAISE NOTICE '1. Check the query results above';
  RAISE NOTICE '2. Verify NGO records exist for all NGO users';
  RAISE NOTICE '3. Verify storage bucket and policies are set up';
  RAISE NOTICE '4. Test profile editing in the app';
  RAISE NOTICE '5. Test profile photo upload in the app';
END $$;
