-- =====================================================
-- FIX ORDER_ITEMS FOREIGN KEY TO MEALS
-- =====================================================
-- Add foreign key relationship between order_items and meals
-- so that Supabase can join them in queries
-- =====================================================

-- Add foreign key constraint if it doesn't exist
DO $$ 
BEGIN
  -- Check if foreign key to meals exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'order_items_meal_id_fkey' 
    AND table_name = 'order_items'
  ) THEN
    -- First drop any existing foreign key on meal_id
    IF EXISTS (
      SELECT 1 FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
      WHERE tc.table_name = 'order_items' 
      AND kcu.column_name = 'meal_id'
      AND tc.constraint_type = 'FOREIGN KEY'
    ) THEN
      EXECUTE (
        SELECT 'ALTER TABLE public.order_items DROP CONSTRAINT ' || constraint_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_name = 'order_items' 
        AND kcu.column_name = 'meal_id'
        AND tc.constraint_type = 'FOREIGN KEY'
        LIMIT 1
      );
    END IF;
    
    -- Add the foreign key with proper name
    ALTER TABLE public.order_items 
    ADD CONSTRAINT order_items_meal_id_fkey 
    FOREIGN KEY (meal_id) 
    REFERENCES public.meals(id) 
    ON DELETE SET NULL;  -- Don't delete order items if meal is deleted
  END IF;
END $$;

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_order_items_meal_id ON public.order_items(meal_id);

-- Verify the foreign key exists
DO $$
DECLARE
  fk_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'order_items_meal_id_fkey' 
    AND table_name = 'order_items'
  ) INTO fk_exists;

  IF fk_exists THEN
    RAISE NOTICE 'Foreign key order_items_meal_id_fkey created successfully';
  ELSE
    RAISE EXCEPTION 'Failed to create foreign key order_items_meal_id_fkey';
  END IF;
END $$;

COMMENT ON CONSTRAINT order_items_meal_id_fkey ON public.order_items IS 'Foreign key to meals table for order item details';
