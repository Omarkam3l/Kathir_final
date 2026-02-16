-- =====================================================
-- COMPLETE EMAIL SYSTEM - FRESH START
-- =====================================================
-- This migration creates a complete email system from scratch
-- with proper logging and error handling

-- =====================================================
-- STEP 1: DROP EXISTING EMAIL SYSTEM (if any)
-- =====================================================
DROP TABLE IF EXISTS email_logs CASCADE;
DROP TABLE IF EXISTS email_queue CASCADE;
DROP FUNCTION IF EXISTS queue_order_email CASCADE;
DROP FUNCTION IF EXISTS get_pending_emails CASCADE;
DROP FUNCTION IF EXISTS process_email_queue_item CASCADE;
DROP TRIGGER IF EXISTS trigger_queue_order_emails ON orders CASCADE;

-- =====================================================
-- STEP 2: CREATE EMAIL QUEUE TABLE
-- =====================================================
CREATE TABLE email_queue (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  recipient_email text NOT NULL,
  recipient_type text NOT NULL CHECK (recipient_type IN ('user', 'restaurant', 'ngo')),
  email_type text NOT NULL CHECK (email_type IN ('invoice', 'new_order', 'ngo_pickup', 'ngo_confirmation')),
  email_data jsonb NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  attempts int NOT NULL DEFAULT 0,
  last_error text,
  created_at timestamptz NOT NULL DEFAULT NOW(),
  sent_at timestamptz,
  CONSTRAINT max_attempts CHECK (attempts <= 3)
);

-- Indexes
CREATE INDEX idx_email_queue_status ON email_queue(status, created_at);
CREATE INDEX idx_email_queue_order ON email_queue(order_id);
CREATE INDEX idx_email_queue_pending ON email_queue(status, attempts) WHERE status = 'pending';

-- =====================================================
-- STEP 3: CREATE EMAIL LOGS TABLE
-- =====================================================
CREATE TABLE email_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email_queue_id uuid REFERENCES email_queue(id) ON DELETE SET NULL,
  order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
  recipient_email text NOT NULL,
  email_type text NOT NULL,
  status text NOT NULL CHECK (status IN ('queued', 'sent', 'failed')),
  error_message text,
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT NOW()
);

-- Index
CREATE INDEX idx_email_logs_order ON email_logs(order_id, created_at DESC);
CREATE INDEX idx_email_logs_status ON email_logs(status, created_at DESC);

-- =====================================================
-- STEP 4: RLS POLICIES
-- =====================================================
ALTER TABLE email_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_logs ENABLE ROW LEVEL SECURITY;

-- Service role can manage everything
CREATE POLICY "Service role can manage email queue"
  ON email_queue FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Service role can manage email logs"
  ON email_logs FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Users can view their own email logs
CREATE POLICY "Users can view own email logs"
  ON email_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders o
      WHERE o.id = order_id
        AND o.user_id = auth.uid()
    )
  );

-- =====================================================
-- STEP 5: FUNCTION TO QUEUE ORDER EMAILS
-- =====================================================
CREATE OR REPLACE FUNCTION queue_order_email()
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
  v_email_id uuid;
BEGIN
  -- Only queue emails for new orders (INSERT) or when status changes to 'confirmed'
  IF (TG_OP = 'INSERT') OR 
     (TG_OP = 'UPDATE' AND NEW.status = 'confirmed' AND OLD.status != 'confirmed') THEN
    
    -- Get user details
    SELECT email, full_name INTO v_user_email, v_user_name
    FROM profiles
    WHERE id = NEW.user_id;
    
    -- Get restaurant details
    SELECT p.email, r.restaurant_name 
    INTO v_restaurant_email, v_restaurant_name
    FROM restaurants r
    JOIN profiles p ON p.id = r.profile_id
    WHERE r.profile_id = NEW.restaurant_id;
    
    -- Get NGO details if donation order
    IF NEW.delivery_type = 'donation' AND NEW.ngo_id IS NOT NULL THEN
      SELECT p.email, n.name 
      INTO v_ngo_email, v_ngo_name
      FROM ngos n
      JOIN profiles p ON p.id = n.profile_id
      WHERE n.profile_id = NEW.ngo_id;
    END IF;
    
    -- Build order data with items
    SELECT jsonb_build_object(
      'order_id', NEW.id,
      'order_number', NEW.order_number,
      'buyer_name', v_user_name,
      'restaurant_name', v_restaurant_name,
      'ngo_name', v_ngo_name,
      'delivery_type', NEW.delivery_type,
      'delivery_address', NEW.delivery_address,
      'total_amount', NEW.total_amount,
      'created_at', NEW.created_at,
      'items', COALESCE(
        (
          SELECT jsonb_agg(
            jsonb_build_object(
              'meal_title', oi.meal_title,
              'quantity', oi.quantity,
              'unit_price', oi.unit_price,
              'subtotal', oi.quantity * oi.unit_price
            )
          )
          FROM order_items oi
          WHERE oi.order_id = NEW.id
        ),
        '[]'::jsonb
      )
    ) INTO v_order_data;
    
    -- 1. Queue invoice email to user
    IF v_user_email IS NOT NULL THEN
      INSERT INTO email_queue (
        order_id, recipient_email, recipient_type, email_type, email_data
      ) VALUES (
        NEW.id, v_user_email, 'user', 
        CASE WHEN NEW.delivery_type = 'donation' THEN 'ngo_confirmation' ELSE 'invoice' END,
        v_order_data
      )
      RETURNING id INTO v_email_id;
      
      -- Log queued email
      INSERT INTO email_logs (
        email_queue_id, order_id, recipient_email, email_type, status
      ) VALUES (
        v_email_id, NEW.id, v_user_email,
        CASE WHEN NEW.delivery_type = 'donation' THEN 'ngo_confirmation' ELSE 'invoice' END,
        'queued'
      );
    END IF;
    
    -- 2. Queue new order notification to restaurant
    IF v_restaurant_email IS NOT NULL THEN
      INSERT INTO email_queue (
        order_id, recipient_email, recipient_type, email_type, email_data
      ) VALUES (
        NEW.id, v_restaurant_email, 'restaurant', 'new_order', v_order_data
      )
      RETURNING id INTO v_email_id;
      
      -- Log queued email
      INSERT INTO email_logs (
        email_queue_id, order_id, recipient_email, email_type, status
      ) VALUES (
        v_email_id, NEW.id, v_restaurant_email, 'new_order', 'queued'
      );
    END IF;
    
    -- 3. Queue pickup notification to NGO (if donation)
    IF NEW.delivery_type = 'donation' AND v_ngo_email IS NOT NULL THEN
      INSERT INTO email_queue (
        order_id, recipient_email, recipient_type, email_type, email_data
      ) VALUES (
        NEW.id, v_ngo_email, 'ngo', 'ngo_pickup', v_order_data
      )
      RETURNING id INTO v_email_id;
      
      -- Log queued email
      INSERT INTO email_logs (
        email_queue_id, order_id, recipient_email, email_type, status
      ) VALUES (
        v_email_id, NEW.id, v_ngo_email, 'ngo_pickup', 'queued'
      );
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$;

