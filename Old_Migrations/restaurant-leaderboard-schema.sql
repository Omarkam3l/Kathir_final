-- =====================================================
-- RESTAURANT LEADERBOARD SCHEMA
-- =====================================================
-- This migration creates the necessary infrastructure for
-- the restaurant leaderboard feature, including:
-- - RPC function to compute leaderboard rankings
-- - Indexes for performance
-- - RLS policies
-- =====================================================

-- =====================================================
-- RPC FUNCTION: get_restaurant_leaderboard
-- =====================================================
-- This function computes restaurant rankings based on meals sold
-- during a specified period (week/month/all time)
-- 
-- Parameters:
--   period_filter: 'week' | 'month' | 'all'
--
-- Returns: Table with columns:
--   restaurant_profile_id: UUID of the restaurant
--   restaurant_name: Name of the restaurant
--   avatar_url: Profile picture URL (from profiles table)
--   score: Total quantity of meals sold (sum of order_items.quantity)
--   rank: Ranking position (1-based)
--
-- Security: SECURITY DEFINER to allow reading across tables
-- Performance: Uses efficient joins and aggregation
-- RLS: Safe because it only exposes public restaurant data

CREATE OR REPLACE FUNCTION get_restaurant_leaderboard(period_filter text DEFAULT 'all')
RETURNS TABLE (
  restaurant_profile_id uuid,
  restaurant_name text,
  avatar_url text,
  score bigint,
  rank bigint
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  date_threshold timestamptz;
BEGIN
  -- Determine date threshold based on period
  CASE period_filter
    WHEN 'week' THEN
      date_threshold := NOW() - INTERVAL '7 days';
    WHEN 'month' THEN
      date_threshold := NOW() - INTERVAL '30 days';
    ELSE
      date_threshold := '1970-01-01'::timestamptz; -- All time
  END CASE;

  -- Return ranked restaurants with their meal counts
  RETURN QUERY
  WITH restaurant_scores AS (
    SELECT 
      r.profile_id,
      r.restaurant_name,
      p.avatar_url,
      COALESCE(SUM(oi.quantity), 0)::bigint AS total_meals_sold
    FROM 
      restaurants r
    INNER JOIN 
      profiles p ON r.profile_id = p.id
    LEFT JOIN 
      orders o ON r.profile_id = o.restaurant_id 
      AND o.status IN ('paid', 'completed')
      AND o.created_at >= date_threshold
    LEFT JOIN 
      order_items oi ON o.id = oi.order_id
    WHERE
      p.approval_status = 'approved'
      AND p.role = 'restaurant'
    GROUP BY 
      r.profile_id, r.restaurant_name, p.avatar_url
  )
  SELECT 
    rs.profile_id,
    rs.restaurant_name,
    rs.avatar_url,
    rs.total_meals_sold,
    ROW_NUMBER() OVER (ORDER BY rs.total_meals_sold DESC, rs.restaurant_name ASC)::bigint AS rank
  FROM 
    restaurant_scores rs
  WHERE
    rs.total_meals_sold > 0  -- Only include restaurants with sales
  ORDER BY 
    rank ASC;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_restaurant_leaderboard(text) TO authenticated;
GRANT EXECUTE ON FUNCTION get_restaurant_leaderboard(text) TO anon;

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================
-- These indexes optimize the leaderboard query performance

-- Index on orders.created_at for period filtering
CREATE INDEX IF NOT EXISTS idx_orders_created_at 
ON orders (created_at DESC) 
WHERE status IN ('paid', 'completed');

-- Index on orders.restaurant_id + status for efficient joins
CREATE INDEX IF NOT EXISTS idx_orders_restaurant_status 
ON orders (restaurant_id, status, created_at DESC);

-- Index on order_items.order_id for efficient aggregation
CREATE INDEX IF NOT EXISTS idx_order_items_order_id 
ON order_items (order_id);

-- Composite index for profiles approval and role
CREATE INDEX IF NOT EXISTS idx_profiles_approval_role 
ON profiles (approval_status, role) 
WHERE approval_status = 'approved' AND role = 'restaurant';

-- =====================================================
-- HELPER FUNCTION: get_my_restaurant_rank
-- =====================================================
-- This function returns the current user's restaurant rank
-- and score for a given period
--
-- Parameters:
--   period_filter: 'week' | 'month' | 'all'
--
-- Returns: Single row with rank and score
-- Returns NULL if user is not a restaurant or has no sales

CREATE OR REPLACE FUNCTION get_my_restaurant_rank(period_filter text DEFAULT 'all')
RETURNS TABLE (
  rank bigint,
  score bigint,
  restaurant_name text
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    lb.rank,
    lb.score,
    lb.restaurant_name
  FROM 
    get_restaurant_leaderboard(period_filter) lb
  WHERE 
    lb.restaurant_profile_id = auth.uid()
  LIMIT 1;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_my_restaurant_rank(text) TO authenticated;

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON FUNCTION get_restaurant_leaderboard(text) IS 
'Computes restaurant leaderboard rankings based on meals sold. 
Period options: week, month, all. 
Returns only restaurants with sales > 0.
Safe for public access - only exposes approved restaurant data.';

COMMENT ON FUNCTION get_my_restaurant_rank(text) IS 
'Returns the current authenticated user''s restaurant rank and score.
Returns NULL if user is not a restaurant or has no sales.';

-- =====================================================
-- NOTES ON DESIGN DECISIONS
-- =====================================================
-- 
-- 1. SECURITY DEFINER: Used to allow the function to read across
--    tables without exposing raw table access. The function only
--    returns public restaurant data (approved restaurants).
--
-- 2. EXCLUDE ZERO SALES: Restaurants with 0 sales are excluded
--    from the leaderboard to keep it meaningful. This is better
--    than showing all restaurants with rank because:
--    - Cleaner UI (no long list of zeros)
--    - Better motivation (only active participants shown)
--    - Easier to implement "Your Impact" card (NULL check)
--
-- 3. PERFORMANCE: Indexes are created on:
--    - orders.created_at for period filtering
--    - orders.restaurant_id + status for joins
--    - order_items.order_id for aggregation
--    This ensures the query runs efficiently even with large datasets.
--
-- 4. SCORE CALCULATION: Uses SUM(order_items.quantity) to count
--    total meals sold, not just number of orders. This is more
--    accurate for restaurants selling multiple items per order.
--
-- 5. STATUS FILTER: Only counts orders with status 'paid' or
--    'completed' to ensure accurate sales tracking.
--
-- 6. RANKING: Uses ROW_NUMBER() for dense ranking. Ties are
--    broken alphabetically by restaurant name for consistency.
--
-- =====================================================
-- END OF MIGRATION
-- =====================================================
