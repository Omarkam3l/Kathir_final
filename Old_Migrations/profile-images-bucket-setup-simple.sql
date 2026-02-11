-- =====================================================
-- PROFILE IMAGES STORAGE - POLICIES ONLY
-- =====================================================
-- This creates RLS policies for profile images storage bucket

-- =====================================================
-- IMPORTANT: Create Bucket via Dashboard First!
-- =====================================================
-- You MUST create the bucket via Supabase Dashboard UI first:
-- 
-- 1. Go to Supabase Dashboard → Storage
-- 2. Click "New bucket" button
-- 3. Fill in the form:
--    - Name: profile-images
--    - Public bucket: YES (check this box)
--    - File size limit: 5242880 (5MB in bytes)
--    - Allowed MIME types: image/jpeg, image/png, image/webp
-- 4. Click "Create bucket"
--
-- After creating the bucket, run this SQL file to create the policies

-- =====================================================
-- STEP 1: Drop Existing Policies (if any)
-- =====================================================

DROP POLICY IF EXISTS "Public can view profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile images" ON storage.objects;

-- =====================================================
-- STEP 2: Create Storage Policies
-- =====================================================

-- Policy 1: Anyone can view profile images (public bucket)
CREATE POLICY "Public can view profile images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-images');

-- Policy 2: Authenticated users can upload their own profile images
CREATE POLICY "Users can upload their own profile images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 3: Users can update their own profile images
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

-- Policy 4: Users can delete their own profile images
CREATE POLICY "Users can delete their own profile images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- =====================================================
-- STEP 3: Add avatar_url column to profiles if not exists
-- =====================================================

DO $
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'avatar_url'
  ) THEN
    ALTER TABLE profiles ADD COLUMN avatar_url text;
    RAISE NOTICE '✅ Added avatar_url column to profiles table';
  ELSE
    RAISE NOTICE '✅ avatar_url column already exists in profiles table';
  END IF;
END $;

-- =====================================================
-- STEP 4: Create RLS Policies for user_addresses
-- =====================================================

-- Enable RLS on user_addresses if not already enabled
ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own addresses" ON user_addresses;
DROP POLICY IF EXISTS "Users can insert their own addresses" ON user_addresses;
DROP POLICY IF EXISTS "Users can update their own addresses" ON user_addresses;
DROP POLICY IF EXISTS "Users can delete their own addresses" ON user_addresses;

-- Policy 1: Users can view their own addresses
CREATE POLICY "Users can view their own addresses"
ON user_addresses FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Policy 2: Users can insert their own addresses
CREATE POLICY "Users can insert their own addresses"
ON user_addresses FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Policy 3: Users can update their own addresses
CREATE POLICY "Users can update their own addresses"
ON user_addresses FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Policy 4: Users can delete their own addresses
CREATE POLICY "Users can delete their own addresses"
ON user_addresses FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- =====================================================
-- STEP 5: Verification Queries
-- =====================================================

-- Check if bucket exists
SELECT 
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id = 'profile-images';

-- Check storage policies
SELECT 
  policyname,
  cmd,
  qual
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND policyname LIKE '%profile images%';

-- Check user_addresses policies
SELECT 
  policyname,
  cmd
FROM pg_policies 
WHERE tablename = 'user_addresses'
ORDER BY policyname;

-- Check profiles table has avatar_url column
SELECT 
  column_name, 
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles' 
AND column_name = 'avatar_url';

-- =====================================================
-- Success Message
-- =====================================================

DO $
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '✅ Profile images storage policies created successfully!';
  RAISE NOTICE '✅ Storage policies created (4 policies)';
  RAISE NOTICE '✅ User addresses RLS policies created (4 policies)';
  RAISE NOTICE '✅ Avatar URL column verified in profiles table';
  RAISE NOTICE '';
  RAISE NOTICE '📋 Storage Policies:';
  RAISE NOTICE '   - Public can view profile images';
  RAISE NOTICE '   - Users can upload their own images';
  RAISE NOTICE '   - Users can update their own images';
  RAISE NOTICE '   - Users can delete their own images';
  RAISE NOTICE '';
  RAISE NOTICE '📋 Upload Path Format:';
  RAISE NOTICE '   - {user_id}/profile.jpg';
  RAISE NOTICE '   - Example: 123e4567-e89b-12d3-a456-426614174000/profile.jpg';
  RAISE NOTICE '';
  RAISE NOTICE '🎉 You can now upload profile images!';
END $;
