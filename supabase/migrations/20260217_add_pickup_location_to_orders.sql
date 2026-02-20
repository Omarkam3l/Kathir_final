-- Migration: Add Pickup Location to Orders
-- Date: 2026-02-17
-- Description: Adds pickup location coordinates and address to orders table
--              Pickup location = restaurant location for pickup orders
--              Pickup location = NGO/user location for delivery orders

-- Add pickup location columns to orders table
ALTER TABLE public.orders 
  ADD COLUMN IF NOT EXISTS pickup_latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS pickup_longitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS pickup_location GEOGRAPHY(POINT, 4326),
  ADD COLUMN IF NOT EXISTS pickup_address_text TEXT;

-- Create index for pickup location queries
CREATE INDEX IF NOT EXISTS idx_orders_pickup_location 
  ON public.orders USING GIST(pickup_location);

-- Function to automatically set pickup location based on delivery type
CREATE OR REPLACE FUNCTION set_order_pickup_location()
RETURNS TRIGGER AS $$
DECLARE
  restaurant_lat DOUBLE PRECISION;
  restaurant_lng DOUBLE PRECISION;
  restaurant_address TEXT;
  ngo_lat DOUBLE PRECISION;
  ngo_lng DOUBLE PRECISION;
  ngo_address TEXT;
BEGIN
  -- For PICKUP orders: pickup location = restaurant location
  IF NEW.delivery_type = 'pickup' THEN
    -- Get restaurant location
    SELECT latitude, longitude, address_text
    INTO restaurant_lat, restaurant_lng, restaurant_address
    FROM restaurants
    WHERE profile_id = NEW.restaurant_id;
    
    IF restaurant_lat IS NOT NULL AND restaurant_lng IS NOT NULL THEN
      NEW.pickup_latitude := restaurant_lat;
      NEW.pickup_longitude := restaurant_lng;
      NEW.pickup_address_text := COALESCE(restaurant_address, 'Restaurant Location');
      NEW.pickup_location := ST_SetSRID(ST_MakePoint(restaurant_lng, restaurant_lat), 4326)::geography;
    END IF;
  
  -- For DELIVERY orders: pickup location = restaurant location (where food is picked up from)
  ELSIF NEW.delivery_type = 'delivery' THEN
    -- Get restaurant location
    SELECT latitude, longitude, address_text
    INTO restaurant_lat, restaurant_lng, restaurant_address
    FROM restaurants
    WHERE profile_id = NEW.restaurant_id;
    
    IF restaurant_lat IS NOT NULL AND restaurant_lng IS NOT NULL THEN
      NEW.pickup_latitude := restaurant_lat;
      NEW.pickup_longitude := restaurant_lng;
      NEW.pickup_address_text := COALESCE(restaurant_address, 'Restaurant Location');
      NEW.pickup_location := ST_SetSRID(ST_MakePoint(restaurant_lng, restaurant_lat), 4326)::geography;
    END IF;
  
  -- For DONATION orders: pickup location = NGO location (where NGO picks up from restaurant)
  ELSIF NEW.delivery_type = 'donation' THEN
    -- Get restaurant location (NGO picks up from restaurant)
    SELECT latitude, longitude, address_text
    INTO restaurant_lat, restaurant_lng, restaurant_address
    FROM restaurants
    WHERE profile_id = NEW.restaurant_id;
    
    IF restaurant_lat IS NOT NULL AND restaurant_lng IS NOT NULL THEN
      NEW.pickup_latitude := restaurant_lat;
      NEW.pickup_longitude := restaurant_lng;
      NEW.pickup_address_text := COALESCE(restaurant_address, 'Restaurant Location');
      NEW.pickup_location := ST_SetSRID(ST_MakePoint(restaurant_lng, restaurant_lat), 4326)::geography;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically set pickup location on order creation/update
DROP TRIGGER IF EXISTS orders_pickup_location_trigger ON public.orders;
CREATE TRIGGER orders_pickup_location_trigger
  BEFORE INSERT OR UPDATE OF delivery_type, restaurant_id, ngo_id
  ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION set_order_pickup_location();

-- Update existing orders with pickup locations (backfill)
-- This will set pickup locations for all existing orders based on their delivery type
UPDATE public.orders o
SET 
  pickup_latitude = r.latitude,
  pickup_longitude = r.longitude,
  pickup_address_text = COALESCE(r.address_text, 'Restaurant Location'),
  pickup_location = CASE 
    WHEN r.latitude IS NOT NULL AND r.longitude IS NOT NULL 
    THEN ST_SetSRID(ST_MakePoint(r.longitude, r.latitude), 4326)::geography
    ELSE NULL
  END
