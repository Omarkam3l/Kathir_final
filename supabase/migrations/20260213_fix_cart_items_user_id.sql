-- =====================================================
-- FIX CART_ITEMS USER_ID COLUMN
-- =====================================================
-- The cart_items table is missing the user_id column
-- This migration adds it back
-- =====================================================

-- First, check current state of cart_items table
DO $$
DECLARE
  v_column_exists boolean;
  v_null_count integer;
BEGIN
  -- Check if user_id column exists
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'cart_items'
      AND column_name = 'user_id'
  ) INTO v_column_exists;
  
  IF v_column_exists THEN
    RAISE NOTICE '⚠️ user_id column already exists';
    
    -- Check for NULL values
    SELECT COUNT(*) INTO v_null_count
    FROM cart_items
    WHERE user_id IS NULL;
    
    IF v_null_count > 0 THEN
      RAISE NOTICE '⚠️ Found % cart items with NULL user_id', v_null_count;
      RAISE NOTICE '🗑️ Deleting orphaned cart items...';
      
      -- Delete cart items with NULL user_id (orphaned data)
      DELETE FROM cart_items WHERE user_id IS NULL;
      
      RAISE NOTICE '✅ Deleted % orphaned cart items', v_null_count;
    END IF;
    
    -- Make sure column is NOT NULL
    ALTER TABLE cart_items
    ALTER COLUMN user_id SET NOT NULL;
    
    RAISE NOTICE '✅ user_id column set to NOT NULL';
    
  ELSE
    RAISE NOTICE '➕ Adding user_id column to cart_items table...';
    
    -- Delete all existing cart items (they're invalid without user_id)
    DELETE FROM cart_items;
    RAISE NOTICE '🗑️ Cleared existing cart items (no user_id)';
    
    -- Add user_id column
    ALTER TABLE cart_items
    ADD COLUMN user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE;
    
    RAISE NOTICE '✅ user_id column added successfully';
  END IF;
  
  -- Add index if not exists
  CREATE INDEX IF NOT EXISTS idx_cart_items_user_id ON cart_items(user_id);
  
  -- Add unique constraint
  ALTER TABLE cart_items
  DROP CONSTRAINT IF EXISTS cart_items_user_meal_unique;
  
  ALTER TABLE cart_items
  ADD CONSTRAINT cart_items_user_meal_unique UNIQUE (user_id, meal_id);
  
  RAISE NOTICE '✅ Indexes and constraints updated';
END;
$$;

-- Verify RLS policies exist
DO $$
BEGIN
  -- Enable RLS if not already enabled
  ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
  
  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS "Users can view their own cart items" ON cart_items;
  DROP POLICY IF EXISTS "Users can insert their own cart items" ON cart_items;
  DROP POLICY IF EXISTS "Users can update their own cart items" ON cart_items;
  DROP POLICY IF EXISTS "Users can delete their own cart items" ON cart_items;
  
  -- Recreate policies
  CREATE POLICY "Users can view their own cart items"
    ON cart_items FOR SELECT
    USING (auth.uid() = user_id);

  CREATE POLICY "Users can insert their own cart items"
    ON cart_items FOR INSERT
    WITH CHECK (auth.uid() = user_id);

  CREATE POLICY "Users can update their own cart items"
    ON cart_items FOR UPDATE
    USING (auth.uid() = user_id);

  CREATE POLICY "Users can delete their own cart items"
    ON cart_items FOR DELETE
    USING (auth.uid() = user_id);
    
  RAISE NOTICE '✅ RLS policies recreated successfully';
END;
$$;

-- Verify the fix
DO $$
DECLARE
  v_column_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'cart_items'
      AND column_name = 'user_id'
  ) INTO v_column_exists;
  
  IF v_column_exists THEN
    RAISE NOTICE '✅ VERIFICATION PASSED: user_id column exists in cart_items';
  ELSE
    RAISE EXCEPTION '❌ VERIFICATION FAILED: user_id column still missing!';
  END IF;
END;
$$;
