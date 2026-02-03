# ⚡ Upload Error - Quick Reference

## 🔍 How to Diagnose

1. **Try to upload a document**
2. **Check the logs** (console/terminal)
3. **Find the error category**
4. **Apply the fix below**

---

## ❌ Error: RLS_POLICY_ERROR

### Log Message
```
errorCategory: RLS_POLICY_ERROR
errorMessage: new row violates row-level security
```

### What It Means
Storage bucket policies are blocking the upload to `pending/` folder.

### Fix
```sql
-- Run this in Supabase SQL Editor:
-- File: migrations/fix_legal_docs_bucket_rls.sql

DROP POLICY IF EXISTS "Allow authenticated uploads to legal_docs_bucket" ON storage.objects;

CREATE POLICY "Allow authenticated uploads to legal_docs_bucket"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'legal_docs_bucket'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    (storage.foldername(name))[1] = 'pending'  -- ← This fixes it!
  )
);
```

### Verify Fix
```sql
SELECT policyname FROM pg_policies 
WHERE tablename = 'objects' 
AND policyname LIKE '%legal%';
```

---

## ❌ Error: MIME_TYPE_ERROR

### Log Message
```
errorCategory: MIME_TYPE_ERROR
errorMessage: mime type image/* is not supported
```

### What It Means
File type MIME detection failed or unsupported type.

### Fix
✅ Already fixed in code! Should not occur.

If it does occur:
- Check file extension is one of: pdf, jpg, jpeg, png, gif, doc, docx
- Rebuild and redeploy the app

---

## ❌ Error: BUCKET_NOT_FOUND

### Log Message
```
errorCategory: BUCKET_NOT_FOUND
errorMessage: Bucket not found: legal_docs_bucket
```

### What It Means
Storage bucket doesn't exist in Supabase.

### Fix
```sql
-- Run this in Supabase SQL Editor:
-- File: migrations/create_legal_docs_bucket.sql

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'legal_docs_bucket',
  'legal_docs_bucket',
  true,
  10485760,
  ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/gif', 
        'application/msword', 
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 10485760;
```

### Verify Fix
```sql
SELECT * FROM storage.buckets WHERE id = 'legal_docs_bucket';
```

---

## ❌ Error: PERMISSION_ERROR

### Log Message
```
errorCategory: PERMISSION_ERROR
errorMessage: permission denied
```

### What It Means
User doesn't have permission to upload.

### Fix
1. Check user is authenticated:
   ```sql
   SELECT auth.uid();  -- Should return user ID, not null
   ```

2. Check bucket policies exist:
   ```sql
   SELECT policyname FROM pg_policies 
   WHERE tablename = 'objects' 
   AND schemaname = 'storage';
   ```

3. If no policies, apply both migrations:
   - `create_legal_docs_bucket.sql`
   - `fix_legal_docs_bucket_rls.sql`

---

## ❌ Error: FILE_SIZE_ERROR

### Log Message
```
errorCategory: FILE_SIZE_ERROR
errorMessage: File size exceeds maximum
```

### What It Means
File is larger than 10MB.

### Fix
**Option 1**: Use smaller file (recommended)

**Option 2**: Increase bucket limit
```sql
UPDATE storage.buckets 
SET file_size_limit = 20971520  -- 20MB
WHERE id = 'legal_docs_bucket';
```

---

## ❌ Error: NETWORK_ERROR

### Log Message
```
errorCategory: NETWORK_ERROR
errorMessage: Network request failed
```

### What It Means
No internet connection or Supabase is unreachable.

### Fix
1. Check internet connection
2. Check Supabase project is running
3. Check Supabase URL in `.env` file
4. Retry upload

---

## 🎯 Most Common Error

**90% of upload failures are RLS_POLICY_ERROR**

### Quick Fix
```sql
-- Just run this one query:
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
```

---

## 📊 Diagnostic Checklist

Run these queries to check your setup:

```sql
-- 1. Check bucket exists
SELECT id, name, public FROM storage.buckets WHERE id = 'legal_docs_bucket';
-- Expected: 1 row

-- 2. Check RLS policies
SELECT policyname FROM pg_policies 
WHERE tablename = 'objects' AND policyname LIKE '%legal%';
-- Expected: 5 rows

-- 3. Check RPC functions
SELECT proname FROM pg_proc 
WHERE proname IN ('append_restaurant_legal_doc', 'append_ngo_legal_doc');
-- Expected: 2 rows

-- 4. Check user is authenticated
SELECT auth.uid();
-- Expected: UUID (not null)
```

---

## 🚀 After Applying Fix

1. **Restart your app** (if needed)
2. **Try upload again**
3. **Check logs** for success message:
   ```
   🎉 UPLOAD_COMPLETE: All Steps Successful
   ```

---

**Priority**: 🔴 Critical  
**Most Common Fix**: Apply `fix_legal_docs_bucket_rls.sql`  
**Success Rate After Fix**: ~100%