FROM restaurants r
WHERE o.restaurant_id = r.profile_id
  AND o.pickup_latitude IS NULL
  AND r.latitude IS NOT NULL
  AND r.longitude IS NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN public.orders.pickup_latitude IS 'Latitude of pickup location (restaurant for all order types)';
COMMENT ON COLUMN public.orders.pickup_longitude IS 'Longitude of pickup location (restaurant for all order types)';
COMMENT ON COLUMN public.orders.pickup_location IS 'PostGIS geography point for pickup location';
COMMENT ON COLUMN public.orders.pickup_address_text IS 'Human-readable pickup address';

-- Function to get orders with pickup locations for a user
CREATE OR REPLACE FUNCTION get_user_orders_with_pickup(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  order_id UUID,
  order_number TEXT,
  order_code INTEGER,
  status TEXT,
  delivery_type TEXT,
  total_amount NUMERIC,
  created_at TIMESTAMPTZ,
  pickup_latitude DOUBLE PRECISION,
  pickup_longitude DOUBLE PRECISION,
  pickup_address_text TEXT,
  delivery_address TEXT,
  restaurant_name TEXT,
  restaurant_latitude DOUBLE PRECISION,
  restaurant_longitude DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id AS order_id,
    o.order_number,
    o.order_code,
    o.status::TEXT,
    o.delivery_type,
    o.total_amount,
    o.created_at,
    o.pickup_latitude,
    o.pickup_longitude,
    o.pickup_address_text,
    o.delivery_address,
    r.restaurant_name,
    r.latitude AS restaurant_latitude,
    r.longitude AS restaurant_longitude
  FROM orders o
  LEFT JOIN restaurants r ON o.restaurant_id = r.profile_id
  WHERE o.user_id = p_user_id
  ORDER BY o.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get orders with pickup locations for a restaurant
CREATE OR REPLACE FUNCTION get_restaurant_orders_with_pickup(
  p_restaurant_id UUID,
  p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  order_id UUID,
  order_number TEXT,
  order_code INTEGER,
  status TEXT,
  delivery_type TEXT,
  total_amount NUMERIC,
  created_at TIMESTAMPTZ,
  pickup_latitude DOUBLE PRECISION,
  pickup_longitude DOUBLE PRECISION,
  pickup_address_text TEXT,
  delivery_address TEXT,
  customer_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id AS order_id,
    o.order_number,
    o.order_code,
    o.status::TEXT,
    o.delivery_type,
    o.total_amount,
    o.created_at,
    o.pickup_latitude,
    o.pickup_longitude,
    o.pickup_address_text,
    o.delivery_address,
    p.full_name AS customer_name
  FROM orders o
  LEFT JOIN profiles p ON o.user_id = p.id
  WHERE o.restaurant_id = p_restaurant_id
  ORDER BY o.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get orders with pickup locations for an NGO
CREATE OR REPLACE FUNCTION get_ngo_orders_with_pickup(
  p_ngo_id UUID,
  p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  order_id UUID,
  order_number TEXT,
  order_code INTEGER,
  status TEXT,
  delivery_type TEXT,
  total_amount NUMERIC,
  created_at TIMESTAMPTZ,
  pickup_latitude DOUBLE PRECISION,
  pickup_longitude DOUBLE PRECISION,
  pickup_address_text TEXT,
  restaurant_name TEXT,
  restaurant_latitude DOUBLE PRECISION,
  restaurant_longitude DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id AS order_id,
    o.order_number,
    o.order_code,
    o.status::TEXT,
    o.delivery_type,
    o.total_amount,
    o.created_at,
    o.pickup_latitude,
    o.pickup_longitude,
    o.pickup_address_text,
    r.restaurant_name,
    r.latitude AS restaurant_latitude,
    r.longitude AS restaurant_longitude
  FROM orders o
  LEFT JOIN restaurants r ON o.restaurant_id = r.profile_id
  WHERE o.ngo_id = p_ngo_id
  ORDER BY o.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Summary
SELECT 
  '=== PICKUP LOCATION MIGRATION COMPLETE ===' as summary,
  'Pickup locations will be automatically set based on delivery type' as details
UNION ALL
SELECT 
  'Pickup Orders' as summary,
  'Pickup location = Restaurant location' as details
UNION ALL
SELECT 
  'Delivery Orders' as summary,
  'Pickup location = Restaurant location (where food is picked up from)' as details
UNION ALL
SELECT 
  'Donation Orders' as summary,
  'Pickup location = Restaurant location (where NGO picks up from)' as details;
