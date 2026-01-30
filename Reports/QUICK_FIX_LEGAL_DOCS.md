# ⚡ QUICK FIX: Legal Docs URLs Empty

## 🐛 Problem
`legal_docs_urls` stays `[]` after upload

## 🔍 Root Cause
Code overwrites array instead of appending:
```dart
// ❌ WRONG
'legal_docs_urls': [url]  // Replaces entire array
```

## ✅ Fix
Use atomic RPC append functions

---

## 🚀 Deploy (2 Steps)

### 1. Run SQL Migration
```
Supabase Dashboard → SQL Editor
Copy: database-fix-legal-docs-append.sql
Paste → Run
```

### 2. Code Already Updated ✅
No action needed - code auto-updated

---

## 🧪 Test (3 Steps)

### 1. Upload Document
Sign up → Verify OTP → Upload

### 2. Check Logs
Look for:
```
legalDoc.verified | urlCount=1
```

### 3. Verify Database
```sql
SELECT legal_docs_urls FROM restaurants 
WHERE profile_id = 'YOUR_ID';
```
Expected: `['https://...']`

---

## 🐛 Still Failing?

### Check Functions Exist
```sql
SELECT proname FROM pg_proc 
WHERE proname LIKE 'append_%_legal_doc';
```
Expected: 2 rows

### Check Error Logs
Look for:
```
ERROR AUTH: db.rpc.append_legal_doc.failed
```
Share complete error

---

## 📁 Files

**Deploy**: `database-fix-legal-docs-append.sql`  
**Updated**: `auth_viewmodel.dart` ✅  
**Docs**: `FIX_LEGAL_DOCS_URLS.md`

---

**Time**: 5 minutes  
**Risk**: Low  
**Priority**: HIGH
