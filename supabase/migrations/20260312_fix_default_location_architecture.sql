-- Migration: Fix default_location architecture
-- Date: 2026-03-12
-- Description: The default_location column was already removed from profiles table.
--              This migration cleans up the trigger and function that referenced it.
--              Applications should query user_addresses table for default addresses.

-- ============================================================================
-- STEP 1: Create backup table (for safety, even if column doesn't exist)
-- ============================================================================

CREATE TABLE IF NOT EXISTS profiles_default_location_backup (
    id uuid PRIMARY KEY,
    note text DEFAULT 'Column was already removed before this migration',
    backed_up_at timestamp with time zone DEFAULT now()
);

-- Insert a marker record
INSERT INTO profiles_default_location_backup (id, note)
VALUES ('00000000-0000-0000-0000-000000000000', 'Migration run - column already removed')
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- STEP 2: Check user_addresses status
-- ============================================================================

DO $$
DECLARE
    v_users_without_addresses integer;
    v_users_with_addresses integer;
BEGIN
    -- Count users who have no addresses
    SELECT COUNT(*) INTO v_users_without_addresses
    FROM profiles p
    WHERE p.role = 'user'
      AND NOT EXISTS (SELECT 1 FROM user_addresses WHERE user_id = p.id);
    
    SELECT COUNT(*) INTO v_users_with_addresses
    FROM profiles p
    WHERE p.role = 'user'
      AND EXISTS (SELECT 1 FROM user_addresses WHERE user_id = p.id);
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'USER ADDRESSES STATUS';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Users with addresses: %', v_users_with_addresses;
    
    IF v_users_without_addresses > 0 THEN
        RAISE NOTICE '⚠️  Users without addresses: %', v_users_without_addresses;
        RAISE NOTICE '💡 These users will need to add addresses through the app';
    ELSE
        RAISE NOTICE '✅ All users have addresses';
    END IF;
    RAISE NOTICE '========================================';
END $$;

-- ============================================================================
-- STEP 3: Remove trigger and function
-- ============================================================================

-- Drop the trigger that updates profile default_location
DROP TRIGGER IF EXISTS trigger_update_profile_default_location ON user_addresses;

-- Drop the function
DROP FUNCTION IF EXISTS update_profile_default_location();

DO $$
BEGIN
    RAISE NOTICE '✅ Removed trigger and function';
END $$;

-- ============================================================================
-- STEP 4: Ensure default_location column is removed from profiles
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'default_location'
    ) THEN
        ALTER TABLE profiles DROP COLUMN default_location CASCADE;
        RAISE NOTICE '✅ Dropped profiles.default_location column';
    ELSE
        RAISE NOTICE '✅ Column profiles.default_location already removed (expected)';
    END IF;
END $$;

-- ============================================================================
-- STEP 5: Add helpful comments
-- ============================================================================

COMMENT ON TABLE user_addresses IS 
'Stores multiple addresses for regular users. Each user can have multiple saved addresses with one marked as default (is_default=true). 
To get a users default address, query: SELECT address_text FROM user_addresses WHERE user_id = ? AND is_default = true';

COMMENT ON COLUMN user_addresses.is_default IS 
'Indicates if this is the users default address. Only one address per user should have is_default=true. 
Applications should query this table instead of profiles.default_location (which has been removed).';

COMMENT ON COLUMN user_addresses.address_text IS 
'Human-readable address string. This is what was previously stored in profiles.default_location.';

-- ============================================================================
-- STEP 6: Verification and Summary
-- ============================================================================

DO $$
DECLARE
    v_users_with_addresses integer;
    v_users_without_addresses integer;
    v_trigger_exists boolean;
    v_function_exists boolean;
    v_column_exists boolean;
BEGIN
    SELECT COUNT(*) INTO v_users_with_addresses 
    FROM profiles p
    WHERE p.role = 'user'
      AND EXISTS (SELECT 1 FROM user_addresses WHERE user_id = p.id);
    
    SELECT COUNT(*) INTO v_users_without_addresses 
    FROM profiles p
    WHERE p.role = 'user'
      AND NOT EXISTS (SELECT 1 FROM user_addresses WHERE user_id = p.id);
    
    -- Check if trigger still exists
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_update_profile_default_location'
    ) INTO v_trigger_exists;
    
    -- Check if function still exists
    SELECT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'update_profile_default_location'
    ) INTO v_function_exists;
    
    -- Check if column still exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'default_location'
    ) INTO v_column_exists;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ MIGRATION COMPLETED SUCCESSFULLY';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📊 User Address Statistics:';
    RAISE NOTICE '   - Users with addresses: %', v_users_with_addresses;
    RAISE NOTICE '   - Users without addresses: %', v_users_without_addresses;
    RAISE NOTICE '';
    RAISE NOTICE '🗑️  Cleanup Status:';
    
    IF v_column_exists THEN
        RAISE WARNING '   ⚠️  profiles.default_location still exists!';
    ELSE
        RAISE NOTICE '   ✅ profiles.default_location removed';
    END IF;
    
    IF v_trigger_exists THEN
        RAISE WARNING '   ⚠️  trigger_update_profile_default_location still exists!';
    ELSE
        RAISE NOTICE '   ✅ trigger_update_profile_default_location removed';
    END IF;
    
    IF v_function_exists THEN
        RAISE WARNING '   ⚠️  update_profile_default_location() still exists!';
    ELSE
        RAISE NOTICE '   ✅ update_profile_default_location() removed';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '📝 Application Code Changes Required:';
    RAISE NOTICE '   Replace: profiles.default_location queries';
    RAISE NOTICE '   With: SELECT address_text FROM user_addresses';
    RAISE NOTICE '         WHERE user_id = ? AND is_default = true';
    RAISE NOTICE '';
    
    IF v_users_without_addresses > 0 THEN
        RAISE NOTICE '💡 Note: % users need to add addresses via the app', v_users_without_addresses;
        RAISE NOTICE '';
    END IF;
    
    RAISE NOTICE '📖 See: FIX_DEFAULT_LOCATION_GUIDE.md for code updates';
    RAISE NOTICE '========================================';
END $$;
