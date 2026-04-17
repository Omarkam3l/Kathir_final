-- Migration: Phone Number Formatting for WhatsApp Integration
-- Description: Ensures all phone numbers are stored in 201xxxxxxxxx format
-- Date: 2026-04-17

-- =====================================================
-- PART 1: Create phone formatting function
-- =====================================================

CREATE OR REPLACE FUNCTION format_egyptian_phone(phone_input TEXT)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  cleaned TEXT;
BEGIN
  -- Return NULL if input is NULL or empty
  IF phone_input IS NULL OR phone_input = '' THEN
    RETURN phone_input;
  END IF;
  
  -- Remove all non-digit characters
  cleaned := regexp_replace(phone_input, '[^\d]', '', 'g');
  
  -- If already starts with 20, return as is
  IF cleaned ~ '^20' THEN
    RETURN cleaned;
  END IF;
  
  -- If starts with 0, remove it and add 20
  IF cleaned ~ '^0' THEN
    RETURN '20' || substring(cleaned from 2);
  END IF;
  
  -- If starts with 1 (missing leading 0), add 20
  IF cleaned ~ '^1' THEN
    RETURN '20' || cleaned;
  END IF;
  
  -- Otherwise, add 20 prefix
  RETURN '20' || cleaned;
END;
$$;

COMMENT ON FUNCTION format_egyptian_phone IS 'Formats Egyptian phone numbers to international format (201xxxxxxxxx) for WhatsApp compatibility';

-- =====================================================
-- PART 2: Create trigger function for profiles table
-- =====================================================

CREATE OR REPLACE FUNCTION trigger_format_phone_profiles()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Format phone_number if it's being inserted or updated
  IF NEW.phone_number IS NOT NULL AND NEW.phone_number != '' THEN
    NEW.phone_number := format_egyptian_phone(NEW.phone_number);
  END IF;
  
  RETURN NEW;
END;
$$;

-- Drop trigger if exists and create new one
DROP TRIGGER IF EXISTS format_phone_before_insert_profiles ON profiles;
CREATE TRIGGER format_phone_before_insert_profiles
  BEFORE INSERT OR UPDATE OF phone_number ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION trigger_format_phone_profiles();

COMMENT ON TRIGGER format_phone_before_insert_profiles ON profiles IS 'Auto-formats phone numbers to 201xxxxxxxxx format';

-- =====================================================
-- PART 3: Create trigger function for restaurants table
-- =====================================================

CREATE OR REPLACE FUNCTION trigger_format_phone_restaurants()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Format phone if it's being inserted or updated
  IF NEW.phone IS NOT NULL AND NEW.phone != '' THEN
    NEW.phone := format_egyptian_phone(NEW.phone);
  END IF;
  
  RETURN NEW;
END;
$$;

-- Drop trigger if exists and create new one
DROP TRIGGER IF EXISTS format_phone_before_insert_restaurants ON restaurants;
CREATE TRIGGER format_phone_before_insert_restaurants
  BEFORE INSERT OR UPDATE OF phone ON restaurants
  FOR EACH ROW
  EXECUTE FUNCTION trigger_format_phone_restaurants();

COMMENT ON TRIGGER format_phone_before_insert_restaurants ON restaurants IS 'Auto-formats phone numbers to 201xxxxxxxxx format';

-- =====================================================
-- PART 4: Update existing phone numbers in profiles
-- =====================================================

-- Update profiles table
UPDATE profiles
SET phone_number = format_egyptian_phone(phone_number)
WHERE phone_number IS NOT NULL 
  AND phone_number != ''
  AND phone_number !~ '^20'; -- Only update if not already formatted

-- =====================================================
-- PART 5: Update existing phone numbers in restaurants
-- =====================================================

-- Update restaurants table
UPDATE restaurants
SET phone = format_egyptian_phone(phone)
WHERE phone IS NOT NULL 
  AND phone != ''
  AND phone !~ '^20'; -- Only update if not already formatted

-- =====================================================
-- PART 6: Add validation check (optional but recommended)
-- =====================================================

-- Add check constraint to ensure phone numbers are properly formatted
-- This is optional but helps maintain data integrity

ALTER TABLE profiles
DROP CONSTRAINT IF EXISTS profiles_phone_number_format_check;

ALTER TABLE profiles
ADD CONSTRAINT profiles_phone_number_format_check
CHECK (
  phone_number IS NULL OR
  phone_number = '' OR
  phone_number ~ '^20\d{10}$'
);

ALTER TABLE restaurants
DROP CONSTRAINT IF EXISTS restaurants_phone_format_check;

ALTER TABLE restaurants
ADD CONSTRAINT restaurants_phone_format_check
CHECK (
  phone IS NULL OR
  phone = '' OR
  phone ~ '^20\d{10}$'
);

-- =====================================================
-- VERIFICATION QUERIES (for testing)
-- =====================================================

-- Check profiles phone numbers
-- SELECT id, phone_number, format_egyptian_phone(phone_number) as formatted
-- FROM profiles
-- WHERE phone_number IS NOT NULL AND phone_number != '';

-- Check restaurants phone numbers
-- SELECT id, phone, format_egyptian_phone(phone) as formatted
-- FROM restaurants
-- WHERE phone IS NOT NULL AND phone != '';

-- Test the function
-- SELECT 
--   format_egyptian_phone('01012345678') as test1,  -- Should return: 201012345678
--   format_egyptian_phone('1012345678') as test2,   -- Should return: 201012345678
--   format_egyptian_phone('201012345678') as test3, -- Should return: 201012345678
--   format_egyptian_phone('+20 10 1234 5678') as test4, -- Should return: 201012345678
--   format_egyptian_phone('0100 123 4567') as test5;   -- Should return: 201001234567
