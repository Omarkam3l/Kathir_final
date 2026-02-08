-- Generate Missing QR Codes and Pickup Codes for Existing Orders
-- Migration: 20260206_generate_missing_qr_codes.sql

-- Update all existing orders that don't have pickup codes or QR codes
UPDATE orders
SET 
    pickup_code = generate_pickup_code(),
    qr_code = generate_qr_code_data(id),
    estimated_ready_time = COALESCE(estimated_ready_time, created_at + INTERVAL '30 minutes')
WHERE pickup_code IS NULL OR qr_code IS NULL;

-- Verify the update
DO $$
DECLARE
    missing_codes INTEGER;
BEGIN
    SELECT COUNT(*) INTO missing_codes
    FROM orders
    WHERE pickup_code IS NULL OR qr_code IS NULL;
    
    IF missing_codes > 0 THEN
        RAISE NOTICE 'Warning: % orders still have missing pickup codes or QR codes', missing_codes;
    ELSE
        RAISE NOTICE 'Success: All orders now have pickup codes and QR codes';
    END IF;
END $$;
