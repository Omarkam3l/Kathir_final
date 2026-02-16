-- =====================================================
-- ORDER ISSUES REPORTING SYSTEM
-- =====================================================
-- Allows users to report issues with completed orders
-- Includes photo upload capability for evidence

-- =====================================================
-- ORDER ISSUES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS order_issues (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  restaurant_id uuid NOT NULL REFERENCES restaurants(profile_id) ON DELETE CASCADE,
  issue_type text NOT NULL CHECK (issue_type IN (
    'food_quality',
    'wrong_order',
    'missing_items',
    'cold_food',
    'packaging_issue',
    'other'
  )),
  description text NOT NULL,
  photo_url text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending',
    'under_review',
    'resolved',
    'rejected'
  )),
  resolution_notes text,
  refund_amount numeric(10,2),
  resolved_at timestamptz,
  resolved_by uuid REFERENCES profiles(id),
  created_at timestamptz NOT NULL DEFAULT NOW(),
  updated_at timestamptz NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_order_issues_order ON order_issues(order_id);
CREATE INDEX idx_order_issues_user ON order_issues(user_id, created_at DESC);
CREATE INDEX idx_order_issues_restaurant ON order_issues(restaurant_id, status, created_at DESC);
CREATE INDEX idx_order_issues_status ON order_issues(status, created_at DESC);

-- =====================================================
-- RLS POLICIES
-- =====================================================
ALTER TABLE order_issues ENABLE ROW LEVEL SECURITY;

-- Users can view their own issues
CREATE POLICY "Users can view own issues"
  ON order_issues FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Users can create issues for their own orders
CREATE POLICY "Users can create issues for own orders"
  ON order_issues FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM orders o
      WHERE o.id = order_id
        AND o.user_id = auth.uid()
        AND o.status IN ('completed', 'delivered')
    )
  );

-- Restaurants can view issues for their orders
CREATE POLICY "Restaurants can view their issues"
  ON order_issues FOR SELECT
  TO authenticated
  USING (restaurant_id = auth.uid());

-- Restaurants can update their issues
CREATE POLICY "Restaurants can update their issues"
  ON order_issues FOR UPDATE
  TO authenticated
  USING (restaurant_id = auth.uid())
  WITH CHECK (restaurant_id = auth.uid());

-- Admins can manage all issues
CREATE POLICY "Admins can manage all issues"
  ON order_issues FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- STORAGE BUCKET FOR ISSUE PHOTOS
-- =====================================================
-- Create storage bucket for order issue photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('order-issues', 'order-issues', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for order-issues bucket
CREATE POLICY "Users can upload issue photos"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'order-issues'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can view issue photos"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'order-issues');

CREATE POLICY "Users can delete own issue photos"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'order-issues'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function: Notify restaurant of new issue
CREATE OR REPLACE FUNCTION notify_restaurant_of_issue()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_user_name text;
  v_order_number text;
  v_notifications_exists boolean;
BEGIN
  -- Check if notifications table exists
  SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'notifications'
  ) INTO v_notifications_exists;
  
  -- Only create notification if table exists
  IF v_notifications_exists THEN
    -- Get user name and order number
    SELECT p.full_name, o.order_number
    INTO v_user_name, v_order_number
    FROM profiles p
    JOIN orders o ON o.id = NEW.order_id
    WHERE p.id = NEW.user_id;
    
    -- Create notification for restaurant (restaurant_id is already the profile_id)
    INSERT INTO notifications (
      user_id,
      title,
      message,
      type,
      data
    ) VALUES (
      NEW.restaurant_id,
      'Order Issue Reported',
      v_user_name || ' reported an issue with order #' || v_order_number,
      'order_issue',
      jsonb_build_object(
        'issue_id', NEW.id,
        'order_id', NEW.order_id,
        'issue_type', NEW.issue_type
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$;

-- Trigger: Notify restaurant when issue is created
DROP TRIGGER IF EXISTS trigger_notify_restaurant_issue ON order_issues;
CREATE TRIGGER trigger_notify_restaurant_issue
  AFTER INSERT ON order_issues
  FOR EACH ROW
  EXECUTE FUNCTION notify_restaurant_of_issue();

-- Function: Update timestamp on issue update
CREATE OR REPLACE FUNCTION update_order_issue_timestamp()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  
  -- Set resolved_at when status changes to resolved
  IF NEW.status = 'resolved' AND OLD.status != 'resolved' THEN
    NEW.resolved_at = NOW();
    NEW.resolved_by = auth.uid();
  END IF;
  
  RETURN NEW;
END;
$$;

-- Trigger: Update timestamp
DROP TRIGGER IF EXISTS trigger_update_issue_timestamp ON order_issues;
CREATE TRIGGER trigger_update_issue_timestamp
  BEFORE UPDATE ON order_issues
  FOR EACH ROW
  EXECUTE FUNCTION update_order_issue_timestamp();

-- =====================================================
-- COMMENTS
-- =====================================================
COMMENT ON TABLE order_issues IS 'User-reported issues with completed orders';
COMMENT ON COLUMN order_issues.issue_type IS 'Type of issue: food_quality, wrong_order, missing_items, cold_food, packaging_issue, other';
COMMENT ON COLUMN order_issues.status IS 'Issue status: pending, under_review, resolved, rejected';
COMMENT ON COLUMN order_issues.photo_url IS 'URL to uploaded photo evidence of the issue';
