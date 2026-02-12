-- =====================================================
-- RESTAURANT RATING SYSTEM
-- =====================================================
-- This migration creates a complete rating system where:
-- 1. Users can rate restaurants after order delivery
-- 2. Restaurant average rating is automatically calculated
-- 3. Rating count is tracked
-- =====================================================

-- =====================================================
-- ADD RATING COLUMNS TO RESTAURANTS TABLE
-- =====================================================

-- Add rating count column (if not exists)
ALTER TABLE restaurants 
ADD COLUMN IF NOT EXISTS rating_count integer DEFAULT 0;

-- Add comment
COMMENT ON COLUMN restaurants.rating IS 'Average rating (0-5 stars) calculated from all user ratings';
COMMENT ON COLUMN restaurants.rating_count IS 'Total number of ratings received';

-- =====================================================
-- CREATE RESTAURANT_RATINGS TABLE
-- =====================================================
-- Stores individual ratings from users

CREATE TABLE IF NOT EXISTS restaurant_ratings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  restaurant_id uuid NOT NULL REFERENCES restaurants(profile_id) ON DELETE CASCADE,
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review_text text,
  created_at timestamptz NOT NULL DEFAULT NOW(),
  updated_at timestamptz NOT NULL DEFAULT NOW(),
  
  -- Ensure one rating per order
  CONSTRAINT restaurant_ratings_order_unique UNIQUE (order_id),
  
  -- Ensure user can only rate restaurants they ordered from
  CONSTRAINT restaurant_ratings_user_restaurant_unique UNIQUE (user_id, restaurant_id, order_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_restaurant_ratings_restaurant ON restaurant_ratings(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_ratings_user ON restaurant_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_ratings_order ON restaurant_ratings(order_id);

-- Comments
COMMENT ON TABLE restaurant_ratings IS 'Individual restaurant ratings from users after order completion';
COMMENT ON COLUMN restaurant_ratings.rating IS 'Rating value from 1 to 5 stars';
COMMENT ON COLUMN restaurant_ratings.review_text IS 'Optional text review from user';

-- =====================================================
-- RLS POLICIES FOR RESTAURANT_RATINGS
-- =====================================================

ALTER TABLE restaurant_ratings ENABLE ROW LEVEL SECURITY;

-- Users can view all ratings
CREATE POLICY "Anyone can view restaurant ratings"
  ON restaurant_ratings
  FOR SELECT
  USING (true);

-- Users can insert ratings for their own completed orders
CREATE POLICY "Users can rate their completed orders"
  ON restaurant_ratings
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_id
        AND orders.user_id = auth.uid()
        AND orders.status IN ('delivered', 'completed')
    )
  );

-- Users can update their own ratings
CREATE POLICY "Users can update their own ratings"
  ON restaurant_ratings
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own ratings
CREATE POLICY "Users can delete their own ratings"
  ON restaurant_ratings
  FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- FUNCTION: Update Restaurant Average Rating
-- =====================================================

CREATE OR REPLACE FUNCTION update_restaurant_rating()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $
DECLARE
  v_avg_rating numeric;
  v_rating_count integer;
