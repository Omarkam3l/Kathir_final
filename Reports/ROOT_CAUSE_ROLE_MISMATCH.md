# 🚨 ROOT CAUSE: Role String Mismatch

## 🔍 CRITICAL FINDINGS

### Issue #1: No OTP Emails for Restaurant Role
### Issue #2: legal_docs_urls Stays Empty

**Both issues have the SAME root cause**: Role string mismatch

---

## 🐛 THE MISMATCH

### What Flutter Sends
**File**: `lib/core/utils/user_role.dart`  
**Line**: 22

```dart
String get wireValue {
  return switch (this) {
    UserRole.restaurant => 'rest',  // ❌ Sends 'rest'
    // ...
  };
}
```

### What Database Expects
**File**: `database-FINAL-AUTH-REBUILD.sql`  
**Lines**: 96, 131, 157

```sql
IF user_role IN ('restaurant', 'ngo') THEN  -- ❌ Expects 'restaurant'
  -- ...
END IF;

IF user_role = 'restaurant' AND profile_created THEN  -- ❌ Expects 'restaurant'
  -- Create restaurant record
END IF;
```

### What ViewModel Checks
**File**: `lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart`  
**Line**: 178

```dart
if (role == 'restaurant') {  // ❌ Checks 'restaurant'
  // Save legal docs URL
}
```

---

## 💥 IMPACT

### Flow Breakdown

```
User signs up as restaurant
  ↓
Flutter sends: role='rest' ✅
  ↓
Supabase creates auth.users with raw_user_meta_data.role='rest' ✅
  ↓
Trigger fires: handle_new_user()
  ↓
Reads: user_role = 'rest'
  ↓
Checks: IF user_role = 'restaurant' ❌ FALSE!
  ↓
Skips restaurant record creation ❌
  ↓
OTP email sent but no restaurant row exists ❌
  ↓
User verifies OTP ✅
  ↓
Uploads document ✅
  ↓
ViewModel checks: if (role == 'restaurant') ❌ FALSE!
  ↓
Skips URL save ❌
  ↓
Result: No restaurant record, no URLs saved
```

### Why OTP Emails Don't Arrive

