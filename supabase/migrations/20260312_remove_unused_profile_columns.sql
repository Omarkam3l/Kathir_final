-- Migration: Remove address and location columns from profiles table
-- Date: 2026-03-12
-- Description: Removes address_text, default_location, profile_latitude, and profile_longitude from profiles table.
--              Address/location data is properly stored in:
--              - user_addresses table (for regular users) - with lat/lng
--              - restaurants table (for restaurant users) - with lat/lng/location
--              - ngos table (for NGO users) - with lat/lng/location

-- ============================================================================
-- STEP 1: Backup existing data (safety first!)
-- ============================================================================

-- Create backup table for profiles address and location data
CREATE TABLE IF NOT EXISTS profiles_address_backup (
    id uuid PRIMARY KEY,
    address_text text,
    default_location text,
    profile_latitude double precision,
    profile_longitude double precision,
    backed_up_at timestamp with time zone DEFAULT now()
);

-- Backup any existing address/location data from profiles
INSERT INTO profiles_address_backup (id, address_text, default_location, profile_latitude, profile_longitude)
SELECT id, address_text, default_location, profile_latitude, profile_longitude
FROM profiles
WHERE address_text IS NOT NULL 
   OR default_location IS NOT NULL
   OR profile_latitude IS NOT NULL
   OR profile_longitude IS NOT NULL
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- STEP 2: Migrate any orphaned data to proper tables
-- ============================================================================

-- For regular users: migrate to user_addresses if they have address but no user_addresses record
INSERT INTO user_addresses (user_id, label, address_text, is_default, created_at, updated_at)
SELECT 
    p.id,
    'Home',
    COALESCE(p.default_location, p.address_text),
    true,
    now(),
    now()
FROM profiles p
WHERE p.role = 'user'
  AND (p.address_text IS NOT NULL OR p.default_location IS NOT NULL)
  AND NOT EXISTS (
    SELECT 1 FROM user_addresses ua WHERE ua.user_id = p.id
  )
ON CONFLICT DO NOTHING;

-- For restaurants: ensure address_text is populated in restaurants table
UPDATE restaurants r
SET 
    address_text = COALESCE(r.address_text, p.address_text, p.default_location),
    updated_at = now()
FROM profiles p
WHERE r.profile_id = p.id
  AND r.address_text IS NULL
  AND (p.address_text IS NOT NULL OR p.default_location IS NOT NULL);

-- For NGOs: ensure address_text is populated in ngos table
UPDATE ngos n
SET 
    address_text = COALESCE(n.address_text, p.address_text, p.default_location),
    updated_at = now()
FROM profiles p
WHERE n.profile_id = p.id
  AND n.address_text IS NULL
  AND (p.address_text IS NOT NULL OR p.default_location IS NOT NULL);

-- ============================================================================
-- STEP 3: Remove address and location columns from profiles table
-- ============================================================================

-- Drop address_text column (addresses stored in user_addresses, restaurants, ngos)
ALTER TABLE profiles DROP COLUMN IF EXISTS address_text;

-- Drop default_location column (redundant with address_text)
ALTER TABLE profiles DROP COLUMN IF EXISTS default_location;

-- Drop profile_latitude column (not used - locations in role-specific tables)
ALTER TABLE profiles DROP COLUMN IF EXISTS profile_latitude;

-- Drop profile_longitude column (not used - locations in role-specific tables)
ALTER TABLE profiles DROP COLUMN IF EXISTS profile_longitude;

-- ============================================================================
-- STEP 4: Add helpful comments for documentation
-- ============================================================================

COMMENT ON TABLE profiles IS 
'Core user profile table. Address and location data is stored in role-specific tables:
- Regular users: user_addresses table (supports multiple addresses with lat/lng)
- Restaurants: restaurants.address_text + latitude/longitude/location (PostGIS)
- NGOs: ngos.address_text + latitude/longitude/location (PostGIS)';

COMMENT ON TABLE user_addresses IS 
'Stores multiple addresses for regular users. Each user can have multiple saved addresses with one marked as default. Includes lat/lng coordinates.';

COMMENT ON COLUMN restaurants.address_text IS 
'Restaurant address (human-readable). Primary address field used throughout the application.';

COMMENT ON COLUMN restaurants.latitude IS 
'Latitude coordinate for restaurant location.';

COMMENT ON COLUMN restaurants.longitude IS 
'Longitude coordinate for restaurant location.';

COMMENT ON COLUMN restaurants.location IS 
'PostGIS geography point (auto-generated from lat/lng). Used for efficient spatial queries.';

COMMENT ON COLUMN ngos.address_text IS 
'NGO address (human-readable). Primary address field used throughout the application.';

COMMENT ON COLUMN ngos.latitude IS 
'Latitude coordinate for NGO location.';

COMMENT ON COLUMN ngos.longitude IS 
'Longitude coordinate for NGO location.';

COMMENT ON COLUMN ngos.location IS 
'PostGIS geography point (auto-generated from lat/lng). Used for efficient spatial queries.';

-- ============================================================================
-- STEP 5: Verification and Summary
-- ============================================================================

DO $$
DECLARE
    v_backup_count integer;
    v_user_addresses integer;
    v_restaurant_addresses integer;
    v_ngo_addresses integer;
BEGIN
    -- Count backed up records
    SELECT COUNT(*) INTO v_backup_count FROM profiles_address_backup;
    
    -- Count addresses in proper tables
    SELECT COUNT(DISTINCT user_id) INTO v_user_addresses FROM user_addresses;
    SELECT COUNT(*) INTO v_restaurant_addresses FROM restaurants WHERE address_text IS NOT NULL;
    SELECT COUNT(*) INTO v_ngo_addresses FROM ngos WHERE address_text IS NOT NULL;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Migration completed successfully';
    RAISE NOTICE '========================================';
    RAISE NOTICE '📦 Backed up records: %', v_backup_count;
    RAISE NOTICE '🗑️  Removed columns: profiles.address_text, profiles.default_location, profiles.profile_latitude, profiles.profile_longitude';
    RAISE NOTICE '';
    RAISE NOTICE '📍 Address data distribution:';
    RAISE NOTICE '   - Users with addresses: %', v_user_addresses;
    RAISE NOTICE '   - Restaurants with addresses: %', v_restaurant_addresses;
    RAISE NOTICE '   - NGOs with addresses: %', v_ngo_addresses;
    RAISE NOTICE '';
    RAISE NOTICE '💡 Backup table: profiles_address_backup (drop after verification)';
    RAISE NOTICE '========================================';
END $$;
