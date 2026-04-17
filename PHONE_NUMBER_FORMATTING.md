# Phone Number Formatting for WhatsApp Integration

## Overview

All phone numbers in the Kathir app are automatically formatted to WhatsApp-compatible international format to ensure seamless WhatsApp message delivery.

## Format Specification

**Target Format:** `201xxxxxxxxx`
- Country Code: `20` (Egypt)
- Mobile Number: `1xxxxxxxxx` (10 digits starting with 1)
- Total Length: 12 digits

**Examples:**
- User enters: `01012345678` → Stored as: `201012345678`
- User enters: `1012345678` → Stored as: `201012345678`
- User enters: `+20 10 1234 5678` → Stored as: `201012345678`
- User enters: `0100 123 4567` → Stored as: `201001234567`

## Implementation

### 1. Flutter App (Client-Side)

**File:** `lib/core/utils/phone_formatter.dart`

**Features:**
- `formatEgyptianPhone(String phone)` - Converts any Egyptian phone format to `201xxxxxxxxx`
- `isValidEgyptianPhone(String phone)` - Validates Egyptian mobile numbers
- `formatForDisplay(String phone)` - Formats for user-friendly display (`+20 10 1234 5678`)

**Usage in App:**
```dart
import 'package:kathir_final/core/utils/phone_formatter.dart';

// Format before saving
final formattedPhone = PhoneFormatter.formatEgyptianPhone(userInput);

// Validate
if (!PhoneFormatter.isValidEgyptianPhone(userInput)) {
  // Show error
}

// Display
final displayPhone = PhoneFormatter.formatForDisplay(storedPhone);
```

**Applied in:**
- ✅ `lib/features/authentication/presentation/screens/auth_screen.dart` - Sign up
- ✅ `lib/features/restaurant_dashboard/presentation/screens/restaurant_profile_screen.dart` - Restaurant profile edit
- ✅ `lib/features/onboarding/presentation/screens/user_profile_setup_screen.dart` - User profile setup

### 2. Database (Server-Side)

**File:** `supabase/migrations/20260417_phone_number_formatting.sql`

**Features:**
- `format_egyptian_phone(TEXT)` - PostgreSQL function to format phone numbers
- Triggers on `profiles` table for `phone_number` column
- Triggers on `restaurants` table for `phone` column
- Automatic formatting on INSERT and UPDATE operations
- Check constraints to ensure data integrity
- Migration to fix existing phone numbers

**Database Triggers:**
```sql
-- Profiles table
CREATE TRIGGER format_phone_before_insert_profiles
  BEFORE INSERT OR UPDATE OF phone_number ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION trigger_format_phone_profiles();

-- Restaurants table
CREATE TRIGGER format_phone_before_insert_restaurants
  BEFORE INSERT OR UPDATE OF phone ON restaurants
  FOR EACH ROW
  EXECUTE FUNCTION trigger_format_phone_restaurants();
```

**Check Constraints:**
```sql
-- Ensures phone numbers match the pattern 201xxxxxxxxx
ALTER TABLE profiles
ADD CONSTRAINT profiles_phone_number_format_check
CHECK (
  phone_number IS NULL OR
  phone_number = '' OR
  phone_number ~ '^20\d{10}$'
);
```

## Affected Tables

### 1. `profiles` Table
- **Column:** `phone_number`
- **Type:** TEXT
- **Format:** `201xxxxxxxxx`
- **Trigger:** `format_phone_before_insert_profiles`
- **Used by:** Users, NGOs

### 2. `restaurants` Table
- **Column:** `phone`
- **Type:** TEXT
- **Format:** `201xxxxxxxxx`
- **Trigger:** `format_phone_before_insert_restaurants`
- **Used by:** Restaurants

### 3. `ngos` Table
- **Note:** NGOs don't have a direct phone column
- **Phone retrieved via:** `ngos.profile_id → profiles.phone_number`

## WhatsApp Integration

The formatted phone numbers are used in:

1. **WhatsApp Message Queue** (`whatsapp_queue` table)
   - `to_phone` column stores formatted numbers

2. **Edge Function** (`send-whatsapp`)
   - Sends messages using formatted phone numbers
   - No additional formatting needed

3. **Database Functions**
   - `queue_whatsapp_message()` - Uses formatted numbers from profiles/restaurants
   - `send_order_whatsapp_messages()` - Retrieves formatted numbers

## Validation Rules

**Valid Egyptian Mobile Prefixes:**
- `10` - Vodafone
- `11` - Etisalat
- `12` - Orange
- `15` - WE (formerly Mobinil)

**Validation Pattern:**
```regex
^20(10|11|12|15)\d{8}$
```