Actually, OTP emails ARE sent by Supabase auth system. The issue is:
1. Restaurant record is NOT created (trigger doesn't recognize 'rest')
2. User can verify OTP successfully
3. But document upload fails because no restaurant record exists
4. Or URLs aren't saved because role check fails

---

## ✅ THE FIX

### Option 1: Change wireValue to 'restaurant' (RECOMMENDED)

**Pros**:
- Matches database expectations
- Matches ViewModel checks
- Consistent with 'ngo' (not 'org')
- More readable

**Cons**:
- Breaks existing data if any users have role='rest'

### Option 2: Update All Checks to Use 'rest'

**Pros**:
- Maintains backward compatibility

**Cons**:
- Inconsistent with 'ngo'
- Less readable
- More places to update

**RECOMMENDATION**: Use Option 1 + migration for existing data

---

## 📋 EVIDENCE FROM CODEBASE

### Places Using 'rest'
1. `lib/core/utils/user_role.dart:22` - wireValue definition
2. `lib/features/_shared/router/app_router.dart:80` - routing check
3. `lib/features/authentication/presentation/screens/pending_approval_screen.dart:16` - UI check
4. `lib/features/authentication/presentation/blocs/auth_provider.dart:33` - needsApproval check

### Places Using 'restaurant'
1. `database-FINAL-AUTH-REBUILD.sql:96,131,157` - trigger checks
2. `lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart:178` - URL save check
3. `lib/features/authentication/domain/entities/user_entity.dart:21` - needsApproval check

### Inconsistency Count
- Uses 'rest': 4 places
- Uses 'restaurant': 5+ places
- **Majority expects 'restaurant'**

---

## 🔧 DETAILED FIX PLAN

### Step 1: Update wireValue
**File**: `lib/core/utils/user_role.dart`

```dart
String get wireValue {
  return switch (this) {
    UserRole.user => 'user',
    UserRole.ngo => 'ngo',
    UserRole.restaurant => 'restaurant',  // ✅ Changed from 'rest'
    UserRole.admin => 'admin',
  };
}
```

### Step 2: Update All 'rest' Checks to 'restaurant'

**File**: `lib/features/_shared/router/app_router.dart:80`
```dart
if (role == 'restaurant') {  // ✅ Changed from 'rest'
  return '/restaurant-dashboard';
}
```

**File**: `lib/features/authentication/presentation/screens/pending_approval_screen.dart:16`
```dart
final isRestaurant = user?.role == 'restaurant';  // ✅ Changed from 'rest'
```

**File**: `lib/features/authentication/presentation/blocs/auth_provider.dart:33`
```dart
bool get needsApproval => role == 'restaurant' || role == 'ngo';  // ✅ Changed from 'rest'
```

### Step 3: Migrate Existing Data (SQL)

```sql
-- Update existing users with role='rest' to role='restaurant'
UPDATE auth.users 
SET raw_user_meta_data = jsonb_set(
  raw_user_meta_data, 
  '{role}', 
  '"restaurant"'
)
WHERE raw_user_meta_data->>'role' = 'rest';

-- Update profiles table
UPDATE public.profiles 
SET role = 'restaurant' 
WHERE role = 'rest';
```

### Step 4: Verify No More Mismatches

Run after fix:
```sql
-- Should return 0 rows
SELECT id, email, raw_user_meta_data->>'role' as role
FROM auth.users 
WHERE raw_user_meta_data->>'role' = 'rest';

-- Should return 0 rows
SELECT id, email, role 
FROM public.profiles 
WHERE role = 'rest';
```

---

## 🧪 TEST CHECKLIST

### Before Fix (Broken)
- [ ] Sign up as restaurant with role='rest'
- [ ] Trigger doesn't create restaurant record
- [ ] OTP email arrives (Supabase sends it)
- [ ] Verify OTP succeeds
- [ ] Upload document succeeds (storage)
- [ ] URL save fails (role check fails)
- [ ] legal_docs_urls stays []

### After Fix (Working)
- [ ] Sign up as restaurant with role='restaurant'
- [ ] Trigger creates restaurant record ✅
- [ ] OTP email arrives ✅
- [ ] Verify OTP succeeds ✅
- [ ] Upload document succeeds ✅
- [ ] URL save succeeds (role check passes) ✅
- [ ] legal_docs_urls contains URL ✅

### Verification Queries

```sql
-- Check role in auth.users
SELECT id, email, raw_user_meta_data->>'role' as role
FROM auth.users 
WHERE email = 'test@example.com';

-- Check role in profiles
SELECT id, email, role 
FROM public.profiles 
WHERE email = 'test@example.com';

-- Check restaurant record exists
SELECT profile_id, restaurant_name, legal_docs_urls
FROM public.restaurants r
JOIN public.profiles p ON p.id = r.profile_id
WHERE p.email = 'test@example.com';
```

---

## 📊 IMPACT ANALYSIS

### Current State (Broken)
- All restaurant signups since deployment: BROKEN
- Restaurant records: NOT CREATED
- Legal docs URLs: NOT SAVED
- Users stuck in limbo (verified but no data)

### After Fix
- New signups: WORKING
- Existing users: Need data migration
- Legal docs: Will save correctly
- Restaurant records: Will be created

---

## 🚨 URGENT ACTIONS

1. **Fix wireValue** (1 minute)
2. **Update all 'rest' checks** (5 minutes)
3. **Migrate existing data** (2 minutes)
4. **Test complete flow** (5 minutes)
5. **Verify no more 'rest' in database** (1 minute)

**Total time**: ~15 minutes

---

## 📝 SUMMARY

**Root Cause**: `UserRole.restaurant.wireValue` returns `'rest'` but database and most code expects `'restaurant'`

**Impact**: 
- Restaurant records not created (trigger doesn't recognize 'rest')
- Legal docs URLs not saved (ViewModel checks for 'restaurant')
- Users can sign up and verify OTP but data is incomplete

**Fix**: 
- Change wireValue from 'rest' to 'restaurant'
- Update all 'rest' checks to 'restaurant'
- Migrate existing data

**Priority**: 🔴 CRITICAL - Blocks all restaurant signups

