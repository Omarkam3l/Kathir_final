# 🔧 COMPLETE FIX: Role Mismatch ('rest' vs 'restaurant')

## 🎯 ROOT CAUSES IDENTIFIED

### Issue #1: No OTP Emails for Restaurant Role
**Actually**: OTP emails ARE sent, but restaurant records aren't created

### Issue #2: legal_docs_urls Stays Empty
**Root Cause**: Role check fails because of string mismatch

**Both issues caused by**: `'rest'` vs `'restaurant'` mismatch

---

## 📊 THE MISMATCH (Evidence)

### What Was Sent
**File**: `lib/core/utils/user_role.dart:22`
```dart
UserRole.restaurant => 'rest',  // ❌ Sent 'rest'
```

### What Was Expected

**Database Trigger** (`database-FINAL-AUTH-REBUILD.sql:96,157`):
```sql
IF user_role = 'restaurant' THEN  -- ❌ Expected 'restaurant'
```

**ViewModel** (`auth_viewmodel.dart:178`):
```dart
if (role == 'restaurant') {  -- ❌ Expected 'restaurant'
```

**Router** (`app_router.dart:80`):
```dart
if (role == 'rest') {  -- ✅ Used 'rest' (inconsistent)
```

---

## 💥 IMPACT ANALYSIS

### Complete Flow Breakdown

```
1. User signs up as restaurant
   ↓
2. Flutter sends: raw_user_meta_data.role = 'rest' ✅
   ↓
3. Supabase creates auth.users record ✅
   ↓
4. Trigger fires: handle_new_user()
   ↓
5. Reads: user_role = 'rest'
   ↓
6. Checks: IF user_role = 'restaurant' ❌ FALSE!
   ↓
7. Skips: INSERT INTO restaurants ❌
   ↓
8. Creates: profile with role='rest' ✅
   ↓
9. Supabase sends OTP email ✅ (auth system always sends)
   ↓
10. User verifies OTP ✅
   ↓
11. User uploads document ✅ (storage succeeds)
   ↓
12. ViewModel checks: if (role == 'restaurant') ❌ FALSE!
   ↓
13. Skips: RPC append_restaurant_legal_doc ❌
   ↓
14. Result: 
    - ✅ User authenticated
    - ✅ Profile exists with role='rest'
    - ❌ No restaurant record
    - ❌ No legal_docs_urls saved
    - ❌ User stuck (can't access dashboard)
```

### Why OTP Emails Seemed Missing

OTP emails were actually sent! The confusion was:
- Supabase auth system ALWAYS sends OTP emails
- The issue is restaurant records weren't created
- So users could verify but had incomplete data

---

## ✅ FIXES APPLIED

### Fix #1: Update wireValue
**File**: `lib/core/utils/user_role.dart`

```dart
// Before
UserRole.restaurant => 'rest',

// After
UserRole.restaurant => 'restaurant',  // ✅ Fixed
```

### Fix #2: Update Router Check
**File**: `lib/features/_shared/router/app_router.dart`

```dart
// Before
if (role == 'rest') {

// After
if (role == 'restaurant') {  // ✅ Fixed
```

### Fix #3: Update Pending Screen Check
**File**: `lib/features/authentication/presentation/screens/pending_approval_screen.dart`

```dart
// Before
final isRestaurant = user?.role == 'rest';

// After
final isRestaurant = user?.role == 'restaurant';  // ✅ Fixed
```

### Fix #4: Update AuthProvider Check
**File**: `lib/features/authentication/presentation/blocs/auth_provider.dart`

```dart
// Before
bool get needsApproval => role == 'rest' || role == 'ngo';

// After
bool get needsApproval => role == 'restaurant' || role == 'ngo';  // ✅ Fixed
```

### Fix #5: Data Migration SQL
**File**: `database-migrate-rest-to-restaurant.sql`

- Updates existing users from 'rest' to 'restaurant'
- Creates missing restaurant records
- Backs up data before migration
- Verifies migration success

---

## 🚀 DEPLOYMENT STEPS

### Step 1: Deploy Code Changes ✅

Code has been updated. Restart Flutter app or hot reload.

