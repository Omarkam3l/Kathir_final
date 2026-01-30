# 📋 Legal Documents Upload - Complete Logging Guide

## ✅ IMPLEMENTED FEATURES

### 1. Enhanced Document Picker with Logging

**File**: `lib/features/authentication/presentation/screens/auth_screen.dart`

#### Features Added:
- ✅ File type validation (PDF, JPG, JPEG, PNG only)
- ✅ File size validation (max 10MB)
- ✅ Comprehensive logging at each step
- ✅ Snackbar feedback for all states
- ✅ File information display (name, size)

#### Log Events:

```dart
// When picker opens
AuthLogger.info('documentPicker.opening', ctx: {
  'role': 'restaurant/ngo',
});

// When file selected
AuthLogger.info('documentPicker.selected', ctx: {
  'fileName': 'license.pdf',
  'fileSize': 524288,
  'fileSizeKB': '512.00',
  'role': 'restaurant',
});

// When file too large
AuthLogger.warn('documentPicker.fileTooLarge', ctx: {
  'fileName': 'large-file.pdf',
  'fileSize': 15728640,
  'maxSize': 10485760,
});

// When selection successful
AuthLogger.info('documentPicker.success', ctx: {
  'fileName': 'license.pdf',
  'documentsUploaded': true,
});

// When user cancels
AuthLogger.info('documentPicker.cancelled', ctx: {
  'role': 'restaurant',
});
```

### 2. Snackbar Feedback States

#### Opening Picker
```
🔄 Opening file picker...
```

#### File Selected Successfully
```
✅ Document selected successfully!
   license.pdf (512.0 KB)
```

#### File Too Large
```
❌ File too large! Maximum size is 10MB
```

#### No File Selected
```
⚠️ No document selected
```

### 3. Storage Upload Logging

**File**: `lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart`

#### Log Events:

```dart
// Upload attempt
AuthLogger.docUploadAttempt(userId: 'abc-123', fileName: 'license.pdf');

// Upload success
AuthLogger.docUploadSuccess(
  userId: 'abc-123',
  fileName: 'license.pdf',
  url: 'https://storage.supabase.co/...',
);

// Upload failed
AuthLogger.docUploadFailed(
  userId: 'abc-123',
  fileName: 'license.pdf',
  error: error,
  stackTrace: stackTrace,
);
```

### 4. Database Save Logging

#### RPC Call Logging:

```dart
// RPC attempt
AuthLogger.dbOp(
  operation: 'rpc.append_restaurant_legal_doc',
  table: 'restaurants',
  userId: 'abc-123',
  extra: {'url': 'https://...'},
);

// RPC success
AuthLogger.info('legalDoc.saved', ctx: {
  'userId': 'abc-123',
  'role': 'restaurant',
  'table': 'restaurants',
  'url': 'https://...',
  'updatedUrls': ['https://...'],
});

// Verification success
AuthLogger.info('legalDoc.verified', ctx: {
  'userId': 'abc-123',
  'urlCount': 1,
});

// Verification failed
AuthLogger.warn('legalDoc.verificationFailed', ctx: {
  'userId': 'abc-123',
  'expectedUrl': 'https://...',
  'actualUrls': [],
});

// RPC failed
AuthLogger.dbOpFailed(
  operation: 'rpc.append_legal_doc',
  table: 'restaurants',
  userId: 'abc-123',
  extra: {'url': 'https://...'},
  error: error,
  stackTrace: stackTrace,
);
```

---

## 🔍 COMPLETE FLOW WITH LOGS

### Successful Upload Flow

