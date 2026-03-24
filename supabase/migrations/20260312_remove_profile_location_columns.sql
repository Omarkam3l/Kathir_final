-- Migration: Remove profile_latitude and profile_longitude columns from profiles table
-- Date: 2026-03-12
-- Description: Removes profile_latitude and profile_longitude columns from profiles table.
--              Also removes the trigger and function that update default_location (which was already removed).
--              Location data is properly stored in role-specific tables:
--              - user_addresses table (for regular users) - with location_lat/location_long
--              - restaurants table (for restaurant users) - with latitude/longitude/location
--              - ngos table (for NGO users) - with latitude/longitude/location

-- ============================================================================
-- STEP 1: Backup existing data (safety first!)
-- ============================================================================

-- Create backup table for profile location data
CREATE TABLE IF NOT EXISTS profiles_location_backup (
    id uuid PRIMARY KEY,
    profile_latitude double precision,
    profile_longitude double precision,
    backed_up_at timestamp with time zone DEFAULT now()
);

-- Backup any existing location data from profiles
INSERT INTO profiles_location_backup (id, profile_latitude, profile_longitude)
SELECT id, profile_latitude, profile_longitude
FROM profiles
WHERE profile_latitude IS NOT NULL OR profile_longitude IS NOT NULL
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- STEP 2: Remove triggers and functions that reference location columns
-- ============================================================================

-- Drop any triggers that depend on profile location columns
DROP TRIGGER IF EXISTS profiles_location_trigger ON profiles;
DROP TRIGGER IF EXISTS trigger_update_profile_location ON profiles;
DROP TRIGGER IF EXISTS trg_update_profile_location ON profiles;

-- Drop the trigger that updates profile default_location
DROP TRIGGER IF EXISTS trigger_update_profile_default_location ON user_addresses;

-- Drop related functions
DROP FUNCTION IF EXISTS update_profile_default_location();
DROP FUNCTION IF EXISTS update_profile_location() CASCADE;
DROP FUNCTION IF EXISTS sync_profile_location() CASCADE;

-- ============================================================================
-- STEP 3: Remove location columns from profiles table
-- ============================================================================

-- Drop profile_latitude column (not used - locations in role-specific tables)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'profile_latitude'
    ) THEN
        ALTER TABLE profiles DROP COLUMN profile_latitude CASCADE;
        RAISE NOTICE '✅ Dropped profiles.profile_latitude column (with CASCADE)';
    ELSE
        RAISE NOTICE '✅ Column profiles.profile_latitude already removed or never existed';
    END IF;
END $$;

-- Drop profile_longitude column (not used - locations in role-specific tables)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'profile_longitude'
    ) THEN
        ALTER TABLE profiles DROP COLUMN profile_longitude CASCADE;
        RAISE NOTICE '✅ Dropped profiles.profile_longitude column (with CASCADE)';
    ELSE
        RAISE NOTICE '✅ Column profiles.profile_longitude already removed or never existed';
    END IF;
END $$;

-- ============================================================================
-- STEP 4: Add helpful comments for documentation
-- ============================================================================

COMMENT ON TABLE profiles IS 
'Core user profile table. Location data is stored in role-specific tables:
- Regular users: user_addresses table (location_lat/location_long)
- Restaurants: restaurants table (latitude/longitude/location PostGIS)
- NGOs: ngos table (latitude/longitude/location PostGIS)';

-- ============================================================================
-- STEP 5: Verification and Summary
-- ============================================================================

DO $$
DECLARE
    v_backup_count integer;
    v_trigger_exists boolean;
    v_function_exists boolean;
BEGIN
    -- Count backed up records
    SELECT COUNT(*) INTO v_backup_count 
    FROM profiles_location_backup 
    WHERE profile_latitude IS NOT NULL OR profile_longitude IS NOT NULL;
    
    -- Check if trigger still exists
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_update_profile_default_location'
    ) INTO v_trigger_exists;
    
    -- Check if function still exists
    SELECT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'update_profile_default_location'
    ) INTO v_function_exists;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Migration completed successfully';
    RAISE NOTICE '========================================';
    RAISE NOTICE '📦 Backed up records with location: %', v_backup_count;
    RAISE NOTICE '🗑️  Removed columns: profiles.profile_latitude, profiles.profile_longitude';
    RAISE NOTICE '🗑️  Removed triggers: profiles_location_trigger, trigger_update_profile_default_location';
    RAISE NOTICE '🗑️  Removed functions: update_profile_default_location(), and any location sync functions';
    RAISE NOTICE '';
    
    IF v_trigger_exists THEN
        RAISE WARNING '⚠️  Trigger still exists - manual cleanup may be needed';
    ELSE
        RAISE NOTICE '✅ Trigger successfully removed';
    END IF;
    
    IF v_function_exists THEN
        RAISE WARNING '⚠️  Function still exists - manual cleanup may be needed';
    ELSE
        RAISE NOTICE '✅ Function successfully removed';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '💡 Backup table: profiles_location_backup (drop after verification)';
    RAISE NOTICE '========================================';
END $$;