### Step 2: Deploy Data Migration (CRITICAL)

1. Open Supabase Dashboard → SQL Editor
2. Open file: `database-migrate-rest-to-restaurant.sql`
3. Copy **ALL contents**
4. Paste into SQL Editor
5. Click **Run**

**Expected output**:
```
Found X users with role='rest' in auth.users
Found Y users with role='rest' in profiles
⚠️  Migration needed - will update Z total users
✅ Updated X users in auth.users (rest → restaurant)
✅ Updated Y users in profiles (rest → restaurant)
✅ Created Z missing restaurant records
✅ VERIFIED: No users with role='rest' in auth.users
✅ VERIFIED: No users with role='rest' in profiles
✅ VERIFIED: All restaurant profiles have restaurant records
```

### Step 3: Deploy Legal Docs RPC Functions

1. Open file: `database-fix-legal-docs-append.sql`
2. Copy **ALL contents**
3. Paste into SQL Editor
4. Click **Run**

**Expected output**:
```
Functions created successfully
```

### Step 4: Verify Deployment

Run in SQL Editor:
```sql
-- Should return 0 rows
SELECT id, email, raw_user_meta_data->>'role' as role
FROM auth.users 
WHERE raw_user_meta_data->>'role' = 'rest';

-- Should return 0 rows
SELECT id, email, role 
FROM public.profiles 
WHERE role = 'rest';

-- Should return 2 rows
SELECT proname FROM pg_proc 
WHERE proname IN ('append_restaurant_legal_doc', 'append_ngo_legal_doc');
```

---

## 🧪 TESTING CHECKLIST

### Test 1: New Restaurant Signup (Complete Flow)

1. **Sign up as restaurant**
   - Email: test-restaurant@example.com
   - Password: password123
   - Organization: Test Restaurant
   - Upload legal document

2. **Check logs**:
   ```
   [timestamp] INFO AUTH: signUpRestaurant.metadata | role=restaurant
   [timestamp] INFO AUTH: signup.result | userId=..., hasSession=false
   [timestamp] INFO AUTH: otp.requested | email=..., type=signup
   ```

3. **Verify OTP email arrives** ✅

4. **Enter OTP code**

5. **Check logs**:
   ```
   [timestamp] INFO AUTH: confirmSignupCode.success | role=restaurant
   [timestamp] INFO AUTH: uploadPendingDocs.start
   [timestamp] INFO AUTH: storage.upload.success
   [timestamp] INFO AUTH: legalDoc.saved | updatedUrls=['https://...']
   [timestamp] INFO AUTH: legalDoc.verified | urlCount=1
   ```

6. **Verify in database**:
   ```sql
   -- Check role
   SELECT raw_user_meta_data->>'role' FROM auth.users WHERE email = 'test-restaurant@example.com';
   -- Expected: 'restaurant'
   
   -- Check profile
   SELECT role FROM profiles WHERE email = 'test-restaurant@example.com';
   -- Expected: 'restaurant'
   
   -- Check restaurant record exists
   SELECT restaurant_name, legal_docs_urls FROM restaurants r
   JOIN profiles p ON p.id = r.profile_id
   WHERE p.email = 'test-restaurant@example.com';
   -- Expected: 1 row with restaurant_name and legal_docs_urls=['https://...']
   ```

### Test 2: Existing User (After Migration)

1. **Find existing user**:
   ```sql
   SELECT id, email FROM profiles WHERE role = 'restaurant' LIMIT 1;
   ```

2. **Check restaurant record exists**:
   ```sql
   SELECT * FROM restaurants WHERE profile_id = 'USER_ID';
   -- Expected: 1 row
   ```

3. **Try uploading document** (if possible)

4. **Verify URL saved**:
   ```sql
   SELECT legal_docs_urls FROM restaurants WHERE profile_id = 'USER_ID';
   -- Expected: Array with URLs
   ```

### Test 3: Role Consistency

1. **Check no 'rest' roles remain**:
   ```sql
   -- Should return 0
   SELECT COUNT(*) FROM auth.users WHERE raw_user_meta_data->>'role' = 'rest';
   
   -- Should return 0
   SELECT COUNT(*) FROM profiles WHERE role = 'rest';
   ```

