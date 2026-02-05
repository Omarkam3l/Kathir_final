-- =====================================================
-- FULL MIGRATION: REMOVE V1 AND APPLY V2
-- =====================================================

-- ---------- REMOVE V1 ----------

DROP FUNCTION IF EXISTS public.donate_meal(uuid, uuid);

DROP POLICY IF EXISTS "Restaurants can view their own donations" ON free_meal_notifications;
DROP POLICY IF EXISTS "Restaurants can insert their own donations" ON free_meal_notifications;

ALTER TABLE IF EXISTS free_meal_notifications DISABLE ROW LEVEL SECURITY;

DROP TABLE IF EXISTS public.free_meal_notifications CASCADE;

-- ---------- CREATE V2 TABLE ----------

CREATE TABLE IF NOT EXISTS public.free_meal_notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  meal_id uuid NOT NULL,
  restaurant_id uuid NOT NULL,
  original_price numeric(12,2) NOT NULL,
  donated_at timestamp with time zone NOT NULL DEFAULT now(),
  notification_sent boolean NOT NULL DEFAULT false,
  claimed_by uuid NULL,
  claimed_at timestamp with time zone NULL,

  CONSTRAINT free_meal_notifications_pkey PRIMARY KEY (id),
  CONSTRAINT free_meal_notifications_meal_id_fkey
    FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE CASCADE,
  CONSTRAINT free_meal_notifications_restaurant_id_fkey
    FOREIGN KEY (restaurant_id) REFERENCES restaurants (profile_id) ON DELETE CASCADE,
  CONSTRAINT free_meal_notifications_claimed_by_fkey
    FOREIGN KEY (claimed_by) REFERENCES profiles (id) ON DELETE SET NULL
);

-- ---------- INDEXES ----------

CREATE INDEX IF NOT EXISTS idx_free_meal_notifications_meal_id
  ON free_meal_notifications(meal_id);

CREATE INDEX IF NOT EXISTS idx_free_meal_notifications_restaurant_id
  ON free_meal_notifications(restaurant_id);

CREATE INDEX IF NOT EXISTS idx_free_meal_notifications_donated_at
  ON free_meal_notifications(donated_at DESC);

CREATE INDEX IF NOT EXISTS idx_free_meal_notifications_claimed_by
  ON free_meal_notifications(claimed_by);

-- ---------- ENABLE RLS ----------

ALTER TABLE free_meal_notifications ENABLE ROW LEVEL SECURITY;

-- ---------- POLICIES ----------

CREATE POLICY "Restaurants can view their own donations"
ON free_meal_notifications
FOR SELECT
TO authenticated
USING (restaurant_id = auth.uid());

CREATE POLICY "Restaurants can insert their own donations"
ON free_meal_notifications
FOR INSERT
TO authenticated
WITH CHECK (restaurant_id = auth.uid());

CREATE POLICY "Users can view free meal notifications"
ON free_meal_notifications
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Users can claim free meals"
ON free_meal_notifications
FOR UPDATE
TO authenticated
USING (claimed_by IS NULL OR claimed_by = auth.uid())
WITH CHECK (claimed_by = auth.uid());

-- ---------- DONATE FUNCTION (V2) ----------

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
  SELECT * INTO v_meal_record
  FROM meals
  WHERE id = p_meal_id
    AND restaurant_id = p_restaurant_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Meal not found or unauthorized';
  END IF;

  v_original_price := v_meal_record.discounted_price;

  UPDATE meals
  SET discounted_price = 0,
      original_price = 0,
      updated_at = now()
  WHERE id = p_meal_id;

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

  FOR v_user IN
    SELECT id FROM profiles WHERE role = 'user'
  LOOP
    INSERT INTO category_notifications (
      user_id,
      meal_id,
      restaurant_id,
      category,
      message,
      is_read
    )
    VALUES (
      v_user.id,
      p_meal_id,
      p_restaurant_id,
      v_meal_record.category,
      'Free meal available! ' || v_meal_record.title || ' is now free to claim!',
      false
    );

    v_notification_count := v_notification_count + 1;
  END LOOP;

  RETURN json_build_object(
    'success', true,
    'donation_id', v_donation_id,
    'meal_id', p_meal_id,
    'original_price', v_original_price,
    'notifications_sent', v_notification_count
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.donate_meal(uuid, uuid) TO authenticated;

-- =====================================================
-- COMMENTS
-- =====================================================
COMMENT ON TABLE free_meal_notifications IS 'Tracks meals donated by restaurants (price set to 0)';
COMMENT ON FUNCTION public.donate_meal IS 'Donates a meal by setting price to 0 and notifying all users';