-- =====================================================
-- STEP 6: CREATE TRIGGER
-- =====================================================
CREATE TRIGGER trigger_queue_order_emails
  AFTER INSERT OR UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION queue_order_email();

-- =====================================================
-- STEP 7: FUNCTION TO GET PENDING EMAILS
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
    AND eq.attempts < 3
  ORDER BY eq.created_at ASC
  LIMIT p_limit;
END;
$$;

-- =====================================================
-- STEP 8: FUNCTION TO PROCESS EMAIL QUEUE ITEM
-- =====================================================
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
DECLARE
  v_order_id uuid;
  v_recipient_email text;
  v_email_type text;
BEGIN
  -- Get email details
  SELECT order_id, recipient_email, email_type
  INTO v_order_id, v_recipient_email, v_email_type
  FROM email_queue
  WHERE id = p_email_id;
  
  IF p_success THEN
    -- Mark as sent
    UPDATE email_queue
    SET 
      status = 'sent',
      sent_at = NOW()
    WHERE id = p_email_id;
    
    -- Log success
    INSERT INTO email_logs (
      email_queue_id, order_id, recipient_email, email_type, status
    ) VALUES (
      p_email_id, v_order_id, v_recipient_email, v_email_type, 'sent'
    );
  ELSE
    -- Increment attempts
    UPDATE email_queue
    SET 
      attempts = attempts + 1,
      last_error = p_error_message,
      status = CASE WHEN attempts + 1 >= 3 THEN 'failed' ELSE 'pending' END
    WHERE id = p_email_id;
    
    -- Log failure
    INSERT INTO email_logs (
      email_queue_id, order_id, recipient_email, email_type, status, error_message
    ) VALUES (
      p_email_id, v_order_id, v_recipient_email, v_email_type, 'failed', p_error_message
    );
  END IF;
END;
$$;

-- =====================================================
-- STEP 9: HELPER FUNCTION TO VIEW EMAIL STATUS
-- =====================================================
CREATE OR REPLACE FUNCTION get_order_email_status(p_order_id uuid)
RETURNS TABLE (
  recipient_email text,
  email_type text,
  status text,
  attempts int,
  last_error text,
  created_at timestamptz,
  sent_at timestamptz
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    eq.recipient_email,
    eq.email_type,
    eq.status,
    eq.attempts,
    eq.last_error,
    eq.created_at,
    eq.sent_at
  FROM email_queue eq
  WHERE eq.order_id = p_order_id
  ORDER BY eq.created_at DESC;
END;
$$;

-- =====================================================
-- COMMENTS
-- =====================================================
COMMENT ON TABLE email_queue IS 'Queue of emails to be sent for orders';
COMMENT ON TABLE email_logs IS 'Log of all email sending attempts';
COMMENT ON FUNCTION queue_order_email() IS 'Trigger function to queue emails when orders are created';
COMMENT ON FUNCTION get_pending_emails(int) IS 'Get pending emails from queue for processing';
COMMENT ON FUNCTION process_email_queue_item(uuid, boolean, text) IS 'Mark email as sent or failed';
COMMENT ON FUNCTION get_order_email_status(uuid) IS 'View email status for a specific order';
