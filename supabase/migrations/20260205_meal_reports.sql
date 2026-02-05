-- =====================================================
-- MEAL REPORTS SYSTEM
-- =====================================================
-- This migration creates a system for users to report
-- issues with meals (wrong info, quality, etc.)
-- =====================================================

-- =====================================================
-- TABLE: meal_reports
-- =====================================================

CREATE TABLE IF NOT EXISTS public.meal_reports (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  meal_id uuid NOT NULL,
  restaurant_id uuid NOT NULL,
  issue_type text NOT NULL,
  details text NULL,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamp with time zone NULL DEFAULT now(),
  resolved_at timestamp with time zone NULL,
  admin_notes text NULL,
  
  CONSTRAINT meal_reports_pkey PRIMARY KEY (id),
  CONSTRAINT meal_reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT meal_reports_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE,
  CONSTRAINT meal_reports_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT meal_reports_issue_type_check CHECK (
    issue_type = ANY(ARRAY[
      'Wrong information'::text,
      'Quality concerns'::text,
      'Meal not available'::text,
      'Incorrect pricing'::text,
      'Location issue'::text,
      'Other'::text
    ])
  ),
  CONSTRAINT meal_reports_status_check CHECK (
    status = ANY(ARRAY[
      'pending'::text,
      'reviewing'::text,
      'resolved'::text,
      'dismissed'::text
    ])
  )
) TABLESPACE pg_default;

-- Indexes for meal_reports
CREATE INDEX IF NOT EXISTS idx_meal_reports_user_id ON public.meal_reports USING btree (user_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_meal_reports_meal_id ON public.meal_reports USING btree (meal_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_meal_reports_restaurant_id ON public.meal_reports USING btree (restaurant_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_meal_reports_status ON public.meal_reports USING btree (status) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_meal_reports_created_at ON public.meal_reports USING btree (created_at DESC) TABLESPACE pg_default;

-- =====================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================

ALTER TABLE meal_reports ENABLE ROW LEVEL SECURITY;

-- Users can view their own reports
CREATE POLICY "Users can view their own reports"
ON meal_reports FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can insert their own reports
CREATE POLICY "Users can insert their own reports"
ON meal_reports FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Restaurants can view reports about their meals
CREATE POLICY "Restaurants can view reports about their meals"
ON meal_reports FOR SELECT
TO authenticated
USING (restaurant_id = auth.uid());

-- =====================================================
-- VIEW: meal_reports_summary
-- =====================================================

CREATE OR REPLACE VIEW meal_reports_summary AS
SELECT 
  mr.restaurant_id,
  COUNT(*) as total_reports,
  COUNT(*) FILTER (WHERE mr.status = 'pending') as pending_reports,
  COUNT(*) FILTER (WHERE mr.status = 'resolved') as resolved_reports,
  MAX(mr.created_at) as latest_report_at
FROM meal_reports mr
GROUP BY mr.restaurant_id;

-- Grant access to view
GRANT SELECT ON meal_reports_summary TO authenticated;

-- =====================================================
-- SUMMARY
-- =====================================================
-- Created table: meal_reports
-- Created RLS policies for users and restaurants
-- Created view for report summary
-- 
-- HOW IT WORKS:
-- 1. Users can report issues with meals
-- 2. Reports are stored with issue type and optional details
-- 3. Restaurants can view reports about their meals
-- 4. Admins can review and resolve reports
-- =====================================================
