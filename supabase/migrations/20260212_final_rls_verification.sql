-- =====================================================
-- FINAL RLS VERIFICATION AND SECURITY HARDENING
-- Ensures all tables have RLS enabled and proper policies
-- =====================================================

-- =====================================================
-- PART 1: VERIFY RLS IS ENABLED ON ALL TABLES
-- =====================================================

DO $$
DECLARE
  tbl RECORD;
BEGIN
  RAISE NOTICE '=== Verifying RLS Status ===';
  
  FOR tbl IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename NOT LIKE 'pg_%'
    ORDER BY tablename
  LOOP
    -- Enable RLS if not already enabled
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tbl.tablename);
    RAISE NOTICE 'RLS enabled on: %', tbl.tablename;
  END LOOP;
END $$;

-- =====================================================
-- PART 2: ADD MISSING POLICIES FOR EDGE CASES
-- =====================================================

-- Ensure NGOs can view free meal notifications (to see what's available)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'free_meal_notifications' 
    AND policyname = 'NGOs can view free meal notifications'
  ) THEN
    CREATE POLICY "NGOs can view free meal notifications"
    ON free_meal_notifications FOR SELECT
    TO authenticated
    USING (true);
  END IF;
END $$;

-- Ensure meal reports have proper restaurant access
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'meal_reports' 
    AND policyname = 'Restaurants can update report status'
  ) THEN
    CREATE POLICY "Restaurants can update report status"
    ON meal_reports FOR UPDATE
    TO authenticated
    USING (restaurant_id = auth.uid())
    WITH CHECK (restaurant_id = auth.uid());
  END IF;
END $$;

-- =====================================================
-- PART 3: OPTIMIZE CATEGORY NOTIFICATIONS
-- =====================================================

-- Add insert policy for category notifications (system should be able to create them)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'category_notifications' 
    AND policyname = 'Users can insert their own notifications'
  ) THEN
    CREATE POLICY "Users can insert their own notifications"
    ON category_notifications FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- =====================================================
-- PART 4: ENSURE USER CATEGORY PREFERENCES ARE COMPLETE
-- =====================================================

-- All CRUD operations should be available for user_category_preferences
-- Policies already exist, just verify they're working

-- =====================================================
-- PART 5: ADD ADMIN OVERRIDE POLICIES WHERE NEEDED
-- =====================================================

-- Admins should be able to view all meal reports
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'meal_reports' 
    AND policyname = 'Admins can view all reports'
  ) THEN
    CREATE POLICY "Admins can view all reports"
    ON meal_reports FOR SELECT
    TO authenticated
    USING (is_admin());
  END IF;
END $$;

-- Admins should be able to view all orders
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'orders' 
    AND policyname = 'Admins can view all orders'
  ) THEN
    CREATE POLICY "Admins can view all orders"
    ON orders FOR SELECT
    TO authenticated
    USING (is_admin());
  END IF;
END $$;

-- =====================================================
-- PART 6: ADD PERFORMANCE MONITORING INDEXES
-- =====================================================

-- Index for frequently queried meal categories
CREATE INDEX IF NOT EXISTS idx_meals_category ON meals(category);

-- Index for meal search by title
CREATE INDEX IF NOT EXISTS idx_meals_title_trgm ON meals USING gin(title gin_trgm_ops);

-- Index for restaurant search by name
CREATE INDEX IF NOT EXISTS idx_restaurants_name_trgm ON restaurants USING gin(restaurant_name gin_trgm_ops);

-- Index for NGO search by name
CREATE INDEX IF NOT EXISTS idx_ngos_name_trgm ON ngos USING gin(organization_name gin_trgm_ops);

-- Index for order status filtering
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- Index for order date range queries
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- =====================================================
-- PART 7: SECURITY AUDIT - CHECK FOR OVERLY PERMISSIVE POLICIES
-- =====================================================

DO $$
DECLARE
  policy_rec RECORD;
  warning_count INTEGER := 0;
BEGIN
  RAISE NOTICE '=== Security Audit ===';
  
  -- Check for policies with "true" in USING clause (overly permissive)
  FOR policy_rec IN
    SELECT tablename, policyname, cmd, qual::text as using_clause
    FROM pg_policies
    WHERE schemaname = 'public'
    AND qual::text = 'true'
    AND cmd != 'INSERT'  -- INSERT with true is sometimes OK
    AND tablename NOT IN ('email_queue')  -- Exclude service tables
  LOOP
    warning_count := warning_count + 1;
    RAISE WARNING 'Overly permissive policy: %.% (%) - USING: true', 
      policy_rec.tablename, policy_rec.policyname, policy_rec.cmd;
  END LOOP;
  
  IF warning_count = 0 THEN
    RAISE NOTICE 'No overly permissive policies found';
  ELSE
    RAISE NOTICE 'Found % potentially overly permissive policies', warning_count;
  END IF;
