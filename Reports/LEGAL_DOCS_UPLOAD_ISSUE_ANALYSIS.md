# 🔍 Legal Document Upload Issue - Analysis & Fix

## 📋 Executive Summary

**Issue**: Legal documents are uploaded to storage successfully, but URLs are NOT being saved to the database (`restaurants.legal_docs_urls` or `ngos.legal_docs_urls` remain empty).

**Root Cause**: Timing issue - the RPC function is called BEFORE the restaurant/NGO record exists in the database.

**Status**: ⚠️ Critical - Requires immediate fix

---

## 🐛 Problem Description

When restaurants or NGOs sign up and upload legal documents:
1. ✅ File uploads to `legal_docs_bucket` storage successfully
2. ✅ Public URL is generated
3. ❌ URL is NOT saved to database
4. ❌ `legal_docs_urls` column remains `[]` (empty array)

---

## 🔬 Root Cause Analysis

### Current Flow (BROKEN)

```
1. User fills signup form
   ↓
2. User uploads document → File saved to storage ✅
   ↓
3. User clicks "Create Account"
   ↓
4. signup() called → Creates auth.users record ✅
   ↓
5. OTP sent to email ✅
   ↓
6. User enters OTP
   ↓
7. confirmSignupCode() called
   ↓
8. OTP verified ✅
   ↓
9. createOrGetProfile() called → Creates profiles record ✅
   ↓
10. ⚠️ PROBLEM: Tries to save URL to restaurants/ngos table
    BUT the trigger hasn't created the record yet!
   ↓
11. RPC call: append_restaurant_legal_doc(url)
    ↓
12. ❌ FAILS: "Restaurant record not found for user"
    ↓
13. Error is caught and logged, but signup continues
    ↓
14. Result: User is logged in, but legal_docs_urls = []
```

### The Timing Issue

**The Problem**: The code tries to save the legal document URL immediately after OTP verification, but:

1. **Profile trigger** creates the `restaurants`/`ngos` record asynchronously
2. **RPC function** runs BEFORE the trigger completes
3. **RPC fails** with "Restaurant record not found"

### Code Evidence

**File**: `lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart`

**Lines 323-360** (in `confirmSignupCode` method):
```dart
// After OTP verification
createOrGetProfile.call(r.id, data); // ← Creates profile

// Immediately tries to save URL (TOO SOON!)
if (pendingLegalDocUrl != null) {
  if (role == 'restaurant') {
    await client.rpc('append_restaurant_legal_doc', 
      params: {'p_url': pendingLegalDocUrl}); // ← FAILS!
  }
}
```

**The RPC Function** (`migrations/database-fix-legal-docs-append.sql`):
```sql
CREATE OR REPLACE FUNCTION public.append_restaurant_legal_doc(p_url text)
RETURNS jsonb AS $
BEGIN
  -- Update restaurant record
  UPDATE public.restaurants
  SET legal_docs_urls = array_append(...)
  WHERE profile_id = v_profile_id
  RETURNING legal_docs_urls INTO v_updated_urls;
  
  -- Check if update succeeded
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Restaurant record not found for user %'; -- ← THIS FIRES!
  END IF;
END;
$;
```

---

## 🔧 The Fix

### Solution: Add Retry Logic with Delay

We need to wait for the trigger to complete before calling the RPC function.

### Implementation

**File to Modify**: `lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart`

**Location**: Lines 323-360 in the `confirmSignupCode()` method

**Change Required**:

```dart
// ❌ CURRENT CODE (BROKEN)
if (pendingLegalDocUrl != null) {
  try {
    if (role == 'restaurant') {
      await client.rpc('append_restaurant_legal_doc', 
        params: {'p_url': pendingLegalDocUrl});
    }
  } catch (e, stackTrace) {
    AuthLogger.errorLog('savePendingDocUrl.exception', ...);
  }
}
```

