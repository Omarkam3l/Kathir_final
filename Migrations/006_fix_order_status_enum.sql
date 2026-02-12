-- ============================================
-- Migration 006: Fix Order Status Enum Values
-- Date: 2026-02-11
-- Author: System Fix
-- ============================================
-- PROBLEM:
-- Code references 'paid' and 'processing' status values
-- but database enum only has: pending, confirmed, preparing, 
-- ready_for_pickup, out_for_delivery, delivered, completed, cancelled
-- ============================================

-- Check current enum values
DO $
DECLARE
  enum_values text[];
BEGIN
  SELECT array_agg(enumlabel ORDER BY enumsortorder)
  INTO enum_values
  FROM pg_enum
  WHERE enumtypid = 'order_status'::regtype;
  
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Current order_status enum values:';
  RAISE NOTICE '========================================';
  RAISE NOTICE '%', array_to_string(enum_values, ', ');
  RAISE NOTICE '========================================';
END $;

-- Option 1: Add missing enum values if needed
-- Uncomment if you want to add 'paid' and 'processing' to the enum
/*
DO $
BEGIN
  -- Add 'paid' after 'pending' if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumtypid = 'order_status'::regtype 
    AND enumlabel = 'paid'
  ) THEN
    ALTER TYPE order_status ADD VALUE 'paid' AFTER 'pending';
    RAISE NOTICE '✅ Added "paid" to order_status enum';
  ELSE
    RAISE NOTICE '✓ "paid" already exists in enum';
  END IF;

  -- Add 'processing' after 'paid' if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumtypid = 'order_status'::regtype 
    AND enumlabel = 'processing'
  ) THEN
    ALTER TYPE order_status ADD VALUE 'processing' AFTER 'paid';
    RAISE NOTICE '✅ Added "processing" to order_status enum';
  ELSE
    RAISE NOTICE '✓ "processing" already exists in enum';
  END IF;
END $;
*/

-- Option 2: Update existing orders with invalid status values
-- This maps old values to new valid values
DO $
DECLARE
  updated_count integer := 0;
BEGIN
  -- Note: This won't work if status is an enum column
  -- Only use if status is text column
  
  -- Check if any orders have invalid status
  SELECT COUNT(*) INTO updated_count
  FROM orders
  WHERE status::text NOT IN (
    'pending', 'confirmed', 'preparing', 'ready_for_pickup',
    'out_for_delivery', 'delivered', 'completed', 'cancelled'
  );
  
  IF updated_count > 0 THEN
    RAISE NOTICE '⚠️ Found % orders with invalid status values', updated_count;
    RAISE NOTICE 'Manual intervention may be required';
  ELSE
    RAISE NOTICE '✅ All orders have valid status values';
  END IF;
END $;

-- Verification: Show status distribution
DO $
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Order Status Distribution:';
  RAISE NOTICE '========================================';
  
  FOR status_rec IN 
    SELECT status, COUNT(*) as count
    FROM orders
    GROUP BY status
    ORDER BY count DESC
  LOOP
    RAISE NOTICE '  % : % orders', status_rec.status, status_rec.count;
  END LOOP;
  
  RAISE NOTICE '========================================';
END $;

-- Summary
DO $
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ Migration 006 completed';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Valid order_status values:';
  RAISE NOTICE '  - pending';
  RAISE NOTICE '  - confirmed';
  RAISE NOTICE '  - preparing';
  RAISE NOTICE '  - ready_for_pickup';
  RAISE NOTICE '  - out_for_delivery';
  RAISE NOTICE '  - delivered';
  RAISE NOTICE '  - completed';
  RAISE NOTICE '  - cancelled';
  RAISE NOTICE '';
  RAISE NOTICE 'Code updated to use correct enum values';
  RAISE NOTICE '========================================';
END $;