```
1. User clicks "Upload Documents"
   [timestamp] INFO AUTH: documentPicker.opening | role=SignUpRole.restaurant

2. User selects file
   [timestamp] INFO AUTH: documentPicker.selected | fileName=license.pdf, fileSize=524288, fileSizeKB=512.00, role=SignUpRole.restaurant
   
   Snackbar: ✅ Document selected successfully! license.pdf (512.0 KB)

3. User completes signup
   [timestamp] INFO AUTH: signup.result | userId=abc-123, hasSession=false

4. User enters OTP
   [timestamp] INFO AUTH: confirmSignupCode.success | userId=abc-123, role=restaurant

5. Upload starts
   [timestamp] INFO AUTH: uploadPendingDocs.start | userId=abc-123, fileName=license.pdf
   [timestamp] INFO AUTH: storage.upload.attempt | userId=abc-123, file=license.pdf

6. Upload succeeds
   [timestamp] INFO AUTH: storage.upload.success | userId=abc-123, file=license.pdf, url=https://...

7. Save to database
   [timestamp] INFO AUTH: db.rpc.append_restaurant_legal_doc | table=restaurants, userId=abc-123, url=https://...
   [timestamp] INFO AUTH: legalDoc.saved | userId=abc-123, role=restaurant, url=https://..., updatedUrls=['https://...']

8. Verify saved
   [timestamp] INFO AUTH: legalDoc.verified | userId=abc-123, urlCount=1
   [timestamp] INFO AUTH: uploadPendingDocs.success | userId=abc-123, url=https://...
```

### Failed Upload Flow (File Too Large)

```
1. User clicks "Upload Documents"
   [timestamp] INFO AUTH: documentPicker.opening | role=SignUpRole.restaurant

2. User selects large file
   [timestamp] INFO AUTH: documentPicker.selected | fileName=huge.pdf, fileSize=15728640, fileSizeKB=15360.00, role=SignUpRole.restaurant
   [timestamp] WARN AUTH: documentPicker.fileTooLarge | fileName=huge.pdf, fileSize=15728640, maxSize=10485760
   
   Snackbar: ❌ File too large! Maximum size is 10MB
```

### Cancelled Selection Flow

```
1. User clicks "Upload Documents"
   [timestamp] INFO AUTH: documentPicker.opening | role=SignUpRole.restaurant

2. User cancels picker
   [timestamp] INFO AUTH: documentPicker.cancelled | role=SignUpRole.restaurant
   
   Snackbar: ⚠️ No document selected
```

---

## 🐛 DEBUGGING EMPTY legal_docs_urls

### Check These Logs:

#### 1. Was file selected?
```
Look for: documentPicker.success | documentsUploaded=true
```
If missing → User didn't select file

#### 2. Was upload attempted?
```
Look for: uploadPendingDocs.start | userId=..., fileName=...
```
If missing → Upload not triggered after OTP

#### 3. Did upload succeed?
```
Look for: storage.upload.success | url=https://...
```
If missing → Storage upload failed

#### 4. Was RPC called?
```
Look for: db.rpc.append_restaurant_legal_doc | url=https://...
```
If missing → Role check failed or RPC not called

#### 5. Did RPC succeed?
```
Look for: legalDoc.saved | updatedUrls=['https://...']
```
If missing → RPC failed (check error logs)

#### 6. Was save verified?
```
Look for: legalDoc.verified | urlCount=1
```
If missing → Verification failed (URL not in array)

### Common Issues:

#### Issue: No upload logs after OTP
**Cause**: `pendingLegalDocBytes` is null  
**Check**: Look for `documentPicker.success` before signup

#### Issue: RPC not called
**Cause**: Role mismatch (role='rest' instead of 'restaurant')  
**Check**: Look for role in logs, should be 'restaurant' not 'rest'

#### Issue: RPC fails
**Cause**: RPC functions not deployed  
**Check**: Deploy `database-fix-legal-docs-append.sql`

#### Issue: Verification fails
**Cause**: URL not actually saved  
**Check**: Look for `legalDoc.verificationFailed` with actualUrls

---

## 📊 VERIFICATION QUERIES

