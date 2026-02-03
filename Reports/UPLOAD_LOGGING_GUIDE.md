# 📊 Legal Document Upload - Comprehensive Logging Guide

## 🎯 Overview

The upload operation now has **8 detailed logging steps** plus comprehensive error analysis to help you identify exactly where problems occur.

---

## 📋 Upload Steps (Success Flow)

When upload succeeds, you'll see these logs in order:

### Step 1: Initialization
```
📤 UPLOAD_STEP_1: Initialization
  bucket: legal_docs_bucket
  path: pending/1738425600000_license.pdf
  fileName: license.pdf
  fileSize: 524288
  fileSizeKB: 512.00
  timestamp: 1738425600000
```

**What it means**: Upload process started, file path generated

---

### Step 2: Authentication Check
```
🔐 UPLOAD_STEP_2: Auth Check
  hasSession: true
  hasUser: true
  userId: abc-123-def-456
  userEmail: test@restaurant.com
  isAuthenticated: true
```

**What it means**: User authentication status verified

**⚠️ Warning Signs**:
- `hasSession: false` → User not logged in
- `hasUser: false` → No user object
- `isAuthenticated: false` → Authentication failed

---

### Step 3: MIME Type Detection
```
📄 UPLOAD_STEP_3: MIME Type Detection
  fileName: license.pdf
  extension: pdf
  contentType: application/pdf
  isSupported: true
```

**What it means**: File type detected and MIME type assigned

**⚠️ Warning Signs**:
- `contentType: application/octet-stream` → Unknown file type
- `isSupported: false` → File type not recognized

---

### Step 4: Data Preparation
```
💾 UPLOAD_STEP_4: Data Preparation
  originalSize: 524288
  convertedSize: 524288
  dataType: Uint8List
  isValid: true
```

**What it means**: File data converted to correct format

**⚠️ Warning Signs**:
- `originalSize != convertedSize` → Data conversion issue
- `isValid: false` → Empty or corrupted data

---

### Step 5: Upload Execution
```
🚀 UPLOAD_STEP_5: Starting Upload
  bucket: legal_docs_bucket
  path: pending/1738425600000_license.pdf
  contentType: application/pdf
  upsert: true
  dataSize: 524288

✅ UPLOAD_STEP_5: Upload Complete
  uploadPath: pending/1738425600000_license.pdf
  expectedPath: pending/1738425600000_license.pdf
  pathsMatch: true
```

**What it means**: File uploaded to storage successfully

**⚠️ Warning Signs**:
- `pathsMatch: false` → Upload path mismatch

---

### Step 6: Public URL Generation
```
🔗 UPLOAD_STEP_6: Public URL Generated
  publicUrl: https://storage.supabase.co/.../pending/1738425600000_license.pdf
  urlLength: 156
  isValid: true
```

**What it means**: Public URL created for accessing the file

**⚠️ Warning Signs**:
- `isValid: false` → URL generation failed
- `urlLength: 0` → Empty URL

---

### Step 7: Verification (Optional)
```
✅ UPLOAD_STEP_7: Verification Success
  fileFound: true
  fileName: 1738425600000_license.pdf
  fileSize: 524288
  createdAt: 2026-02-01T10:30:00Z
```

**What it means**: File verified in storage bucket

**⚠️ Note**: If this step fails, it's OK - the file is still uploaded

---

### Step 8: Complete
```
🎉 UPLOAD_COMPLETE: All Steps Successful
  fileName: license.pdf
  publicUrl: https://storage.supabase.co/.../pending/1738425600000_license.pdf
  uploadPath: pending/1738425600000_license.pdf
  totalSteps: 8
```

**What it means**: Upload completed successfully!

---

## ❌ Error Analysis (Failure Flow)

When upload fails, you'll see detailed error analysis:

### Error Log Format
```
❌ UPLOAD_FAILED: Error Analysis
  errorCategory: RLS_POLICY_ERROR
  errorType: StorageException
  errorMessage: new row violates row-level security
  solution: Apply fix_legal_docs_bucket_rls.sql migration
  bucket: legal_docs_bucket
  fileName: license.pdf
  fileSize: 524288
  path: pending/1738425600000_license.pdf
```

---

## 🔍 Error Categories

### 1. RLS_POLICY_ERROR
```
errorCategory: RLS_POLICY_ERROR
errorMessage: new row violates row-level security
solution: Apply fix_legal_docs_bucket_rls.sql migration
```

**Cause**: Storage bucket RLS policies blocking upload

**Fix**: Apply the migration file:
```sql
-- Run in Supabase SQL Editor:
-- migrations/fix_legal_docs_bucket_rls.sql
```

---

### 2. MIME_TYPE_ERROR
```
errorCategory: MIME_TYPE_ERROR
errorMessage: mime type image/* is not supported
solution: Check file extension and MIME type mapping
```

**Cause**: Invalid or unsupported MIME type

**Fix**: Already fixed in code - should not occur

---

### 3. BUCKET_NOT_FOUND
```
errorCategory: BUCKET_NOT_FOUND
errorMessage: Bucket not found: legal_docs_bucket
solution: Apply create_legal_docs_bucket.sql migration
```

**Cause**: Storage bucket doesn't exist

**Fix**: Apply the migration file:
```sql
-- Run in Supabase SQL Editor:
-- migrations/create_legal_docs_bucket.sql
```

