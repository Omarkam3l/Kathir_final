-- =====================================================
-- ADD SUBTOTAL COLUMN TO ORDER_ITEMS
-- =====================================================
-- This migration adds the missing subtotal column to order_items
-- table, which is required by the email notification system.
--
-- The subtotal is computed as quantity * unit_price and stored
-- for performance and consistency.
-- =====================================================

-- Add subtotal column as a computed/generated column
ALTER TABLE order_items 
ADD COLUMN IF NOT EXISTS subtotal numeric(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED;

-- Add comment
COMMENT ON COLUMN order_items.subtotal IS 'Computed as quantity * unit_price. Used in order emails and reporting.';

-- Verify the column was added
DO $
BEGIN
  IF EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'order_items' 
    AND column_name = 'subtotal'
  ) THEN
    RAISE NOTICE '✅ Successfully added subtotal column to order_items';
  ELSE
    RAISE EXCEPTION '❌ Failed to add subtotal column to order_items';
  END IF;
END;
$;