**Examples:**
- ✅ `201012345678` - Valid (Vodafone)
- ✅ `201112345678` - Valid (Etisalat)
- ✅ `201212345678` - Valid (Orange)
- ✅ `201512345678` - Valid (WE)
- ❌ `201312345678` - Invalid (13 is not a valid prefix)
- ❌ `20101234567` - Invalid (too short)
- ❌ `2010123456789` - Invalid (too long)

## Testing

### Test in Flutter App

```dart
void testPhoneFormatter() {
  // Test formatting
  assert(PhoneFormatter.formatEgyptianPhone('01012345678') == '201012345678');
  assert(PhoneFormatter.formatEgyptianPhone('1012345678') == '201012345678');
  assert(PhoneFormatter.formatEgyptianPhone('201012345678') == '201012345678');
  assert(PhoneFormatter.formatEgyptianPhone('+20 10 1234 5678') == '201012345678');
  
  // Test validation
  assert(PhoneFormatter.isValidEgyptianPhone('01012345678') == true);
  assert(PhoneFormatter.isValidEgyptianPhone('01312345678') == false);
  
  // Test display formatting
  assert(PhoneFormatter.formatForDisplay('201012345678') == '+20 10 1234 5678');
}
```

### Test in Database

```sql
-- Test the formatting function
SELECT 
  format_egyptian_phone('01012345678') as test1,  -- Should return: 201012345678
  format_egyptian_phone('1012345678') as test2,   -- Should return: 201012345678
  format_egyptian_phone('201012345678') as test3, -- Should return: 201012345678
  format_egyptian_phone('+20 10 1234 5678') as test4, -- Should return: 201012345678
  format_egyptian_phone('0100 123 4567') as test5;   -- Should return: 201001234567

-- Verify existing phone numbers
SELECT id, phone_number 
FROM profiles 
WHERE phone_number IS NOT NULL 
  AND phone_number != ''
  AND phone_number !~ '^20\d{10}$';  -- Should return 0 rows

SELECT id, phone 
FROM restaurants 
WHERE phone IS NOT NULL 
  AND phone != ''
  AND phone !~ '^20\d{10}$';  -- Should return 0 rows
```

## Migration Steps

1. **Apply Database Migration**
   ```bash
   # In Supabase dashboard or CLI
   supabase migration up
   ```

2. **Verify Triggers**
   ```sql
   -- Check triggers are created
   SELECT trigger_name, event_manipulation, event_object_table
   FROM information_schema.triggers
   WHERE trigger_name LIKE 'format_phone%';
   ```

3. **Test Insert/Update**
   ```sql
   -- Test profile insert
   INSERT INTO profiles (id, full_name, phone_number)
   VALUES (gen_random_uuid(), 'Test User', '01012345678');
   
   -- Verify formatting
   SELECT phone_number FROM profiles WHERE full_name = 'Test User';
   -- Should return: 201012345678
   ```

4. **Update Flutter App**
   - Import `phone_formatter.dart` in relevant screens
   - Add validation to phone input fields
   - Format phone numbers before API calls

## Troubleshooting

### Issue: Phone numbers not formatting

**Check:**
1. Triggers are enabled: `SELECT * FROM pg_trigger WHERE tgname LIKE 'format_phone%';`
2. Function exists: `SELECT * FROM pg_proc WHERE proname = 'format_egyptian_phone';`
3. No errors in logs: Check Supabase logs

### Issue: Validation failing in app

**Check:**
1. Phone formatter imported correctly
2. Validation called before submission
3. User entering valid Egyptian mobile number

### Issue: WhatsApp messages not sending

**Check:**
1. Phone numbers in database are formatted: `SELECT phone_number FROM profiles LIMIT 10;`
2. WhatsApp queue has formatted numbers: `SELECT to_phone FROM whatsapp_queue LIMIT 10;`
3. Edge function receiving correct format

## Benefits

1. **Consistency** - All phone numbers stored in same format
2. **WhatsApp Compatibility** - Direct use in WhatsApp API without formatting
3. **Data Integrity** - Check constraints prevent invalid formats
4. **User Experience** - Users can enter phone in any format
5. **Automatic** - No manual intervention needed
6. **Retroactive** - Migration fixes existing data

## Related Files

- `lib/core/utils/phone_formatter.dart` - Flutter utility
- `supabase/migrations/20260417_phone_number_formatting.sql` - Database migration
- `SUPABASE_WHATSAPP_COMPLETE_SETUP.md` - WhatsApp integration guide
- `META_WHATSAPP_TEMPLATES_TO_CREATE.md` - WhatsApp templates

## Future Enhancements

1. Support for other country codes (if expanding beyond Egypt)
2. Phone number verification via OTP
3. Duplicate phone number detection
4. Phone number change history tracking
