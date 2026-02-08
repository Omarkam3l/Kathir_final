-- =====================================================
-- VERIFY CART_ITEMS FOREIGN KEY CONSTRAINTS
-- =====================================================
-- This ensures the foreign key relationships exist
-- and Supabase can detect them for queries
-- =====================================================

-- Ensure cart_items table exists with proper foreign keys
DO $$ 
BEGIN
  -- Check if foreign key to meals exists, if not create it
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'cart_items_meal_id_fkey' 
    AND table_name = 'cart_items'
  ) THEN
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
    ALTER TABLE public.cart_items 
    ADD CONSTRAINT cart_items_user_id_fkey 
    FOREIGN KEY (user_id) 
    REFERENCES public.profiles(id) 
    ON DELETE CASCADE;
  END IF;
END $$;

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_cart_items_user_id ON public.cart_items(user_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_meal_id ON public.cart_items(meal_id);

-- Verify the constraints exist
SELECT 
  tc.constraint_name, 
  tc.table_name, 
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'cart_items';

COMMENT ON TABLE cart_items IS 'Shopping cart items with foreign keys to meals and profiles';
