-- =====================================================
-- EMAIL SYSTEM HELPER FUNCTIONS
-- =====================================================
-- Additional helper functions for debugging and testing
-- the email notification system
-- =====================================================

-- =====================================================
-- FUNCTION: Manually Queue Emails for Existing Order
-- =====================================================
-- Use this to manually queue emails for orders that were
-- created before the email system was set up

CREATE OR REPLACE FUNCTION manually_queue_order_emails(p_order_id uuid)
RETURNS jsonb
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
  v_order_record RECORD;
  v_emails_queued int := 0;
BEGIN
  -- Get order details
  SELECT * INTO v_order_record
  FROM orders
  WHERE id = p_order_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Order not found'
    );
  END IF;

  -- Get order details with all related data
  SELECT jsonb_build_object(
    'order_id', v_order_record.id,
    'order_number', v_order_record.id::text,
    'total_amount', v_order_record.total_amount,
    'delivery_type', v_order_record.delivery_type,
    'delivery_address', v_order_record.delivery_address,
    'created_at', v_order_record.created_at,
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
      WHERE oi.order_id = p_order_id
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
  WHERE p.id = v_order_record.user_id;

  -- Get restaurant details
  SELECT 
    p.email,
    r.restaurant_name
  INTO 
    v_restaurant_email,
    v_restaurant_name
  FROM restaurants r
  JOIN profiles p ON r.profile_id = p.id
  WHERE r.profile_id = v_order_record.restaurant_id;

  -- Get NGO details if donation
  IF v_order_record.ngo_id IS NOT NULL THEN
    SELECT 
      p.email,
      p.full_name
    INTO 
      v_ngo_email,
      v_ngo_name
    FROM profiles p
    WHERE p.id = v_order_record.ngo_id;
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

  -- Delete any existing queued emails for this order
  DELETE FROM email_queue WHERE order_id = p_order_id;

  -- Queue emails based on buyer type
  IF v_buyer_type = 'user' THEN
    
    -- Email 1: Invoice to user
    INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
    VALUES (p_order_id, v_user_email, 'user', 'invoice', v_order_data);
    v_emails_queued := v_emails_queued + 1;

    -- Email 2: New order notification to restaurant
    INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
    VALUES (p_order_id, v_restaurant_email, 'restaurant', 'new_order', v_order_data);
    v_emails_queued := v_emails_queued + 1;

    -- Email 3: If donation, notify NGO
    IF v_order_record.ngo_id IS NOT NULL AND v_ngo_email IS NOT NULL THEN
      INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
      VALUES (p_order_id, v_ngo_email, 'ngo', 'ngo_pickup', v_order_data);
      v_emails_queued := v_emails_queued + 1;
    END IF;

  ELSIF v_buyer_type = 'ngo' THEN
    
    -- Email 1: New order notification to restaurant
    INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
    VALUES (p_order_id, v_restaurant_email, 'restaurant', 'new_order', v_order_data);
    v_emails_queued := v_emails_queued + 1;

    -- Email 2: Confirmation to NGO
    INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
    VALUES (p_order_id, v_user_email, 'ngo', 'ngo_confirmation', v_order_data);
    v_emails_queued := v_emails_queued + 1;

  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'emails_queued', v_emails_queued,
    'order_id', p_order_id,
    'message', format('Successfully queued %s emails for order', v_emails_queued)
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;

COMMENT ON FUNCTION manually_queue_order_emails(uuid) IS 
'Manually queue emails for an existing order. Useful for testing or re-sending emails.';

-- Grant execute permission
GRANT EXECUTE ON FUNCTION manually_queue_order_emails(uuid) TO authenticated, service_role;

-- =====================================================
-- FUNCTION: Get Email Queue Status
-- =====================================================
-- Get detailed status of email queue for an order

CREATE OR REPLACE FUNCTION get_order_email_status(p_order_id uuid)
RETURNS TABLE (
  email_id uuid,
  recipient_email text,
  recipient_type text,
  email_type text,
  status text,
  attempts int,
  error_message text,
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
    eq.id,
    eq.recipient_email,
    eq.recipient_type,
    eq.email_type,
    eq.status,
    eq.attempts,
    eq.error_message,
    eq.created_at,
    eq.sent_at
  FROM email_queue eq
  WHERE eq.order_id = p_order_id
  ORDER BY eq.created_at;
END;
$$;

COMMENT ON FUNCTION get_order_email_status(uuid) IS 
'Get email queue status for a specific order';

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_order_email_status(uuid) TO authenticated, service_role;

-- =====================================================
-- FUNCTION: Retry Failed Emails
-- =====================================================
-- Reset failed emails to pending status for retry

CREATE OR REPLACE FUNCTION retry_failed_emails(p_order_id uuid DEFAULT NULL)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_updated_count int;
BEGIN
  IF p_order_id IS NOT NULL THEN
    -- Retry failed emails for specific order
    UPDATE email_queue
    SET 
      status = 'pending',
      attempts = 0,
      error_message = NULL,
      last_attempt_at = NULL,
      updated_at = NOW()
    WHERE order_id = p_order_id
      AND status = 'failed';
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RETURN jsonb_build_object(
      'success', true,
      'emails_reset', v_updated_count,
      'order_id', p_order_id
    );
  ELSE
    -- Retry all failed emails
    UPDATE email_queue
    SET 
      status = 'pending',
      attempts = 0,
      error_message = NULL,
      last_attempt_at = NULL,
      updated_at = NOW()
    WHERE status = 'failed';
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RETURN jsonb_build_object(
      'success', true,
      'emails_reset', v_updated_count,
      'message', 'All failed emails reset to pending'
    );
  END IF;
END;
$$;

COMMENT ON FUNCTION retry_failed_emails(uuid) IS 
'Reset failed emails to pending status for retry. Pass order_id to retry specific order, or NULL for all failed emails.';

-- Grant execute permission
GRANT EXECUTE ON FUNCTION retry_failed_emails(uuid) TO authenticated, service_role;

-- =====================================================
-- VERIFICATION
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '✅ Email system helper functions created successfully!';
  RAISE NOTICE '';
  RAISE NOTICE 'Available functions:';
  RAISE NOTICE '  - manually_queue_order_emails(order_id) - Queue emails for existing order';
  RAISE NOTICE '  - get_order_email_status(order_id) - Check email status';
  RAISE NOTICE '  - retry_failed_emails(order_id) - Retry failed emails';
  RAISE NOTICE '';
  RAISE NOTICE 'Example usage:';
  RAISE NOTICE '  SELECT manually_queue_order_emails(''YOUR_ORDER_ID'');';
  RAISE NOTICE '  SELECT * FROM get_order_email_status(''YOUR_ORDER_ID'');';
  RAISE NOTICE '  SELECT retry_failed_emails(''YOUR_ORDER_ID'');';
END;
$$;
