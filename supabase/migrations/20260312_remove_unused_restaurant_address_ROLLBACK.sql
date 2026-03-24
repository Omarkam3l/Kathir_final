-- ROLLBACK Migration: Restore 'address' column to restaurants table
-- Date: 2026-03-12
-- Description: Restores the 'address' column to restaurants table

-- ⚠️ WARNING: Only run this if you need to rollback the migration!

-- ============================================================================
-- STEP 1: Restore column to restaurants table
-- ============================================================================

-- Add back address column
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS address text;

-- ============================================================================
-- STEP 2: Restore data from backup table
-- ============================================================================

-- Verify backup table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'restaurants_address_backup') THEN
        RAISE EXCEPTION 'Backup table restaurants_address_backup does not exist! Cannot rollback.';
    END IF;
END $$;

-- Restore backed up data
UPDATE restaurants r
SET address = b.address
FROM restaurants_address_backup b
WHERE r.profile_id = b.profile_id
  AND b.address IS NOT NULL;

-- ============================================================================
-- STEP 3: Verification
-- ============================================================================

DO $$
DECLARE
    v_restored_count integer;
BEGIN
    SELECT COUNT(*) INTO v_restored_count 
    FROM restaurants 
    WHERE address IS NOT NULL;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '🔄 ROLLBACK COMPLETED';
    RAISE NOTICE '========================================';
    RAISE NOTICE '📊 Restored records with address: %', v_restored_count;
    RAISE NOTICE '📝 Column restored: restaurants.address';
    RAISE NOTICE '⚠️  Backup table still exists: restaurants_address_backup';
    RAISE NOTICE '💡 Drop backup table manually after verification';
    RAISE NOTICE '========================================';
END $$;

-- ============================================================================
-- STEP 4: Cleanup (OPTIONAL)
-- ============================================================================

-- Uncomment after verifying rollback worked
-- DROP TABLE IF EXISTS restaurants_address_backup;
