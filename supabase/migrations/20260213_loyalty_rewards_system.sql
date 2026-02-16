-- =====================================================
-- LOYALTY & REWARDS SYSTEM
-- =====================================================
-- Complete loyalty program with points, tiers, badges, and rewards
-- Users earn points from orders and can redeem them for rewards

-- =====================================================
-- USER LOYALTY PROFILE
-- =====================================================
CREATE TABLE IF NOT EXISTS user_loyalty (
  user_id uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  total_points int NOT NULL DEFAULT 0,
  available_points int NOT NULL DEFAULT 0,
  lifetime_points int NOT NULL DEFAULT 0,
  current_tier text NOT NULL DEFAULT 'bronze' CHECK (current_tier IN ('bronze', 'silver', 'gold', 'platinum')),
  total_orders int NOT NULL DEFAULT 0,
  total_donations int NOT NULL DEFAULT 0,
  meals_rescued int NOT NULL DEFAULT 0,
  co2_saved numeric(10,2) NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT NOW(),
  updated_at timestamptz NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_user_loyalty_tier ON user_loyalty(current_tier);
CREATE INDEX idx_user_loyalty_points ON user_loyalty(available_points DESC);

-- =====================================================
-- POINTS TRANSACTIONS
-- =====================================================
CREATE TABLE IF NOT EXISTS loyalty_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  points int NOT NULL,
  transaction_type text NOT NULL CHECK (transaction_type IN ('earned', 'redeemed', 'expired', 'bonus')),
  source text NOT NULL CHECK (source IN ('order', 'donation', 'referral', 'bonus', 'reward_redemption')),
  order_id uuid REFERENCES orders(id) ON DELETE SET NULL,
  reward_id uuid,
  description text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_loyalty_transactions_user ON loyalty_transactions(user_id, created_at DESC);
CREATE INDEX idx_loyalty_transactions_order ON loyalty_transactions(order_id);

-- =====================================================
-- BADGES
-- =====================================================
CREATE TABLE IF NOT EXISTS user_badges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  badge_type text NOT NULL CHECK (badge_type IN (
    'food_rescuer', 'ngo_supporter', 'eco_warrior', 'first_order', 
    'loyal_customer', 'top_donor', 'community_hero', 'early_adopter'
  )),
  badge_name text NOT NULL,
  badge_description text NOT NULL,
  icon text NOT NULL,
  earned_at timestamptz NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, badge_type)
);

-- Index
CREATE INDEX idx_user_badges_user ON user_badges(user_id, earned_at DESC);

-- =====================================================
-- AVAILABLE REWARDS
-- =====================================================
CREATE TABLE IF NOT EXISTS rewards_catalog (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reward_type text NOT NULL CHECK (reward_type IN ('discount', 'free_delivery', 'donation', 'priority_support', 'special_offer')),
  title text NOT NULL,
  description text NOT NULL,
  points_cost int NOT NULL,
  discount_percentage int,
  discount_amount numeric(10,2),
  min_tier text CHECK (min_tier IN ('bronze', 'silver', 'gold', 'platinum')),
  is_active boolean NOT NULL DEFAULT true,
  valid_days int NOT NULL DEFAULT 30,
  icon text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT NOW()
);

-- Index
CREATE INDEX idx_rewards_catalog_active ON rewards_catalog(is_active, points_cost);

-- =====================================================
-- USER REDEEMED REWARDS
-- =====================================================
CREATE TABLE IF NOT EXISTS user_rewards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reward_id uuid NOT NULL REFERENCES rewards_catalog(id) ON DELETE CASCADE,
  transaction_id uuid REFERENCES loyalty_transactions(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'used', 'expired')),
  redeemed_at timestamptz NOT NULL DEFAULT NOW(),
  expires_at timestamptz NOT NULL,
  used_at timestamptz,
  order_id uuid REFERENCES orders(id) ON DELETE SET NULL
);

-- Indexes
CREATE INDEX idx_user_rewards_user ON user_rewards(user_id, status, expires_at);
CREATE INDEX idx_user_rewards_status ON user_rewards(status, expires_at);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- User Loyalty
ALTER TABLE user_loyalty ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own loyalty profile"
  ON user_loyalty FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "System can manage loyalty profiles"
  ON user_loyalty FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Loyalty Transactions
ALTER TABLE loyalty_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own transactions"
  ON loyalty_transactions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "System can manage transactions"
  ON loyalty_transactions FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- User Badges
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own badges"
  ON user_badges FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "System can manage badges"
  ON user_badges FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Rewards Catalog
ALTER TABLE rewards_catalog ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active rewards"
  ON rewards_catalog FOR SELECT
  TO authenticated
  USING (is_active = true);

CREATE POLICY "System can manage rewards catalog"
  ON rewards_catalog FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- User Rewards