2. **Check all restaurants have records**:
   ```sql
   -- Should return 0
   SELECT COUNT(*) FROM profiles p
   LEFT JOIN restaurants r ON r.profile_id = p.id
   WHERE p.role = 'restaurant' AND r.profile_id IS NULL;
   ```

### Test 4: Routing & UI

1. **Log in as restaurant user**
2. **Verify redirects to**: `/restaurant-dashboard` (not error)
3. **Check pending approval screen** shows correct role
4. **Verify needsApproval** returns true for restaurant

---

## 📈 EXPECTED LOGS (After Fix)

### Successful Restaurant Signup

```
[2026-01-29T20:00:00.000] INFO AUTH: signup.viewmodel.start | role=SignUpRole.restaurant, email=test@example.com, hasOrgName=true

[2026-01-29T20:00:00.100] INFO AUTH: signup.attempt | role=restaurant, email=test@example.com

[2026-01-29T20:00:00.200] INFO AUTH: signUpRestaurant.metadata | email=test@example.com, fullName=Test User, orgName=Test Restaurant, hasPhone=true, role=restaurant

[2026-01-29T20:00:01.000] INFO AUTH: signup.result | role=restaurant, email=test@example.com, userId=abc-123-def, hasSession=false, emailConfirmed=false

[2026-01-29T20:00:01.100] INFO AUTH: otp.requested | email=test@example.com, type=signup

[2026-01-29T20:00:01.200] INFO AUTH: signup.viewmodel.success | role=SignUpRole.restaurant, email=test@example.com, userId=abc-123-def, isVerified=false

--- User enters OTP ---

[2026-01-29T20:01:00.000] INFO AUTH: confirmSignupCode.attempt | email=test@example.com

[2026-01-29T20:01:00.500] INFO AUTH: otp.verify.attempt | email=test@example.com, type=signup

[2026-01-29T20:01:01.000] INFO AUTH: otp.verify.result | email=test@example.com, type=signup, success=true, userId=abc-123-def

[2026-01-29T20:01:01.100] INFO AUTH: confirmSignupCode.success | email=test@example.com, userId=abc-123-def, role=restaurant

[2026-01-29T20:01:01.200] INFO AUTH: uploadPendingDocs.start | userId=abc-123-def, fileName=license.pdf

[2026-01-29T20:01:01.300] INFO AUTH: storage.upload.attempt | userId=abc-123-def, file=license.pdf

[2026-01-29T20:01:02.000] INFO AUTH: storage.upload.success | userId=abc-123-def, file=license.pdf, url=https://storage.supabase.co/...

[2026-01-29T20:01:02.100] INFO AUTH: db.rpc.append_restaurant_legal_doc | table=restaurants, userId=abc-123-def, url=https://...

[2026-01-29T20:01:02.500] INFO AUTH: legalDoc.saved | userId=abc-123-def, role=restaurant, table=restaurants, url=https://..., updatedUrls=['https://...']

[2026-01-29T20:01:02.600] INFO AUTH: legalDoc.verified | userId=abc-123-def, urlCount=1

[2026-01-29T20:01:02.700] INFO AUTH: uploadPendingDocs.success | userId=abc-123-def, url=https://...
```

---

## 🐛 TROUBLESHOOTING

### Issue: Still seeing role='rest' after code update

**Cause**: Hot reload didn't pick up enum change  
**Fix**: Full restart of Flutter app

### Issue: Migration shows 0 users to update

**Cause**: No existing users with role='rest' (good!)  
**Action**: Proceed with testing new signups

### Issue: Restaurant record still not created

**Possible causes**:
1. Migration not run → Deploy `database-migrate-rest-to-restaurant.sql`
2. Trigger not deployed → Deploy `database-FINAL-AUTH-REBUILD.sql`
3. Role still 'rest' → Check `raw_user_meta_data->>'role'`

**Debug**:
```sql
-- Check actual role in database
SELECT 
  au.id,
  au.email,
  au.raw_user_meta_data->>'role' as auth_role,
  p.role as profile_role,
  r.profile_id IS NOT NULL as has_restaurant_record
FROM auth.users au
LEFT JOIN profiles p ON p.id = au.id
LEFT JOIN restaurants r ON r.profile_id = au.id
WHERE au.email = 'test@example.com';
```

