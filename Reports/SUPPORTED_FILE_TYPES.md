# 📄 Legal Documents - Supported File Types

## ✅ All Supported Types

Users can now upload **ANY** of these safe document types:

| # | File Type | Extensions | MIME Type | Icon |
|---|-----------|------------|-----------|------|
| 1 | PDF Document | `.pdf` | application/pdf | 📕 |
| 2 | JPEG Image | `.jpg`, `.jpeg` | image/jpeg | 🖼️ |
| 3 | PNG Image | `.png` | image/png | 🖼️ |
| 4 | GIF Image | `.gif` | image/gif | 🖼️ |
| 5 | Word 97-2003 | `.doc` | application/msword | 📘 |
| 6 | Word 2007+ | `.docx` | application/vnd.openxmlformats-officedocument.wordprocessingml.document | 📘 |

## 🎯 Configuration Match

### Bucket Configuration
```sql
-- From: migrations/create_legal_docs_bucket.sql
allowed_mime_types = ARRAY[
  'application/pdf',
  'image/jpeg',
  'image/png',
  'image/gif',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
]
```

### File Picker Configuration
```dart
// From: lib/features/authentication/presentation/screens/auth_screen.dart
allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'doc', 'docx']
```

### MIME Type Detection
```dart
if (fileName.endsWith('.pdf')) → 'application/pdf'
if (fileName.endsWith('.jpg|.jpeg')) → 'image/jpeg'
if (fileName.endsWith('.png')) → 'image/png'
if (fileName.endsWith('.gif')) → 'image/gif'
if (fileName.endsWith('.doc')) → 'application/msword'
if (fileName.endsWith('.docx')) → 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
```

✅ **100% Match** - All configurations are synchronized!

## 🧪 Testing Checklist

Test each file type:

- [ ] Upload `.pdf` file → Should work ✅
- [ ] Upload `.jpg` file → Should work ✅
- [ ] Upload `.jpeg` file → Should work ✅
- [ ] Upload `.png` file → Should work ✅
- [ ] Upload `.gif` file → Should work ✅
- [ ] Upload `.doc` file → Should work ✅
- [ ] Upload `.docx` file → Should work ✅

## 📱 User Experience

### File Picker Dialog
When user clicks "Upload Documents", they will see:
```
Select files
Allowed: pdf, jpg, jpeg, png, gif, doc, docx
```

### UI Instructions
```
Please upload your legal documents 
(Business License, Registration Certificate, etc.)
Supported formats: PDF, JPG, PNG, GIF, DOC, DOCX
```

### Upload Success
```
✅ Document uploaded successfully!
   license.pdf
```

## 🔒 Security

All file types are:
- ✅ Validated by extension
- ✅ Validated by MIME type
- ✅ Size limited (10MB max)
- ✅ Stored in secure bucket with RLS policies

## 📊 Common Use Cases

| Document Type | Recommended Format | Why |
|---------------|-------------------|-----|
| Business License | PDF | Official, can't be edited |
| Registration Certificate | PDF | Official, can't be edited |
| Scanned Documents | JPG/PNG | From scanner/phone camera |
| Signed Forms | PDF or DOCX | Editable or final version |
| Company Logo | PNG/GIF | Transparent background |

## 🚫 Not Supported

These file types are **NOT** allowed for security:
- ❌ Executable files (.exe, .bat, .sh)
- ❌ Scripts (.js, .py, .php)
- ❌ Archives (.zip, .rar, .7z)
- ❌ Other office formats (.xls, .ppt)

## 💡 Tips for Users

**Best Practices**:
1. Use PDF for official documents (most professional)
2. Use JPG/PNG for scanned documents or photos
3. Keep file size under 10MB
4. Use clear, readable scans
5. Ensure document is complete and not cut off

**File Size Limits**:
- Maximum: 10MB per file
- Recommended: Under 5MB for faster upload

---

**Status**: ✅ All Types Supported  
**Last Updated**: 2026-02-01  
**Total Supported Types**: 6 (PDF, JPEG, PNG, GIF, DOC, DOCX)
