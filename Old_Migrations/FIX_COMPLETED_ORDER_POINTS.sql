-- =====================================================
-- FIX: Award Points for Completed Orders
-- =====================================================
-- This fixes the issue where completed orders didn't award points
-- because the loyalty profile was missing

-- Step 1: Create loyalty profile if missing
INSERT INTO user_loyalty (user_id)
SELECT auth.uid()
WHERE NOT EXISTS (
  SELECT 1 FROM user_loyalty WHERE user_id = auth.uid()
)
AND EXISTS (
  SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'user'
);

-- Step 2: Check your completed orders that are missing points
SELECT 
  o.id,
  o.order_number,
  o.status,
  o.total_amount,
  o.delivery_type,
  o.ngo_id,
  o.created_at,
  FLOOR(o.total_amount) as base_points,
  CASE 
    WHEN o.delivery_type = 'donation' AND o.ngo_id IS NOT NULL 
    THEN FLOOR(o.total_amount) * 2 
    ELSE FLOOR(o.total_amount) 
  END as points_with_bonus,
  CASE 
    WHEN EXISTS (SELECT 1 FROM loyalty_transactions lt WHERE lt.order_id = o.id)
    THEN '✓ Points Already Awarded'
    ELSE '✗ Missing Points - Will Award'
  END as points_status
FROM orders o
WHERE o.user_id = auth.uid()
  AND o.status = 'completed'
ORDER BY o.created_at DESC;

-- Step 3: Manually award points for all completed orders without points
DO $$
DECLARE
  v_order RECORD;
  v_points int;
  v_is_donation boolean;
  v_user_role text;
BEGIN
  -- Get user role
  SELECT role INTO v_user_role FROM profiles WHERE id = auth.uid();
  
  -- Only process if user is a regular user
  IF v_user_role = 'user' THEN
    -- Loop through completed orders without points
    FOR v_order IN 
      SELECT 
        o.id as order_id,
        o.user_id,
        o.order_number,
        o.total_amount,
        o.delivery_type,
        o.ngo_id
      FROM orders o
      WHERE o.user_id = auth.uid()
        AND o.status = 'completed'
        AND NOT EXISTS (
          SELECT 1 FROM loyalty_transactions lt 
          WHERE lt.order_id = o.id 
            AND lt.transaction_type = 'earned'
        )
    LOOP
      -- Calculate points: 1 point per EGP
      v_points := FLOOR(v_order.total_amount);
      
      -- Check if it's a donation (double points)
      v_is_donation := (v_order.delivery_type = 'donation' AND v_order.ngo_id IS NOT NULL);
      IF v_is_donation THEN
        v_points := v_points * 2;
      END IF;
      
      -- Award points
      INSERT INTO loyalty_transactions (
        user_id,
        points,
        transaction_type,
        source,
        order_id,
        description
      ) VALUES (
        v_order.user_id,
        v_points,
        'earned',
        CASE WHEN v_is_donation THEN 'donation' ELSE 'order' END,
        v_order.order_id,
        CASE 
          WHEN v_is_donation THEN 'Earned ' || v_points || ' points from donation (2x bonus!)'
          ELSE 'Earned ' || v_points || ' points from order'
        END
      );
      
      -- Update loyalty profile
      UPDATE user_loyalty
      SET 
        total_points = total_points + v_points,
        available_points = available_points + v_points,
        lifetime_points = lifetime_points + v_points,
        total_orders = total_orders + 1,
        total_donations = total_donations + CASE WHEN v_is_donation THEN 1 ELSE 0 END,
        updated_at = NOW()
      WHERE user_id = v_order.user_id;
      
      -- Check and award badges
      PERFORM check_and_award_badges(v_order.user_id);
      
      -- Check and update tier
      PERFORM update_user_tier(v_order.user_id);
      
      RAISE NOTICE '✓ Awarded % points for order %', v_points, v_order.order_number;
    END LOOP;
  END IF;
END $$;

-- Step 4: Verify points were awarded
SELECT 
  lt.points,
  lt.transaction_type,
  lt.source,
  lt.description,
  lt.created_at,
  o.order_number,
  o.total_amount
FROM loyalty_transactions lt
JOIN orders o ON o.id = lt.order_id
WHERE lt.user_id = auth.uid()
ORDER BY lt.created_at DESC;

-- Step 5: Check your updated loyalty profile
SELECT 
  total_points,
  available_points,
  lifetime_points,
  current_tier,
  total_orders,
  total_donations,
  created_at,
  updated_at
FROM user_loyalty
WHERE user_id = auth.uid();

-- Step 6: Check any badges you earned
SELECT 
  badge_type,
  badge_name,
  badge_description,
  icon,
  earned_at
FROM user_badges
WHERE user_id = auth.uid()
ORDER BY earned_at DESC;
