-- =====================================================
-- FIX: Update donate_meal function to work with actual schema
-- =====================================================
-- The category_notifications table only has:
-- id, user_id, meal_id, category, sent_at, is_read
-- It does NOT have restaurant_id or message columns
-- =====================================================

CREATE OR REPLACE FUNCTION public.donate_meal(
  p_meal_id uuid,
  p_restaurant_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_meal_record RECORD;
  v_original_price numeric(12,2);
  v_donation_id uuid;
  v_notification_count integer := 0;
  v_user RECORD;
BEGIN
  -- Get meal details
  SELECT * INTO v_meal_record
  FROM meals
  WHERE id = p_meal_id
    AND restaurant_id = p_restaurant_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Meal not found or unauthorized';
  END IF;

  -- Store original price
  v_original_price := v_meal_record.discounted_price;

  -- Update meal price to 0
  UPDATE meals
  SET discounted_price = 0,
      original_price = 0,
      updated_at = now()
  WHERE id = p_meal_id;

  -- Create donation record
  INSERT INTO free_meal_notifications (
    meal_id,
    restaurant_id,
    original_price,
    notification_sent
  )
  VALUES (
    p_meal_id,
    p_restaurant_id,
    v_original_price,
    true
  )
  RETURNING id INTO v_donation_id;

  -- Create notifications for all users (role = 'user', not 'restaurant' or 'ngo')
  -- Using the actual category_notifications schema
  FOR v_user IN
    SELECT id FROM profiles WHERE role = 'user'
  LOOP
    INSERT INTO category_notifications (
      user_id,
      meal_id,
      category
    )
    VALUES (
      v_user.id,
      p_meal_id,
      v_meal_record.category
    );

    v_notification_count := v_notification_count + 1;
  END LOOP;

  -- Return success response
  RETURN json_build_object(
    'success', true,
    'donation_id', v_donation_id,
    'meal_id', p_meal_id,
    'original_price', v_original_price,
    'notifications_sent', v_notification_count,
    'message', 'Meal donated successfully! ' || v_notification_count || ' users notified.'
  );

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error donating meal: %', SQLERRM;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.donate_meal(uuid, uuid) TO authenticated;

COMMENT ON FUNCTION public.donate_meal IS 'Donates a meal by setting price to 0 and notifying all users (role=user)';
