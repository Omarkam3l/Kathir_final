-- Migration: Add Location Support to Restaurants and NGOs
-- Date: 2026-02-16
-- Description: Adds PostGIS location support with fallback to lat/lng columns

-- Enable PostGIS extension (safe if already exists)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Add location columns to restaurants table
ALTER TABLE public.restaurants 
  ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS location GEOGRAPHY(POINT, 4326),
  ADD COLUMN IF NOT EXISTS location_updated_at TIMESTAMPTZ DEFAULT NOW();

-- Add location columns to ngos table
ALTER TABLE public.ngos 
  ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS location GEOGRAPHY(POINT, 4326),
  ADD COLUMN IF NOT EXISTS location_updated_at TIMESTAMPTZ DEFAULT NOW();

-- Create indexes for spatial queries (GIST index for PostGIS)
CREATE INDEX IF NOT EXISTS idx_restaurants_location ON public.restaurants USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_ngos_location ON public.ngos USING GIST(location);

-- Create indexes for fallback lat/lng queries
CREATE INDEX IF NOT EXISTS idx_restaurants_lat_lng ON public.restaurants(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_ngos_lat_lng ON public.ngos(latitude, longitude);

-- Function to automatically update location geography from lat/lng
CREATE OR REPLACE FUNCTION update_location_from_coordinates()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    NEW.location_updated_at := NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to auto-update location geography
DROP TRIGGER IF EXISTS restaurants_location_trigger ON public.restaurants;
CREATE TRIGGER restaurants_location_trigger
  BEFORE INSERT OR UPDATE OF latitude, longitude
  ON public.restaurants
  FOR EACH ROW
  EXECUTE FUNCTION update_location_from_coordinates();

DROP TRIGGER IF EXISTS ngos_location_trigger ON public.ngos;
CREATE TRIGGER ngos_location_trigger
  BEFORE INSERT OR UPDATE OF latitude, longitude
  ON public.ngos
  FOR EACH ROW
  EXECUTE FUNCTION update_location_from_coordinates();

-- Function to find nearby restaurants (for future use)
CREATE OR REPLACE FUNCTION find_nearby_restaurants(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  radius_meters INTEGER DEFAULT 5000,
  limit_count INTEGER DEFAULT 20
)
RETURNS TABLE (
  profile_id UUID,
  restaurant_name TEXT,
  address TEXT,
  address_text TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  distance_meters DOUBLE PRECISION,
  rating DOUBLE PRECISION,
  rating_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.profile_id,
    r.restaurant_name,
    r.address,
    r.address_text,
    r.latitude,
    r.longitude,
    ST_Distance(
      r.location,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
    ) AS distance_meters,
    r.rating,
    r.rating_count
  FROM public.restaurants r
  WHERE r.location IS NOT NULL
    AND ST_DWithin(
      r.location,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
      radius_meters
    )
  ORDER BY distance_meters ASC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to find nearby NGOs (for future use)
CREATE OR REPLACE FUNCTION find_nearby_ngos(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  radius_meters INTEGER DEFAULT 5000,
  limit_count INTEGER DEFAULT 20
)
RETURNS TABLE (
  profile_id UUID,
  organization_name TEXT,
  address_text TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  distance_meters DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    n.profile_id,
    n.organization_name,
    n.address_text,
    n.latitude,
    n.longitude,
    ST_Distance(
      n.location,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
    ) AS distance_meters
  FROM public.ngos n
  WHERE n.location IS NOT NULL
    AND ST_DWithin(
      n.location,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
      radius_meters
    )
  ORDER BY distance_meters ASC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update RLS policies for restaurants location updates
-- Restaurant owners can update their own location
-- ============================================================
-- RLS: Enable and Policies (FIXED - no IF NOT EXISTS)
-- ============================================================

-- Make sure RLS is enabled
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ngos ENABLE ROW LEVEL SECURITY;

-- Drop old policies if they exist (safe)
DROP POLICY IF EXISTS "Restaurant owners can update their location" ON public.restaurants;
DROP POLICY IF EXISTS "NGO users can update their location" ON public.ngos;
DROP POLICY IF EXISTS "Anyone can read restaurant locations" ON public.restaurants;
DROP POLICY IF EXISTS "Anyone can read NGO locations" ON public.ngos;

-- Restaurant owners can update ONLY their own row (location fields)
CREATE POLICY "Restaurant owners can update their location"
  ON public.restaurants
  FOR UPDATE
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

-- NGO users can update ONLY their own row (location fields)
CREATE POLICY "NGO users can update their location"
  ON public.ngos
  FOR UPDATE
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

-- Allow reading locations (needed for nearby search)
CREATE POLICY "Anyone can read restaurant locations"
  ON public.restaurants
  FOR SELECT
  USING (true);

CREATE POLICY "Anyone can read NGO locations"
  ON public.ngos
  FOR SELECT
  USING (true);


-- Add comments for documentation
COMMENT ON COLUMN public.restaurants.latitude IS 'Latitude coordinate for restaurant location';
COMMENT ON COLUMN public.restaurants.longitude IS 'Longitude coordinate for restaurant location';
COMMENT ON COLUMN public.restaurants.location IS 'PostGIS geography point for spatial queries';
COMMENT ON COLUMN public.restaurants.location_updated_at IS 'Timestamp when location was last updated';

COMMENT ON COLUMN public.ngos.latitude IS 'Latitude coordinate for NGO location';
COMMENT ON COLUMN public.ngos.longitude IS 'Longitude coordinate for NGO location';
COMMENT ON COLUMN public.ngos.location IS 'PostGIS geography point for spatial queries';
COMMENT ON COLUMN public.ngos.location_updated_at IS 'Timestamp when location was last updated';
