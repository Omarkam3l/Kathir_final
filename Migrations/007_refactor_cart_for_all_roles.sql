-- =====================================================
-- Migration: Refactor cart_items for all roles (users + NGOs)
-- =====================================================
-- Description: 
-- - Rename user_id to profile_id for consistency
-- - Update RLS policies to work for all authenticated users
-- - Maintain unique constraint per profile + meal
-- =====================================================

-- Step 1: Rename user_id column to profile_id
-- =====================================================
DO $$ 
BEGIN
  -- Check if column needs renaming
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'cart_items' 
    AND column_name = 'user_id'
  ) THEN
    -- Rename column
    ALTER TABLE public.cart_items 
    RENAME COLUMN user_id TO profile_id;
    
    RAISE NOTICE '✅ Renamed cart_items.user_id to profile_id';
  ELSE
    RAISE NOTICE 'ℹ️ Column already named profile_id';
  END IF;
END $$;

-- Step 2: Update unique constraint
-- =====================================================
DO $$ 
BEGIN
  -- Drop old constraint if exists
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'cart_items_user_id_meal_id_key'
  ) THEN
    ALTER TABLE public.cart_items 
    DROP CONSTRAINT cart_items_user_id_meal_id_key;
    
    RAISE NOTICE '✅ Dropped old unique constraint';
  END IF;
  
  -- Create new constraint if not exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'cart_items_profile_id_meal_id_key'
  ) THEN
    ALTER TABLE public.cart_items 
    ADD CONSTRAINT cart_items_profile_id_meal_id_key 
    UNIQUE (profile_id, meal_id);
    
    RAISE NOTICE '✅ Created new unique constraint';
  END IF;
END $$;

-- Step 3: Update indexes
-- =====================================================
-- Drop old indexes
DROP INDEX IF EXISTS idx_cart_items_user_id;

-- Create new indexes
CREATE INDEX IF NOT EXISTS idx_cart_items_profile_id 
ON public.cart_items(profile_id);

CREATE INDEX IF NOT EXISTS idx_cart_items_profile_meal 
ON public.cart_items(profile_id, meal_id);

-- Step 4: Drop old RLS policies
-- =====================================================
DROP POLICY IF EXISTS "Users can view their own cart items" ON public.cart_items;
DROP POLICY IF EXISTS "Users can insert their own cart items" ON public.cart_items;
DROP POLICY IF EXISTS "Users can update their own cart items" ON public.cart_items;
DROP POLICY IF EXISTS "Users can delete their own cart items" ON public.cart_items;
DROP POLICY IF EXISTS "Users can manage own cart" ON public.cart_items;

-- Step 5: Create new RLS policies for all authenticated users
-- =====================================================

-- Enable RLS
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

-- Policy: SELECT - All authenticated users can view their own cart
CREATE POLICY "Authenticated users can view own cart items"
ON public.cart_items FOR SELECT
TO authenticated
USING (auth.uid() = profile_id);

-- Policy: INSERT - All authenticated users can add to their cart
CREATE POLICY "Authenticated users can insert own cart items"
ON public.cart_items FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = profile_id);

-- Policy: UPDATE - All authenticated users can update their cart
CREATE POLICY "Authenticated users can update own cart items"
ON public.cart_items FOR UPDATE
TO authenticated
USING (auth.uid() = profile_id)
WITH CHECK (auth.uid() = profile_id);

-- Policy: DELETE - All authenticated users can delete from their cart
CREATE POLICY "Authenticated users can delete own cart items"
ON public.cart_items FOR DELETE
TO authenticated
USING (auth.uid() = profile_id);

-- Step 6: Add helpful comments
-- =====================================================
COMMENT ON TABLE public.cart_items IS 
'Shopping cart for all user types (users, NGOs). Uses profile_id to support all roles.';

COMMENT ON COLUMN public.cart_items.profile_id IS 
'Profile ID of cart owner (works for users, NGOs, and all roles)';

COMMENT ON COLUMN public.cart_items.meal_id IS 
'Meal being added to cart';

COMMENT ON COLUMN public.cart_items.quantity IS 
'Quantity of this meal in cart (must be > 0)';

-- Step 7: Verify setup
-- =====================================================
DO $$ 
DECLARE
  policy_count int;
BEGIN
  -- Count active policies
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
  AND tablename = 'cart_items';
  
  RAISE NOTICE '✅ Migration complete! Active RLS policies: %', policy_count;
  
  -- Verify column exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'cart_items' 
    AND column_name = 'profile_id'
  ) THEN
    RAISE NOTICE '✅ Column profile_id exists';
  ELSE
    RAISE EXCEPTION '❌ Column profile_id missing!';
  END IF;
END $$;