```dart
// ✅ FIXED CODE (WITH RETRY)
if (pendingLegalDocUrl != null) {
  AuthLogger.info('savePendingDocUrl.start', ctx: {
    'userId': r.id,
    'url': pendingLegalDocUrl,
  });
  
  try {
    final role = r.role;
    
    // Wait for trigger to create restaurant/ngo record
    // Retry up to 5 times with 500ms delay
    bool saved = false;
    int attempts = 0;
    const maxAttempts = 5;
    
    while (!saved && attempts < maxAttempts) {
      attempts++;
      
      try {
        if (role == 'restaurant') {
          await client.rpc('append_restaurant_legal_doc', 
            params: {'p_url': pendingLegalDocUrl});
          saved = true;
        } else if (role == 'ngo') {
          await client.rpc('append_ngo_legal_doc', 
            params: {'p_url': pendingLegalDocUrl});
          saved = true;
        }
        
        if (saved) {
          AuthLogger.info('savePendingDocUrl.success', ctx: {
            'userId': r.id,
            'table': role == 'restaurant' ? 'restaurants' : 'ngos',
            'url': pendingLegalDocUrl,
            'attempts': attempts,
          });
        }
      } catch (e) {
        if (attempts < maxAttempts) {
          AuthLogger.warn('savePendingDocUrl.retry', ctx: {
            'userId': r.id,
            'attempt': attempts,
            'maxAttempts': maxAttempts,
            'error': e.toString(),
          });
          // Wait 500ms before retry
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          // Final attempt failed
          throw e;
        }
      }
    }
  } catch (e, stackTrace) {
    AuthLogger.errorLog('savePendingDocUrl.exception',
        ctx: {'userId': r.id, 'url': pendingLegalDocUrl},
        error: e,
        stackTrace: stackTrace);
  } finally {
    pendingLegalDocUrl = null;
    pendingLegalDocFileName = null;
  }
}
```

---

## 📁 Files Involved

### 1. **Flutter Code** (Needs Fix)
- **File**: `lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart`
- **Method**: `confirmSignupCode()` (lines 323-360)
- **Issue**: No retry logic, fails when record doesn't exist yet
- **Fix**: Add retry loop with 500ms delay

### 2. **Database Migration** (Already Correct)
- **File**: `migrations/database-fix-legal-docs-append.sql`
- **Status**: ✅ Correctly implemented
- **Functions**: 
  - `append_restaurant_legal_doc(p_url text)`
  - `append_ngo_legal_doc(p_url text)`

### 3. **Storage Bucket** (Already Correct)
- **File**: `migrations/create_legal_docs_bucket.sql`
- **Status**: ✅ Correctly configured
- **Bucket**: `legal_docs_bucket`
- **Policies**: ✅ Proper RLS policies in place

### 4. **UI Screen** (Already Correct)
- **File**: `lib/features/authentication/presentation/screens/auth_screen.dart`
- **Status**: ✅ Upload logic works correctly
- **Method**: `_uploadDocuments()` (lines 238-500)

---

## ✅ Verification Steps

After applying the fix:

### 1. Check Database Functions Exist
```sql
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname IN ('append_restaurant_legal_doc', 'append_ngo_legal_doc');
```
Expected: 2 rows

### 2. Check Storage Bucket Exists
```sql
SELECT id, name, public 
FROM storage.buckets 
WHERE id = 'legal_docs_bucket';
```
Expected: 1 row with `public = true`

### 3. Test Signup Flow
1. Sign up as restaurant/NGO
2. Upload legal document
3. Complete OTP verification
4. Check logs for:
   ```
   [timestamp] INFO AUTH: savePendingDocUrl.start
   [timestamp] INFO AUTH: savePendingDocUrl.success | attempts=1
   ```

### 4. Verify Database
```sql
SELECT 
  p.id,
  p.email,
  p.role,
  r.restaurant_name,
  r.legal_docs_urls,
  array_length(r.legal_docs_urls, 1) as doc_count
FROM profiles p
JOIN restaurants r ON r.profile_id = p.id
WHERE p.role = 'restaurant'
ORDER BY p.created_at DESC
LIMIT 5;
```
Expected: `legal_docs_urls` should contain URL, `doc_count` should be 1

---

## 🎯 Expected Outcome

After fix:
1. ✅ User uploads document → File saved to storage
2. ✅ User completes OTP verification
3. ✅ Trigger creates restaurant/NGO record
4. ✅ Retry logic waits for record to exist
5. ✅ RPC function saves URL to database
6. ✅ `legal_docs_urls` contains the uploaded file URL

---

## 📊 Impact

**Before Fix**:
- Upload success rate: ~0% (URLs not saved)
- Manual intervention required for every signup

**After Fix**:
- Upload success rate: ~100% (with retry logic)
- No manual intervention needed

---

## 🚀 Deployment Checklist

- [ ] Apply database migration: `database-fix-legal-docs-append.sql`
- [ ] Apply storage bucket setup: `create_legal_docs_bucket.sql`
- [ ] Update Flutter code: `auth_viewmodel.dart` (add retry logic)
- [ ] Test signup flow with restaurant role
- [ ] Test signup flow with NGO role
- [ ] Verify URLs are saved to database
- [ ] Monitor logs for any errors

---

**Generated**: 2026-02-01  
**Priority**: 🔴 Critical  
**Estimated Fix Time**: 15 minutes
