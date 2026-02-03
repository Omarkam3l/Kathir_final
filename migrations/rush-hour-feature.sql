-- =====================================================
-- RUSH HOUR FEATURE MIGRATION
-- =====================================================
-- This migration implements Rush Hour settings for restaurants
-- allowing them to set time-based discount periods that override
-- individual meal discounts.
--
-- Business Rules:
-- 1. One active rush hour per restaurant (enforced by unique index)
-- 2. Rush hour active when: is_active=true AND now() BETWEEN start_time AND end_time
-- 3. When active, ALL meals use rush hour discount
-- 4. When inactive, meals use their original discount
-- 5. No bulk updates to meal rows (computed on-the-fly)
-- =====================================================

-- =====================================================
-- STEP 1: UNIQUE PARTIAL INDEX
-- =====================================================
-- Ensures at most ONE active rush_hour per restaurant
-- This prevents race conditions and duplicate active rows

CREATE UNIQUE INDEX IF NOT EXISTS idx_rush_hours_one_active_per_restaurant
ON rush_hours (restaurant_id)
WHERE is_active = true;

COMMENT ON INDEX idx_rush_hours_one_active_per_restaurant IS
'Ensures only one active rush hour configuration per restaurant at any time';

-- =====================================================
-- STEP 2: ADDITIONAL INDEXES FOR PERFORMANCE
-- =====================================================

-- Index for finding active rush hours efficiently
CREATE INDEX IF NOT EXISTS idx_rush_hours_active_time
ON rush_hours (restaurant_id, is_active, start_time, end_time)
WHERE is_active = true;

-- Index for restaurant lookup
CREATE INDEX IF NOT EXISTS idx_rush_hours_restaurant_id
ON rush_hours (restaurant_id);

-- =====================================================
-- STEP 3: RPC FUNCTION - set_rush_hour_settings
-- =====================================================
-- Safely creates or updates rush hour settings for the authenticated restaurant
-- Handles concurrent calls and prevents unique constraint violations

CREATE OR REPLACE FUNCTION set_rush_hour_settings(
  p_is_active boolean,
  p_start_time timestamptz,
  p_end_time timestamptz,
  p_discount_percentage integer
)
RETURNS json
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_restaurant_id uuid;
  v_existing_id uuid;
  v_result json;
BEGIN
  -- Get authenticated restaurant ID
  v_restaurant_id := auth.uid();
  
  IF v_restaurant_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Verify user is a restaurant
  IF NOT EXISTS (
    SELECT 1 FROM restaurants WHERE profile_id = v_restaurant_id
  ) THEN
    RAISE EXCEPTION 'User is not a restaurant';
  END IF;
  
  -- Validate inputs
  IF p_discount_percentage < 0 OR p_discount_percentage > 100 THEN
    RAISE EXCEPTION 'Discount percentage must be between 0 and 100';
  END IF;
  
  IF p_is_active AND p_end_time <= p_start_time THEN
    RAISE EXCEPTION 'End time must be after start time';
  END IF;
  
  -- Handle based on is_active flag
  IF p_is_active THEN
    -- ACTIVATE: Upsert the active rush hour
    -- First, deactivate any existing active rush hour
    UPDATE rush_hours
    SET is_active = false
    WHERE restaurant_id = v_restaurant_id
      AND is_active = true;
    
    -- Check if there's an existing row (active or inactive)
    SELECT id INTO v_existing_id
    FROM rush_hours
    WHERE restaurant_id = v_restaurant_id
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_existing_id IS NOT NULL THEN
      -- Update existing row
      UPDATE rush_hours
      SET 
        is_active = true,
        start_time = p_start_time,
        end_time = p_end_time,
        discount_percentage = p_discount_percentage
      WHERE id = v_existing_id
      RETURNING json_build_object(
        'id', id,
        'restaurant_id', restaurant_id,
        'is_active', is_active,
        'start_time', start_time,
        'end_time', end_time,
        'discount_percentage', discount_percentage,
        'active_now', (is_active AND NOW() BETWEEN start_time AND end_time)
      ) INTO v_result;
    ELSE
      -- Insert new row
      INSERT INTO rush_hours (
        restaurant_id,
        is_active,
        start_time,
        end_time,
        discount_percentage
      )
      VALUES (
        v_restaurant_id,
        true,
        p_start_time,
        p_end_time,
        p_discount_percentage
      )
      RETURNING json_build_object(
        'id', id,
        'restaurant_id', restaurant_id,
        'is_active', is_active,
        'start_time', start_time,
        'end_time', end_time,
        'discount_percentage', discount_percentage,
        'active_now', (is_active AND NOW() BETWEEN start_time AND end_time)
      ) INTO v_result;
    END IF;
  ELSE
    -- DEACTIVATE: Set is_active = false for any active rush hour
    UPDATE rush_hours
    SET is_active = false
    WHERE restaurant_id = v_restaurant_id
      AND is_active = true
    RETURNING json_build_object(
      'id', id,
      'restaurant_id', restaurant_id,
      'is_active', is_active,
      'start_time', start_time,
      'end_time', end_time,
      'discount_percentage', discount_percentage,
      'active_now', false
    ) INTO v_result;
    
    -- If no active row existed, return the most recent inactive one
    IF v_result IS NULL THEN
      SELECT json_build_object(
        'id', id,
        'restaurant_id', restaurant_id,
        'is_active', is_active,
        'start_time', start_time,
        'end_time', end_time,
        'discount_percentage', discount_percentage,
        'active_now', false
      ) INTO v_result
      FROM rush_hours
      WHERE restaurant_id = v_restaurant_id
      ORDER BY created_at DESC
      LIMIT 1;
    END IF;
    
    -- If still no result, return a default inactive state
    IF v_result IS NULL THEN
      v_result := json_build_object(
        'id', NULL,
        'restaurant_id', v_restaurant_id,
        'is_active', false,
        'start_time', NULL,
        'end_time', NULL,
        'discount_percentage', 0,
        'active_now', false
      );
    END IF;
  END IF;
  
  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION set_rush_hour_settings IS
