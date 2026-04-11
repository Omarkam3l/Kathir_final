-- Add discount tracking columns to orders table
-- This allows restaurants to see the original order value before promo code discounts

ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS promo_code text,
ADD COLUMN IF NOT EXISTS discount_percentage numeric(5,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS discount_amount numeric(12,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS original_total numeric(12,2);

COMMENT ON COLUMN public.orders.promo_code IS 'Promo code applied to this order';
COMMENT ON COLUMN public.orders.discount_percentage IS 'Discount percentage from promo code (e.g., 100 for 100% off)';
COMMENT ON COLUMN public.orders.discount_amount IS 'Actual discount amount in currency';
COMMENT ON COLUMN public.orders.original_total IS 'Original total before promo code discount (what restaurant sees)';
