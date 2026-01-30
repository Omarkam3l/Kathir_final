# 🚨 IMMEDIATE FIX STEPS

## Error: "signUpRestaurant failed"

### Step 1: Run Enhanced Logging (Already Done ✅)
The code now logs detailed error information. Try signup again and look for:

```
[...] ERROR AUTH: signUpRestaurant.authException | statusCode=..., message=...
```

This will tell us the EXACT error from Supabase.

---

### Step 2: Check if Database Migrations Were Deployed

**CRITICAL**: Did you run these SQL migrations in Supabase?

1. `database-migrations-002-fix-trigger-robustness.sql`
2. `database-migrations-003-fix-storage-rls.sql`

**To Check**:
```sql
-- Run in Supabase SQL Editor
SELECT prosrc FROM pg_proc WHERE proname = 'handle_new_user';
```

**Expected**: Should show function with `NULLIF`, `TRIM`, and `EXCEPTION` blocks

**If NOT deployed**: 
1. Open Supabase Dashboard → SQL Editor
2. Copy `database-migrations-002-fix-trigger-robustness.sql`
3. Paste and click "Run"
4. Verify: "Success. No rows returned"

---

### Step 3: Check for Duplicate Email

```sql
-- Run in Supabase SQL Editor
SELECT id, email, created_at 
FROM auth.users 
WHERE email = 'mohamedelekhnawy324@gmail.com';
```

**If returns a row**: Email already registered!

**Fix**:
```sql
-- Delete existing user (CAREFUL - only in development!)
DELETE FROM auth.users WHERE email = 'mohamedelekhnawy324@gmail.com';
```

Then try signup again.

---

### Step 4: Common Error Messages & Fixes

#### Error: "User already registered"
**Cause**: Email already exists in database  
**Fix**: Use different email or delete existing user (Step 3)

#### Error: "Database error saving new user"
**Cause**: Trigger not updated (still has old version)  
**Fix**: Deploy migration 002 (Step 2)

#### Error: "Invalid email"
**Cause**: Email format invalid  
**Fix**: Use valid email format

#### Error: "Weak password"
**Cause**: Password doesn't meet requirements  
**Fix**: Use stronger password (min 6 characters)

#### Error: "Email rate limit exceeded"
**Cause**: Too many signup attempts  
**Fix**: Wait 1 hour or use different email

---

### Step 5: Get Detailed Error

**Try signup again** with the updated code. You should now see:

```
[...] INFO AUTH: signUpRestaurant.metadata | email=..., fullName=..., orgName=..., hasPhone=..., role=restaurant
[...] ERROR AUTH: signUpRestaurant.authException | statusCode=XXX, message=EXACT_ERROR_MESSAGE
```

**Share this log** and I'll provide the exact fix.

---

### Step 6: Verify Trigger Function

Run this in Supabase SQL Editor:

```sql
-- Check if trigger function has exception blocks
SELECT prosrc 
FROM pg_proc 
WHERE proname = 'handle_new_user';
```

**Look for**:
- `NULLIF(TRIM(org_name), '')`
- `EXCEPTION WHEN OTHERS THEN`
- `RAISE WARNING`

**If NOT found**: Trigger not updated, deploy migration 002

---

### Step 7: Manual Test

Try this in Supabase SQL Editor to test trigger:

```sql
-- Test signup simulation
DO $$
DECLARE
  test_id uuid := gen_random_uuid();
BEGIN
  -- Insert test user
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_user_meta_data,
    created_at,
    updated_at,
    aud,
    role
  )
  VALUES (
    test_id,
    '00000000-0000-0000-0000-000000000000',
    'test-' || test_id::text || '@example.com',
    crypt('password123', gen_salt('bf')),
    NOW(),
    jsonb_build_object(
      'role', 'restaurant',
      'full_name', 'Test Restaurant',
      'organization_name', ''  -- Empty string to test edge case
    ),
    NOW(),
    NOW(),
    'authenticated',
    'authenticated'
  );
  
  -- Check if profile was created
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = test_id) THEN
    RAISE NOTICE 'SUCCESS: Profile created';
  ELSE
    RAISE EXCEPTION 'FAILED: Profile not created';
  END IF;
  
  -- Check if restaurant was created
  IF EXISTS (SELECT 1 FROM public.restaurants WHERE profile_id = test_id) THEN
    RAISE NOTICE 'SUCCESS: Restaurant created';
  ELSE
    RAISE EXCEPTION 'FAILED: Restaurant not created';
  END IF;
  
  -- Cleanup
  DELETE FROM auth.users WHERE id = test_id;
  
  RAISE NOTICE 'Test completed successfully';
END $$;
```

**Expected**: "Test completed successfully"  
**If fails**: Shows exact error from trigger

---

## 🎯 Most Likely Causes (In Order)

### 1. **Trigger Not Updated** (90% probability)
- Migration 002 not deployed
- Still using old trigger with empty string bug
- **Fix**: Deploy migration 002

### 2. **Duplicate Email** (5% probability)
- Email already exists in database
- **Fix**: Delete existing user or use different email

### 3. **RLS Policy Blocking** (3% probability)
- Service role can't insert into profiles/restaurants
- **Fix**: Check RLS policies

### 4. **Invalid Input** (2% probability)
- Email format invalid
- Password too weak
- **Fix**: Validate input

---

## 📞 Next Steps

1. **Try signup again** with updated logging
2. **Share the complete error log** including:
   - `signUpRestaurant.metadata` line
   - `signUpRestaurant.authException` or `signUpRestaurant.failed` line
   - Full error message and statusCode
3. **Run diagnostic queries** from `DIAGNOSTIC_QUERIES.sql`
4. **Verify migrations deployed** (Step 2 above)

---

## 🔧 Quick Commands

### Check Trigger Status
```sql
SELECT tgname, tgenabled 
FROM pg_trigger 
WHERE tgname = 'on_auth_user_created';
```

### Check Function Version
```sql
SELECT 
  CASE 
    WHEN prosrc LIKE '%NULLIF%' THEN 'Updated (v2)'
    ELSE 'Old (v1)'
  END as version
FROM pg_proc 
WHERE proname = 'handle_new_user';
```

### Check Recent Errors
```sql
-- In Supabase Dashboard → Logs → Postgres Logs
-- Look for errors in last 5 minutes
```

---

**Status**: Waiting for detailed error log  
**Next**: Share the `authException` log with statusCode and message