END $$;

-- =====================================================
-- PART 8: FINAL VERIFICATION REPORT
-- =====================================================

DO $$
DECLARE
  total_tables INTEGER;
  tables_with_rls INTEGER;
  tables_without_policies INTEGER;
  total_policies INTEGER;
BEGIN
  RAISE NOTICE '=== FINAL RLS VERIFICATION REPORT ===';
  
  -- Count total tables
  SELECT COUNT(*) INTO total_tables
  FROM pg_tables
  WHERE schemaname = 'public'
  AND tablename NOT LIKE 'pg_%';
  
  -- Count tables with RLS enabled
  SELECT COUNT(*) INTO tables_with_rls
  FROM pg_tables t
  WHERE t.schemaname = 'public'
  AND t.tablename NOT LIKE 'pg_%'
  AND EXISTS (
    SELECT 1 FROM pg_class c
    WHERE c.relname = t.tablename
    AND c.relrowsecurity = true
  );
  
  -- Count tables without any policies
  SELECT COUNT(*) INTO tables_without_policies
  FROM pg_tables t
  WHERE t.schemaname = 'public'
  AND t.tablename NOT LIKE 'pg_%'
  AND NOT EXISTS (
    SELECT 1 FROM pg_policies p
    WHERE p.tablename = t.tablename
  );
  
  -- Count total policies
  SELECT COUNT(*) INTO total_policies
  FROM pg_policies
  WHERE schemaname = 'public';
  
  RAISE NOTICE 'Total tables: %', total_tables;
  RAISE NOTICE 'Tables with RLS enabled: %', tables_with_rls;
  RAISE NOTICE 'Tables without policies: %', tables_without_policies;
  RAISE NOTICE 'Total RLS policies: %', total_policies;
  
  IF tables_with_rls = total_tables THEN
    RAISE NOTICE '✓ All tables have RLS enabled';
  ELSE
    RAISE WARNING '✗ Some tables do not have RLS enabled';
  END IF;
  
  IF tables_without_policies = 0 THEN
    RAISE NOTICE '✓ All tables have at least one policy';
  ELSE
    RAISE WARNING '✗ % tables have no policies', tables_without_policies;
  END IF;
  
  RAISE NOTICE '=== Policy Count by Table ===';
  
  FOR rec IN
    SELECT 
      t.tablename,
      COUNT(p.policyname) as policy_count
    FROM pg_tables t
    LEFT JOIN pg_policies p ON p.tablename = t.tablename
    WHERE t.schemaname = 'public'
    AND t.tablename NOT LIKE 'pg_%'
    GROUP BY t.tablename
    ORDER BY policy_count DESC, t.tablename
  LOOP
    RAISE NOTICE '%: % policies', rec.tablename, rec.policy_count;
  END LOOP;
END $$;

-- =====================================================
-- PART 9: CREATE HELPER VIEW FOR MONITORING
-- =====================================================

-- Create a view to easily monitor RLS status
CREATE OR REPLACE VIEW rls_status AS
SELECT 
  t.tablename,
  c.relrowsecurity as rls_enabled,
  COUNT(p.policyname) as policy_count,
  array_agg(p.policyname ORDER BY p.policyname) as policies
FROM pg_tables t
JOIN pg_class c ON c.relname = t.tablename
LEFT JOIN pg_policies p ON p.tablename = t.tablename
WHERE t.schemaname = 'public'
AND t.tablename NOT LIKE 'pg_%'
GROUP BY t.tablename, c.relrowsecurity
ORDER BY t.tablename;

COMMENT ON VIEW rls_status IS 
'Monitor RLS status and policy count for all tables. Use: SELECT * FROM rls_status;';

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'RLS VERIFICATION AND HARDENING COMPLETE';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Review the security audit warnings above';
  RAISE NOTICE '2. Test all user flows (user, restaurant, NGO)';
  RAISE NOTICE '3. Monitor query performance with EXPLAIN ANALYZE';
  RAISE NOTICE '4. Use: SELECT * FROM rls_status; to monitor RLS';
  RAISE NOTICE '';
END $$;
