-- =====================================================
-- ADD STRIPE PAYMENT INTEGRATION COLUMNS
-- =====================================================
-- Adds necessary columns for Stripe payment tracking
-- Run this migration in Supabase SQL Editor
-- =====================================================

-- Add Stripe columns to orders table
ALTER TABLE public.orders 
  ADD COLUMN IF NOT EXISTS stripe_payment_intent_id TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT;

-- Add Stripe columns to profiles table
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT UNIQUE;

-- Update payments table with Stripe-specific columns
ALTER TABLE public.payments 
  ADD COLUMN IF NOT EXISTS stripe_payment_intent_id TEXT,
  ADD COLUMN IF NOT EXISTS stripe_charge_id TEXT,
  ADD COLUMN IF NOT EXISTS payment_method_type TEXT,
  ADD COLUMN IF NOT EXISTS last_4 TEXT,
  ADD COLUMN IF NOT EXISTS card_brand TEXT;

-- Create index for fast webhook lookups
CREATE INDEX IF NOT EXISTS idx_orders_stripe_payment_intent 
  ON public.orders(stripe_payment_intent_id);

CREATE INDEX IF NOT EXISTS idx_payments_stripe_payment_intent 
  ON public.payments(stripe_payment_intent_id);

-- Add comments
COMMENT ON COLUMN public.orders.stripe_payment_intent_id IS 'Stripe PaymentIntent ID for tracking payments';
COMMENT ON COLUMN public.orders.stripe_customer_id IS 'Stripe Customer ID for the user';
COMMENT ON COLUMN public.profiles.stripe_customer_id IS 'Stripe Customer ID linked to this profile';
COMMENT ON COLUMN public.payments.stripe_payment_intent_id IS 'Stripe PaymentIntent ID';
COMMENT ON COLUMN public.payments.stripe_charge_id IS 'Stripe Charge ID';
COMMENT ON COLUMN public.payments.payment_method_type IS 'Payment method type (card, wallet, etc.)';
COMMENT ON COLUMN public.payments.last_4 IS 'Last 4 digits of card';
COMMENT ON COLUMN public.payments.card_brand IS 'Card brand (visa, mastercard, etc.)';

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON public.orders TO service_role;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO service_role;
GRANT SELECT, INSERT, UPDATE ON public.payments TO service_role;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Stripe columns added successfully';
  RAISE NOTICE '✅ Indexes created';
  RAISE NOTICE '✅ Migration complete';
END $$;
