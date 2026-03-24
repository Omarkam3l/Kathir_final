-- ROLLBACK Migration: Restore default_location to profiles table
-- Date: 2026-03-12
-- Description: Restores profiles.default_location column and trigger

-- ⚠️ WARNING: Only run this if you need to rollback the migration!

-- ============================================================================
-- STEP 1: Restore column to profiles table
-- ============================================================================

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS default_location text;

-- ============================================================================
-- STEP 2: Restore data from backup
-- ============================================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles_default_location_backup') THEN
        RAISE EXCEPTION 'Backup table profiles_default_location_backup does not exist! Cannot rollback.';
    END IF;
END $$;

UPDATE profiles p
SET default_location = b.default_location
FROM profiles_default_location_backup b
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
-- STEP 4: Restore comment
-- ============================================================================

COMMENT ON COLUMN profiles.default_location IS 
'User default delivery address for homepage display';

-- ============================================================================
-- STEP 5: Verification
-- ============================================================================

DO $$
DECLARE
    v_restored_count integer;
    v_trigger_exists boolean;
BEGIN
    SELECT COUNT(*) INTO v_restored_count 
    FROM profiles 
    WHERE default_location IS NOT NULL;
    
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_update_profile_default_location'
    ) INTO v_trigger_exists;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '🔄 ROLLBACK COMPLETED';
    RAISE NOTICE '========================================';
    RAISE NOTICE '📊 Restored records: %', v_restored_count;
    RAISE NOTICE '📝 Column restored: profiles.default_location';
    
    IF v_trigger_exists THEN
        RAISE NOTICE '✅ Trigger restored: trigger_update_profile_default_location';
    ELSE
        RAISE WARNING '⚠️  Trigger not restored';
    END IF;
    
    RAISE NOTICE '========================================';
END $$;

-- Uncomment after verification
-- DROP TABLE IF EXISTS profiles_default_location_backup;
