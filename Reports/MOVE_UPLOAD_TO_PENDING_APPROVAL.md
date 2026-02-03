# 🔄 Move Legal Document Upload to Pending Approval Screen

## 🎯 Problem

Legal documents are being uploaded **BEFORE** OTP verification, when the user is **NOT authenticated**. This causes:
- ❌ 403 / RLS Unauthorized errors
- ❌ Storage upload failures
- ❌ Race conditions with database triggers

## ✅ Solution

Move the upload logic to the **Pending Approval Screen**, which runs **AFTER** OTP verification when the user is fully authenticated.

---

## 📋 Implementation Steps

### Step 1: Clean Up auth_screen.dart

**Remove these from `lib/features/authentication/presentation/screens/auth_screen.dart`**:

1. **Remove the UploadState enum** (line ~25):
```dart
// DELETE THIS:
enum UploadState { idle, uploading, success, error }
```

2. **Remove upload-related state variables** (lines ~30-41):
```dart
// DELETE THESE:
List<int>? _legalDocBytes;
UploadState _uploadState = UploadState.idle;
String? _uploadError;
String? _uploadedDocUrl;
String? _uploadedFileName;
bool _isUploading = false;
bool _documentsUploaded = false;
```

3. **Remove the entire `_uploadDocuments()` method** (lines ~160-610)

4. **Remove the entire `_buildDocumentUploadSection()` method** (lines ~643-860)

5. **Remove the document upload section from UI** (lines ~404-410):
```dart
// DELETE THIS:
if (!isLogin &&
    (_selectedRole == UserRole.ngo ||
        _selectedRole == UserRole.restaurant)) ...[
  const SizedBox(height: 20),
  _buildDocumentUploadSection(
      isDark, textPrimary, textMuted, surface, border),
],
```

6. **Remove unused imports**:
```dart
// DELETE THESE:
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
```

7. **Simplify `_handleSignUp()` method** - remove all upload-related checks and URL storage logic

---

### Step 2: Update pending_approval_screen.dart

**Replace `lib/features/authentication/presentation/screens/pending_approval_screen.dart`** with the new implementation that includes upload functionality.

**Key Features**:
- Check if `legal_docs_urls` is empty
- If empty → show upload UI
- If not empty → show "Documents submitted" message
- Upload only when user is authenticated
- Use existing RPC functions to save URLs
- Comprehensive logging

---

### Step 3: Update Navigation Flow

The navigation is already correct in `app_router.dart`:
- After OTP verification → `/pending-approval` (for restaurant/NGO)
- After OTP verification → `/home` (for regular users)

No changes needed here! ✅

---

### Step 4: Remove Pending Logic from auth_viewmodel.dart

**In `lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart`**:

Remove these variables (lines ~38-40):
```dart
// DELETE THESE:
List<int>? pendingLegalDocBytes;
String? pendingLegalDocFileName;
String? pendingLegalDocUrl;
```

Remove the entire pending document upload logic from `confirmSignupCode()` method (lines ~323-390)

---

## 🎯 Expected Flow After Implementation

### For Restaurant/NGO Users:

```
1. User fills signup form (NO upload here!)
   ↓
2. User clicks "Create Account"
   ↓
3. OTP sent to email
   ↓
4. User enters OTP
   ↓
5. OTP verified ✅
   ↓
6. User is now AUTHENTICATED ✅
   ↓
7. Navigate to Pending Approval Screen
   ↓
8. Check legal_docs_urls:
   - If empty → Show upload UI
   - If not empty → Show "Awaiting approval" message
   ↓
9. User uploads document (NOW authenticated!)
   ↓
10. Upload succeeds ✅ (no RLS errors!)
   ↓
11. Save URL using RPC function ✅
   ↓
12. Show "Documents submitted, awaiting approval"
```

### For Regular Users:

```
1. User fills signup form
   ↓
2. User clicks "Create Account"
   ↓
3. OTP sent to email
   ↓
4. User enters OTP
   ↓
5. OTP verified ✅
   ↓
6. Navigate to /home ✅
```

---

## ✅ Benefits

1. **No RLS Errors** - Upload happens when user is authenticated
2. **No Race Conditions** - Database trigger completes before upload
3. **Better UX** - Clear separation of signup and document upload
4. **Retry Capability** - Users can retry upload if it fails
5. **Cleaner Code** - Signup screen is simpler

---

## 🔧 Files to Modify

| File | Action | Lines |
|------|--------|-------|
| `auth_screen.dart` | Remove upload logic | ~160-860 |
| `auth_viewmodel.dart` | Remove pending variables | ~38-40, ~323-390 |
| `pending_approval_screen.dart` | Add upload functionality | Replace entire file |

---

## 📝 Testing Checklist

After implementation:

- [ ] Regular user signup works (no upload required)
- [ ] Restaurant signup redirects to pending approval
- [ ] NGO signup redirects to pending approval
- [ ] Pending approval screen shows upload UI
- [ ] Document upload succeeds (no RLS errors)
- [ ] URL is saved to database
- [ ] Screen shows "Documents submitted" after upload
- [ ] Users who already uploaded see "Awaiting approval"

---

## 🚀 Next Steps

Due to the complexity and size of the auth_screen.dart file, I recommend:

1. **Manual cleanup** of auth_screen.dart (remove upload logic)
2. **Create new** pending_approval_screen.dart with upload functionality
3. **Test** the new flow thoroughly

Would you like me to:
- A) Create the new pending_approval_screen.dart with full upload functionality?
- B) Provide step-by-step instructions for manual cleanup?
- C) Create a complete replacement auth_screen.dart file?

---

**Status**: 📋 Implementation Plan Ready  
**Priority**: 🔴 Critical  
**Estimated Time**: 2-3 hours for complete implementation
