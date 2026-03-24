-- Verification Script: Check migration success
-- Run this after executing the migration to verify everything is correct

\echo '========================================'
\echo 'MIGRATION VERIFICATION SCRIPT'
\echo '========================================'
\echo ''

-- ============================================================================
-- 1. Check columns were removed
-- ============================================================================

\echo '1. Checking if columns were removed...'
\echo ''

SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ profiles.address_text removed'
        ELSE '❌ profiles.address_text still exists'
    END as status
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name = 'address_text';

SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ profiles.default_location removed'
        ELSE '❌ profiles.default_location still exists'
    END as status
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name = 'default_location';

SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ profiles.profile_latitude removed'
        ELSE '❌ profiles.profile_latitude still exists'
    END as status
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name = 'profile_latitude';

SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ profiles.profile_longitude removed'
        ELSE '❌ profiles.profile_longitude still exists'
    END as status
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name = 'profile_longitude';

SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ restaurants.address removed'
        ELSE '❌ restaurants.address still exists'
    END as status
FROM information_schema.columns 
WHERE table_name = 'restaurants' AND column_name = 'address';

-- Check trigger removed
SELECT 
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_profile_default_location')
        THEN '✅ trigger_update_profile_default_location removed'
        ELSE '❌ trigger_update_profile_default_location still exists'
    END as status;

-- Check function removed
SELECT 
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_profile_default_location')
        THEN '✅ update_profile_default_location() function removed'
        ELSE '❌ update_profile_default_location() function still exists'
    END as status;

\echo ''

-- ============================================================================
-- 2. Check backup tables exist
-- ============================================================================

\echo '2. Checking backup tables...'
\echo ''

SELECT 
    'profiles_address_backup' as backup_table,
    COUNT(*) as records_backed_up
FROM profiles_address_backup;

SELECT 
    'profiles_location_backup' as backup_table,
    COUNT(*) as records_backed_up
FROM profiles_location_backup;

SELECT 
    'restaurants_address_backup' as backup_table,
    COUNT(*) as records_backed_up
FROM restaurants_address_backup;

\echo ''

-- ============================================================================
-- 3. Verify data is in proper tables
-- ============================================================================

\echo '3. Verifying address data distribution...'
\echo ''

-- Count users with addresses in user_addresses table
SELECT 
    'Regular Users' as user_type,
    COUNT(DISTINCT p.id) as total_users,
    COUNT(DISTINCT ua.user_id) as users_with_addresses,
    ROUND(COUNT(DISTINCT ua.user_id)::numeric / NULLIF(COUNT(DISTINCT p.id), 0) * 100, 2) as percentage
FROM profiles p
LEFT JOIN user_addresses ua ON p.id = ua.user_id
WHERE p.role = 'user'
GROUP BY user_type;

-- Count restaurants with addresses
SELECT 
    'Restaurants' as user_type,
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE address_text IS NOT NULL) as users_with_addresses,
    ROUND(COUNT(*) FILTER (WHERE address_text IS NOT NULL)::numeric / NULLIF(COUNT(*), 0) * 100, 2) as percentage
FROM restaurants;

-- Count NGOs with addresses
SELECT 
    'NGOs' as user_type,
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE address_text IS NOT NULL) as users_with_addresses,
    ROUND(COUNT(*) FILTER (WHERE address_text IS NOT NULL)::numeric / NULLIF(COUNT(*), 0) * 100, 2) as percentage
FROM ngos;

\echo ''

-- ============================================================================
-- 4. Check for any orphaned data
-- ============================================================================

\echo '4. Checking for orphaned data...'
\echo ''

-- Check if any users have no address data at all
SELECT 
    p.role,
    COUNT(*) as users_without_addresses
FROM profiles p
WHERE p.role = 'user'
  AND NOT EXISTS (SELECT 1 FROM user_addresses WHERE user_id = p.id)
GROUP BY p.role;

SELECT 
    'restaurant' as role,
    COUNT(*) as users_without_addresses
