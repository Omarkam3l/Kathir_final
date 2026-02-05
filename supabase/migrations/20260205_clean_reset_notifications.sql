-- =====================================================
-- CLEAN RESET: Notification System
-- =====================================================
-- This script completely resets the notification system
-- Removes all test data and recreates everything cleanly
-- =====================================================

-- Step 1: Drop existing trigger and function
DROP TRIGGER IF EXISTS trg_notify_category_subscribers ON meals;
DROP FUNCTION IF EXISTS notify_category_subscribers() CASCADE;

-- Step 2: Clear all test notification data (keep user preferences)
DELETE FROM category_notifications;

-- Step 3: Recreate the trigger function with correct syntax
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

-- Step 4: Recreate the trigger
CREATE TRIGGER trg_notify_category_subscribers
AFTER INSERT OR UPDATE ON meals
FOR EACH ROW
EXECUTE FUNCTION notify_category_subscribers();

-- Step 5: Grant necessary permissions
-- Allow the trigger to insert notifications
GRANT INSERT ON category_notifications TO authenticated;
GRANT SELECT ON user_category_preferences TO authenticated;

-- Step 6: Ensure RLS policies allow trigger operations
-- The trigger runs with the privileges of the user who performs the INSERT/UPDATE
-- But we need to ensure the system can insert notifications

-- Create a policy that allows the trigger to insert notifications
DROP POLICY IF EXISTS "System can insert notifications for triggers" ON category_notifications;
CREATE POLICY "System can insert notifications for triggers"
ON category_notifications FOR INSERT
TO authenticated
WITH CHECK (true);

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- Run these queries after applying this migration to verify:

-- 1. Check trigger exists and is enabled
-- SELECT tgname, tgenabled FROM pg_trigger WHERE tgname = 'trg_notify_category_subscribers';

-- 2. Check function exists
-- SELECT proname FROM pg_proc WHERE proname = 'notify_category_subscribers';

-- 3. Verify notification count is 0 (all test data cleared)
-- SELECT COUNT(*) FROM category_notifications;

-- 4. Check your category preferences are still there
-- SELECT * FROM user_category_preferences WHERE user_id = auth.uid();

-- =====================================================
-- TESTING INSTRUCTIONS
-- =====================================================
-- After applying this migration:
-- 1. Log in as a USER account
-- 2. Go to Favorites > Meal Categories tab
-- 3. Subscribe to at least one category (e.g., "Meals")
-- 4. Log out and log in as a RESTAURANT account
-- 5. Add a new meal with:
--    - category matching what you subscribed to
--    - status will be 'active' (automatically set in add_meal_screen.dart)
--    - quantity_available > 0
--    - expiry_date in the future
-- 6. Log out and log back in as the USER account
-- 7. Click the notifications icon - you should see the new notification!
-- =====================================================

-- =====================================================
-- SUMMARY
-- =====================================================
-- ✅ Dropped old trigger and function
-- ✅ Cleared all test notification data
-- ✅ Recreated trigger function with correct $$ syntax
-- ✅ Recreated trigger on meals table
-- ✅ Added explicit permissions for trigger operations
-- ✅ Added RLS policy to allow system to insert notifications
-- ✅ Kept user category preferences intact
-- =====================================================
