-- ============================================
-- MEAL IMAGES STORAGE BUCKET SETUP
-- ============================================
-- Purpose: Create storage bucket for meal images
-- Bucket: meal-images (public)
-- Max Size: 5MB per file
-- Allowed Types: JPEG, PNG, WebP
-- ============================================

-- ============================================
-- PART 1: CREATE BUCKET
-- ============================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'meal-images',
  'meal-images',
  true,  -- Public bucket so images can be viewed without authentication
  5242880,  -- 5MB limit (5 * 1024 * 1024)
  ARRAY['image/jpeg', 'image/png', 'image/jpg', 'image/webp']::text[]
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types,
  public = EXCLUDED.public;

-- ============================================
-- PART 2: STORAGE POLICIES
-- ============================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "Restaurant can upload meal images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view meal images" ON storage.objects;
DROP POLICY IF EXISTS "Restaurant can update own meal images" ON storage.objects;
DROP POLICY IF EXISTS "Restaurant can delete own meal images" ON storage.objects;

-- Policy 1: Allow restaurants to upload meal images
CREATE POLICY "Restaurant can upload meal images"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'meal-images' AND
    -- Check user is a restaurant
    auth.uid() IN (
      SELECT profile_id FROM public.restaurants
    )
  );

-- Policy 2: Allow anyone to view meal images (public bucket)
CREATE POLICY "Anyone can view meal images"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'meal-images');

-- Policy 3: Allow restaurants to update their own meal images
CREATE POLICY "Restaurant can update own meal images"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'meal-images' AND
    auth.uid() IN (SELECT profile_id FROM public.restaurants)
  )
  WITH CHECK (
    bucket_id = 'meal-images' AND
    auth.uid() IN (SELECT profile_id FROM public.restaurants)
  );

-- Policy 4: Allow restaurants to delete their own meal images
CREATE POLICY "Restaurant can delete own meal images"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'meal-images' AND
    auth.uid() IN (SELECT profile_id FROM public.restaurants)
  );

-- ============================================
-- PART 3: VERIFICATION
-- ============================================

-- Check bucket exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'meal-images') THEN
    RAISE NOTICE '✅ Bucket meal-images created successfully';
  ELSE
    RAISE WARNING '❌ Bucket meal-images NOT found';
  END IF;
END $$;

-- Check policies exist
DO $$
DECLARE
  policy_count integer;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'storage' 
    AND tablename = 'objects'
    AND policyname LIKE '%meal images%';
  
  RAISE NOTICE 'Created % storage policies for meal-images', policy_count;
END $$;

-- ============================================
-- USAGE EXAMPLES
-- ============================================

-- Upload path format:
-- meal-images/{restaurant_id}/{meal_id}_{timestamp}.jpg
-- Example: meal-images/abc-123-def/meal-456_1706543210.jpg

-- Get public URL:
-- https://{project_ref}.supabase.co/storage/v1/object/public/meal-images/{restaurant_id}/{filename}

-- ============================================
-- NOTES
-- ============================================

-- File naming convention:
-- - Use restaurant_id as folder name
-- - Use meal_id + timestamp for uniqueness
-- - Example: meal-456_1706543210.jpg

-- Image optimization recommendations:
-- - Compress images before upload
-- - Recommended size: 800x600px
-- - Format: JPEG for photos, PNG for graphics
-- - Quality: 80-85% for JPEG

-- Security:
-- - Public bucket allows viewing without auth
-- - Only authenticated restaurants can upload
-- - Restaurants can only manage their own images
-- - 5MB file size limit enforced

-- ============================================
-- END OF SETUP
-- ============================================
