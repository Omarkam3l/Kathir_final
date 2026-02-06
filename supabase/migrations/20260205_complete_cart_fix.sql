-- =====================================================
-- COMPLETE CART SYSTEM FIX
-- =====================================================
-- This migration ensures cart_items table is properly set up
-- with all necessary constraints and relationships
-- =====================================================

-- First, check if updated_at column exists, if not add it
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'cart_items' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE public.cart_items ADD COLUMN updated_at timestamptz DEFAULT now();
  END IF;
END $$;

-- Ensure cart_items table has correct structure
-- (This won't fail if table already exists)
CREATE TABLE IF NOT EXISTS public.cart_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  meal_id uuid NOT NULL REFERENCES public.meals(id) ON DELETE CASCADE,
  quantity integer NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, meal_id)
);

-- Ensure foreign key constraints exist with proper names
DO $$ 
BEGIN
  -- Check if foreign key to meals exists, if not create it
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'cart_items_meal_id_fkey' 
    AND table_name = 'cart_items'
  ) THEN
    -- First drop any existing foreign key on meal_id
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
      WHERE tc.table_name = 'cart_items' 
      AND kcu.column_name = 'meal_id'
      AND tc.constraint_type = 'FOREIGN KEY'
    ) THEN
      EXECUTE (
        SELECT 'ALTER TABLE public.cart_items DROP CONSTRAINT ' || constraint_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_name = 'cart_items' 
        AND kcu.column_name = 'meal_id'
        AND tc.constraint_type = 'FOREIGN KEY'
        LIMIT 1
      );
    END IF;
    
    ALTER TABLE public.cart_items 
    ADD CONSTRAINT cart_items_meal_id_fkey 
    FOREIGN KEY (meal_id) 
    REFERENCES public.meals(id) 
    ON DELETE CASCADE;
  END IF;

  -- Check if foreign key to profiles exists, if not create it
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'cart_items_user_id_fkey' 
    AND table_name = 'cart_items'
  ) THEN
    -- First drop any existing foreign key on user_id
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
      WHERE tc.table_name = 'cart_items' 
      AND kcu.column_name = 'user_id'
      AND tc.constraint_type = 'FOREIGN KEY'
    ) THEN
      EXECUTE (
        SELECT 'ALTER TABLE public.cart_items DROP CONSTRAINT ' || constraint_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_name = 'cart_items' 
        AND kcu.column_name = 'user_id'
        AND tc.constraint_type = 'FOREIGN KEY'
        LIMIT 1
      );
    END IF;
    
    ALTER TABLE public.cart_items 
    ADD CONSTRAINT cart_items_user_id_fkey 
    FOREIGN KEY (user_id) 
    REFERENCES public.profiles(id) 
    ON DELETE CASCADE;
  END IF;
END $$;

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_cart_items_user_id ON public.cart_items(user_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_meal_id ON public.cart_items(meal_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_created_at ON public.cart_items(created_at DESC);

-- Create or replace the trigger function for updated_at
CREATE OR REPLACE FUNCTION update_cart_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop and recreate trigger to ensure it works
DROP TRIGGER IF EXISTS trg_cart_items_updated_at ON public.cart_items;
CREATE TRIGGER trg_cart_items_updated_at
BEFORE UPDATE ON public.cart_items
FOR EACH ROW
EXECUTE FUNCTION update_cart_items_updated_at();

-- Enable RLS
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own cart items" ON public.cart_items;
DROP POLICY IF EXISTS "Users can insert their own cart items" ON public.cart_items;
DROP POLICY IF EXISTS "Users can update their own cart items" ON public.cart_items;
DROP POLICY IF EXISTS "Users can delete their own cart items" ON public.cart_items;

-- Create RLS policies
CREATE POLICY "Users can view their own cart items"
ON public.cart_items FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own cart items"
ON public.cart_items FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own cart items"
ON public.cart_items FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own cart items"
ON public.cart_items FOR DELETE
USING (auth.uid() = user_id);

-- Clean up any invalid cart items (meals that don't exist)
DELETE FROM public.cart_items
WHERE meal_id NOT IN (SELECT id FROM public.meals);

-- Clean up any cart items with invalid quantities
UPDATE public.cart_items
SET quantity = 1
WHERE quantity IS NULL OR quantity <= 0;

-- Verify the setup
DO $$
DECLARE
  fk_count integer;
  policy_count integer;
  has_updated_at boolean;
BEGIN
  -- Check foreign keys
  SELECT COUNT(*) INTO fk_count
  FROM information_schema.table_constraints
  WHERE table_name = 'cart_items' 
  AND constraint_type = 'FOREIGN KEY';
  
  IF fk_count < 2 THEN
    RAISE EXCEPTION 'Cart items table missing foreign keys';
  END IF;

  -- Check RLS policies
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE tablename = 'cart_items';
  
  IF policy_count < 4 THEN
    RAISE WARNING 'Cart items table missing some RLS policies';
  END IF;

  -- Check updated_at column
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'cart_items' AND column_name = 'updated_at'
  ) INTO has_updated_at;

  IF NOT has_updated_at THEN
    RAISE EXCEPTION 'Cart items table missing updated_at column';
  END IF;

  RAISE NOTICE 'Cart items table setup complete: % foreign keys, % policies, updated_at column exists', fk_count, policy_count;
END $$;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cart_items TO authenticated;

COMMENT ON TABLE public.cart_items IS 'Shopping cart items with proper foreign keys and RLS policies';
COMMENT ON COLUMN public.cart_items.user_id IS 'User who owns this cart item';
COMMENT ON COLUMN public.cart_items.meal_id IS 'Meal being added to cart';
COMMENT ON COLUMN public.cart_items.quantity IS 'Quantity of this meal in cart (must be > 0)';
COMMENT ON COLUMN public.cart_items.updated_at IS 'Timestamp of last update';
