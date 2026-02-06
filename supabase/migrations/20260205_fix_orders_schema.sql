-- =====================================================
-- FIX ORDERS TABLE SCHEMA
-- =====================================================
-- Problem: orders.meal_id only allows ONE meal per order
-- Solution: Remove meal_id, use order_items table instead
-- =====================================================

-- Remove meal_id column (wrong design for multi-item orders)
ALTER TABLE public.orders DROP COLUMN IF EXISTS meal_id;

-- Add missing columns for proper order management
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS order_number text UNIQUE;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payment_method text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payment_status text DEFAULT 'pending';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- Add check constraint for payment_status
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_payment_status_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_payment_status_check CHECK (
  payment_status = ANY(ARRAY['pending'::text, 'paid'::text, 'failed'::text, 'refunded'::text])
);

-- Add check constraint for payment_method
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_payment_method_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_payment_method_check CHECK (
  payment_method = ANY(ARRAY['card'::text, 'wallet'::text, 'cod'::text, 'cash'::text])
);

-- Create index on order_number for fast lookups
CREATE INDEX IF NOT EXISTS idx_orders_order_number ON public.orders USING btree (order_number);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON public.orders USING btree (payment_status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders USING btree (created_at DESC);

-- Add trigger for updated_at
DROP TRIGGER IF EXISTS trg_update_orders_updated_at ON public.orders;
CREATE TRIGGER trg_update_orders_updated_at
BEFORE UPDATE ON public.orders
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- VERIFY ORDER_ITEMS TABLE
-- =====================================================
-- This table is correct, just ensure it exists

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items USING btree (order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_meal_id ON public.order_items USING btree (meal_id);

-- =====================================================
-- HELPER FUNCTION: Generate Order Number
-- =====================================================

CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS text
LANGUAGE plpgsql
AS $
DECLARE
  new_order_number text;
  counter integer := 0;
BEGIN
  LOOP
    -- Generate order number: ORD + timestamp + random 4 digits
    new_order_number := 'ORD' || 
                       to_char(now(), 'YYYYMMDD') || 
                       lpad(floor(random() * 10000)::text, 4, '0');
    
    -- Check if it exists
    IF NOT EXISTS (SELECT 1 FROM orders WHERE order_number = new_order_number) THEN
      RETURN new_order_number;
    END IF;
    
    counter := counter + 1;
    IF counter > 10 THEN
      -- Fallback to UUID if we can't generate unique number
      RETURN 'ORD' || replace(gen_random_uuid()::text, '-', '');
    END IF;
  END LOOP;
END;
$;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON COLUMN orders.order_number IS 'Unique human-readable order number (e.g., ORD20260205001)';
COMMENT ON COLUMN orders.payment_method IS 'Payment method used: card, wallet, cod, cash';
COMMENT ON COLUMN orders.payment_status IS 'Payment status: pending, paid, failed, refunded';
COMMENT ON FUNCTION generate_order_number IS 'Generates unique order number with format ORD + date + random digits';

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION generate_order_number() TO authenticated;

