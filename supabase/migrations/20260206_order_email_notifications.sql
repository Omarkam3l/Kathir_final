-- =====================================================
-- ORDER EMAIL NOTIFICATIONS SYSTEM
-- =====================================================
-- This migration creates a comprehensive email notification system
-- for orders using Supabase Edge Functions.
--
-- Features:
-- 1. User purchases → Email to user (invoice) + restaurant (new order)
-- 2. User donates to NGO → Email to user + restaurant + NGO
-- 3. NGO purchases → Email to restaurant(s) + NGO
--
-- Implementation:
-- - Database trigger on orders table
-- - Edge function to send emails via Resend/SendGrid
-- - Email templates for different scenarios
-- =====================================================

-- =====================================================
-- EMAIL QUEUE TABLE
-- =====================================================
-- Store emails to be sent (for retry logic and tracking)

CREATE TABLE IF NOT EXISTS email_queue (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  recipient_email text NOT NULL,
  recipient_type text NOT NULL CHECK (recipient_type IN ('user', 'restaurant', 'ngo')),
  email_type text NOT NULL CHECK (email_type IN ('invoice', 'new_order', 'ngo_pickup', 'ngo_confirmation')),
  email_data jsonb NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  attempts int NOT NULL DEFAULT 0,
  last_attempt_at timestamptz,
  sent_at timestamptz,
  error_message text,
  created_at timestamptz NOT NULL DEFAULT NOW(),
  updated_at timestamptz NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_email_queue_status ON email_queue(status, created_at);
CREATE INDEX idx_email_queue_order_id ON email_queue(order_id);

-- RLS policies
ALTER TABLE email_queue ENABLE ROW LEVEL SECURITY;

-- Only system can manage email queue
CREATE POLICY "Service role can manage email queue"
  ON email_queue
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- FUNCTION: Queue Order Emails
-- =====================================================
-- This function queues all necessary emails when an order is created

CREATE OR REPLACE FUNCTION queue_order_emails()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_user_email text;
  v_user_name text;
  v_restaurant_email text;
  v_restaurant_name text;
  v_ngo_email text;
  v_ngo_name text;
  v_order_data jsonb;
  v_buyer_type text;
BEGIN
  -- Get order details with all related data
  SELECT jsonb_build_object(
    'order_id', NEW.id,
    'order_number', NEW.id::text,
    'total_amount', NEW.total_amount,
    'delivery_type', NEW.delivery_type,
    'delivery_address', NEW.delivery_address,
    'created_at', NEW.created_at,
    'items', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'meal_title', m.title,
          'quantity', oi.quantity,
          'unit_price', oi.unit_price,
          'subtotal', oi.subtotal
        )
      )
      FROM order_items oi
      JOIN meals m ON oi.meal_id = m.id
      WHERE oi.order_id = NEW.id
    )
  ) INTO v_order_data;

  -- Get user/buyer details
  SELECT 
    p.email,
    p.full_name,
    p.role
  INTO 
    v_user_email,
    v_user_name,
    v_buyer_type
  FROM profiles p
  WHERE p.id = NEW.user_id;

  -- Get restaurant details
  SELECT 
    p.email,
    r.restaurant_name
  INTO 
    v_restaurant_email,
    v_restaurant_name
  FROM restaurants r
  JOIN profiles p ON r.profile_id = p.id
  WHERE r.profile_id = NEW.restaurant_id;

  -- Get NGO details if donation
  IF NEW.ngo_id IS NOT NULL THEN
    SELECT 
      p.email,
      p.full_name
    INTO 
      v_ngo_email,
      v_ngo_name
    FROM profiles p
    WHERE p.id = NEW.ngo_id;
  END IF;

  -- Add buyer and restaurant info to order data
  v_order_data := v_order_data || jsonb_build_object(
    'buyer_email', v_user_email,
    'buyer_name', v_user_name,
    'buyer_type', v_buyer_type,
    'restaurant_email', v_restaurant_email,
    'restaurant_name', v_restaurant_name,
    'ngo_email', v_ngo_email,
    'ngo_name', v_ngo_name
  );

  -- SCENARIO 1 & 2: User purchases (delivery/pickup or donate to NGO)
  IF v_buyer_type = 'user' THEN
    
    -- Email 1: Invoice to user
    INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
    VALUES (
      NEW.id,
      v_user_email,
      'user',
      'invoice',
      v_order_data
    );

    -- Email 2: New order notification to restaurant
    INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
    VALUES (
      NEW.id,
      v_restaurant_email,
      'restaurant',
      'new_order',
      v_order_data
    );

    -- Email 3: If donation, notify NGO
    IF NEW.ngo_id IS NOT NULL AND v_ngo_email IS NOT NULL THEN
      INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
      VALUES (
        NEW.id,
        v_ngo_email,
        'ngo',
        'ngo_pickup',
        v_order_data
      );
    END IF;

  -- SCENARIO 3: NGO purchases
  ELSIF v_buyer_type = 'ngo' THEN
    
    -- Email 1: New order notification to restaurant
    INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
    VALUES (
      NEW.id,
      v_restaurant_email,
      'restaurant',
      'new_order',
      v_order_data
    );

    -- Email 2: Confirmation to NGO
    INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
    VALUES (
      NEW.id,
      v_user_email,
      'ngo',
      'ngo_confirmation',
      v_order_data
    );

  END IF;

  RETURN NEW;