### Check if URL was saved
```sql
SELECT 
  p.email,
  r.restaurant_name,
  r.legal_docs_urls,
  array_length(r.legal_docs_urls, 1) as url_count
FROM restaurants r
JOIN profiles p ON p.id = r.profile_id
WHERE p.email = 'YOUR_EMAIL';
```

### Check recent uploads
```sql
SELECT 
  p.email,
  p.role,
  CASE 
    WHEN p.role = 'restaurant' THEN r.legal_docs_urls
    WHEN p.role = 'ngo' THEN n.legal_docs_urls
  END as legal_docs_urls,
  p.created_at
FROM profiles p
LEFT JOIN restaurants r ON r.profile_id = p.id
LEFT JOIN ngos n ON n.profile_id = p.id
WHERE p.role IN ('restaurant', 'ngo')
ORDER BY p.created_at DESC
LIMIT 10;
```

### Check storage objects
```sql
SELECT 
  name,
  bucket_id,
  created_at,
  metadata->>'size' as file_size
FROM storage.objects
WHERE bucket_id = 'legal-docs'
ORDER BY created_at DESC
LIMIT 10;
```

---

## 🧪 TESTING CHECKLIST

### Test 1: Complete Flow
- [ ] Click "Upload Documents"
- [ ] See snackbar: "Opening file picker..."
- [ ] Select PDF file (< 10MB)
- [ ] See snackbar: "Document selected successfully! filename.pdf (XXX KB)"
- [ ] Complete signup
- [ ] Enter OTP
- [ ] Check logs for complete flow (all 8 steps above)
- [ ] Verify URL in database

### Test 2: File Too Large
- [ ] Click "Upload Documents"
- [ ] Select file > 10MB
- [ ] See snackbar: "File too large! Maximum size is 10MB"
- [ ] Check logs for `documentPicker.fileTooLarge`

### Test 3: Cancel Selection
- [ ] Click "Upload Documents"
- [ ] Cancel picker (press ESC or close)
- [ ] See snackbar: "No document selected"
- [ ] Check logs for `documentPicker.cancelled`

### Test 4: Invalid File Type
- [ ] Click "Upload Documents"
- [ ] Try to select .txt or .doc file
- [ ] Should not appear in picker (filtered)

---

## 📝 LOG ANALYSIS TIPS

### Filter Logs by Event

```bash
# Document picker events
grep "documentPicker" logs.txt

# Upload events
grep "storage.upload" logs.txt

# Database save events
grep "legalDoc" logs.txt

# All legal docs related
grep -E "documentPicker|storage.upload|legalDoc|append_.*_legal_doc" logs.txt
```

### Count Events

```bash
# Count successful uploads
grep -c "storage.upload.success" logs.txt

# Count failed saves
grep -c "legalDoc.verificationFailed" logs.txt

# Count by role
grep "role=restaurant" logs.txt | wc -l
```

---

## 🎯 SUCCESS CRITERIA

After implementation:
- ✅ User sees snackbar for every action
- ✅ Every step is logged with context
- ✅ File validation works (size, type)
- ✅ Upload success/failure is clear
- ✅ Database save is verified
- ✅ Empty arrays are debuggable via logs

---

## 📞 TROUBLESHOOTING

### No logs appearing?

**Check**: `AuthLogger.enabled` is true (default in debug mode)

### Snackbar not showing?

**Check**: `mounted` is true before showing snackbar

### Upload succeeds but array empty?

**Check logs for**:
1. `legalDoc.saved` - RPC was called
2. `legalDoc.verified` - Verification passed
3. If verification failed, check `actualUrls` in log

**Run query**:
```sql
SELECT legal_docs_urls FROM restaurants WHERE profile_id = 'USER_ID';
```

### Role mismatch errors?

**Check**: Role should be 'restaurant' not 'rest'  
**Fix**: Deploy `database-migrate-rest-to-restaurant.sql`

---

**Status**: ✅ Logging implemented  
**Files Modified**: `auth_screen.dart`, `auth_viewmodel.dart`  
**Next**: Test complete flow and verify logs

