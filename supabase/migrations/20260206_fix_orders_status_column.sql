-- Fix Orders Status Column Type
-- Migration: 20260206_fix_orders_status_column.sql
-- This migration fixes the status column to use the order_status enum type

-- First, check if the order_status enum exists, if not create it
DO $$ BEGIN
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

-- Drop triggers that depend on the status column
DROP TRIGGER IF EXISTS trigger_log_order_status_change ON orders;
DROP TRIGGER IF EXISTS trigger_auto_generate_order_codes ON orders;

-- Drop the existing status column if it's text type and recreate as enum
DO $$ 
BEGIN
    -- Check if status column exists and is text type
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'orders' 
        AND column_name = 'status'
        AND data_type = 'text'
    ) THEN
        -- Backup existing status values
        ALTER TABLE orders ADD COLUMN IF NOT EXISTS status_backup text;
        UPDATE orders SET status_backup = status WHERE status_backup IS NULL;
        
        -- Drop the text status column
        ALTER TABLE orders DROP COLUMN IF EXISTS status;
        
        -- Add new status column with enum type
        ALTER TABLE orders ADD COLUMN status order_status DEFAULT 'pending';
        
        -- Migrate data from backup, mapping old values to new enum values
        UPDATE orders 
        SET status = CASE 
            WHEN status_backup = 'pending' THEN 'pending'::order_status
            WHEN status_backup = 'paid' THEN 'confirmed'::order_status
            WHEN status_backup = 'processing' THEN 'preparing'::order_status
            WHEN status_backup = 'ready_for_pickup' THEN 'ready_for_pickup'::order_status
            WHEN status_backup = 'out_for_delivery' THEN 'out_for_delivery'::order_status
            WHEN status_backup = 'completed' THEN 'completed'::order_status
            WHEN status_backup = 'cancelled' THEN 'cancelled'::order_status
            ELSE 'pending'::order_status
        END
        WHERE status_backup IS NOT NULL;
        
        -- Drop backup column
        ALTER TABLE orders DROP COLUMN IF EXISTS status_backup;
    END IF;
END $$;

-- Ensure the status column has the correct default
ALTER TABLE orders ALTER COLUMN status SET DEFAULT 'pending'::order_status;

-- Add check constraint to ensure only valid enum values
-- (This is automatically enforced by the enum type, but we add it for clarity)
COMMENT ON COLUMN orders.status IS 'Order status: pending, confirmed, preparing, ready_for_pickup, out_for_delivery, delivered, completed, cancelled';

-- Update any NULL status values to 'pending'
UPDATE orders SET status = 'pending'::order_status WHERE status IS NULL;

-- Make status NOT NULL
ALTER TABLE orders ALTER COLUMN status SET NOT NULL;

-- Recreate the trigger function with correct type
CREATE OR REPLACE FUNCTION log_order_status_change()
RETURNS TRIGGER AS $
BEGIN
    -- Only log if status actually changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO order_status_history (order_id, status, changed_by, notes)
        VALUES (NEW.id, NEW.status, auth.uid(), 'Status changed from ' || OLD.status::text || ' to ' || NEW.status::text);
        
        -- Update timestamp fields based on status
        CASE NEW.status
            WHEN 'ready_for_pickup' THEN
                NEW.actual_ready_time := NOW();
            WHEN 'delivered' THEN
                NEW.delivered_at := NOW();
            WHEN 'completed' THEN
                IF NEW.delivery_type = 'pickup' THEN
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
$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER trigger_log_order_status_change
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION log_order_status_change();

-- Recreate the auto-generate codes trigger
CREATE OR REPLACE FUNCTION auto_generate_order_codes()
RETURNS TRIGGER AS $
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
$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_generate_order_codes
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_order_codes();

-- Grant necessary permissions for order_status_history
GRANT INSERT ON order_status_history TO authenticated;
GRANT SELECT ON order_status_history TO authenticated;

-- Add RLS policy to allow restaurants to insert status history for their orders
CREATE POLICY "Restaurants can insert status history for their orders"
    ON order_status_history FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_status_history.order_id
            AND orders.restaurant_id = auth.uid()
        )
    );

-- Add RLS policy to allow system (triggers) to insert status history
-- This is needed for the trigger function to work
ALTER TABLE order_status_history DISABLE ROW LEVEL SECURITY;

-- Re-enable RLS but with a permissive policy for inserts from triggers
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;

-- Allow inserts from authenticated users (including triggers running as authenticated)
CREATE POLICY "Allow status history inserts"
    ON order_status_history FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- But restrict selects to relevant users
DROP POLICY IF EXISTS "Users can view their order history" ON order_status_history;
DROP POLICY IF EXISTS "Restaurants can view their order history" ON order_status_history;

CREATE POLICY "Users can view their order history"
    ON order_status_history FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_status_history.order_id
            AND orders.user_id = auth.uid()
        )
    );

CREATE POLICY "Restaurants can view their order history"
    ON order_status_history FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_status_history.order_id
            AND orders.restaurant_id = auth.uid()
        )
    );
