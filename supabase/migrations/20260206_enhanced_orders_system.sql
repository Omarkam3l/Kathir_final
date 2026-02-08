-- Enhanced Orders System with States, QR Codes, and Tracking
-- Migration: 20260206_enhanced_orders_system.sql

-- Drop existing order_status type if exists and recreate with all states
DO $$ BEGIN
    DROP TYPE IF EXISTS order_status CASCADE;
    CREATE TYPE order_status AS ENUM (
        'pending',
        'confirmed',
        'preparing',
        'ready_for_pickup',
        'out_for_delivery',
        'delivered',
        'completed',
        'cancelled'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Add new columns to orders table
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS status order_status DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS qr_code TEXT,
ADD COLUMN IF NOT EXISTS pickup_code VARCHAR(6),
ADD COLUMN IF NOT EXISTS estimated_ready_time TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS actual_ready_time TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS picked_up_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS cancellation_reason TEXT,
ADD COLUMN IF NOT EXISTS special_instructions TEXT,
ADD COLUMN IF NOT EXISTS rating INTEGER CHECK (rating >= 1 AND rating <= 5),
ADD COLUMN IF NOT EXISTS review_text TEXT,
ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ;

-- Create order_status_history table for tracking
CREATE TABLE IF NOT EXISTS order_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    status order_status NOT NULL,
    changed_by UUID REFERENCES profiles(id),
    changed_at TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(order_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_user_status ON orders(user_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_restaurant_status ON orders(restaurant_id, status);

-- Function to generate unique pickup code
CREATE OR REPLACE FUNCTION generate_pickup_code()
RETURNS TEXT AS $$
DECLARE
    code TEXT;
    exists BOOLEAN;
BEGIN
    LOOP
        -- Generate 6-digit alphanumeric code
        code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6));
        
        -- Check if code already exists in active orders
        SELECT EXISTS(
            SELECT 1 FROM orders 
            WHERE pickup_code = code 
            AND status IN ('pending', 'confirmed', 'preparing', 'ready_for_pickup')
        ) INTO exists;
        
        EXIT WHEN NOT exists;
    END LOOP;
    
    RETURN code;
END;
$$ LANGUAGE plpgsql;

-- Function to generate QR code data (JSON string with order info)
CREATE OR REPLACE FUNCTION generate_qr_code_data(order_uuid UUID)
RETURNS TEXT AS $$
DECLARE
    qr_data JSONB;
BEGIN
    SELECT jsonb_build_object(
        'order_id', o.id,
        'pickup_code', o.pickup_code,
        'user_id', o.user_id,
        'restaurant_id', o.restaurant_id,
        'total', o.total_amount,
        'created_at', o.created_at
    ) INTO qr_data
    FROM orders o
    WHERE o.id = order_uuid;
    
    RETURN qr_data::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate pickup code and QR data on order creation
CREATE OR REPLACE FUNCTION auto_generate_order_codes()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate pickup code if not exists
    IF NEW.pickup_code IS NULL THEN
        NEW.pickup_code := generate_pickup_code();
    END IF;
    
    -- Generate QR code data
    IF NEW.qr_code IS NULL THEN
        NEW.qr_code := generate_qr_code_data(NEW.id);
    END IF;
    
    -- Set estimated ready time (30 minutes from now by default)
    IF NEW.estimated_ready_time IS NULL THEN
        NEW.estimated_ready_time := NOW() + INTERVAL '30 minutes';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_auto_generate_order_codes ON orders;
CREATE TRIGGER trigger_auto_generate_order_codes
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_order_codes();

-- Trigger to log status changes
CREATE OR REPLACE FUNCTION log_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only log if status actually changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO order_status_history (order_id, status, changed_by, notes)
        VALUES (NEW.id, NEW.status, auth.uid(), 'Status changed from ' || OLD.status || ' to ' || NEW.status);
        
        -- Update timestamp fields based on status
        CASE NEW.status
            WHEN 'ready_for_pickup' THEN
                NEW.actual_ready_time := NOW();
            WHEN 'delivered' THEN
                NEW.delivered_at := NOW();
            WHEN 'completed' THEN
                IF NEW.delivery_method = 'pickup' THEN
                    NEW.picked_up_at := NOW();
                ELSE
                    NEW.delivered_at := NOW();
                END IF;
            WHEN 'cancelled' THEN
                NEW.cancelled_at := NOW();
            ELSE
                NULL;
        END CASE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for status logging
DROP TRIGGER IF EXISTS trigger_log_order_status_change ON orders;
CREATE TRIGGER trigger_log_order_status_change
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION log_order_status_change();

-- Function to verify pickup code
CREATE OR REPLACE FUNCTION verify_pickup_code(
    p_order_id UUID,
    p_pickup_code TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    is_valid BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM orders
        WHERE id = p_order_id
        AND pickup_code = UPPER(p_pickup_code)
        AND status = 'ready_for_pickup'
    ) INTO is_valid;
    
    RETURN is_valid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to complete pickup
CREATE OR REPLACE FUNCTION complete_pickup(
    p_order_id UUID,
    p_pickup_code TEXT
)
RETURNS JSONB AS $$
DECLARE
    is_valid BOOLEAN;
    result JSONB;
BEGIN
    -- Verify pickup code
    is_valid := verify_pickup_code(p_order_id, p_pickup_code);
    
    IF NOT is_valid THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Invalid pickup code or order not ready'
        );
    END IF;
    
    -- Update order status
    UPDATE orders
    SET status = 'completed',
        picked_up_at = NOW()
    WHERE id = p_order_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Order picked up successfully'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT SELECT, INSERT ON order_status_history TO authenticated;
GRANT EXECUTE ON FUNCTION generate_pickup_code() TO authenticated;
GRANT EXECUTE ON FUNCTION generate_qr_code_data(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION verify_pickup_code(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION complete_pickup(UUID, TEXT) TO authenticated;

-- Update existing orders with pickup codes (for migration)
UPDATE orders
SET pickup_code = generate_pickup_code(),
    qr_code = generate_qr_code_data(id)
WHERE pickup_code IS NULL;

-- Add RLS policies for order_status_history
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their order history"
    ON order_status_history FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_status_history.order_id
            AND orders.user_id = auth.uid()
        )
    );

CREATE POLICY "Restaurants can view their order history"
    ON order_status_history FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_status_history.order_id
            AND orders.restaurant_id IN (
                SELECT id FROM profiles WHERE id = auth.uid() AND role = 'restaurant'
            )
        )
    );

-- Comment on tables and columns
COMMENT ON COLUMN orders.status IS 'Current status of the order';
COMMENT ON COLUMN orders.qr_code IS 'QR code data (JSON) for pickup verification';
COMMENT ON COLUMN orders.pickup_code IS '6-character alphanumeric code for pickup';
COMMENT ON COLUMN orders.estimated_ready_time IS 'When the order is estimated to be ready';
COMMENT ON COLUMN orders.actual_ready_time IS 'When the order was actually ready';
COMMENT ON COLUMN orders.picked_up_at IS 'When the order was picked up by customer';
COMMENT ON COLUMN orders.delivered_at IS 'When the order was delivered';
COMMENT ON COLUMN orders.rating IS 'Customer rating (1-5 stars)';
COMMENT ON TABLE order_status_history IS 'Tracks all status changes for orders';