### Issue: Legal docs URLs still empty

**Possible causes**:
1. RPC functions not deployed → Deploy `database-fix-legal-docs-append.sql`
2. Role check still failing → Verify role is 'restaurant' not 'rest'
3. Upload happening before OTP → Check logs for order

**Debug**:
```dart
// Add to uploadLegalDoc method
print('User role: ${user?.role}');
print('Checking: role == restaurant: ${user?.role == 'restaurant'}');
```

---

## 📊 VERIFICATION QUERIES

### Check Role Distribution
```sql
SELECT 
  COALESCE(raw_user_meta_data->>'role', 'null') as role,
  COUNT(*) as count
FROM auth.users
GROUP BY raw_user_meta_data->>'role'
ORDER BY count DESC;
```

### Check Restaurant Records
```sql
SELECT 
  COUNT(*) as total_restaurants,
  COUNT(CASE WHEN array_length(legal_docs_urls, 1) > 0 THEN 1 END) as with_docs,
  COUNT(CASE WHEN legal_docs_urls = ARRAY[]::text[] THEN 1 END) as without_docs
FROM restaurants;
```

### Check Orphaned Profiles
```sql
-- Profiles with role='restaurant' but no restaurant record
SELECT 
  p.id,
  p.email,
  p.role,
  p.created_at
FROM profiles p
LEFT JOIN restaurants r ON r.profile_id = p.id
WHERE p.role = 'restaurant' 
  AND r.profile_id IS NULL;
```

---

## 📝 FILES MODIFIED/CREATED

### Modified (Code)
1. ✅ `lib/core/utils/user_role.dart` - Changed wireValue 'rest' → 'restaurant'
2. ✅ `lib/features/_shared/router/app_router.dart` - Updated role check
3. ✅ `lib/features/authentication/presentation/screens/pending_approval_screen.dart` - Updated role check
4. ✅ `lib/features/authentication/presentation/blocs/auth_provider.dart` - Updated needsApproval check

### Created (SQL)
1. ✅ `database-migrate-rest-to-restaurant.sql` - Data migration script

### Already Exists (From Previous Fix)
1. ✅ `database-fix-legal-docs-append.sql` - RPC functions for URL append
2. ✅ `database-FINAL-AUTH-REBUILD.sql` - Complete auth rebuild (if not deployed)

### Documentation
1. ✅ `ROOT_CAUSE_ROLE_MISMATCH.md` - Root cause analysis
2. ✅ `COMPLETE_FIX_ROLE_MISMATCH.md` - This file

---

## 🎯 SUCCESS CRITERIA

After deployment, verify:

- [ ] No users with role='rest' in auth.users
- [ ] No users with role='rest' in profiles
- [ ] All restaurant profiles have restaurant records
- [ ] New restaurant signups create restaurant records
- [ ] OTP emails arrive for restaurant signups
- [ ] Legal docs URLs are saved correctly
- [ ] Restaurant users can access dashboard
- [ ] Routing works correctly for restaurant role

---

## ⏱️ DEPLOYMENT TIMELINE

1. **Code changes**: ✅ Complete (hot reload or restart app)
2. **Data migration**: ⏳ Deploy `database-migrate-rest-to-restaurant.sql` (2 min)
3. **RPC functions**: ⏳ Deploy `database-fix-legal-docs-append.sql` (1 min)
4. **Testing**: ⏳ Complete flow test (5 min)
5. **Verification**: ⏳ Run verification queries (2 min)

**Total**: ~10 minutes

---

## 🚨 PRIORITY

**Level**: 🔴 CRITICAL  
**Impact**: Blocks all restaurant signups  
**Users Affected**: All restaurant users since deployment  
**Data Loss**: No data loss, but incomplete records  
**Rollback**: Backup tables created, can rollback if needed

---

**Status**: ✅ Code fixed, ⏳ Awaiting SQL deployment  
**Next**: Deploy both SQL migrations and test complete flow

