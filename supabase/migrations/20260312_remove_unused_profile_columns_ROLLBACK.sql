-- ROLLBACK Migration: Restore address and location columns to profiles table
-- Date: 2026-03-12
-- Description: Restores address_text, default_location, profile_latitude, and profile_longitude columns to profiles table
--              and restores data from backup table

-- ⚠️ WARNING: Only run this if you need to rollback the migration!
-- ⚠️ This should be run immediately after the forward migration if issues are found

-- ============================================================================
-- STEP 1: Restore columns to profiles table
-- ============================================================================

-- Add back address_text column
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS address_text text;

-- Add back default_location column
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS default_location text;

-- Add back profile_latitude column
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS profile_latitude double precision;

-- Add back profile_longitude column
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS profile_longitude double precision;

-- ============================================================================
-- STEP 2: Restore data from backup table
-- ============================================================================

-- Verify backup table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles_address_backup') THEN
        RAISE EXCEPTION 'Backup table profiles_address_backup does not exist! Cannot rollback.';
    END IF;
END $$;

-- Restore backed up data
UPDATE profiles p
SET 
    address_text = b.address_text,
    default_location = b.default_location,
    profile_latitude = b.profile_latitude,
    profile_longitude = b.profile_longitude
FROM profiles_address_backup b
WHERE p.id = b.id;

-- ============================================================================
-- STEP 3: Restore comments
-- ============================================================================

COMMENT ON COLUMN profiles.address_text IS 
'Primary address for all stakeholders (users, restaurants, NGOs) - displayed on home screen';

COMMENT ON COLUMN profiles.default_location IS 
'User default delivery address for homepage display';

COMMENT ON COLUMN profiles.profile_latitude IS 
'User profile latitude coordinate';

COMMENT ON COLUMN profiles.profile_longitude IS 
'User profile longitude coordinate';

-- ============================================================================
-- STEP 4: Verification
-- ============================================================================

DO $$
DECLARE
    v_restored_count integer;
    v_backup_count integer;
BEGIN
    SELECT COUNT(*) INTO v_backup_count FROM profiles_address_backup;
    
    SELECT COUNT(*) INTO v_restored_count 
    FROM profiles p
    INNER JOIN profiles_address_backup b ON p.id = b.id
    WHERE (p.address_text IS NOT NULL AND p.address_text = b.address_text) 
       OR (p.default_location IS NOT NULL AND p.default_location = b.default_location)
       OR (p.profile_latitude IS NOT NULL AND p.profile_latitude = b.profile_latitude)
       OR (p.profile_longitude IS NOT NULL AND p.profile_longitude = b.profile_longitude);
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '🔄 ROLLBACK COMPLETED';
    RAISE NOTICE '========================================';
    RAISE NOTICE '📊 Backup records: %', v_backup_count;
    RAISE NOTICE '📊 Restored records: %', v_restored_count;
    RAISE NOTICE '';
    
    IF v_restored_count = v_backup_count THEN
        RAISE NOTICE '✅ All data restored successfully';
    ELSE
        RAISE WARNING '⚠️  Some records may not have been restored. Please verify manually.';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '📝 Columns restored: profiles.address_text, profiles.default_location, profiles.profile_latitude, profiles.profile_longitude';
    RAISE NOTICE '⚠️  Backup table still exists: profiles_address_backup';
    RAISE NOTICE '💡 Drop backup table manually after verification';
    RAISE NOTICE '========================================';
END $$;

-- ============================================================================
-- STEP 5: Cleanup (OPTIONAL - only after verifying rollback worked)
-- ============================================================================

-- Uncomment the line below ONLY after verifying the rollback was successful
-- DROP TABLE IF EXISTS profiles_address_backup;
