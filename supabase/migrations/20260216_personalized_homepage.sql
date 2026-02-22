-- =====================================================
-- PERSONALIZED HOMEPAGE BASED ON USER PREFERENCES
-- =====================================================
-- Shows meals based on user's favorite meal categories

CREATE OR REPLACE FUNCTION get_personalized_meals(
  p_user_id uuid,
  p_limit int DEFAULT 20
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
  quantity_available int,
  expiry_date timestamptz,
  restaurant_name text,
  restaurant_rating double precision
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_user_categories text[];
BEGIN
  -- Get user's favorite categories
  SELECT array_agg(category)
  INTO v_user_categories
  FROM user_category_preferences
  WHERE user_id = p_user_id
    AND notifications_enabled = true;
  
  -- If user has no preferences, return all meals
  IF v_user_categories IS NULL OR array_length(v_user_categories, 1) = 0 THEN
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
      m.quantity_available,
      m.expiry_date,
      r.restaurant_name,
      r.rating
    FROM meals m
    LEFT JOIN restaurants r ON m.restaurant_id = r.profile_id
    WHERE (m.status = 'active' OR m.status IS NULL)
      AND m.quantity_available > 0
      AND m.expiry_date > NOW()
    ORDER BY m.created_at DESC
    LIMIT p_limit;
  ELSE
    -- Return meals matching user's favorite categories first, then others
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
      m.quantity_available,
      m.expiry_date,
      r.restaurant_name,
      r.rating
    FROM meals m
    LEFT JOIN restaurants r ON m.restaurant_id = r.profile_id
    WHERE (m.status = 'active' OR m.status IS NULL)
      AND m.quantity_available > 0
      AND m.expiry_date > NOW()
    ORDER BY 
      CASE WHEN m.category = ANY(v_user_categories) THEN 0 ELSE 1 END,
      m.created_at DESC
    LIMIT p_limit;
  END IF;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_personalized_meals(uuid, int) TO authenticated;
GRANT EXECUTE ON FUNCTION get_personalized_meals(uuid, int) TO anon;

COMMENT ON FUNCTION get_personalized_meals(uuid, int) IS 'Returns meals personalized based on user category preferences. Preferred categories shown first.';
