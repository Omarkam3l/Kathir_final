# ⚡ Legal Docs Upload - Quick Fix Reference

## 🐛 The Problem
Legal document URLs not saved to database after upload.

## 🔧 The Fix
Added retry logic to wait for database trigger completion.

---

## 📋 What Changed

### Single File Modified
```
lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart
```

### What Was Added
- Retry loop (up to 5 attempts)
- 500ms delay between retries
- Better error logging

---

## ✅ Quick Test

### 1. Sign Up Flow
```
1. Go to signup screen
2. Select "Restaurant" or "NGO"
3. Fill in all fields
4. Click "Upload Documents"
5. Select a PDF or image file
6. Wait for "Document uploaded successfully" ✅
7. Click "Create Account"
8. Enter OTP from email
9. Should redirect to home ✅
```

### 2. Verify Database
```sql
-- Check if URL was saved
SELECT 
  email,
  legal_docs_urls,
  array_length(legal_docs_urls, 1) as count
FROM profiles p
JOIN restaurants r ON r.profile_id = p.id
ORDER BY p.created_at DESC
LIMIT 1;
```

**Expected**: `count` should be `1`, `legal_docs_urls` should contain URL

---

## 🔍 Troubleshooting

### Still Not Working?

**Check 1**: RPC functions exist
```sql
SELECT proname FROM pg_proc 
WHERE proname LIKE 'append_%_legal_doc';
```
Expected: 2 rows

**Fix**: Run `migrations/database-fix-legal-docs-append.sql`

---

**Check 2**: Storage bucket exists
```sql
SELECT * FROM storage.buckets 
WHERE id = 'legal_docs_bucket';
```
Expected: 1 row

**Fix**: Run `migrations/create_legal_docs_bucket.sql`

---

**Check 3**: Check logs
Look for:
```
✅ savePendingDocUrl.success
```

If you see:
```
❌ savePendingDocUrl.exception
```
Share the error message for diagnosis.

---

## 📊 Success Indicators

✅ File uploads without errors  
✅ "Document uploaded successfully" message appears  
✅ OTP verification completes  
✅ User redirected to home  
✅ Database shows URL in `legal_docs_urls`  
✅ Logs show `savePendingDocUrl.success`  

---

## 📞 Need Help?

1. Check detailed analysis: `Reports/LEGAL_DOCS_UPLOAD_ISSUE_ANALYSIS.md`
2. Check deployment guide: `LEGAL_DOCS_FIX_DEPLOYMENT.md`
3. Check summary: `LEGAL_DOCS_ISSUE_SUMMARY.md`

---

**Status**: ✅ Fixed & Ready  
**Risk**: 🟢 Low (only adds retry logic)  
**Testing**: ⏳ Pending production test
