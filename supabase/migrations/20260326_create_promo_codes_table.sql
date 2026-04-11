-- Create promo_codes table for managing discount codes
CREATE TABLE IF NOT EXISTS public.promo_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  description TEXT,
  discount_percentage NUMERIC(5,2) NOT NULL CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
  is_active BOOLEAN DEFAULT true,
  valid_from TIMESTAMP WITH TIME ZONE DEFAULT now(),
  valid_until TIMESTAMP WITH TIME ZONE,
  max_uses INTEGER,
  current_uses INTEGER DEFAULT 0,
  min_order_amount NUMERIC(10,2) DEFAULT 0,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  CONSTRAINT code_uppercase CHECK (code = UPPER(code))
);

-- Add indexes for performance
CREATE INDEX idx_promo_codes_code ON public.promo_codes(code);
CREATE INDEX idx_promo_codes_active ON public.promo_codes(is_active);
CREATE INDEX idx_promo_codes_valid_dates ON public.promo_codes(valid_from, valid_until);

-- Add comments
COMMENT ON TABLE public.promo_codes IS 'Promotional discount codes for orders';
COMMENT ON COLUMN public.promo_codes.code IS 'Unique promo code (uppercase)';
COMMENT ON COLUMN public.promo_codes.discount_percentage IS 'Discount percentage (0-100)';
COMMENT ON COLUMN public.promo_codes.is_active IS 'Whether the promo code is currently active';
COMMENT ON COLUMN public.promo_codes.valid_from IS 'Start date for promo code validity';
COMMENT ON COLUMN public.promo_codes.valid_until IS 'End date for promo code validity (null = no expiry)';
COMMENT ON COLUMN public.promo_codes.max_uses IS 'Maximum number of times code can be used (null = unlimited)';
COMMENT ON COLUMN public.promo_codes.current_uses IS 'Current number of times code has been used';
COMMENT ON COLUMN public.promo_codes.min_order_amount IS 'Minimum order amount required to use code';

-- Enable RLS
ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read active promo codes
CREATE POLICY "Anyone can read active promo codes"
  ON public.promo_codes
  FOR SELECT
  USING (is_active = true);

-- Policy: Only admins/restaurants can insert promo codes
CREATE POLICY "Admins and restaurants can insert promo codes"
  ON public.promo_codes
  FOR INSERT
  WITH CHECK (
    auth.uid() IN (
      SELECT id FROM public.profiles 
      WHERE role IN ('admin', 'restaurant')
    )
  );

-- Policy: Only admins/restaurants can update their own promo codes
CREATE POLICY "Admins and restaurants can update their promo codes"
  ON public.promo_codes
  FOR UPDATE
  USING (
    auth.uid() IN (
      SELECT id FROM public.profiles 
      WHERE role IN ('admin', 'restaurant')
    )
  );

-- Policy: Only admins can delete promo codes
CREATE POLICY "Only admins can delete promo codes"
  ON public.promo_codes
  FOR DELETE
  USING (
    auth.uid() IN (
      SELECT id FROM public.profiles 
      WHERE role = 'admin'
    )
  );

-- Function to increment promo code usage
CREATE OR REPLACE FUNCTION public.increment_promo_code_usage(p_code TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.promo_codes
  SET 
    current_uses = current_uses + 1,
    updated_at = now()
  WHERE code = UPPER(p_code)
    AND is_active = true;
END;
$$;

-- Function to validate and get promo code discount
CREATE OR REPLACE FUNCTION public.validate_promo_code(
  p_code TEXT,
  p_order_amount NUMERIC DEFAULT 0
)
RETURNS TABLE (
  is_valid BOOLEAN,
  discount_percentage NUMERIC,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_promo RECORD;
BEGIN
  -- Get promo code details
  SELECT * INTO v_promo
  FROM public.promo_codes
  WHERE code = UPPER(p_code)
    AND is_active = true;

  -- Check if code exists
  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 0::NUMERIC, 'Invalid promo code'::TEXT;
    RETURN;
  END IF;

  -- Check if code has started
  IF v_promo.valid_from > now() THEN
    RETURN QUERY SELECT false, 0::NUMERIC, 'Promo code not yet valid'::TEXT;
    RETURN;
  END IF;

  -- Check if code has expired
  IF v_promo.valid_until IS NOT NULL AND v_promo.valid_until < now() THEN
    RETURN QUERY SELECT false, 0::NUMERIC, 'Promo code has expired'::TEXT;
    RETURN;
  END IF;

  -- Check usage limit
  IF v_promo.max_uses IS NOT NULL AND v_promo.current_uses >= v_promo.max_uses THEN
    RETURN QUERY SELECT false, 0::NUMERIC, 'Promo code usage limit reached'::TEXT;
    RETURN;
  END IF;

  -- Check minimum order amount
  IF p_order_amount < v_promo.min_order_amount THEN
    RETURN QUERY SELECT 
      false, 
      0::NUMERIC, 
      format('Minimum order amount is EGP %s', v_promo.min_order_amount)::TEXT;
    RETURN;
  END IF;

  -- All checks passed
  RETURN QUERY SELECT true, v_promo.discount_percentage, 'Valid promo code'::TEXT;
END;
$$;

-- Insert some demo promo codes
INSERT INTO public.promo_codes (code, description, discount_percentage, is_active, max_uses, min_order_amount)
VALUES
  ('SAVE10', '10% discount on all orders', 10.0, true, NULL, 0),
  ('SAVE20', '20% discount on all orders', 20.0, true, NULL, 0),
  ('SAVE30', '30% discount on orders above EGP 50', 30.0, true, NULL, 50),
  ('WELCOME15', '15% welcome discount for new users', 15.0, true, 100, 0),
  ('FIRSTORDER', '25% discount on first order', 25.0, true, 1000, 0)
ON CONFLICT (code) DO NOTHING;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION public.increment_promo_code_usage(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_promo_code(TEXT, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_promo_code(TEXT, NUMERIC) TO anon;

COMMENT ON FUNCTION public.increment_promo_code_usage IS 'Increment the usage count of a promo code';
COMMENT ON FUNCTION public.validate_promo_code IS 'Validate a promo code and return discount percentage';
