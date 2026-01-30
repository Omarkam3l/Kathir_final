# 🔐 COMPLETE AUTHENTICATION WORKFLOW

## 📋 TABLE OF CONTENTS
1. User Signup Flow
2. Restaurant/NGO Signup Flow
3. Login Flow
4. Password Reset Flow
5. Admin Approval Flow
6. Document Upload Flow

---

## 👤 USER SIGNUP FLOW

### Step-by-Step Process

```
1. User opens app → /auth screen
   
2. User selects "Individual" role
   
3. User fills form:
   - Full Name
   - Email
   - Password
   
4. User clicks "Create Account"
   
5. App calls: signUpUser()
   ↓
   Supabase creates auth.users with:
   - email
   - encrypted_password
   - raw_user_meta_data: {role: 'user', full_name: '...'}
   
6. Trigger fires: handle_new_user()
   ↓
   Creates profile:
   - id: auth.users.id
   - role: 'user'
   - approval_status: 'approved' (auto-approved for users)
   - is_verified: false
   
7. Supabase sends OTP email
   
8. App navigates to: /verification screen
   
9. User enters OTP code
   
10. App calls: verifySignupOtp()
    ↓
    Supabase verifies OTP
    ↓
    Updates: email_confirmed_at = NOW()
    
11. Profile updated: is_verified = true
    
12. App redirects to: /home
```

### Database State After User Signup

```sql
-- auth.users
{
  id: 'uuid',
  email: 'user@example.com',
  email_confirmed_at: '2026-01-29...',
  raw_user_meta_data: {
    role: 'user',
    full_name: 'John Doe'
  }
}

-- profiles
{
  id: 'uuid',
  email: 'user@example.com',
  role: 'user',
  full_name: 'John Doe',
  approval_status: 'approved',
  is_verified: true
}
```

---

## 🏪 RESTAURANT/NGO SIGNUP FLOW

### Step-by-Step Process

```
1. User opens app → /auth screen
   
2. User selects "Restaurant" or "NGO" role
   
3. User fills form:
   - Full Name
   - Email
   - Password
   - Organization Name
   - Phone Number (optional)
   
4. User clicks "Upload Documents"
   ↓
   File picker opens (PDF, JPG, PNG only, max 10MB)
   ↓
   User selects file
   ↓
   File stored in memory (pendingLegalDocBytes)
   ↓
   Snackbar: "Document selected successfully!"
   
5. User clicks "Create Account"
   
6. App calls: signUpRestaurant() or signUpNGO()
   ↓
   Supabase creates auth.users with:
   - email
   - encrypted_password
   - raw_user_meta_data: {
       role: 'restaurant',
       full_name: '...',
       organization_name: '...',
       phone_number: '...'
     }
   
7. Trigger fires: handle_new_user()
   ↓
   Creates profile:
   - id: auth.users.id
   - role: 'restaurant'
   - approval_status: 'pending' (requires admin approval)
   - is_verified: false
   ↓
   Creates restaurant record:
   - profile_id: auth.users.id
   - restaurant_name: organization_name or default
   - legal_docs_urls: [] (empty initially)
   
8. Supabase sends OTP email
   
9. App navigates to: /verification screen
   
10. User enters OTP code
    
11. App calls: verifySignupOtp()
    ↓
    Supabase verifies OTP
    ↓
    Updates: email_confirmed_at = NOW()
    ↓
    Profile updated: is_verified = true
    
12. Upload pending documents:
    ↓
    Upload to storage: legal-docs/{user_id}/{filename}
    ↓
    Returns URL: https://storage.supabase.co/...
    ↓
    Call RPC: append_restaurant_legal_doc(url)
    ↓
    Updates: legal_docs_urls = [url]
    
13. App redirects to: /pending-approval screen
    
14. User waits for admin approval
    
15. Admin reviews and approves
    ↓
    Updates: approval_status = 'approved'
    
16. User can now access: /restaurant-dashboard
```

### Database State After Restaurant Signup

```sql
-- auth.users
{
  id: 'uuid',
  email: 'restaurant@example.com',
  email_confirmed_at: '2026-01-29...',
  raw_user_meta_data: {
    role: 'restaurant',
    full_name: 'John Doe',
    organization_name: 'Green Leaf Bistro',
    phone_number: '+1234567890'
  }
}

-- profiles
{
  id: 'uuid',
  email: 'restaurant@example.com',
  role: 'restaurant',
  full_name: 'John Doe',
  phone_number: '+1234567890',
  approval_status: 'pending',
  is_verified: true
}

-- restaurants
{
  profile_id: 'uuid',
  restaurant_name: 'Green Leaf Bistro',
  legal_docs_urls: ['https://storage.supabase.co/...'],
  rating: 0,
  min_order_price: 0
}
```

---

## 🔑 LOGIN FLOW

### Step-by-Step Process

