# 🚀 Legal Documents Upload Fix - Deployment Guide

## 📋 Quick Summary

**Issue**: Legal document URLs not being saved to database after upload  
**Root Cause**: RPC function called before database trigger creates restaurant/NGO record  
**Fix**: Added retry logic with 500ms delay (up to 5 attempts)

---

## ✅ What Was Fixed

### File Modified
- **`lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart`**
  - Added retry logic in `confirmSignupCode()` method
  - Waits for database trigger to complete before saving URL
  - Retries up to 5 times with 500ms delay between attempts

### How It Works Now

```
1. User uploads document → Saved to storage ✅
2. User completes OTP verification
3. Profile trigger creates restaurant/NGO record
4. NEW: Retry loop waits for record to exist
5. RPC function saves URL to database ✅
6. Success! legal_docs_urls contains the URL
```

---

## 🔧 Deployment Steps

### Step 1: Verify Database Setup

Run these queries in Supabase SQL Editor:

```sql
-- 1. Check RPC functions exist
SELECT proname 
FROM pg_proc 
WHERE proname IN ('append_restaurant_legal_doc', 'append_ngo_legal_doc');
-- Expected: 2 rows
```

If functions don't exist, run:
```sql
-- Apply this migration file:
-- migrations/database-fix-legal-docs-append.sql
```

```sql
-- 2. Check storage bucket exists
SELECT id, name, public 
FROM storage.buckets 
WHERE id = 'legal_docs_bucket';
-- Expected: 1 row with public = true
```

If bucket doesn't exist, run:
```sql
-- Apply this migration file:
-- migrations/create_legal_docs_bucket.sql
```

### Step 2: Deploy Flutter Code

The fix has already been applied to:
- `lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart`

**No additional changes needed!** Just rebuild and deploy your Flutter app.

### Step 3: Test the Fix

1. **Sign up as Restaurant**:
   - Fill signup form
   - Upload a legal document (PDF/image)
   - Wait for "Document uploaded successfully" message
   - Complete OTP verification
   - Check logs for success message

2. **Verify in Database**:
```sql
SELECT 
  p.email,
  p.role,
  r.restaurant_name,
  r.legal_docs_urls,
  array_length(r.legal_docs_urls, 1) as doc_count
FROM profiles p
JOIN restaurants r ON r.profile_id = p.id
WHERE p.role = 'restaurant'
ORDER BY p.created_at DESC
LIMIT 1;
```

Expected result:
- `legal_docs_urls` should contain the uploaded file URL
- `doc_count` should be 1

3. **Check Logs**:
Look for these log entries:
```
[timestamp] INFO AUTH: savePendingDocUrl.start | userId=..., url=https://...
[timestamp] INFO AUTH: savePendingDocUrl.success | userId=..., table=restaurants, attempts=1
```

If you see retry attempts:
```
[timestamp] WARN AUTH: savePendingDocUrl.retry | attempt=1, maxAttempts=5
[timestamp] INFO AUTH: savePendingDocUrl.success | attempts=2
```
This is normal! It means the trigger took a moment to complete.

---

## 🔍 Troubleshooting

### Issue: "Restaurant record not found" after 5 attempts

**Cause**: Database trigger is not creating the record

**Fix**:
1. Check if trigger exists:
```sql
SELECT tgname, tgrelid::regclass 
FROM pg_trigger 
WHERE tgname LIKE '%profile%';
```

2. If missing, apply the trigger migration:
```sql
-- migrations/database-FINAL-AUTH-REBUILD.sql
-- Look for: CREATE TRIGGER handle_new_profile_trigger
```

### Issue: "Permission denied for function append_restaurant_legal_doc"

**Cause**: RPC function permissions not granted

**Fix**:
```sql
GRANT EXECUTE ON FUNCTION public.append_restaurant_legal_doc(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.append_ngo_legal_doc(text) TO authenticated;
```

### Issue: Upload succeeds but URL still empty

**Cause**: Check the logs for the actual error

**Debug**:
1. Enable verbose logging in your app
2. Look for `savePendingDocUrl.exception` in logs
3. Share the error message for further diagnosis

---

## 📊 Success Metrics

After deployment, monitor:

1. **Upload Success Rate**:
```sql
SELECT 
  'restaurants' as type,
  COUNT(*) as total,
  COUNT(CASE WHEN array_length(legal_docs_urls, 1) > 0 THEN 1 END) as with_docs,
  ROUND(100.0 * COUNT(CASE WHEN array_length(legal_docs_urls, 1) > 0 THEN 1 END) / COUNT(*), 2) as success_rate
FROM public.restaurants
UNION ALL
SELECT 
  'ngos' as type,
  COUNT(*) as total,
  COUNT(CASE WHEN array_length(legal_docs_urls, 1) > 0 THEN 1 END) as with_docs,
  ROUND(100.0 * COUNT(CASE WHEN array_length(legal_docs_urls, 1) > 0 THEN 1 END) / COUNT(*), 2) as success_rate
FROM public.ngos;
```

Expected: `success_rate` should be close to 100%

2. **Retry Attempts Distribution**:
Check logs to see how many retries are typically needed:
- 1 attempt: Trigger completed immediately (ideal)
- 2-3 attempts: Normal (trigger took 500-1000ms)
- 4-5 attempts: Slow (investigate database performance)

---

## 🎯 Expected Outcome

✅ Legal documents upload successfully  
✅ URLs are saved to database automatically  
✅ No manual intervention required  
✅ Retry logic handles timing issues gracefully  

---

## 📞 Support

If issues persist after deployment:
1. Check the detailed analysis: `Reports/LEGAL_DOCS_UPLOAD_ISSUE_ANALYSIS.md`
2. Review logs for error messages
3. Verify all migration files have been applied

---

**Deployment Date**: 2026-02-01  
**Status**: ✅ Ready for Production  
**Risk Level**: 🟢 Low (only adds retry logic, no breaking changes)