ALTER TABLE user_rewards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own rewards"
  ON user_rewards FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "System can manage user rewards"
  ON user_rewards FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function: Initialize loyalty profile for new user
CREATE OR REPLACE FUNCTION initialize_user_loyalty()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Only for regular users, not restaurants or NGOs
  IF NEW.role = 'user' THEN
    INSERT INTO user_loyalty (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Trigger: Create loyalty profile on user signup
DROP TRIGGER IF EXISTS trigger_initialize_loyalty ON profiles;
CREATE TRIGGER trigger_initialize_loyalty
  AFTER INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION initialize_user_loyalty();

-- Function: Award points for completed order
CREATE OR REPLACE FUNCTION award_order_points()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_points int;
  v_user_role text;
  v_is_donation boolean;
BEGIN
  -- Only award points when order is completed
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    
    -- Check if user is a regular user (not restaurant/NGO)
    SELECT role INTO v_user_role FROM profiles WHERE id = NEW.user_id;
    
    IF v_user_role = 'user' THEN
      -- Calculate points: 1 point per EGP spent
      v_points := FLOOR(NEW.total_amount);
      
      -- Bonus points for donations
      v_is_donation := (NEW.delivery_type = 'donation' AND NEW.ngo_id IS NOT NULL);
      IF v_is_donation THEN
        v_points := v_points * 2; -- Double points for donations
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
        NEW.user_id,
        v_points,
        'earned',
        CASE WHEN v_is_donation THEN 'donation' ELSE 'order' END,
        NEW.id,
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
      WHERE user_id = NEW.user_id;
      
      -- Check and award badges
      PERFORM check_and_award_badges(NEW.user_id);
      
      -- Check and update tier
      PERFORM update_user_tier(NEW.user_id);
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Trigger: Award points on order completion
DROP TRIGGER IF EXISTS trigger_award_order_points ON orders;
CREATE TRIGGER trigger_award_order_points
  AFTER UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION award_order_points();

-- Function: Check and award badges
CREATE OR REPLACE FUNCTION check_and_award_badges(p_user_id uuid)
RETURNS void
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_total_orders int;
  v_total_donations int;
  v_lifetime_points int;
BEGIN
  -- Get user stats
  SELECT total_orders, total_donations, lifetime_points
  INTO v_total_orders, v_total_donations, v_lifetime_points
  FROM user_loyalty
  WHERE user_id = p_user_id;
  
  -- First Order Badge
  IF v_total_orders >= 1 THEN
    INSERT INTO user_badges (user_id, badge_type, badge_name, badge_description, icon)
    VALUES (p_user_id, 'first_order', 'First Order', 'Completed your first order', '🎉')
    ON CONFLICT (user_id, badge_type) DO NOTHING;
  END IF;
  
  -- Food Rescuer Badge (5+ orders)
  IF v_total_orders >= 5 THEN
    INSERT INTO user_badges (user_id, badge_type, badge_name, badge_description, icon)
    VALUES (p_user_id, 'food_rescuer', 'Food Rescuer', 'Rescued food 5+ times', '🦸')
    ON CONFLICT (user_id, badge_type) DO NOTHING;
  END IF;
  
  -- NGO Supporter Badge (3+ donations)
  IF v_total_donations >= 3 THEN
    INSERT INTO user_badges (user_id, badge_type, badge_name, badge_description, icon)
    VALUES (p_user_id, 'ngo_supporter', 'NGO Supporter', 'Donated to NGOs 3+ times', '❤️')
    ON CONFLICT (user_id, badge_type) DO NOTHING;
  END IF;
  
  -- Loyal Customer Badge (10+ orders)
  IF v_total_orders >= 10 THEN
    INSERT INTO user_badges (user_id, badge_type, badge_name, badge_description, icon)
    VALUES (p_user_id, 'loyal_customer', 'Loyal Customer', 'Completed 10+ orders', '⭐')
    ON CONFLICT (user_id, badge_type) DO NOTHING;
  END IF;
  
  -- Eco Warrior Badge (500+ points)
  IF v_lifetime_points >= 500 THEN
    INSERT INTO user_badges (user_id, badge_type, badge_name, badge_description, icon)
    VALUES (p_user_id, 'eco_warrior', 'Eco Warrior', 'Earned 500+ lifetime points', '🌱')
    ON CONFLICT (user_id, badge_type) DO NOTHING;
  END IF;
END;
$$;

-- Function: Update user tier based on points
CREATE OR REPLACE FUNCTION update_user_tier(p_user_id uuid)
RETURNS void
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_lifetime_points int;
  v_new_tier text;
  v_current_tier text;
BEGIN
  SELECT lifetime_points, current_tier
  INTO v_lifetime_points, v_current_tier
  FROM user_loyalty
  WHERE user_id = p_user_id;
  
  -- Determine tier based on lifetime points
  IF v_lifetime_points >= 1000 THEN
    v_new_tier := 'platinum';
  ELSIF v_lifetime_points >= 500 THEN
    v_new_tier := 'gold';
  ELSIF v_lifetime_points >= 200 THEN
    v_new_tier := 'silver';
  ELSE
    v_new_tier := 'bronze';
  END IF;
  
  -- Update tier if changed
  IF v_new_tier != v_current_tier THEN
    UPDATE user_loyalty
    SET current_tier = v_new_tier, updated_at = NOW()
    WHERE user_id = p_user_id;
  END IF;
END;
$$;

-- Function: Redeem reward
CREATE OR REPLACE FUNCTION redeem_reward(
  p_user_id uuid,
  p_reward_id uuid
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_available_points int;
  v_points_cost int;
  v_current_tier text;
  v_min_tier text;
  v_valid_days int;
  v_transaction_id uuid;
  v_reward_id uuid;
BEGIN
  -- Get user loyalty info
  SELECT available_points, current_tier
  INTO v_available_points, v_current_tier
  FROM user_loyalty
  WHERE user_id = p_user_id;
  
  -- Get reward info
  SELECT points_cost, min_tier, valid_days
  INTO v_points_cost, v_min_tier, v_valid_days
  FROM rewards_catalog
  WHERE id = p_reward_id AND is_active = true;
  
  -- Validate reward exists
  IF v_points_cost IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Reward not found or inactive');
  END IF;
  
  -- Check if user has enough points
  IF v_available_points < v_points_cost THEN
    RETURN jsonb_build_object('success', false, 'error', 'Insufficient points');
  END IF;
  
  -- Check tier requirement
  IF v_min_tier IS NOT NULL THEN
    IF (v_current_tier = 'bronze' AND v_min_tier IN ('silver', 'gold', 'platinum')) OR
       (v_current_tier = 'silver' AND v_min_tier IN ('gold', 'platinum')) OR
       (v_current_tier = 'gold' AND v_min_tier = 'platinum') THEN
      RETURN jsonb_build_object('success', false, 'error', 'Tier requirement not met');
    END IF;
  END IF;
  
  -- Deduct points
  UPDATE user_loyalty
  SET available_points = available_points - v_points_cost,
      updated_at = NOW()
  WHERE user_id = p_user_id;
  
  -- Record transaction
  INSERT INTO loyalty_transactions (
    user_id,
    points,
    transaction_type,
    source,
    reward_id,
    description
  ) VALUES (
    p_user_id,
    -v_points_cost,
    'redeemed',
    'reward_redemption',
    p_reward_id,
    'Redeemed reward for ' || v_points_cost || ' points'
  )
  RETURNING id INTO v_transaction_id;
  
  -- Create user reward
  INSERT INTO user_rewards (
    user_id,
    reward_id,
    transaction_id,
    expires_at
  ) VALUES (
    p_user_id,
    p_reward_id,
    v_transaction_id,
    NOW() + (v_valid_days || ' days')::interval
  )
  RETURNING id INTO v_reward_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'reward_id', v_reward_id,
    'remaining_points', v_available_points - v_points_cost
  );
END;
$$;

-- =====================================================
-- SEED DEFAULT REWARDS
-- =====================================================
INSERT INTO rewards_catalog (reward_type, title, description, points_cost, discount_percentage, min_tier, icon) VALUES
('free_delivery', 'Free Delivery', 'Get free delivery on your next order', 50, NULL, NULL, '🚚'),
('discount', '10% Off', 'Get 10% off your next order', 100, 10, NULL, '💰'),
('discount', '20% Off', 'Get 20% off your next order', 200, 20, 'silver', '💎'),
('donation', 'Donate 50 EGP', 'Donate 50 EGP to an NGO of your choice', 50, NULL, NULL, '❤️'),
('donation', 'Donate 100 EGP', 'Donate 100 EGP to an NGO of your choice', 100, NULL, NULL, '💝'),
('priority_support', 'Priority Support', 'Get priority customer support for 30 days', 150, NULL, 'silver', '⭐'),
('discount', '30% Off', 'Get 30% off your next order', 300, 30, 'gold', '👑')
ON CONFLICT DO NOTHING;

-- =====================================================
-- COMMENTS
-- =====================================================
COMMENT ON TABLE user_loyalty IS 'User loyalty profiles with points and tier information';
COMMENT ON TABLE loyalty_transactions IS 'History of all points earned and redeemed';
COMMENT ON TABLE user_badges IS 'Badges earned by users for achievements';
COMMENT ON TABLE rewards_catalog IS 'Available rewards that users can redeem';
COMMENT ON TABLE user_rewards IS 'Rewards redeemed by users';
