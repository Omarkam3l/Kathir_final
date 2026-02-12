-- =====================================================
-- CONTINUE RLS POLICY CLEANUP
-- Part 2: Clean up remaining duplicates and optimize
-- =====================================================

-- =====================================================
-- PART 1: CLEAN UP RUSH_HOURS DUPLICATES
-- =====================================================

-- Drop redundant rush_hours policies (ALL policy covers everything)
DROP POLICY IF EXISTS "Restaurants can delete their own rush hours" ON rush_hours;
DROP POLICY IF EXISTS "Restaurants can insert their own rush hours" ON rush_hours;
DROP POLICY IF EXISTS "Restaurants can update their own rush hours" ON rush_hours;
DROP POLICY IF EXISTS "Restaurants can view their own rush hours" ON rush_hours;

-- Keep only:
-- - "Restaurant owners can manage rush hours" (ALL command)
-- - "Public can view active rush hours" (for public browsing)
-- - "Public can view rush hours" (for public browsing)

-- Remove duplicate public view policy
DROP POLICY IF EXISTS "Public can view rush hours" ON rush_hours;

-- Keep only "Public can view active rush hours" for public access

-- =====================================================
-- PART 2: CLEAN UP USER_ADDRESSES DUPLICATES
-- =====================================================

-- Remove old {public} role policies (keep {authenticated} versions)
DROP POLICY IF EXISTS "Users can delete own addresses" ON user_addresses;
DROP POLICY IF EXISTS "Users can insert own addresses" ON user_addresses;
DROP POLICY IF EXISTS "Users can update own addresses" ON user_addresses;
DROP POLICY IF EXISTS "Users can view own addresses" ON user_addresses;

-- Keep only the {authenticated} versions:
-- - "Users can delete their own addresses"
-- - "Users can insert their own addresses"
-- - "Users can update their own addresses"
-- - "Users can view their own addresses"

-- =====================================================
-- PART 3: OPTIMIZE MESSAGES POLICIES (PREVENT RECURSION)
-- =====================================================

-- Messages policies use EXISTS with conversations join
-- This can cause recursion if conversations also queries messages
-- Convert to more efficient pattern

DROP POLICY IF EXISTS "Users can send messages in their conversations" ON messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON messages;
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON messages;

-- Recreate with optimized queries
CREATE POLICY "messages_insert_conversation_members"
ON messages FOR INSERT
TO authenticated
WITH CHECK (
  sender_id = auth.uid() AND
  conversation_id IN (
    SELECT id FROM conversations 
    WHERE ngo_id = auth.uid() OR restaurant_id = auth.uid()
  )
);

CREATE POLICY "messages_select_conversation_members"
ON messages FOR SELECT
TO authenticated
USING (
  conversation_id IN (
    SELECT id FROM conversations 
    WHERE ngo_id = auth.uid() OR restaurant_id = auth.uid()
  )
);

CREATE POLICY "messages_update_conversation_members"
ON messages FOR UPDATE
TO authenticated
USING (
  conversation_id IN (
    SELECT id FROM conversations 
    WHERE ngo_id = auth.uid() OR restaurant_id = auth.uid()
  )
)
WITH CHECK (
  conversation_id IN (
    SELECT id FROM conversations 
    WHERE ngo_id = auth.uid() OR restaurant_id = auth.uid()
  )
);

-- =====================================================
-- PART 4: OPTIMIZE PAYMENTS POLICIES
-- =====================================================

-- Payments policy uses EXISTS with orders join
-- Convert to IN subquery for consistency

DROP POLICY IF EXISTS "Users can view own payments" ON payments;

CREATE POLICY "payments_select_users"
ON payments FOR SELECT
TO authenticated
USING (
  order_id IN (
    SELECT id FROM orders WHERE user_id = auth.uid()
  )
);

-- Add restaurant view policy (they should see payments for their orders)
CREATE POLICY "payments_select_restaurants"
ON payments FOR SELECT
TO authenticated
USING (
  order_id IN (
    SELECT id FROM orders WHERE restaurant_id = auth.uid()
  )
);

-- =====================================================
-- PART 5: ADD MISSING NGO POLICIES FOR MEALS
-- =====================================================

-- NGOs should be able to view meals to see what's available for donation
-- Add policy if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'meals' 
    AND policyname = 'NGOs can view available meals'
  ) THEN
    CREATE POLICY "NGOs can view available meals"
    ON meals FOR SELECT
    TO authenticated
    USING (
      quantity_available > 0 AND 
      expiry_date > now() AND
      (status = 'active' OR status IS NULL)
    );
  END IF;
END $$;

-- =====================================================
-- PART 6: OPTIMIZE PROFILES POLICIES
-- =====================================================

-- Profiles policies look good but let's ensure they're indexed
-- Add index for approval_status lookups (if not exists)
CREATE INDEX IF NOT EXISTS idx_profiles_approval_status_approved 
ON profiles(approval_status) 
WHERE approval_status = 'approved';

-- =====================================================
-- PART 7: ADD HELPFUL INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes for conversation lookups
CREATE INDEX IF NOT EXISTS idx_conversations_ngo_id ON conversations(ngo_id) WHERE ngo_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_conversations_restaurant_id ON conversations(restaurant_id) WHERE restaurant_id IS NOT NULL;

-- Indexes for message lookups
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);

-- Indexes for cart operations
CREATE INDEX IF NOT EXISTS idx_cart_items_user_id ON cart_items(user_id);

-- Indexes for favorites
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorite_restaurants_user_id ON favorite_restaurants(user_id);

-- Indexes for meal lookups
CREATE INDEX IF NOT EXISTS idx_meals_restaurant_id ON meals(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_meals_status_expiry ON meals(status, expiry_date) 
WHERE status = 'active' AND expiry_date > now();

-- Indexes for rush hours
CREATE INDEX IF NOT EXISTS idx_rush_hours_restaurant_id ON rush_hours(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_rush_hours_active ON rush_hours(is_active) WHERE is_active = true;

-- Indexes for user addresses
CREATE INDEX IF NOT EXISTS idx_user_addresses_user_id ON user_addresses(user_id);

-- Indexes for payments
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);

-- =====================================================
-- PART 8: ADD COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON POLICY "messages_select_conversation_members" ON messages IS 
'Users can view messages in conversations they are part of - uses IN subquery to prevent recursion';

COMMENT ON POLICY "payments_select_users" ON payments IS 
'Users can view payments for their orders - uses IN subquery to prevent recursion';

COMMENT ON POLICY "payments_select_restaurants" ON payments IS 
'Restaurants can view payments for orders they received';

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

DO $$
DECLARE
  policy_count INTEGER;
BEGIN
  RAISE NOTICE '=== RLS Policy Cleanup Summary ===';
  
  SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'rush_hours';
  RAISE NOTICE 'rush_hours policies: %', policy_count;
  
  SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'user_addresses';
  RAISE NOTICE 'user_addresses policies: %', policy_count;
  
  SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'messages';
  RAISE NOTICE 'messages policies: %', policy_count;
  
  SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'payments';
  RAISE NOTICE 'payments policies: %', policy_count;
  
  SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'meals';
  RAISE NOTICE 'meals policies: %', policy_count;
  
  RAISE NOTICE '=== Index Summary ===';
  RAISE NOTICE 'Total indexes created: %', (
    SELECT COUNT(*) FROM pg_indexes 
    WHERE schemaname = 'public' 
    AND indexname LIKE 'idx_%'
  );
END $$;
