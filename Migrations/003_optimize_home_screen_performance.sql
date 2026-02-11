-- ============================================
-- Migration 003: Optimize Home Screen Performance
-- Date: 2026-02-10
-- Author: System Fix
-- ============================================
-- PROBLEM:
-- Home screen meals take 3-5 seconds to load due to:
-- 1. Complex query fetching 20+ columns
-- 2. Missing database indexes for filtering
-- 3. No pagination (fetches all meals)
-- 4. Inner join on restaurants table
--
-- SOLUTION:
-- Add composite indexes to optimize the most common query patterns:
-- - Filter by status, quantity_available, expiry_date
-- - Order by created_at DESC
-- - Join with restaurants table
-- ============================================

-- ============================================
-- Index 1: Composite Index for Active Available Meals
-- ============================================
-- Optimizes: WHERE status='active' AND quantity_available > 0 AND expiry_date > NOW()
-- This is the primary filter used in home screen

CREATE INDEX IF NOT EXISTS idx_meals_active_available 
ON public.meals (status, quantity_available, expiry_date)
WHERE status = 'active' AND quantity_available > 0;

COMMENT ON INDEX idx_meals_active_available IS 
  'Partial index for active meals with available quantity. Optimizes home screen meal listing query.';

-- ============================================
-- Index 2: Ordering Index
-- ============================================
-- Optimizes: ORDER BY created_at DESC
-- Used to show newest meals first

CREATE INDEX IF NOT EXISTS idx_meals_created_at_desc 
ON public.meals (created_at DESC);

COMMENT ON INDEX idx_meals_created_at_desc IS 
  'Index for ordering meals by creation date (newest first). Used in home screen pagination.';

-- ============================================
-- Index 3: Restaurant Lookup Index
-- ============================================
-- Optimizes: JOIN restaurants WHERE meals.restaurant_id = restaurants.profile_id
-- Speeds up the inner join with restaurants table

CREATE INDEX IF NOT EXISTS idx_meals_restaurant_lookup 
ON public.meals (restaurant_id, status)
WHERE status = 'active';

COMMENT ON INDEX idx_meals_restaurant_lookup IS 
  'Composite index for restaurant joins. Optimizes queries that filter by restaurant and status.';

-- ============================================
-- Index 4: Category Filter Index
-- ============================================
-- Optimizes: WHERE category = 'X' (for category filtering)
-- Useful for future category-based filtering

CREATE INDEX IF NOT EXISTS idx_meals_category 
ON public.meals (category)
WHERE status = 'active';

COMMENT ON INDEX idx_meals_category IS 
  'Index for filtering meals by category. Useful for category-specific meal listings.';

-- ============================================
-- Index 5: Expiry Date Range Index
-- ============================================
-- Optimizes: WHERE expiry_date BETWEEN X AND Y
-- Useful for finding meals expiring soon

CREATE INDEX IF NOT EXISTS idx_meals_expiry_range 
ON public.meals (expiry_date)
WHERE status = 'active' AND quantity_available > 0;

COMMENT ON INDEX idx_meals_expiry_range IS 
  'Index for finding meals by expiry date range. Useful for "expiring soon" features.';

-- ============================================
-- Analyze Tables for Query Planner
-- ============================================
-- Update statistics so PostgreSQL can use the new indexes effectively

ANALYZE public.meals;
ANALYZE public.restaurants;

-- ============================================
-- Verification Queries
-- ============================================

-- Check index sizes
DO $$
DECLARE
  idx_record RECORD;
  total_size bigint := 0;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Index Sizes:';
  RAISE NOTICE '========================================';
  
  FOR idx_record IN 
    SELECT 
      indexname,
      pg_size_pretty(pg_relation_size(schemaname||'.'||indexname)) as size,
      pg_relation_size(schemaname||'.'||indexname) as bytes
    FROM pg_indexes
    WHERE tablename = 'meals' 
      AND indexname LIKE 'idx_meals_%'
    ORDER BY pg_relation_size(schemaname||'.'||indexname) DESC
  LOOP
    RAISE NOTICE '  % : %', idx_record.indexname, idx_record.size;
    total_size := total_size + idx_record.bytes;
  END LOOP;
  
  RAISE NOTICE '  Total: %', pg_size_pretty(total_size);
  RAISE NOTICE '========================================';
END $$;

-- Test query performance (explain analyze)
DO $$
DECLARE
  meal_count integer;
  query_plan text;
BEGIN
  -- Count active meals
  SELECT COUNT(*) INTO meal_count
  FROM meals
  WHERE status = 'active' 
    AND quantity_available > 0 
    AND expiry_date > NOW();
  
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Query Performance Test:';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Active meals available: %', meal_count;
  RAISE NOTICE '';
  RAISE NOTICE 'Run this query to see execution plan:';
  RAISE NOTICE 'EXPLAIN ANALYZE';
  RAISE NOTICE 'SELECT m.id, m.title, m.discounted_price, m.quantity_available';
  RAISE NOTICE 'FROM meals m';
  RAISE NOTICE 'INNER JOIN restaurants r ON m.restaurant_id = r.profile_id';
  RAISE NOTICE 'WHERE m.status = ''active''';
  RAISE NOTICE '  AND m.quantity_available > 0';
  RAISE NOTICE '  AND m.expiry_date > NOW()';
  RAISE NOTICE 'ORDER BY m.created_at DESC';
  RAISE NOTICE 'LIMIT 20;';
  RAISE NOTICE '========================================';
END $$;

-- Summary
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ Migration 003 applied successfully';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Created 5 performance indexes:';
  RAISE NOTICE '1. idx_meals_active_available - Primary filter optimization';
  RAISE NOTICE '2. idx_meals_created_at_desc - Ordering optimization';
  RAISE NOTICE '3. idx_meals_restaurant_lookup - Join optimization';
  RAISE NOTICE '4. idx_meals_category - Category filter optimization';
  RAISE NOTICE '5. idx_meals_expiry_range - Expiry date optimization';
  RAISE NOTICE '';
  RAISE NOTICE 'Expected performance improvement:';
  RAISE NOTICE '- Query time: 3-5s → <1s';
  RAISE NOTICE '- Index usage: 0% → 95%+';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '- Update Dart code to add pagination (.limit(20))';
  RAISE NOTICE '- Implement caching (30 second cache)';
  RAISE NOTICE '- Reduce columns fetched (only needed fields)';
  RAISE NOTICE '========================================';
END $$;
