-- =====================================================
-- FREE MEAL NOTIFICATIONS - SEPARATE SYSTEM
-- =====================================================
-- Free meal notifications are different from category notifications
-- They deserve their own table and special treatment in the UI
-- =====================================================

-- Create free_meal_user_notifications table
CREATE TABLE IF NOT EXISTS public.free_meal_user_notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  meal_id uuid NOT NULL,
  donation_id uuid NOT NULL,
  restaurant_id uuid NOT NULL,
  sent_at timestamp with time zone NOT NULL DEFAULT now(),
  is_read boolean NOT NULL DEFAULT false,
  claimed boolean NOT NULL DEFAULT false,
  claimed_at timestamp with time zone NULL,
  
  CONSTRAINT free_meal_user_notifications_pkey PRIMARY KEY (id),
  CONSTRAINT free_meal_user_notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
  CONSTRAINT free_meal_user_notifications_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE,
  CONSTRAINT free_meal_user_notifications_donation_id_fkey FOREIGN KEY (donation_id) REFERENCES free_meal_notifications(id) ON DELETE CASCADE,
  CONSTRAINT free_meal_user_notifications_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES restaurants(profile_id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_free_meal_user_notifications_user_id ON public.free_meal_user_notifications USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_free_meal_user_notifications_meal_id ON public.free_meal_user_notifications USING btree (meal_id);
CREATE INDEX IF NOT EXISTS idx_free_meal_user_notifications_is_read ON public.free_meal_user_notifications USING btree (is_read);
CREATE INDEX IF NOT EXISTS idx_free_meal_user_notifications_sent_at ON public.free_meal_user_notifications USING btree (sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_free_meal_user_notifications_claimed ON public.free_meal_user_notifications USING btree (claimed);

-- Enable RLS
ALTER TABLE free_meal_user_notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own free meal notifications"
ON free_meal_user_notifications FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can update their own free meal notifications"
ON free_meal_user_notifications FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- =====================================================
-- UPDATE DONATE_MEAL FUNCTION
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

  -- Create FREE MEAL notifications for all users AND NGOs (separate from category notifications)
  FOR v_user IN
    SELECT id FROM profiles WHERE role IN ('user', 'ngo')
  LOOP
    INSERT INTO free_meal_user_notifications (
      user_id,
      meal_id,
      donation_id,
      restaurant_id
    )
    VALUES (
      v_user.id,
      p_meal_id,
      v_donation_id,
      p_restaurant_id
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
    'message', 'Meal donated successfully!'
  );

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error donating meal: %', SQLERRM;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.donate_meal(uuid, uuid) TO authenticated;

-- =====================================================
-- HELPER FUNCTION: Get user's free meal notifications
-- =====================================================
CREATE OR REPLACE FUNCTION public.get_free_meal_notifications(
  p_user_id uuid,
  p_limit integer DEFAULT 50
)
RETURNS TABLE(
  id uuid,
  meal_id uuid,
  meal_title text,
  meal_image_url text,
  meal_category text,
  meal_quantity integer,
  restaurant_id uuid,
  restaurant_name text,
  restaurant_logo text,
  sent_at timestamp with time zone,
  is_read boolean,
  claimed boolean,
  claimed_at timestamp with time zone
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    fmn.id,
    fmn.meal_id,
    m.title as meal_title,
    m.image_url as meal_image_url,
    m.category as meal_category,
    m.quantity_available as meal_quantity,
    fmn.restaurant_id,
    r.restaurant_name,
    p.avatar_url as restaurant_logo,
    fmn.sent_at,
    fmn.is_read,
    fmn.claimed,
    fmn.claimed_at
  FROM free_meal_user_notifications fmn
  INNER JOIN meals m ON fmn.meal_id = m.id
  INNER JOIN restaurants r ON fmn.restaurant_id = r.profile_id
  LEFT JOIN profiles p ON r.profile_id = p.id
  WHERE fmn.user_id = p_user_id
  ORDER BY fmn.sent_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_free_meal_notifications(uuid, integer) TO authenticated;

-- =====================================================
-- COMMENTS
-- =====================================================
COMMENT ON TABLE free_meal_user_notifications IS 'Special notifications for free meal donations - separate from category notifications';
COMMENT ON FUNCTION public.get_free_meal_notifications IS 'Get user free meal notifications with meal and restaurant details';
COMMENT ON FUNCTION public.donate_meal IS 'Donates a meal and creates special free meal notifications for all users';