---

### 4. PERMISSION_ERROR
```
errorCategory: PERMISSION_ERROR
errorMessage: permission denied for bucket legal_docs_bucket
solution: Check bucket policies and user authentication
```

**Cause**: User doesn't have permission to upload

**Fix**: Check RLS policies and user authentication

---

### 5. FILE_SIZE_ERROR
```
errorCategory: FILE_SIZE_ERROR
errorMessage: File size exceeds maximum allowed size
solution: File exceeds 10MB limit
```

**Cause**: File too large (>10MB)

**Fix**: Use smaller file or increase bucket limit

---

### 6. NETWORK_ERROR
```
errorCategory: NETWORK_ERROR
errorMessage: Network request failed
solution: Check internet connection
```

**Cause**: No internet connection or network issue

**Fix**: Check internet connection and retry

---

## 🔍 Storage Exception Details

For `StorageException` errors, additional details are logged:

```
🔍 STORAGE_EXCEPTION_DETAILS
  message: new row violates row-level security
  statusCode: 403
  error: RLS policy violation
```

---

## 📊 How to Read Logs

### Success Example
```
[2026-02-01 10:30:00] INFO AUTH: 📤 UPLOAD_STEP_1: Initialization | bucket=legal_docs_bucket, path=pending/...
[2026-02-01 10:30:00] INFO AUTH: 🔐 UPLOAD_STEP_2: Auth Check | hasSession=true, isAuthenticated=true
[2026-02-01 10:30:00] INFO AUTH: 📄 UPLOAD_STEP_3: MIME Type Detection | contentType=application/pdf
[2026-02-01 10:30:00] INFO AUTH: 💾 UPLOAD_STEP_4: Data Preparation | isValid=true
[2026-02-01 10:30:01] INFO AUTH: 🚀 UPLOAD_STEP_5: Starting Upload | bucket=legal_docs_bucket
[2026-02-01 10:30:02] INFO AUTH: ✅ UPLOAD_STEP_5: Upload Complete | pathsMatch=true
[2026-02-01 10:30:02] INFO AUTH: 🔗 UPLOAD_STEP_6: Public URL Generated | isValid=true
[2026-02-01 10:30:02] INFO AUTH: ✅ UPLOAD_STEP_7: Verification Success | fileFound=true
[2026-02-01 10:30:02] INFO AUTH: 🎉 UPLOAD_COMPLETE: All Steps Successful | totalSteps=8
```

**Result**: ✅ Upload succeeded!

---

### Failure Example (RLS Error)
```
[2026-02-01 10:30:00] INFO AUTH: 📤 UPLOAD_STEP_1: Initialization | bucket=legal_docs_bucket
[2026-02-01 10:30:00] INFO AUTH: 🔐 UPLOAD_STEP_2: Auth Check | hasSession=true, isAuthenticated=true
[2026-02-01 10:30:00] INFO AUTH: 📄 UPLOAD_STEP_3: MIME Type Detection | contentType=application/pdf
[2026-02-01 10:30:00] INFO AUTH: 💾 UPLOAD_STEP_4: Data Preparation | isValid=true
[2026-02-01 10:30:01] INFO AUTH: 🚀 UPLOAD_STEP_5: Starting Upload | bucket=legal_docs_bucket
[2026-02-01 10:30:01] ERROR AUTH: ❌ UPLOAD_FAILED: Error Analysis | errorCategory=RLS_POLICY_ERROR
[2026-02-01 10:30:01] ERROR AUTH: 🔍 STORAGE_EXCEPTION_DETAILS | statusCode=403
```

**Result**: ❌ Upload failed at Step 5 due to RLS policy

**Fix**: Apply `fix_legal_docs_bucket_rls.sql` migration

---

## 🎯 Quick Troubleshooting

### Problem: Upload fails at Step 2
**Symptom**: `isAuthenticated: false`  
**Fix**: User needs to log in first

---

### Problem: Upload fails at Step 5 with RLS error
**Symptom**: `errorCategory: RLS_POLICY_ERROR`  
**Fix**: Apply `migrations/fix_legal_docs_bucket_rls.sql`

---

### Problem: Upload fails at Step 5 with MIME error
**Symptom**: `errorCategory: MIME_TYPE_ERROR`  
**Fix**: Check file extension (should be pdf, jpg, png, gif, doc, docx)

---

### Problem: Upload fails at Step 5 with bucket not found
**Symptom**: `errorCategory: BUCKET_NOT_FOUND`  
**Fix**: Apply `migrations/create_legal_docs_bucket.sql`

---

## 📝 Log Filtering

### View all upload logs:
```bash
grep "UPLOAD_" logs.txt
```

### View only errors:
```bash
grep "UPLOAD_FAILED" logs.txt
```

### View specific step:
```bash
grep "UPLOAD_STEP_5" logs.txt
```

### View error categories:
```bash
grep "errorCategory" logs.txt
```

---

## 🚀 Next Steps

1. **Test upload** with a real file
2. **Check logs** for the 8 steps
3. **If error occurs**, check the error category
4. **Apply fix** based on error category
5. **Retry upload**

---

**Status**: ✅ Comprehensive Logging Enabled  
**Total Steps**: 8  
**Error Categories**: 6  
**Date**: 2026-02-01
