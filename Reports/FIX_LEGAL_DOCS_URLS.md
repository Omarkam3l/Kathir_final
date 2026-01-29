# 🔧 FIX: Legal Documents URLs Not Saving

## 🐛 ROOT CAUSE

**File**: `lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart`  
**Lines**: 186-188 (restaurants), 199-201 (ngos)

### The Problem

```dart
// ❌ WRONG: Overwrites entire array
await client.from('restaurants').update({
  'legal_docs_urls': [result.url]  // Replaces array with single element
}).eq('profile_id', userId);
```

**Why it fails**:
1. **Overwrites existing URLs**: If array has `['url1.pdf']`, update replaces it with `['url2.pdf']`
2. **Race conditions**: Multiple uploads can overwrite each other
3. **Not atomic**: Read-modify-write cycle is not safe
4. **No verification**: Doesn't check if update succeeded

### Evidence from Codebase

**Upload flow**:
```
signup() → stores pendingLegalDocBytes
  ↓
confirmSignupCode() → verifies OTP
  ↓
uploadLegalDoc() → uploads to storage, returns URL
  ↓
❌ client.from('restaurants').update({'legal_docs_urls': [url]})
  ↓
Result: URL uploaded but array overwritten, stays []
```

---

## ✅ THE FIX

### Solution: Atomic Append via RPC Functions

**Why RPC?**
- ✅ Atomic operation (no race conditions)
- ✅ Handles NULL arrays safely with COALESCE
- ✅ Server-side validation
- ✅ Returns updated array for verification
- ✅ SECURITY DEFINER with auth.uid() check

---

## 📋 DEPLOYMENT STEPS

### Step 1: Deploy SQL Functions

1. Open Supabase Dashboard → SQL Editor
2. Open file: `database-fix-legal-docs-append.sql`
3. Copy **ALL contents**
4. Paste into SQL Editor
5. Click **Run**

**Expected output**:
```
Functions created successfully
Test from authenticated session: SELECT append_restaurant_legal_doc('https://example.com/doc.pdf')
```

### Step 2: Verify Functions Exist

Run in SQL Editor:
```sql
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname IN ('append_restaurant_legal_doc', 'append_ngo_legal_doc');
```

**Expected**: Returns 2 rows

### Step 3: Test Functions (Optional)

From authenticated Flutter session:
```dart
final result = await Supabase.instance.client.rpc(
  'append_restaurant_legal_doc',
  params: {'p_url': 'https://example.com/test.pdf'},
);
print(result); // Should show updated array
```

### Step 4: Code Already Updated ✅

The Flutter code has been updated to use RPC functions:
- File: `lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart`
- Changes: Lines 173-260 (uploadLegalDoc method)

---

## 🔍 WHAT CHANGED IN CODE

### Before (Broken)
```dart
await client.from('restaurants').update({
  'legal_docs_urls': [result.url]  // ❌ Overwrites
}).eq('profile_id', userId);
```

### After (Fixed)
```dart
// Call RPC function to atomically append URL
final rpcResult = await client.rpc(
  'append_restaurant_legal_doc',
  params: {'p_url': result.url},
);

// Verify URL was saved by reading back
final verification = await client
    .from('restaurants')
    .select('legal_docs_urls')
    .eq('profile_id', userId)
    .single();

final savedUrls = verification['legal_docs_urls'] as List?;
if (savedUrls == null || !savedUrls.contains(result.url)) {
  AuthLogger.warn('legalDoc.verificationFailed', ctx: {
    'expectedUrl': result.url,
    'actualUrls': savedUrls,
  });
}
```

**Key improvements**:
1. ✅ Uses RPC for atomic append
2. ✅ Verifies URL was saved
3. ✅ Logs verification result
4. ✅ Handles errors gracefully

---

## 🧪 TESTING CHECKLIST

### Test 1: Single Document Upload

1. Sign up as restaurant/NGO
2. Verify OTP
3. Upload legal document
4. Check logs for:
   ```
   [timestamp] INFO AUTH: legalDoc.saved | userId=..., url=..., updatedUrls=[...]
   [timestamp] INFO AUTH: legalDoc.verified | userId=..., urlCount=1
   ```
5. Verify in database:
   ```sql
   SELECT legal_docs_urls FROM restaurants WHERE profile_id = 'USER_ID';
   -- Expected: ['https://...']
   ```

### Test 2: Multiple Document Uploads

1. Upload first document
2. Upload second document
3. Check database:
   ```sql
   SELECT legal_docs_urls FROM restaurants WHERE profile_id = 'USER_ID';
   -- Expected: ['https://doc1.pdf', 'https://doc2.pdf']
   ```

### Test 3: Verify No Overwrites

1. Manually insert URL:
   ```sql
   UPDATE restaurants 
   SET legal_docs_urls = ARRAY['https://existing.pdf']
   WHERE profile_id = 'USER_ID';
   ```
2. Upload new document via app
3. Check database:
   ```sql
   SELECT legal_docs_urls FROM restaurants WHERE profile_id = 'USER_ID';
   -- Expected: ['https://existing.pdf', 'https://new.pdf']
   ```

### Test 4: Error Handling

1. Try uploading without authentication (should fail)
2. Try uploading empty URL (should fail)
3. Check logs for proper error messages

---

## 📊 VERIFICATION QUERIES

