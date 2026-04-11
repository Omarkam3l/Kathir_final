-- Cart payload for Stripe webhooks (metadata alone exceeds Stripe's 500-char limit)
CREATE TABLE IF NOT EXISTS public.stripe_checkout_snapshots (
  payment_intent_id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  cart_items JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_stripe_checkout_snapshots_user
  ON public.stripe_checkout_snapshots (user_id);

CREATE INDEX IF NOT EXISTS idx_stripe_checkout_snapshots_created
  ON public.stripe_checkout_snapshots (created_at);

COMMENT ON TABLE public.stripe_checkout_snapshots IS
  'Temporary cart JSON for payment_intent.succeeded webhook; deleted after order creation.';

ALTER TABLE public.stripe_checkout_snapshots ENABLE ROW LEVEL SECURITY;
