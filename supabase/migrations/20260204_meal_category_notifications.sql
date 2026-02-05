-- =====================================================
-- MEAL CATEGORY NOTIFICATIONS SYSTEM
-- =====================================================
-- This migration creates a system for users to subscribe
-- to notifications for specific meal categories
-- =====================================================

-- =====================================================
-- TABLE: user_category_preferences
-- =====================================================

CREATE TABLE IF NOT EXISTS public.user_category_preferences (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  category text NOT NULL,
  notifications_enabled boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NULL DEFAULT now(),
  updated_at timestamp with time zone NULL DEFAULT now(),
  
  CONSTRAINT user_category_preferences_pkey PRIMARY KEY (id),
  CONSTRAINT user_category_preferences_user_category_unique UNIQUE (user_id, category),
  CONSTRAINT user_category_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT user_category_preferences_category_check CHECK (
    category = ANY(ARRAY[
      'Meals'::text,
      'Bakery'::text,
      'Meat & Poultry'::text,
      'Seafood'::text,
      'Vegetables'::text,
      'Desserts'::text,
      'Groceries'::text
    ])
  )
) TABLESPACE pg_default;

-- Indexes for user_category_preferences
CREATE INDEX IF NOT EXISTS idx_user_category_preferences_user_id ON public.user_category_preferences USING btree (user_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_user_category_preferences_category ON public.user_category_preferences USING btree (category) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_user_category_preferences_notifications_enabled ON public.user_category_preferences USING btree (notifications_enabled) TABLESPACE pg_default;

-- Trigger for updated_at
CREATE TRIGGER trg_update_user_category_preferences_updated_at 
BEFORE UPDATE ON user_category_preferences 
FOR EACH ROW 
EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- TABLE: category_notifications (for tracking sent notifications)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.category_notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  meal_id uuid NOT NULL,
  category text NOT NULL,
  sent_at timestamp with time zone NULL DEFAULT now(),
  is_read boolean NOT NULL DEFAULT false,
  
  CONSTRAINT category_notifications_pkey PRIMARY KEY (id),
  CONSTRAINT category_notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT category_notifications_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- Indexes for category_notifications
CREATE INDEX IF NOT EXISTS idx_category_notifications_user_id ON public.category_notifications USING btree (user_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_category_notifications_meal_id ON public.category_notifications USING btree (meal_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_category_notifications_is_read ON public.category_notifications USING btree (is_read) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_category_notifications_sent_at ON public.category_notifications USING btree (sent_at DESC) TABLESPACE pg_default;

-- =====================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================

ALTER TABLE user_category_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE category_notifications ENABLE ROW LEVEL SECURITY;

-- user_category_preferences Policies
CREATE POLICY "Users can view their own category preferences"
ON user_category_preferences FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own category preferences"
ON user_category_preferences FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own category preferences"
ON user_category_preferences FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own category preferences"
ON user_category_preferences FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- category_notifications Policies
CREATE POLICY "Users can view their own notifications"
ON category_notifications FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can update their own notifications"
ON category_notifications FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- =====================================================
-- FUNCTION: Notify users when new meal matches their preferences
-- =====================================================

CREATE OR REPLACE FUNCTION notify_category_subscribers()
RETURNS TRIGGER AS $$
BEGIN
  -- Only notify for new active meals
  IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.status != 'active' AND NEW.status = 'active'))
     AND NEW.status = 'active'
     AND NEW.quantity_available > 0
     AND NEW.expiry_date > NOW()
  THEN
    -- Insert notifications for all users subscribed to this category
    INSERT INTO category_notifications (user_id, meal_id, category)
    SELECT 
      ucp.user_id,
      NEW.id,
      NEW.category
    FROM user_category_preferences ucp
    WHERE ucp.category = NEW.category
      AND ucp.notifications_enabled = true
      AND ucp.user_id != NEW.restaurant_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to notify subscribers when new meal is added
DROP TRIGGER IF EXISTS trg_notify_category_subscribers ON meals;
CREATE TRIGGER trg_notify_category_subscribers
AFTER INSERT OR UPDATE ON meals
FOR EACH ROW
EXECUTE FUNCTION notify_category_subscribers();

-- =====================================================
-- VIEW: user_notifications_summary
-- =====================================================

CREATE OR REPLACE VIEW user_notifications_summary AS
SELECT 
  cn.user_id,
  cn.category,
  COUNT(*) as unread_count,
  MAX(cn.sent_at) as latest_notification_at
FROM category_notifications cn
WHERE cn.is_read = false
GROUP BY cn.user_id, cn.category;

-- Grant access to view
GRANT SELECT ON user_notifications_summary TO authenticated;

-- =====================================================
-- SUMMARY
-- =====================================================
-- Created tables: 
--   - user_category_preferences (stores user's category subscriptions)
--   - category_notifications (tracks notifications sent to users)
-- Created trigger to automatically notify users when new meals match their preferences
-- Created RLS policies for security
-- Created view for notification summary
-- 
-- HOW IT WORKS:
-- 1. Users subscribe to meal categories they're interested in
-- 2. When a restaurant adds a new meal, the trigger checks for subscribers
-- 3. Notifications are created for all subscribed users
-- 4. Users can view their notifications in the app
-- 5. Notifications can be marked as read
-- =====================================================