### Check if URLs are saved
```sql
-- For restaurants
SELECT 
  r.profile_id,
  p.email,
  r.restaurant_name,
  r.legal_docs_urls,
  array_length(r.legal_docs_urls, 1) as url_count
FROM restaurants r
JOIN profiles p ON p.id = r.profile_id
WHERE r.legal_docs_urls IS NOT NULL 
  AND array_length(r.legal_docs_urls, 1) > 0;

-- For NGOs
SELECT 
  n.profile_id,
  p.email,
  n.organization_name,
  n.legal_docs_urls,
  array_length(n.legal_docs_urls, 1) as url_count
FROM ngos n
JOIN profiles p ON p.id = n.profile_id
WHERE n.legal_docs_urls IS NOT NULL 
  AND array_length(n.legal_docs_urls, 1) > 0;
```

### Check for empty arrays (should be none after fix)
```sql
-- Restaurants with empty arrays
SELECT profile_id, restaurant_name 
FROM restaurants 
WHERE legal_docs_urls = ARRAY[]::text[] 
   OR legal_docs_urls IS NULL;

-- NGOs with empty arrays
SELECT profile_id, organization_name 
FROM ngos 
WHERE legal_docs_urls = ARRAY[]::text[] 
   OR legal_docs_urls IS NULL;
```

### Test RPC function directly
```sql
-- Must be run from authenticated session (not SQL Editor)
-- Use Flutter/Dart to test:
SELECT append_restaurant_legal_doc('https://test.com/doc.pdf');
```

---

## 🔒 SECURITY NOTES

### RPC Function Security

1. **SECURITY DEFINER**: Function runs with elevated privileges
2. **auth.uid() validation**: Only authenticated users can call
3. **Profile ownership check**: Users can only update their own records
4. **Input validation**: Empty URLs are rejected

### RLS Policies

The existing RLS policies still apply:
- Users can only update their own restaurant/NGO records
- RPC function respects these boundaries via `auth.uid() = profile_id`

---

## 🐛 TROUBLESHOOTING

### Error: "Function does not exist"

**Cause**: SQL migration not deployed  
**Fix**: Deploy `database-fix-legal-docs-append.sql`

### Error: "Not authenticated"

**Cause**: Calling RPC before OTP verification  
**Fix**: Ensure upload happens AFTER `confirmSignupCode()` succeeds

### Error: "Restaurant record not found"

**Cause**: Restaurant/NGO row doesn't exist  
**Fix**: Ensure trigger created the row during signup

### URLs still empty after upload

**Possible causes**:
1. RPC function not deployed → Deploy SQL migration
2. Error during RPC call → Check logs for `dbOpFailed`
3. Wrong user ID → Check `userId` matches `auth.uid()`
4. RLS blocking → Check user is authenticated

**Debug steps**:
```dart
// Add this after RPC call
print('RPC Result: $rpcResult');
print('User ID: $userId');
print('Auth UID: ${Supabase.instance.client.auth.currentUser?.id}');
```

---

## 📈 EXPECTED LOGS

### Successful Upload & Save

```
[timestamp] INFO AUTH: uploadPendingDocs.start | userId=abc-123, fileName=license.pdf

[timestamp] INFO AUTH: storage.upload.attempt | userId=abc-123, file=license.pdf

[timestamp] INFO AUTH: storage.upload.success | userId=abc-123, file=license.pdf, url=https://...

[timestamp] INFO AUTH: db.rpc.append_restaurant_legal_doc | table=restaurants, userId=abc-123, url=https://...

[timestamp] INFO AUTH: legalDoc.saved | userId=abc-123, role=restaurant, table=restaurants, url=https://..., updatedUrls=[https://...]

[timestamp] INFO AUTH: legalDoc.verified | userId=abc-123, urlCount=1

[timestamp] INFO AUTH: uploadPendingDocs.success | userId=abc-123, url=https://...
```

### Failed Save (Before Fix)

```
[timestamp] INFO AUTH: storage.upload.success | userId=abc-123, url=https://...

[timestamp] INFO AUTH: db.update | table=restaurants, userId=abc-123, field=legal_docs_urls

[timestamp] INFO AUTH: legalDoc.saved | userId=abc-123, role=restaurant, table=restaurants

// But database still shows []
```

### Failed Save (After Fix - with error)

```
[timestamp] INFO AUTH: storage.upload.success | userId=abc-123, url=https://...

[timestamp] INFO AUTH: db.rpc.append_restaurant_legal_doc | table=restaurants, userId=abc-123

[timestamp] ERROR AUTH: db.rpc.append_legal_doc.failed | table=restaurants, userId=abc-123, url=https://..., error=...

[timestamp] WARN AUTH: legalDoc.verificationFailed | userId=abc-123, expectedUrl=https://..., actualUrls=[]
```

---

## 📝 SUMMARY

### Root Cause
- Code used `.update({'legal_docs_urls': [url]})` which **overwrites** array
- No atomic append operation
- No verification that save succeeded

### Fix Applied
- ✅ Created RPC functions: `append_restaurant_legal_doc()`, `append_ngo_legal_doc()`
- ✅ Updated Flutter code to use RPC instead of direct update
- ✅ Added verification step to confirm URL was saved
- ✅ Enhanced logging for debugging

### Deployment Required
1. Deploy `database-fix-legal-docs-append.sql` in Supabase SQL Editor
2. Code changes already applied (no Flutter rebuild needed if hot reload works)
3. Test with new signup or existing user

### Testing
- Upload document after OTP verification
- Check logs for `legalDoc.verified`
- Query database to confirm URLs are saved
- Try multiple uploads to verify append works

---

**Status**: ✅ Fix ready for deployment  
**Priority**: 🔴 HIGH - Blocks document verification  
**ETA**: 5 minutes (2 min SQL deploy + 3 min test)

