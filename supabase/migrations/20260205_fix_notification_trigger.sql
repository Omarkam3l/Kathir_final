-- =====================================================
-- FIX: Notification Trigger Function
-- =====================================================
-- This fixes the syntax error in the trigger function
-- by using proper $$ delimiters
-- =====================================================

-- Drop and recreate the function with correct syntax
DROP FUNCTION IF EXISTS notify_category_subscribers() CASCADE;

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

-- Recreate the trigger
DROP TRIGGER IF EXISTS trg_notify_category_subscribers ON meals;
CREATE TRIGGER trg_notify_category_subscribers
AFTER INSERT OR UPDATE ON meals
FOR EACH ROW
EXECUTE FUNCTION notify_category_subscribers();

-- Grant necessary permissions for the trigger to work
GRANT INSERT ON category_notifications TO authenticated;
GRANT SELECT ON user_category_preferences TO authenticated;

-- =====================================================
-- SUMMARY
-- =====================================================
-- Fixed the trigger function syntax error ($ -> $$)
-- Recreated the trigger
-- Added explicit permissions for the trigger to insert notifications
-- =====================================================
