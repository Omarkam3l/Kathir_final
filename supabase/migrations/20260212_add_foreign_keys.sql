-- =====================================================
-- ADD FOREIGN KEYS FOR DATA INTEGRITY
-- =====================================================
-- This migration adds proper foreign key constraints to ensure:
-- 1. Orders reference valid meals (can't delete meals in active orders)
-- 2. Favorites reference valid meals (auto-cleanup when meal deleted)
-- 3. Cascade deletes work properly
-- =====================================================

-- =====================================================
-- STEP 1: Clean up any orphaned records first
-- =====================================================

-- Remove favorites for deleted meals
DELETE FROM favorites
WHERE meal_id NOT IN (SELECT id FROM meals);

-- Remove favorite_restaurants for deleted restaurants
DELETE FROM favorite_restaurants
WHERE restaurant_id NOT IN (SELECT profile_id FROM restaurants);

-- Check for order_items with deleted meals (should not delete these!)
DO $$
DECLARE
  orphaned_count INT;
BEGIN
  SELECT COUNT(*) INTO orphaned_count
  FROM order_items
  WHERE meal_id NOT IN (SELECT id FROM meals);
  
  IF orphaned_count > 0 THEN
    RAISE WARNING '⚠️ Found % order_items with deleted meals. These will be preserved.', orphaned_count;
  END IF;
END $$;

-- =====================================================
-- STEP 2: Add Foreign Keys
-- =====================================================

-- FAVORITES TABLE
-- When meal is deleted → remove from favorites (CASCADE)
ALTER TABLE favorites
  DROP CONSTRAINT IF EXISTS favorites_meal_id_fkey,
  ADD CONSTRAINT favorites_meal_id_fkey
    FOREIGN KEY (meal_id)
    REFERENCES meals(id)
    ON DELETE CASCADE;

COMMENT ON CONSTRAINT favorites_meal_id_fkey ON favorites IS
'When a meal is deleted, automatically remove it from all favorites';

-- FAVORITE_RESTAURANTS TABLE
-- When restaurant is deleted → remove from favorites (CASCADE)
ALTER TABLE favorite_restaurants
  DROP CONSTRAINT IF EXISTS favorite_restaurants_restaurant_id_fkey,
  ADD CONSTRAINT favorite_restaurants_restaurant_id_fkey
    FOREIGN KEY (restaurant_id)
    REFERENCES restaurants(profile_id)
    ON DELETE CASCADE;

COMMENT ON CONSTRAINT favorite_restaurants_restaurant_id_fkey ON favorite_restaurants IS
'When a restaurant is deleted, automatically remove it from all favorites';

-- ORDER_ITEMS TABLE
-- When meal is deleted → PREVENT if in active orders (RESTRICT)
-- This protects order history and email generation
ALTER TABLE order_items
  DROP CONSTRAINT IF EXISTS order_items_meal_id_fkey,
  ADD CONSTRAINT order_items_meal_id_fkey
    FOREIGN KEY (meal_id)
    REFERENCES meals(id)
    ON DELETE RESTRICT;

COMMENT ON CONSTRAINT order_items_meal_id_fkey ON order_items IS
'Prevents deleting meals that are in orders. Protects order history and email generation.';

-- When order is deleted → delete order_items (CASCADE)
ALTER TABLE order_items
  DROP CONSTRAINT IF EXISTS order_items_order_id_fkey,
  ADD CONSTRAINT order_items_order_id_fkey
    FOREIGN KEY (order_id)
    REFERENCES orders(id)
    ON DELETE CASCADE;

COMMENT ON CONSTRAINT order_items_order_id_fkey ON order_items IS
'When an order is deleted, automatically delete all its items';

-- =====================================================
-- STEP 3: Update Meal Deletion Logic
-- =====================================================

-- Create a function to safely delete meals
CREATE OR REPLACE FUNCTION safe_delete_meal(p_meal_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_order_count INT;
  v_result jsonb;
BEGIN
  -- Check if meal is in any orders
  SELECT COUNT(*) INTO v_order_count
  FROM order_items
  WHERE meal_id = p_meal_id;
  
  IF v_order_count > 0 THEN
    -- Can't delete - meal is in orders
    v_result := jsonb_build_object(
      'success', false,
      'message', format('Cannot delete meal. It is in %s order(s). Mark as inactive instead.', v_order_count),
      'order_count', v_order_count
    );
  ELSE
    -- Safe to delete
    DELETE FROM meals WHERE id = p_meal_id;
    
    v_result := jsonb_build_object(
      'success', true,
      'message', 'Meal deleted successfully'
    );
  END IF;
  
  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION safe_delete_meal(uuid) IS
'Safely deletes a meal only if it is not in any orders. Otherwise suggests marking as inactive.';

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION safe_delete_meal(uuid) TO authenticated;

-- =====================================================
-- STEP 4: Verification
-- =====================================================

DO $$
DECLARE
  v_favorites_fk BOOLEAN;
  v_favorite_restaurants_fk BOOLEAN;
  v_order_items_meal_fk BOOLEAN;
  v_order_items_order_fk BOOLEAN;
BEGIN
  -- Check if all FKs exist
  SELECT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'favorites_meal_id_fkey'
    AND table_name = 'favorites'
  ) INTO v_favorites_fk;
  
  SELECT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'favorite_restaurants_restaurant_id_fkey'
    AND table_name = 'favorite_restaurants'
  ) INTO v_favorite_restaurants_fk;
  
  SELECT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'order_items_meal_id_fkey'
    AND table_name = 'order_items'
  ) INTO v_order_items_meal_fk;
  
  SELECT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'order_items_order_id_fkey'
    AND table_name = 'order_items'
  ) INTO v_order_items_order_fk;
  
  RAISE NOTICE '=== FOREIGN KEYS VERIFICATION ===';
  RAISE NOTICE 'favorites → meals: %', CASE WHEN v_favorites_fk THEN '✅' ELSE '❌' END;
  RAISE NOTICE 'favorite_restaurants → restaurants: %', CASE WHEN v_favorite_restaurants_fk THEN '✅' ELSE '❌' END;
  RAISE NOTICE 'order_items → meals: %', CASE WHEN v_order_items_meal_fk THEN '✅' ELSE '❌' END;
  RAISE NOTICE 'order_items → orders: %', CASE WHEN v_order_items_order_fk THEN '✅' ELSE '❌' END;
  RAISE NOTICE '';
  
  IF v_favorites_fk AND v_favorite_restaurants_fk AND v_order_items_meal_fk AND v_order_items_order_fk THEN
    RAISE NOTICE '✅ All foreign keys added successfully!';
  ELSE
    RAISE WARNING '❌ Some foreign keys failed to add. Check errors above.';
  END IF;
END $$;

-- =====================================================
-- EXPECTED BEHAVIOR AFTER MIGRATION
-- =====================================================
-- 1. Deleting a meal with orders → BLOCKED (protects order history)
-- 2. Deleting a meal without orders → Removes from favorites automatically
-- 3. Deleting an order → Removes all order_items automatically
-- 4. Favorites queries can use nested joins (faster)
-- 5. Email generation is protected (meals always exist for orders)
-- =====================================================