'Creates or updates rush hour settings for the authenticated restaurant. 
Safely handles concurrent calls and prevents duplicate active rows.';

-- Grant execute to authenticated users only
GRANT EXECUTE ON FUNCTION set_rush_hour_settings(boolean, timestamptz, timestamptz, integer) 
TO authenticated;

-- =====================================================
-- STEP 4: RPC FUNCTION - get_my_rush_hour
-- =====================================================
-- Returns the current rush hour configuration for the authenticated restaurant

CREATE OR REPLACE FUNCTION get_my_rush_hour()
RETURNS json
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_restaurant_id uuid;
  v_result json;
BEGIN
  -- Get authenticated restaurant ID
  v_restaurant_id := auth.uid();
  
  IF v_restaurant_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Get the most recent rush hour configuration (active or inactive)
  SELECT json_build_object(
    'id', id,
    'restaurant_id', restaurant_id,
    'is_active', is_active,
    'start_time', start_time,
    'end_time', end_time,
    'discount_percentage', discount_percentage,
    'active_now', (is_active AND NOW() BETWEEN start_time AND end_time)
  ) INTO v_result
  FROM rush_hours
  WHERE restaurant_id = v_restaurant_id
  ORDER BY 
    CASE WHEN is_active THEN 0 ELSE 1 END,  -- Active first
    created_at DESC
  LIMIT 1;
  
  -- If no configuration exists, return default
  IF v_result IS NULL THEN
    v_result := json_build_object(
      'id', NULL,
      'restaurant_id', v_restaurant_id,
      'is_active', false,
      'start_time', NULL,
      'end_time', NULL,
      'discount_percentage', 50,  -- Default 50%
      'active_now', false
    );
  END IF;
  
  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION get_my_rush_hour IS
'Returns the current rush hour configuration for the authenticated restaurant, 
including whether it is currently active (active_now).';

-- Grant execute to authenticated users only
GRANT EXECUTE ON FUNCTION get_my_rush_hour() TO authenticated;

-- =====================================================
-- STEP 5: VIEW - meals_with_effective_discount
-- =====================================================
-- Computes the effective discount for each meal based on rush hour status
-- This is the PRIMARY way to fetch meals with correct pricing

CREATE OR REPLACE VIEW meals_with_effective_discount AS
SELECT 
  m.id,
  m.restaurant_id,
  m.title,
  m.description,
  m.category,
  m.image_url,
  m.original_price,
  m.discounted_price,
  m.quantity_available,
  m.expiry_date,
  m.pickup_deadline,
  m.status,
  m.location,
  m.unit,
  m.fulfillment_method,
  m.is_donation_available,
  m.ingredients,
  m.allergens,
  m.co2_savings,
  m.pickup_time,
  m.created_at,
  m.updated_at,
  
  -- Computed fields for rush hour
  COALESCE(rh.discount_percentage, 
    ROUND(((m.original_price - m.discounted_price) / m.original_price * 100)::numeric, 0)::integer
  ) AS effective_discount_percentage,
  
  (rh.id IS NOT NULL AND rh.is_active AND NOW() BETWEEN rh.start_time AND rh.end_time) AS rush_hour_active_now,
  
  -- Computed effective price
  CASE 
    WHEN rh.id IS NOT NULL AND rh.is_active AND NOW() BETWEEN rh.start_time AND rh.end_time THEN
      ROUND(m.original_price * (1 - rh.discount_percentage / 100.0), 2)
    ELSE
      m.discounted_price
  END AS effective_price,
  
  -- Restaurant info
  r.restaurant_name,
  r.rating AS restaurant_rating,
  r.address_text AS restaurant_address
  
