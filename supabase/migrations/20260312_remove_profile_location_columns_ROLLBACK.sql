-- ROLLBACK Migration: Restore profile_latitude and profile_longitude columns
-- Date: 2026-03-12
-- Description: Restores profile_latitude and profile_longitude columns to profiles table
--              and restores the trigger/function for default_location updates

-- ⚠️ WARNING: Only run this if you need to rollback the migration!

-- ============================================================================
-- STEP 1: Restore columns to profiles table
-- ============================================================================

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
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles_location_backup') THEN
        RAISE EXCEPTION 'Backup table profiles_location_backup does not exist! Cannot rollback.';
    END IF;
END $$;

-- Restore backed up data
UPDATE profiles p
SET 
    profile_latitude = b.profile_latitude,
    profile_longitude = b.profile_longitude
FROM profiles_location_backup b
WHERE p.id = b.id;

-- ============================================================================
-- STEP 3: Restore function and trigger
-- ============================================================================

-- Recreate the function
CREATE OR REPLACE FUNCTION public.update_profile_default_location() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- When an address is set as default, update the profile
  IF NEW.is_default = true THEN
    UPDATE profiles
    SET default_location = NEW.address_text
    WHERE id = NEW.user_id;
  END IF;
  
  -- When an address is unset as default, check if there are other defaults
  IF OLD.is_default = true AND NEW.is_default = false THEN
    -- Check if there's another default address
    DECLARE
      other_default TEXT;
    BEGIN
      SELECT address_text INTO other_default
      FROM user_addresses
      WHERE user_id = NEW.user_id 
        AND is_default = true 
        AND id != NEW.id
      LIMIT 1;
      
      -- Update profile with the other default, or NULL if none
      UPDATE profiles
      SET default_location = other_default
      WHERE id = NEW.user_id;
    END;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Recreate the trigger
DROP TRIGGER IF EXISTS trigger_update_profile_default_location ON user_addresses;
CREATE TRIGGER trigger_update_profile_default_location
  AFTER INSERT OR UPDATE OF is_default, address_text ON user_addresses
  FOR EACH ROW
  EXECUTE FUNCTION update_profile_default_location();

-- ============================================================================
-- STEP 4: Restore comments
-- ============================================================================

COMMENT ON COLUMN profiles.profile_latitude IS 
'User profile latitude coordinate';

COMMENT ON COLUMN profiles.profile_longitude IS 
'User profile longitude coordinate';

-- ============================================================================
-- STEP 5: Verification
-- ============================================================================

DO $$
DECLARE
    v_restored_count integer;
    v_backup_count integer;
    v_trigger_exists boolean;
    v_function_exists boolean;
BEGIN
    SELECT COUNT(*) INTO v_backup_count FROM profiles_location_backup;
    
    SELECT COUNT(*) INTO v_restored_count 
    FROM profiles p
    INNER JOIN profiles_location_backup b ON p.id = b.id
    WHERE (p.profile_latitude IS NOT NULL AND p.profile_latitude = b.profile_latitude) 
       OR (p.profile_longitude IS NOT NULL AND p.profile_longitude = b.profile_longitude);
    
    -- Check if trigger exists
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_update_profile_default_location'
    ) INTO v_trigger_exists;
    
    -- Check if function exists
    SELECT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'update_profile_default_location'
    ) INTO v_function_exists;
    
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
    RAISE NOTICE '📝 Columns restored: profiles.profile_latitude, profiles.profile_longitude';
    
    IF v_trigger_exists THEN
        RAISE NOTICE '✅ Trigger restored: trigger_update_profile_default_location';
    ELSE
        RAISE WARNING '⚠️  Trigger not restored - manual intervention needed';
    END IF;
    
    IF v_function_exists THEN
        RAISE NOTICE '✅ Function restored: update_profile_default_location()';
    ELSE
        RAISE WARNING '⚠️  Function not restored - manual intervention needed';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  Backup table still exists: profiles_location_backup';
    RAISE NOTICE '💡 Drop backup table manually after verification';
    RAISE NOTICE '========================================';
END $$;

-- ============================================================================
-- STEP 6: Cleanup (OPTIONAL)
-- ============================================================================

-- Uncomment after verifying rollback worked
-- DROP TABLE IF EXISTS profiles_location_backup;
