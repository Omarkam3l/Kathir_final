    -- =====================================================
    -- PROFILE IMAGES STORAGE BUCKET SETUP
    -- =====================================================
    -- This creates a storage bucket for user profile images

    -- =====================================================
    -- STEP 1: Create Storage Bucket
    -- =====================================================

    INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    VALUES (
    'profile-images',
    'profile-images',
    true,  -- Public bucket so images can be accessed via URL
    5242880,  -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
    )
    ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];

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

    -- The avatar_url column should already exist in profiles table
    -- But let's make sure it's there
    DO $
    BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'avatar_url'
    ) THEN
        ALTER TABLE profiles ADD COLUMN avatar_url text;
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
    SELECT * FROM storage.buckets WHERE id = 'profile-images';

    -- Check storage policies
    SELECT * FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects'
    AND policyname LIKE '%profile images%';

    -- Check user_addresses policies
    SELECT * FROM pg_policies 
    WHERE tablename = 'user_addresses'
    ORDER BY policyname;

    -- Check profiles table has avatar_url column
    SELECT column_name, data_type 
    FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'avatar_url';

    -- =====================================================
    -- Success Message
    -- =====================================================

    DO $
    BEGIN
    RAISE NOTICE '✅ Profile images storage bucket created successfully!';
    RAISE NOTICE '✅ Storage policies created (4 policies)';
    RAISE NOTICE '✅ User addresses RLS policies created (4 policies)';
    RAISE NOTICE '✅ Avatar URL column verified in profiles table';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Bucket Details:';
    RAISE NOTICE '   - Bucket ID: profile-images';
    RAISE NOTICE '   - Public: Yes';
    RAISE NOTICE '   - Max Size: 5MB';
    RAISE NOTICE '   - Allowed: JPEG, PNG, WebP';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Upload Path Format:';
    RAISE NOTICE '   - {user_id}/profile.jpg';
    RAISE NOTICE '   - Example: 123e4567-e89b-12d3-a456-426614174000/profile.jpg';
    END $;