END;
$$;

-- =====================================================
-- TRIGGER: Send emails on order creation
-- =====================================================

DROP TRIGGER IF EXISTS trigger_queue_order_emails ON orders;

CREATE TRIGGER trigger_queue_order_emails
  AFTER INSERT ON orders
  FOR EACH ROW
  EXECUTE FUNCTION queue_order_emails();

-- =====================================================
-- FUNCTION: Process Email Queue (called by Edge Function)
-- =====================================================
-- This function marks emails as sent or failed

CREATE OR REPLACE FUNCTION process_email_queue_item(
  p_email_id uuid,
  p_success boolean,
  p_error_message text DEFAULT NULL
)
RETURNS void
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_success THEN
    UPDATE email_queue
    SET 
      status = 'sent',
      sent_at = NOW(),
      updated_at = NOW()
    WHERE id = p_email_id;
  ELSE
    UPDATE email_queue
    SET 
      status = 'failed',
      attempts = attempts + 1,
      last_attempt_at = NOW(),
      error_message = p_error_message,
      updated_at = NOW()
    WHERE id = p_email_id;
  END IF;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION process_email_queue_item(uuid, boolean, text) TO service_role;

-- =====================================================
-- FUNCTION: Get Pending Emails (for Edge Function)
-- =====================================================

CREATE OR REPLACE FUNCTION get_pending_emails(p_limit int DEFAULT 10)
RETURNS TABLE (
  id uuid,
  order_id uuid,
  recipient_email text,
  recipient_type text,
  email_type text,
  email_data jsonb,
  attempts int
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    eq.id,
    eq.order_id,
    eq.recipient_email,
    eq.recipient_type,
    eq.email_type,
    eq.email_data,
    eq.attempts
  FROM email_queue eq
  WHERE eq.status = 'pending'
    AND eq.attempts < 3  -- Max 3 attempts
  ORDER BY eq.created_at ASC
  LIMIT p_limit;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_pending_emails(int) TO service_role;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE email_queue IS 
'Queue for order-related emails. Processed by Edge Function.';

COMMENT ON FUNCTION queue_order_emails() IS 
'Automatically queues emails when an order is created. 
Handles user purchases, donations, and NGO purchases.';

COMMENT ON FUNCTION process_email_queue_item(uuid, boolean, text) IS 
'Marks an email as sent or failed. Called by Edge Function after sending.';

COMMENT ON FUNCTION get_pending_emails(int) IS 
'Returns pending emails to be processed by Edge Function.';