FROM meals m
LEFT JOIN restaurants r ON m.restaurant_id = r.profile_id
LEFT JOIN rush_hours rh ON m.restaurant_id = rh.restaurant_id 
  AND rh.is_active = true
  AND NOW() BETWEEN rh.start_time AND rh.end_time
WHERE 
  (m.status = 'active' OR m.status IS NULL)
  AND m.quantity_available > 0
  AND m.expiry_date > NOW();

COMMENT ON VIEW meals_with_effective_discount IS
'Returns meals with computed effective discount and price based on rush hour status. 
Use this view instead of querying meals directly to ensure correct pricing.';

-- Grant access to view
GRANT SELECT ON meals_with_effective_discount TO authenticated, anon;

-- =====================================================
-- STEP 6: RPC FUNCTION - get_meals_with_effective_discount
-- =====================================================
-- Alternative to the view for more control (e.g., filtering, pagination)

CREATE OR REPLACE FUNCTION get_meals_with_effective_discount(
  p_restaurant_id uuid DEFAULT NULL,
  p_category text DEFAULT NULL,
  p_limit integer DEFAULT 50,
  p_offset integer DEFAULT 0
)
RETURNS TABLE (
  id uuid,
  restaurant_id uuid,
  title text,
  description text,
  category text,
  image_url text,
  original_price numeric,
  discounted_price numeric,
  effective_price numeric,
  quantity_available integer,
  expiry_date timestamptz,
  status text,
  location text,
  effective_discount_percentage integer,
  rush_hour_active_now boolean,
  restaurant_name text,
  restaurant_rating double precision
)
SECURITY INVOKER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.id,
    m.restaurant_id,
    m.title,
    m.description,
    m.category,
    m.image_url,
    m.original_price,
    m.discounted_price,
    CASE 
      WHEN rh.id IS NOT NULL AND rh.is_active AND NOW() BETWEEN rh.start_time AND rh.end_time THEN
        ROUND(m.original_price * (1 - rh.discount_percentage / 100.0), 2)
      ELSE
        m.discounted_price
    END AS effective_price,
    m.quantity_available,
    m.expiry_date,
    m.status,
    m.location,
    COALESCE(rh.discount_percentage, 
      ROUND(((m.original_price - m.discounted_price) / m.original_price * 100)::numeric, 0)::integer
    ) AS effective_discount_percentage,
    (rh.id IS NOT NULL AND rh.is_active AND NOW() BETWEEN rh.start_time AND rh.end_time) AS rush_hour_active_now,
    r.restaurant_name,
    r.rating AS restaurant_rating
  FROM meals m
  LEFT JOIN restaurants r ON m.restaurant_id = r.profile_id
  LEFT JOIN rush_hours rh ON m.restaurant_id = rh.restaurant_id 
    AND rh.is_active = true
    AND NOW() BETWEEN rh.start_time AND rh.end_time
  WHERE 
    (m.status = 'active' OR m.status IS NULL)
    AND m.quantity_available > 0
    AND m.expiry_date > NOW()
    AND (p_restaurant_id IS NULL OR m.restaurant_id = p_restaurant_id)
    AND (p_category IS NULL OR m.category = p_category)
  ORDER BY m.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION get_meals_with_effective_discount IS
'Returns meals with effective discount and price, with optional filtering and pagination.';

-- Grant execute to all users
GRANT EXECUTE ON FUNCTION get_meals_with_effective_discount(uuid, text, integer, integer) 
TO authenticated, anon;

-- =====================================================
-- STEP 7: RLS POLICIES FOR rush_hours
-- =====================================================

-- Enable RLS
ALTER TABLE rush_hours ENABLE ROW LEVEL SECURITY;

-- Policy: Restaurants can view their own rush hours
CREATE POLICY "Restaurants can view their own rush hours"
ON rush_hours FOR SELECT
TO authenticated
USING (restaurant_id = auth.uid());

-- Policy: Restaurants can insert their own rush hours
CREATE POLICY "Restaurants can insert their own rush hours"
ON rush_hours FOR INSERT
TO authenticated
WITH CHECK (restaurant_id = auth.uid());

-- Policy: Restaurants can update their own rush hours
CREATE POLICY "Restaurants can update their own rush hours"
ON rush_hours FOR UPDATE
TO authenticated
USING (restaurant_id = auth.uid())
WITH CHECK (restaurant_id = auth.uid());

-- Policy: Restaurants can delete their own rush hours
CREATE POLICY "Restaurants can delete their own rush hours"
ON rush_hours FOR DELETE
TO authenticated
USING (restaurant_id = auth.uid());

