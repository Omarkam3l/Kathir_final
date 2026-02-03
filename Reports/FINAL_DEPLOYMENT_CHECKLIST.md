# ✅ Legal Documents Upload - Final Deployment Checklist

## 🎯 Overview

All code fixes are complete. You need to apply **ONE database migration** to fix the RLS policy error.

---

## 📋 Deployment Steps

### ✅ Step 1: Flutter Code (Already Done)

All Flutter code fixes have been applied:

- ✅ `lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart`
  - Retry logic for database trigger timing
  
- ✅ `lib/features/authentication/presentation/screens/auth_screen.dart`
  - Type conversion (List<int> → Uint8List)
  - MIME type detection (PDF, JPEG, PNG, GIF, DOC, DOCX)
  - File picker updated to allow all types

**Action**: ✅ No action needed - code is ready!

---

### 🔴 Step 2: Database Migration (REQUIRED)

**File**: `migrations/fix_legal_docs_bucket_rls.sql`

**What it fixes**: "new row violates row-level security" error

**How to apply**:

#### Option A: Supabase Dashboard (Recommended)

1. Go to your Supabase project
2. Click **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy the entire content of `migrations/fix_legal_docs_bucket_rls.sql`
5. Paste into the SQL editor
6. Click **Run** (or press Ctrl+Enter)
7. Wait for success message: ✅ "Success. No rows returned"

#### Option B: Supabase CLI

```bash
# If you have Supabase CLI installed
supabase db push migrations/fix_legal_docs_bucket_rls.sql
```

#### Option C: Manual Copy-Paste

```sql
-- Copy this entire block and run in Supabase SQL Editor:

DROP POLICY IF EXISTS "Allow authenticated uploads to legal_docs_bucket" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to read own legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read of legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to update own legal docs" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete own legal docs" ON storage.objects;

CREATE POLICY "Allow authenticated uploads to legal_docs_bucket"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'legal_docs_bucket'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    (storage.foldername(name))[1] = 'pending'
  )
);

CREATE POLICY "Allow users to read own legal docs"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'legal_docs_bucket'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    (storage.foldername(name))[1] = 'pending'
  )
);

CREATE POLICY "Allow public read of legal docs"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'legal_docs_bucket');

CREATE POLICY "Allow users to update own legal docs"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'legal_docs_bucket'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    (storage.foldername(name))[1] = 'pending'
  )
);

CREATE POLICY "Allow users to delete own legal docs"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'legal_docs_bucket'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    (storage.foldername(name))[1] = 'pending'
  )
);
```

**Action**: 🔴 **REQUIRED** - Apply this migration now!

---

### ✅ Step 3: Verify Migration

After applying the migration, verify it worked:

```sql
-- Run this query to check policies:
SELECT 
  policyname, 
  cmd,
  qual::text as condition
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE '%legal%';
```

**Expected**: You should see 5 policies, and the conditions should include `'pending'`.

**Action**: ✅ Verify policies are updated

---

### ✅ Step 4: Test Upload

1. **Open your app**
2. **Go to signup screen**
3. **Select "Restaurant" or "NGO"**
4. **Fill in all fields**
5. **Click "Upload Documents"**
6. **Select a file** (PDF, JPG, PNG, GIF, DOC, or DOCX)
7. **Wait for success message**: "Document uploaded successfully!" ✅
8. **Complete signup** (enter OTP)
9. **Check database**:

```sql
SELECT 
  p.email,
  r.restaurant_name,
  r.legal_docs_urls,
  array_length(r.legal_docs_urls, 1) as doc_count
FROM profiles p
JOIN restaurants r ON r.profile_id = p.id
WHERE p.email = 'your-test-email@example.com';
```

**Expected**: `legal_docs_urls` should contain the uploaded file URL, `doc_count` should be 1

**Action**: ✅ Test with real signup

---

## 🎯 Success Criteria

After deployment, you should see:

- ✅ File picker allows: PDF, JPG, PNG, GIF, DOC, DOCX
- ✅ Upload succeeds without RLS error
- ✅ Success message: "Document uploaded successfully!"
- ✅ URL saved to database after OTP verification
- ✅ No errors in console/logs

---

## 🐛 Troubleshooting

### Issue: Still getting RLS error

**Cause**: Migration not applied or not applied correctly

**Fix**:
1. Check if policies exist:
   ```sql
   SELECT policyname FROM pg_policies 
   WHERE tablename = 'objects' 
   AND policyname LIKE '%legal%';
   ```
2. If no policies found, re-run the migration
3. Make sure you're running it in the correct Supabase project

---

### Issue: MIME type error

**Cause**: File type not supported

**Fix**: Only use these file types:
- ✅ PDF (.pdf)
- ✅ JPEG (.jpg, .jpeg)
- ✅ PNG (.png)
- ✅ GIF (.gif)
- ✅ Word (.doc, .docx)

---

### Issue: URL not saved to database

**Cause**: Database trigger timing issue

**Fix**: Already fixed with retry logic. Check logs for:
```
savePendingDocUrl.success | attempts=1 (or 2, 3, etc.)
```

If you see `attempts=5` and still failing, check if RPC functions exist:
```sql
SELECT proname FROM pg_proc 
WHERE proname IN ('append_restaurant_legal_doc', 'append_ngo_legal_doc');
```

---

## 📊 All Issues Fixed

| Issue | Status | Fix Location |
|-------|--------|--------------|
| Type mismatch (List<int> vs Uint8List) | ✅ Fixed | `auth_screen.dart` |
| MIME type wildcard error | ✅ Fixed | `auth_screen.dart` |
| Limited file type support | ✅ Fixed | `auth_screen.dart` |
| RLS policy blocking upload | 🔴 **Needs Migration** | `fix_legal_docs_bucket_rls.sql` |
| URL not saved to database | ✅ Fixed | `auth_viewmodel.dart` |

---

## 📝 Documentation

Comprehensive guides created:

1. `LEGAL_DOCS_ISSUE_SUMMARY.md` - Overview with diagrams
2. `Reports/LEGAL_DOCS_UPLOAD_ISSUE_ANALYSIS.md` - Detailed analysis
3. `LEGAL_DOCS_FIX_DEPLOYMENT.md` - Deployment guide
4. `STORAGE_MIME_TYPE_FIX.md` - MIME type fix details
5. `RLS_POLICY_FIX.md` - RLS policy fix details
6. `SUPPORTED_FILE_TYPES.md` - File types reference
7. `FINAL_DEPLOYMENT_CHECKLIST.md` - This file

---

## 🚀 Ready to Deploy!

**Current Status**:
- ✅ Flutter code: Ready
- 🔴 Database migration: **Apply now!**
- ⏳ Testing: Pending

**Next Action**: 
1. Apply the database migration (Step 2 above)
2. Test the upload flow (Step 4 above)
3. Celebrate! 🎉

---

**Priority**: 🔴 Critical  
**Estimated Time**: 5 minutes  
**Risk**: 🟢 Low (only updates RLS policies)