```
1. User opens app → /auth screen
   
2. User clicks "Sign In" tab
   
3. User fills form:
   - Email
   - Password
   
4. User clicks "Sign In"
   
5. App calls: signIn()
   ↓
   Supabase validates credentials
   ↓
   Returns session + user
   
6. App checks user role:
   
   IF role = 'user':
     → Redirect to /home
   
   IF role = 'restaurant' OR 'ngo':
     Check approval_status:
     
     IF approval_status = 'pending':
       → Redirect to /pending-approval
     
     IF approval_status = 'approved':
       → Redirect to /restaurant-dashboard or /ngo-dashboard
     
     IF approval_status = 'rejected':
       → Show error: "Your account has been rejected"
   
   IF role = 'admin':
     → Redirect to /admin-dashboard
```

---

## 🔄 PASSWORD RESET FLOW

### Step-by-Step Process

```
1. User clicks "Forgot Password?"
   
2. App navigates to: /forgot-password screen
   
3. User enters email
   
4. User clicks "Send Reset Link"
   
5. App calls: sendPasswordResetEmail()
   ↓
   Supabase sends recovery email with OTP
   
6. App navigates to: /verification screen (recovery mode)
   
7. User enters OTP from email
   
8. App calls: verifyRecoveryOtp()
   ↓
   Supabase validates OTP
   ↓
   Sets password recovery session
   
9. App navigates to: /reset-password screen
   
10. User enters new password
    
11. App calls: updatePassword()
    ↓
    Supabase updates encrypted_password
    
12. App redirects to: /auth (login)
    
13. User logs in with new password
```

---

## 👨‍💼 ADMIN APPROVAL FLOW

### Step-by-Step Process

```
1. Admin logs in → /admin-dashboard
   
2. Admin sees pending approvals list:
   - Restaurant/NGO name
   - Owner name
   - Email
   - Phone
   - Submitted date
   - Documents count
   
3. Admin clicks on pending user
   
4. Admin reviews:
   - User details
   - Organization info
   - Legal documents (view/download)
   
5. Admin decides:
   
   APPROVE:
   ↓
   App calls: updateApprovalStatus('approved')
   ↓
   UPDATE profiles SET approval_status = 'approved'
   ↓
   User can now access dashboard
   ↓
   (Optional) Send approval email notification
   
   REJECT:
   ↓
   App calls: updateApprovalStatus('rejected')
   ↓
   UPDATE profiles SET approval_status = 'rejected'
   ↓
   User cannot access dashboard
   ↓
   (Optional) Send rejection email with reason
```

---

## 📄 DOCUMENT UPLOAD FLOW (Detailed)

### During Signup

```
1. User selects file
   ↓
   Logs: documentPicker.opening
   ↓
   File picker opens (filtered: PDF, JPG, PNG)
   ↓
   User selects file
   ↓
   Validate file size (max 10MB)
   ↓
   IF too large:
     Show error snackbar
     Logs: documentPicker.fileTooLarge
     STOP
   ↓
   Store in memory: pendingLegalDocBytes
   ↓
   Logs: documentPicker.success
   ↓
   Show success snackbar with filename and size
```

### After OTP Verification

```
1. OTP verified successfully
   ↓
   Check if pendingLegalDocBytes exists
   ↓
   IF exists:
     ↓
     Logs: uploadPendingDocs.start
     ↓
     Upload to storage:
       Bucket: legal-docs
       Path: {user_id}/{filename}
       ↓
       Logs: storage.upload.attempt
       ↓
       Returns URL
       ↓
       Logs: storage.upload.success
     ↓
     Save URL to database:
       Call RPC: append_restaurant_legal_doc(url)
       ↓
       Logs: db.rpc.append_restaurant_legal_doc
       ↓
       RPC appends URL to array atomically
       ↓
       Logs: legalDoc.saved
     ↓
     Verify saved:
       SELECT legal_docs_urls FROM restaurants
       ↓
       Check if URL in array
       ↓
       IF found:
         Logs: legalDoc.verified
       ELSE:
         Logs: legalDoc.verificationFailed
     ↓
     Clear pending documents from memory
     ↓
     Logs: uploadPendingDocs.success
```

---

## 🔐 SECURITY & RLS

### Row Level Security Policies

**Profiles**:
- Users can view own profile
- Users can update own profile (except approval_status)
- Admins can view all profiles
- Admins can update approval_status

**Restaurants/NGOs**:
- Owners can view/update own record
- Public can view approved records only
- Admins can view all records

**Storage (legal-docs)**:
- Users can upload to own folder only: {user_id}/*
- Users can view own documents
- Admins can view all documents
- Max file size: 10MB
- Allowed types: PDF, JPG, JPEG, PNG

---

## 📊 STATE TRANSITIONS

### Approval Status States

```
pending → approved → (user can access dashboard)
pending → rejected → (user blocked)
rejected → pending → (admin can reopen)
```

### Verification States

```
is_verified: false → (after signup)
is_verified: true → (after OTP verification)
```

---

## 🎯 KEY POINTS

1. **Users** are auto-approved, no admin review needed
2. **Restaurants/NGOs** require admin approval
3. **Documents** upload after OTP verification (when authenticated)
4. **Role** must be 'restaurant' not 'rest' (fixed)
5. **URLs** saved using RPC append (atomic, no overwrites)
6. **Admins** identified by role='admin' in profiles or JWT claim