-- Policy: Public can view active rush hours (for computing effective discounts)
-- This is optional - if you prefer to keep rush hours private, remove this
CREATE POLICY "Public can view active rush hours"
ON rush_hours FOR SELECT
TO authenticated, anon
USING (is_active = true);

-- =====================================================
-- STEP 8: HELPER FUNCTION - calculate_effective_price
-- =====================================================
-- Utility function to calculate effective price for a single meal
-- Useful for checkout and order processing

CREATE OR REPLACE FUNCTION calculate_effective_price(
  p_meal_id uuid
)
RETURNS numeric
SECURITY INVOKER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_effective_price numeric;
BEGIN
  SELECT 
    CASE 
      WHEN rh.id IS NOT NULL AND rh.is_active AND NOW() BETWEEN rh.start_time AND rh.end_time THEN
        ROUND(m.original_price * (1 - rh.discount_percentage / 100.0), 2)
      ELSE
        m.discounted_price
    END
  INTO v_effective_price
  FROM meals m
  LEFT JOIN rush_hours rh ON m.restaurant_id = rh.restaurant_id 
    AND rh.is_active = true
    AND NOW() BETWEEN rh.start_time AND rh.end_time
  WHERE m.id = p_meal_id;
  
  RETURN COALESCE(v_effective_price, 0);
END;
$$;

COMMENT ON FUNCTION calculate_effective_price IS
'Calculates the effective price for a meal considering rush hour discounts.
Use this in checkout/order processing to ensure correct pricing.';

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION calculate_effective_price(uuid) TO authenticated;

-- =====================================================
-- STEP 9: TRIGGER - Update restaurants.rush_hour_active
-- =====================================================
-- Optional: Add a denormalized flag to restaurants table for quick lookup
-- This is useful if you want to show "Rush Hour Active" badge on restaurant cards

-- First, add the column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'restaurants' AND column_name = 'rush_hour_active'
  ) THEN
    ALTER TABLE restaurants ADD COLUMN rush_hour_active boolean DEFAULT false;
  END IF;
END $$;

-- Function to update the flag
CREATE OR REPLACE FUNCTION update_restaurant_rush_hour_flag()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Update the restaurant's rush_hour_active flag
  UPDATE restaurants
  SET rush_hour_active = (
    EXISTS (
      SELECT 1 FROM rush_hours
      WHERE restaurant_id = COALESCE(NEW.restaurant_id, OLD.restaurant_id)
        AND is_active = true
        AND NOW() BETWEEN start_time AND end_time
    )
  )
  WHERE profile_id = COALESCE(NEW.restaurant_id, OLD.restaurant_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Trigger on INSERT/UPDATE/DELETE
DROP TRIGGER IF EXISTS trg_update_rush_hour_flag ON rush_hours;
CREATE TRIGGER trg_update_rush_hour_flag
AFTER INSERT OR UPDATE OR DELETE ON rush_hours
FOR EACH ROW
EXECUTE FUNCTION update_restaurant_rush_hour_flag();

-- =====================================================
-- SUMMARY & NOTES
-- =====================================================

-- Key Design Decisions:
--
-- 1. UNIQUE PARTIAL INDEX: Prevents multiple active rush hours per restaurant
--    - Uses WHERE is_active = true to allow multiple inactive rows
--    - Prevents race conditions in concurrent updates
--
-- 2. COMPUTED EFFECTIVE DISCOUNT: Never updates meal rows
--    - Avoids data inconsistency
--    - Allows instant activation/deactivation
--    - Preserves original meal discounts
--
-- 3. SECURITY DEFINER for set/get functions:
--    - Allows bypassing RLS for safe operations
--    - Restricted to authenticated users only
--    - Validates restaurant ownership
--
-- 4. VIEW + RPC for meals:
--    - View for simple queries (no parameters)
--    - RPC for filtered/paginated queries
--    - Both compute effective discount on-the-fly
--
-- 5. TIMESTAMPTZ for start/end times:
--    - Supports timezone-aware scheduling
--    - Allows future scheduling
--    - Handles DST correctly
--
-- Edge Cases Handled:
-- - Concurrent updates (unique index + transaction)
-- - No existing rush hour (returns default)
-- - Invalid time range (validation)
-- - Invalid discount (validation)
-- - Non-restaurant user (validation)
-- - Unauthenticated user (exception)
-- - Rush hour ends while user browsing (computed on-the-fly)
--
-- Performance Considerations:
-- - Indexes on restaurant_id, is_active, time range
-- - Single query for meals with effective discount
-- - No N+1 queries
-- - Efficient LEFT JOIN (only active rush hours)
--
-- =====================================================
-- END OF MIGRATION
-- =====================================================
