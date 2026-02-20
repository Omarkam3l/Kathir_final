-- Add latitude and longitude columns to user_addresses table
ALTER TABLE user_addresses 
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS location geography(Point, 4326),
ADD COLUMN IF NOT EXISTS location_updated_at TIMESTAMPTZ DEFAULT now();

-- Create index for location-based queries
CREATE INDEX IF NOT EXISTS idx_user_addresses_location ON user_addresses USING GIST (location);

-- Create trigger to automatically update location from coordinates
CREATE OR REPLACE FUNCTION update_user_address_location()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    NEW.location_updated_at := NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_addresses_location_trigger
  BEFORE INSERT OR UPDATE OF latitude, longitude ON user_addresses
  FOR EACH ROW
  EXECUTE FUNCTION update_user_address_location();

-- Add comments
COMMENT ON COLUMN user_addresses.latitude IS 'Latitude coordinate for address location';
COMMENT ON COLUMN user_addresses.longitude IS 'Longitude coordinate for address location';
COMMENT ON COLUMN user_addresses.location IS 'PostGIS geography point for spatial queries';
