-- Migration: Cleanup backup tables
-- Date: 2026-03-12
-- Description: Drops all backup tables created during the database cleanup migrations.
--              Only run this after verifying everything works correctly!

-- ⚠️ WARNING: This will permanently delete backup data!
-- ⚠️ Make sure your application is working correctly before running this!

-- ============================================================================
-- List backup tables before dropping
-- ============================================================================

DO $$
DECLARE
    v_profiles_address_backup integer;
    v_profiles_location_backup integer;
    v_profiles_default_location_backup integer;
    v_restaurants_address_backup integer;
BEGIN
    -- Count records in each backup table
    SELECT COUNT(*) INTO v_profiles_address_backup 
    FROM profiles_address_backup 
    WHERE true;
    
    SELECT COUNT(*) INTO v_profiles_location_backup 
    FROM profiles_location_backup 
    WHERE true;
    
    SELECT COUNT(*) INTO v_profiles_default_location_backup 
    FROM profiles_default_location_backup 
    WHERE true;
    
    SELECT COUNT(*) INTO v_restaurants_address_backup 
    FROM restaurants_address_backup 
    WHERE true;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'BACKUP TABLES TO BE DROPPED';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'profiles_address_backup: % records', v_profiles_address_backup;
    RAISE NOTICE 'profiles_location_backup: % records', v_profiles_location_backup;
    RAISE NOTICE 'profiles_default_location_backup: % records', v_profiles_default_location_backup;
    RAISE NOTICE 'restaurants_address_backup: % records', v_restaurants_address_backup;
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  These tables will be dropped in 5 seconds...';
    RAISE NOTICE '💡 Press Ctrl+C now to cancel if you need the backups!';
    RAISE NOTICE '';
    
    -- Wait 5 seconds to give user time to cancel
    PERFORM pg_sleep(5);
    
EXCEPTION
    WHEN undefined_table THEN
        RAISE NOTICE '⚠️  Some backup tables do not exist (already dropped or never created)';
END $$;

-- ============================================================================
-- Drop backup tables
-- ============================================================================

-- Drop profiles_address_backup
DROP TABLE IF EXISTS profiles_address_backup CASCADE;

-- Drop profiles_location_backup
DROP TABLE IF EXISTS profiles_location_backup CASCADE;

-- Drop profiles_default_location_backup
DROP TABLE IF EXISTS profiles_default_location_backup CASCADE;

-- Drop restaurants_address_backup
DROP TABLE IF EXISTS restaurants_address_backup CASCADE;

-- ============================================================================
-- Verification
-- ============================================================================

DO $$
DECLARE
    v_remaining_tables integer;
BEGIN
    -- Count remaining backup tables
    SELECT COUNT(*) INTO v_remaining_tables
    FROM information_schema.tables
    WHERE table_name IN (
        'profiles_address_backup',
        'profiles_location_backup',
        'profiles_default_location_backup',
        'restaurants_address_backup'
    );
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ CLEANUP COMPLETED';
    RAISE NOTICE '========================================';
    
    IF v_remaining_tables = 0 THEN
        RAISE NOTICE '✅ All backup tables dropped successfully';
    ELSE
        RAISE WARNING '⚠️  % backup tables still exist', v_remaining_tables;
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '🗑️  Dropped tables:';
    RAISE NOTICE '   - profiles_address_backup';
    RAISE NOTICE '   - profiles_location_backup';
    RAISE NOTICE '   - profiles_default_location_backup';
    RAISE NOTICE '   - restaurants_address_backup';
    RAISE NOTICE '';
    RAISE NOTICE '💡 Backup data is now permanently deleted';
    RAISE NOTICE '========================================';
END $$;
