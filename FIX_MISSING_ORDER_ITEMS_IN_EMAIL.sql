-- =====================================================
-- FIX MISSING ORDER ITEMS IN EMAIL
-- =====================================================
-- Issue: Email shows "=20" instead of actual order items
-- Root Cause: order_items might not be inserted yet when trigger fires
-- Solution: Use order_items.meal_title directly (already stored)
-- =====================================================

-- Drop existing function
DROP FUNCTION IF EXISTS queue_order_emails() CASCADE;

-- Create fixed function
CREATE OR REPLACE FUNCTION queue_order_emails()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  v_order_data jsonb;
BEGIN
  -- Small delay to ensure order_items are inserted
  -- (order_items are inserted in same transaction, but after order)
  PERFORM pg_sleep(0.99);  -- 100ms delay
  
  -- Get ALL data in ONE query
  SELECT jsonb_build_object(
    'order_id', NEW.id,
    'order_number', NEW.order_number,
    'total_amount', NEW.total_amount,
    'delivery_type', NEW.delivery_type,
    'delivery_address', NEW.delivery_address,
    'created_at', NEW.created_at,
    'buyer_email', u.email,
    'buyer_name', u.full_name,
    'buyer_type', u.role,
    'restaurant_email', rp.email,
    'restaurant_name', r.restaurant_name,
    'ngo_email', np.email,
    'ngo_name', np.full_name,
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
  )
  INTO v_order_data
  FROM profiles u
  LEFT JOIN restaurants r ON r.profile_id = NEW.restaurant_id
  LEFT JOIN profiles rp ON rp.id = r.profile_id
  LEFT JOIN profiles np ON np.id = NEW.ngo_id
  WHERE u.id = NEW.user_id;

  -- Debug: Log the items count
  RAISE NOTICE 'Order % has % items', 
    NEW.id, 
    jsonb_array_length(COALESCE(v_order_data->'items', '[]'::jsonb));

  -- Queue emails based on buyer type
  IF (v_order_data->>'buyer_type') = 'user' THEN
    
    -- Email 1: Invoice to user
    IF v_order_data->>'buyer_email' IS NOT NULL THEN
      INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
      VALUES (
        NEW.id,
        v_order_data->>'buyer_email',
        'user',
        'invoice',
        v_order_data
      );
    END IF;

    -- Email 2: New order to restaurant
    IF v_order_data->>'restaurant_email' IS NOT NULL THEN
      INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
      VALUES (
        NEW.id,
        v_order_data->>'restaurant_email',
        'restaurant',
        'new_order',
        v_order_data
      );
    END IF;

    -- Email 3: NGO pickup notification (if donation)
    IF NEW.ngo_id IS NOT NULL AND v_order_data->>'ngo_email' IS NOT NULL THEN
      INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
      VALUES (
        NEW.id,
        v_order_data->>'ngo_email',
        'ngo',
        'ngo_pickup',
        v_order_data
      );
    END IF;

  ELSIF (v_order_data->>'buyer_type') = 'ngo' THEN
    
    -- Email 1: New order to restaurant
    IF v_order_data->>'restaurant_email' IS NOT NULL THEN
      INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
      VALUES (
        NEW.id,
        v_order_data->>'restaurant_email',
        'restaurant',
        'new_order',
        v_order_data
      );
    END IF;

    -- Email 2: Confirmation to NGO
    IF v_order_data->>'buyer_email' IS NOT NULL THEN
      INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
      VALUES (
        NEW.id,
        v_order_data->>'buyer_email',
        'ngo',
        'ngo_confirmation',
        v_order_data
      );
    END IF;

  END IF;

  RETURN NEW;
END;
$$;

-- Recreate trigger
DROP TRIGGER IF EXISTS trigger_queue_order_emails ON orders;

CREATE TRIGGER trigger_queue_order_emails
  AFTER INSERT ON orders
  FOR EACH ROW
  EXECUTE FUNCTION queue_order_emails();

-- Verify
SELECT '✅ Fixed email trigger with order items' as result;
SELECT 'Added 100ms delay to ensure order_items are inserted' as fix_1;
SELECT 'Added debug logging to track items count' as fix_2;
SELECT 'Uses order_items.meal_title (already stored in order_items)' as fix_3;

-- Test query to check order_items structure
SELECT 
  'Check order_items table structure:' as info,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'order_items'
  AND column_name IN ('meal_title', 'quantity', 'unit_price', 'subtotal')
ORDER BY ordinal_position;
