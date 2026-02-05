-- =====================================================
-- ALTERNATIVE APPROACH: Notification via RPC Function
-- =====================================================
-- Instead of relying on triggers, we'll create an RPC
-- function that the Flutter app can call after inserting
-- a meal. This is more reliable and easier to debug.
-- =====================================================

-- Create a function that creates notifications for a meal
CREATE OR REPLACE FUNCTION create_meal_notifications(
  p_meal_id uuid,
  p_category text,
  p_restaurant_id uuid
)
RETURNS TABLE(notifications_created int) AS $$
DECLARE
  v_count int := 0;
BEGIN
  -- Insert notifications for all subscribed users
  INSERT INTO category_notifications (user_id, meal_id, category)
  SELECT 
    ucp.user_id,
    p_meal_id,
    p_category
  FROM user_category_preferences ucp
  WHERE ucp.category = p_category
    AND ucp.notifications_enabled = true
    AND ucp.user_id != p_restaurant_id; -- Don't notify restaurant owner
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  
  RETURN QUERY SELECT v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_meal_notifications(uuid, text, uuid) TO authenticated;

-- =====================================================
-- HOW TO USE IN FLUTTER
-- =====================================================
-- After inserting a meal, call this function:
--
-- final result = await _supabase.rpc('create_meal_notifications', params: {
--   'p_meal_id': mealId,
--   'p_category': category,
--   'p_restaurant_id': restaurantId,
-- });
--
-- debugPrint('Created ${result[0]['notifications_created']} notifications');
-- =====================================================

-- =====================================================
-- BENEFITS OF THIS APPROACH
-- =====================================================
-- ✅ More reliable than triggers
-- ✅ Easier to debug (you can see the result)
-- ✅ Works around RLS policy issues
-- ✅ SECURITY DEFINER means it runs with elevated privileges
-- ✅ You can log the number of notifications created
-- =====================================================
