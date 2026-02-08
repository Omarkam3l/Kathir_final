-- Add default_location column to profiles table
-- This will store the user's default address text for quick access on homepage

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS default_location TEXT;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_default_location 
ON profiles(id) 
WHERE default_location IS NOT NULL;

-- Add comment
COMMENT ON COLUMN profiles.default_location IS 'User default delivery address for homepage display';

-- Create function to update default_location when user_addresses changes
CREATE OR REPLACE FUNCTION update_profile_default_location()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update profile when address changes
DROP TRIGGER IF EXISTS trigger_update_profile_default_location ON user_addresses;
CREATE TRIGGER trigger_update_profile_default_location
  AFTER INSERT OR UPDATE OF is_default, address_text ON user_addresses
  FOR EACH ROW
  EXECUTE FUNCTION update_profile_default_location();

-- Create trigger for when address is deleted
CREATE OR REPLACE FUNCTION handle_address_deletion()
RETURNS TRIGGER AS $$
BEGIN
  -- If the deleted address was default, clear the profile's default_location
  IF OLD.is_default = true THEN
    UPDATE profiles
    SET default_location = NULL
    WHERE id = OLD.user_id;
  END IF;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_handle_address_deletion ON user_addresses;
CREATE TRIGGER trigger_handle_address_deletion
  BEFORE DELETE ON user_addresses
  FOR EACH ROW
  EXECUTE FUNCTION handle_address_deletion();

-- Backfill existing default addresses into profiles
UPDATE profiles p
SET default_location = ua.address_text
FROM user_addresses ua
WHERE ua.user_id = p.id 
  AND ua.is_default = true
  AND p.default_location IS NULL;
