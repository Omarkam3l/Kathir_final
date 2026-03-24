-- Migration: Remove unused 'address' column from restaurants table
-- Date: 2026-03-12
-- Description: Removes the unused 'address' column from restaurants table.
--              The 'address_text' column is the one actually being used throughout the app.
--              Restaurants also have latitude/longitude/location for coordinates.

-- ============================================================================
-- STEP 1: Backup existing data (safety first!)
-- ============================================================================

-- Create backup table for restaurant address data
CREATE TABLE IF NOT EXISTS restaurants_address_backup (
    profile_id uuid PRIMARY KEY,
    address text,
    address_text text,
    backed_up_at timestamp with time zone DEFAULT now()
);

-- Check if 'address' column exists before backing up
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'restaurants' AND column_name = 'address'
    ) THEN
        -- Backup with address column
        INSERT INTO restaurants_address_backup (profile_id, address, address_text)
        SELECT profile_id, address, address_text
        FROM restaurants
        WHERE address IS NOT NULL OR address_text IS NOT NULL
        ON CONFLICT (profile_id) DO NOTHING;
        
        RAISE NOTICE '✅ Backed up data including address column';
    ELSE
        -- Backup without address column (it doesn't exist)
        INSERT INTO restaurants_address_backup (profile_id, address_text)
        SELECT profile_id, address_text
        FROM restaurants
        WHERE address_text IS NOT NULL
        ON CONFLICT (profile_id) DO NOTHING;
        
        RAISE NOTICE '✅ Backed up data (address column does not exist)';
    END IF;
END $$;

-- ============================================================================
-- STEP 2: Migrate any data from 'address' to 'address_text' if needed
-- ============================================================================

-- Check if 'address' column exists and migrate data if needed
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'restaurants' AND column_name = 'address'
    ) THEN
        -- If 'address' has data but 'address_text' is empty, copy it over
        UPDATE restaurants
        SET 
            address_text = address,
            updated_at = now()
        WHERE address IS NOT NULL 
          AND (address_text IS NULL OR address_text = '');
        
        RAISE NOTICE '✅ Migrated data from address to address_text';
    ELSE
        RAISE NOTICE '✅ No migration needed - address column does not exist';
    END IF;
END $$;

-- ============================================================================
-- STEP 3: Remove unused 'address' column
-- ============================================================================

-- Drop the unused 'address' column (if it exists)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'restaurants' AND column_name = 'address'
    ) THEN
        ALTER TABLE restaurants DROP COLUMN address;
        RAISE NOTICE '✅ Dropped restaurants.address column';
    ELSE
        RAISE NOTICE '✅ Column restaurants.address already removed or never existed';
    END IF;
END $$;

-- ============================================================================
-- STEP 4: Add helpful comments for documentation
-- ============================================================================

COMMENT ON COLUMN restaurants.address_text IS 
'Restaurant address (human-readable). This is the primary address field used throughout the application.';

COMMENT ON COLUMN restaurants.latitude IS 
'Latitude coordinate for restaurant location. Used with longitude for distance calculations and map display.';

COMMENT ON COLUMN restaurants.longitude IS 
'Longitude coordinate for restaurant location. Used with latitude for distance calculations and map display.';

COMMENT ON COLUMN restaurants.location IS 
'PostGIS geography point (auto-generated from lat/lng). Used for efficient spatial queries like finding nearby restaurants.';

-- ============================================================================
-- STEP 5: Verification and Summary
-- ============================================================================

DO $$
DECLARE
    v_backup_count integer;
    v_restaurants_count integer;
    v_with_address integer;
    v_with_location integer;
BEGIN
    SELECT COUNT(*) INTO v_backup_count FROM restaurants_address_backup;
    SELECT COUNT(*) INTO v_restaurants_count FROM restaurants;
    SELECT COUNT(*) INTO v_with_address FROM restaurants WHERE address_text IS NOT NULL;
    SELECT COUNT(*) INTO v_with_location FROM restaurants WHERE latitude IS NOT NULL AND longitude IS NOT NULL;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Migration completed successfully';
    RAISE NOTICE '========================================';
    RAISE NOTICE '📦 Backed up records: %', v_backup_count;
    RAISE NOTICE '📊 Total restaurants: %', v_restaurants_count;
    RAISE NOTICE '📍 Restaurants with address_text: %', v_with_address;
    RAISE NOTICE '🗺️  Restaurants with coordinates: %', v_with_location;
    RAISE NOTICE '';
    RAISE NOTICE '🗑️  Removed column: restaurants.address (unused)';
    RAISE NOTICE '✅ Kept columns: address_text, latitude, longitude, location';
    RAISE NOTICE '';
    RAISE NOTICE '💡 Backup table: restaurants_address_backup (drop after verification)';
    RAISE NOTICE '========================================';
END $$;