BEGIN
  -- Calculate new average rating and count
  SELECT 
    COALESCE(AVG(rating), 0),
    COUNT(*)
  INTO 
    v_avg_rating,
    v_rating_count
  FROM restaurant_ratings
  WHERE restaurant_id = COALESCE(NEW.restaurant_id, OLD.restaurant_id);
  
  -- Update restaurant table
  UPDATE restaurants
  SET 
    rating = ROUND(v_avg_rating::numeric, 1),
    rating_count = v_rating_count,
    updated_at = NOW()
  WHERE profile_id = COALESCE(NEW.restaurant_id, OLD.restaurant_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$;

COMMENT ON FUNCTION update_restaurant_rating() IS 
'Automatically recalculates restaurant average rating when a rating is added, updated, or deleted';

-- =====================================================
-- TRIGGERS: Auto-update Restaurant Rating
-- =====================================================

-- Trigger on INSERT
DROP TRIGGER IF EXISTS trigger_update_restaurant_rating_insert ON restaurant_ratings;
CREATE TRIGGER trigger_update_restaurant_rating_insert
  AFTER INSERT ON restaurant_ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_restaurant_rating();

-- Trigger on UPDATE
DROP TRIGGER IF EXISTS trigger_update_restaurant_rating_update ON restaurant_ratings;
CREATE TRIGGER trigger_update_restaurant_rating_update
  AFTER UPDATE ON restaurant_ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_restaurant_rating();

-- Trigger on DELETE
DROP TRIGGER IF EXISTS trigger_update_restaurant_rating_delete ON restaurant_ratings;
CREATE TRIGGER trigger_update_restaurant_rating_delete
  AFTER DELETE ON restaurant_ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_restaurant_rating();

-- =====================================================
-- FUNCTION: Submit Restaurant Rating (RPC)
-- =====================================================

CREATE OR REPLACE FUNCTION submit_restaurant_rating(
  p_order_id uuid,
  p_rating integer,
  p_review_text text DEFAULT NULL
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $
DECLARE
  v_user_id uuid;
  v_restaurant_id uuid;
  v_order_status text;
  v_rating_id uuid;
BEGIN
  -- Get authenticated user
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Validate rating value
  IF p_rating < 1 OR p_rating > 5 THEN
    RAISE EXCEPTION 'Rating must be between 1 and 5';
  END IF;
  
  -- Get order details and validate
  SELECT 
    o.restaurant_id,
    o.status::text
  INTO 
    v_restaurant_id,
    v_order_status
  FROM orders o
  WHERE o.id = p_order_id
    AND o.user_id = v_user_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found or does not belong to user';
  END IF;
  
  -- Check if order is completed/delivered
  IF v_order_status NOT IN ('delivered', 'completed') THEN
    RAISE EXCEPTION 'Can only rate completed or delivered orders';
  END IF;
  
  -- Insert or update rating
  INSERT INTO restaurant_ratings (
    order_id,
    user_id,
    restaurant_id,
    rating,
    review_text
  )
  VALUES (
    p_order_id,
    v_user_id,
    v_restaurant_id,
    p_rating,
    p_review_text
  )
  ON CONFLICT (order_id) 
  DO UPDATE SET
    rating = EXCLUDED.rating,
    review_text = EXCLUDED.review_text,
    updated_at = NOW()
  RETURNING id INTO v_rating_id;
  
  -- Also update the orders table rating columns (for backward compatibility)
  UPDATE orders
  SET 
    rating = p_rating,
    review_text = p_review_text,
    reviewed_at = NOW()
  WHERE id = p_order_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'rating_id', v_rating_id,
    'message', 'Rating submitted successfully'
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$;

COMMENT ON FUNCTION submit_restaurant_rating(uuid, integer, text) IS 
'Submit or update a restaurant rating for a completed order. 
Automatically updates restaurant average rating.';

-- Grant execute permission
GRANT EXECUTE ON FUNCTION submit_restaurant_rating(uuid, integer, text) TO authenticated;

-- =====================================================
-- FUNCTION: Get Restaurant Ratings (RPC)
-- =====================================================

CREATE OR REPLACE FUNCTION get_restaurant_ratings(
  p_restaurant_id uuid,
  p_limit integer DEFAULT 50,
  p_offset integer DEFAULT 0
)
RETURNS TABLE (
  id uuid,
  rating integer,
  review_text text,
  user_name text,
  user_avatar text,
  created_at timestamptz,
  order_id uuid
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $
BEGIN
  RETURN QUERY
  SELECT 
    rr.id,
    rr.rating,
    rr.review_text,
    p.full_name as user_name,
    p.avatar_url as user_avatar,
    rr.created_at,
    rr.order_id
  FROM restaurant_ratings rr
  JOIN profiles p ON rr.user_id = p.id
  WHERE rr.restaurant_id = p_restaurant_id
  ORDER BY rr.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$;

COMMENT ON FUNCTION get_restaurant_ratings(uuid, integer, integer) IS 
'Get all ratings for a restaurant with user details';

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_restaurant_ratings(uuid, integer, integer) TO authenticated, anon;

-- =====================================================
-- FUNCTION: Check if User Can Rate Order
-- =====================================================

CREATE OR REPLACE FUNCTION can_rate_order(p_order_id uuid)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $
DECLARE
  v_user_id uuid;
  v_order_status text;
  v_existing_rating integer;
BEGIN
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'can_rate', false,
      'reason', 'Not authenticated'
    );
  END IF;
  
  -- Check order status and ownership
  SELECT o.status::text
  INTO v_order_status
  FROM orders o
  WHERE o.id = p_order_id
    AND o.user_id = v_user_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'can_rate', false,
      'reason', 'Order not found'
    );
  END IF;
  
  IF v_order_status NOT IN ('delivered', 'completed') THEN
    RETURN jsonb_build_object(
      'can_rate', false,
      'reason', 'Order not yet completed'
    );
  END IF;
  
  -- Check if already rated
  SELECT rating
  INTO v_existing_rating
  FROM restaurant_ratings
  WHERE order_id = p_order_id;
  
  IF FOUND THEN
    RETURN jsonb_build_object(
      'can_rate', true,
      'already_rated', true,
      'existing_rating', v_existing_rating,
      'reason', 'Can update existing rating'
    );
  END IF;
  
  RETURN jsonb_build_object(
    'can_rate', true,
    'already_rated', false,
    'reason', 'Can submit new rating'
  );
END;
$;

COMMENT ON FUNCTION can_rate_order(uuid) IS 
'Check if the authenticated user can rate a specific order';

-- Grant execute permission
GRANT EXECUTE ON FUNCTION can_rate_order(uuid) TO authenticated;

-- =====================================================
-- VERIFICATION
-- =====================================================

DO $
BEGIN
  -- Verify table exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'restaurant_ratings') THEN
    RAISE NOTICE '✅ restaurant_ratings table created successfully';
  ELSE
    RAISE EXCEPTION '❌ Failed to create restaurant_ratings table';
  END IF;
  
  -- Verify rating_count column exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'restaurants' AND column_name = 'rating_count'
  ) THEN
    RAISE NOTICE '✅ rating_count column added to restaurants table';
  ELSE
    RAISE EXCEPTION '❌ Failed to add rating_count column';
  END IF;
  
  RAISE NOTICE '✅ Restaurant rating system setup complete!';
END;
$;