FROM profiles p
INNER JOIN restaurants r ON p.id = r.profile_id
WHERE p.role = 'restaurant'
  AND r.address_text IS NULL;

SELECT 
    'ngo' as role,
    COUNT(*) as users_without_addresses
FROM profiles p
INNER JOIN ngos n ON p.id = n.profile_id
WHERE p.role = 'ngo'
  AND n.address_text IS NULL;

\echo ''

-- ============================================================================
-- 5. Verify location data (lat/lng)
-- ============================================================================

\echo '5. Checking location coordinates...'
\echo ''

-- Restaurants with coordinates
SELECT 
    'Restaurants' as table_name,
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE latitude IS NOT NULL AND longitude IS NOT NULL) as with_coordinates,
    COUNT(*) FILTER (WHERE location IS NOT NULL) as with_postgis_location
FROM restaurants;

-- NGOs with coordinates
SELECT 
    'NGOs' as table_name,
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE latitude IS NOT NULL AND longitude IS NOT NULL) as with_coordinates,
    COUNT(*) FILTER (WHERE location IS NOT NULL) as with_postgis_location
FROM ngos;

-- User addresses with coordinates
SELECT 
    'User Addresses' as table_name,
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE location_lat IS NOT NULL AND location_long IS NOT NULL) as with_coordinates
FROM user_addresses;

\echo ''

-- ============================================================================
-- 6. Final Summary
-- ============================================================================

\echo '========================================'
\echo 'VERIFICATION SUMMARY'
\echo '========================================'

DO $$
DECLARE
    v_profiles_address_removed boolean;
    v_profiles_location_removed boolean;
    v_restaurants_address_removed boolean;
    v_backup_profiles integer;
    v_backup_restaurants integer;
BEGIN
    -- Check columns removed
    SELECT COUNT(*) = 0 INTO v_profiles_address_removed
    FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'address_text';
    
    SELECT COUNT(*) = 0 INTO v_profiles_location_removed
    FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'default_location';
    
    SELECT COUNT(*) = 0 INTO v_restaurants_address_removed
    FROM information_schema.columns 
    WHERE table_name = 'restaurants' AND column_name = 'address';
    
    -- Check backups
    SELECT COUNT(*) INTO v_backup_profiles FROM profiles_address_backup;
    SELECT COUNT(*) INTO v_backup_restaurants FROM restaurants_address_backup;
    
    RAISE NOTICE '';
    RAISE NOTICE '📋 Migration Status:';
    RAISE NOTICE '  - profiles.address_text: %', CASE WHEN v_profiles_address_removed THEN '✅ Removed' ELSE '❌ Still exists' END;
    RAISE NOTICE '  - profiles.default_location: %', CASE WHEN v_profiles_location_removed THEN '✅ Removed' ELSE '❌ Still exists' END;
    RAISE NOTICE '  - restaurants.address: %', CASE WHEN v_restaurants_address_removed THEN '✅ Removed' ELSE '❌ Still exists' END;
    RAISE NOTICE '';
    RAISE NOTICE '💾 Backup Status:';
    RAISE NOTICE '  - profiles_address_backup: % records', v_backup_profiles;
    RAISE NOTICE '  - restaurants_address_backup: % records', v_backup_restaurants;
    RAISE NOTICE '';
    
    IF v_profiles_address_removed AND v_profiles_location_removed AND v_restaurants_address_removed THEN
        RAISE NOTICE '✅ MIGRATION SUCCESSFUL!';
        RAISE NOTICE '';
        RAISE NOTICE '📝 Next Steps:';
        RAISE NOTICE '  1. Update application code (6 files)';
        RAISE NOTICE '  2. Test all address-related features';
        RAISE NOTICE '  3. Monitor for issues';
        RAISE NOTICE '  4. Drop backup tables after 1 week';
    ELSE
        RAISE WARNING '⚠️  MIGRATION INCOMPLETE - Some columns still exist';
        RAISE NOTICE 'Please check the migration logs for errors';
    END IF;
    
    RAISE NOTICE '';
END $$;

\echo '========================================'
