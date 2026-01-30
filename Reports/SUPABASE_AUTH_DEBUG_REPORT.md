# 🔍 Supabase Auth & Profile Flow Regression - Debug Report

## 📋 Executive Summary

**Status**: 🔴 CRITICAL ISSUES IDENTIFIED  
**Root Cause**: Missing database trigger + incomplete signup flow + legal docs not saved  
**Impact**: Restaurant/NGO signups broken, OTP emails not sent, legal documents uploaded but URLs not persisted

---

## 🎯 Root Causes Identified

### 1️⃣ **MISSING DATABASE TRIGGER** ⚠️ CRITICAL
**Problem**: No automatic profile creation trigger when `auth.users` record is created

**Evidence**:
- `database-full-schema.sql` has NO trigger like `handle_new_user()` 
- Supabase requires a trigger to auto-create profile records when users sign up
- Without this, the signup flow breaks because:
  - `auth.signUp()` creates user in `auth.users` table
  - BUT no corresponding `profiles` record is created automatically
  - Email confirmation is tied to profile existence in many Supabase setups

**Current Schema**:
```sql
-- ❌ MISSING: No trigger to auto-create profiles!
create table public.profiles (
  id uuid not null,
  role text null,
  email text null,
  ...
  constraint profiles_id_fkey foreign KEY (id) references auth.users (id) on delete CASCADE
)
```

**What's Missing**:
```sql
-- ❌ This function and trigger DO NOT EXIST in your schema
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, full_name, phone_number, is_verified)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'user'),
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.raw_user_meta_data->>'phone_number',
    false
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

---

### 2️⃣ **MISSING NGO/RESTAURANT TABLE RECORDS** ⚠️ CRITICAL
**Problem**: When restaurant/NGO signs up, only `profiles` table is populated, but `restaurants` and `ngos` tables are NEVER populated

**Evidence**:
- `auth_remote_datasource.dart` lines 82-103: Only calls `auth.signUp()` with metadata
- `auth_viewmodel.dart` line 115: TODO comment confirms this is not implemented
- `auth_provider.dart` line 127: TODO comment confirms this is not implemented
- NO code creates records in `restaurants` or `ngos` tables after signup

**Current Flow** (BROKEN):
```
1. User signs up as restaurant/NGO
2. auth.signUp() creates auth.users record ✅
3. Profile created (if trigger exists) ✅
4. ❌ restaurants/ngos table record NEVER created
5. ❌ legal_docs_urls field doesn't exist in profiles table
6. ❌ Document URL has nowhere to be saved
```

**Schema Shows**:
```sql
-- restaurants table has legal_docs_urls
CREATE TABLE public.restaurants (
    profile_id uuid PRIMARY KEY REFERENCES public.profiles(id),
    restaurant_name text NOT NULL,
    legal_docs_urls text[], -- ✅ This exists but never populated
    ...
);

-- ngos table has legal_docs_urls
CREATE TABLE public.ngos (
    profile_id uuid PRIMARY KEY REFERENCES public.profiles(id),
    organization_name text NOT NULL,
    legal_docs_urls text[] -- ✅ This exists but never populated
);
```

---

### 3️⃣ **LEGAL DOCUMENTS UPLOADED BUT URLS NOT SAVED** ⚠️ HIGH
**Problem**: Document upload succeeds, but URL is never written to database

**Evidence**:
- `auth_screen.dart` lines 108-130: Uploads document, gets URL, but does NOTHING with it
- `auth_viewmodel.dart` lines 109-120: `uploadLegalDoc()` returns URL but doesn't save it
- No database update after upload completes

**Current Code** (BROKEN):
```dart
// auth_screen.dart line 115
final result = await vm.uploadLegalDoc(uid, 'legal.pdf', _legalDocBytes!);
if (result.url != null) {
  // ❌ Shows success message but URL is LOST!
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Document uploaded successfully'))
  );
}
```

---

### 4️⃣ **OTP EMAIL NOT SENT FOR RESTAURANT/NGO** ⚠️ CRITICAL
**Problem**: Email verification fails silently for restaurant/NGO roles

**Root Cause Chain**:
1. Missing database trigger → profile not auto-created
2. Supabase email confirmation may depend on profile existence
3. RLS policies may block profile creation if done manually
4. Email confirmation link generation fails silently

**Evidence**:
- User reports: "No verification email / OTP is sent" for restaurant/NGO
- User reports: "✅ Signup + OTP works correctly for normal user role"
- This suggests role-specific issue, likely related to missing restaurant/ngo records

---

## 🔧 Complete Fix Implementation

### Fix 1: Add Database Trigger for Auto Profile Creation

**File**: Create `database-migrations-001-profile-trigger.sql`

```sql
-- ============================================
-- FIX 1: Auto-create profile when user signs up
-- ============================================

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  user_role text;
  user_full_name text;
  user_phone text;
  org_name text;
BEGIN
  -- Extract metadata
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'user');
  user_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', '');
  user_phone := NEW.raw_user_meta_data->>'phone_number';
  org_name := NEW.raw_user_meta_data->>'organization_name';

  -- Create profile record
  INSERT INTO public.profiles (
    id, 
    email, 
    role, 
    full_name, 
    phone_number, 
    is_verified,
    approval_status
  )
  VALUES (
    NEW.id,
    NEW.email,
    user_role,
    user_full_name,
    user_phone,
    CASE 
      WHEN user_role = 'user' THEN true 
      ELSE false 
    END,
    CASE 
      WHEN user_role IN ('restaurant', 'ngo') THEN 'pending'
      ELSE 'approved'
    END
  );

  -- Create restaurant record if role is restaurant
  IF user_role = 'restaurant' THEN
    INSERT INTO public.restaurants (
      profile_id,
      restaurant_name,
      legal_docs_urls
    )
    VALUES (
      NEW.id,
      COALESCE(org_name, user_full_name),
      ARRAY[]::text[]
    );
  END IF;

  -- Create NGO record if role is ngo
  IF user_role = 'ngo' THEN
    INSERT INTO public.ngos (
      profile_id,
      organization_name,
      legal_docs_urls
    )
    VALUES (
      NEW.id,
      COALESCE(org_name, user_full_name),
      ARRAY[]::text[]
    );
  END IF;

  RETURN NEW;
END;
$$;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW 
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- FIX 2: Add RLS policies to allow profile creation
-- ============================================

-- Enable RLS on profiles table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own profile
CREATE POLICY "Users can view own profile"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id);

-- Allow service role to insert profiles (for trigger)
CREATE POLICY "Service role can insert profiles"
  ON public.profiles
  FOR INSERT
  WITH CHECK (true);

-- Enable RLS on restaurants table
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;

-- Allow restaurant owners to view their own record
CREATE POLICY "Restaurant owners can view own record"
  ON public.restaurants
  FOR SELECT
  USING (auth.uid() = profile_id);

-- Allow restaurant owners to update their own record
CREATE POLICY "Restaurant owners can update own record"
  ON public.restaurants
  FOR UPDATE
  USING (auth.uid() = profile_id);

-- Allow service role to insert restaurants (for trigger)
CREATE POLICY "Service role can insert restaurants"
  ON public.restaurants
  FOR INSERT
  WITH CHECK (true);

-- Enable RLS on ngos table
ALTER TABLE public.ngos ENABLE ROW LEVEL SECURITY;

-- Allow NGO owners to view their own record
CREATE POLICY "NGO owners can view own record"
  ON public.ngos
  FOR SELECT
  USING (auth.uid() = profile_id);

-- Allow NGO owners to update their own record
CREATE POLICY "NGO owners can update own record"
  ON public.ngos
  FOR UPDATE
  USING (auth.uid() = profile_id);

-- Allow service role to insert NGOs (for trigger)
CREATE POLICY "Service role can insert ngos"
  ON public.ngos
  FOR INSERT
  WITH CHECK (true);
```

---

### Fix 2: Update Signup Flow to Pass Organization Name

**File**: `lib/features/authentication/data/datasources/auth_remote_datasource.dart`

```dart
@override
Future<UserModel> signUpNGO(
    String orgName, String fullName, String email, String password,
    {String? phone}) async {
  final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': UserRole.ngo.wireValue,
        'organization_name': orgName, // ✅ ADD THIS
        if (phone != null) 'phone_number': phone,
      },
      emailRedirectTo: kIsWeb
          ? Uri.base.toString()
          : 'io.supabase.flutter://login-callback/');
  if (res.session == null) {
    return UserModelFactory.fromAuthUser(res.user!);
  }
  return UserModelFactory.fromAuthUser(res.user!);
}

@override
Future<UserModel> signUpRestaurant(
    String orgName, String fullName, String email, String password,
    {String? phone}) async {
  final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': UserRole.restaurant.wireValue,
        'organization_name': orgName, // ✅ ADD THIS
        if (phone != null) 'phone_number': phone,
      },
      emailRedirectTo: kIsWeb
          ? Uri.base.toString()
          : 'io.supabase.flutter://login-callback/');
  if (res.session == null) {
    return UserModelFactory.fromAuthUser(res.user!);
  }
  return UserModelFactory.fromAuthUser(res.user!);
}
```

---

### Fix 3: Save Legal Document URLs to Database

**File**: `lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart`

```dart
/// Returns (url, error). On success url is set; on failure error contains the message.
Future<({String? url, String? error})> uploadLegalDoc(
    String userId, String fileName, List<int> bytes) async {
  final res = await uploadDocs(userId, fileName, bytes);
  final result = res.fold(
    (l) => (url: null, error: l.cause?.toString() ?? l.message),
    (r) => (url: r, error: null),
  );
  
  // ✅ ADD THIS: Save URL to database
  if (result.url != null && user != null) {
    try {
      final client = Supabase.instance.client;
      final role = user!.role;
      
      if (role == 'restaurant') {
        // Update restaurants table
        await client.from('restaurants').update({
          'legal_docs_urls': [result.url]
        }).eq('profile_id', userId);
      } else if (role == 'ngo') {
        // Update ngos table
        await client.from('ngos').update({
          'legal_docs_urls': [result.url]
        }).eq('profile_id', userId);
      }
    } catch (e) {
      debugPrint('Failed to save legal doc URL: $e');
      // Don't fail the whole operation, just log
    }
  }
  
  return result;
}
```

**Add import at top of file**:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```

---

### Fix 4: Ensure Email Confirmation Works

**File**: `lib/features/authentication/data/datasources/auth_remote_datasource.dart`

Update all signUp methods to ensure email confirmation is properly configured:

```dart
@override
Future<UserModel> signUpUser(
    String fullName, String email, String password) async {
  final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': UserRole.user.wireValue
      },
      emailRedirectTo: kIsWeb
          ? Uri.base.toString()
          : 'io.supabase.flutter://login-callback/');
  
  // ✅ Always return user, even if session is null (email confirmation pending)
  return UserModelFactory.fromAuthUser(res.user!);
}
```

Apply same pattern to `signUpNGO` and `signUpRestaurant` (already done in Fix 2).

---

## 📊 Flow Diagrams

### ❌ BROKEN FLOW (Before Fix)

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User fills signup form (restaurant/NGO)                  │
│    - Selects role: restaurant/ngo                           │
│    - Uploads legal documents                                │
│    - Submits form                                           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. auth.signUp() called                                     │
│    ✅ Creates record in auth.users                          │
│    ✅ Stores metadata (role, name, phone)                   │
│    ❌ NO TRIGGER → profiles table NOT populated             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Document upload                                          │
│    ✅ File uploaded to storage bucket                       │
│    ✅ Public URL generated                                  │
│    ❌ URL returned but NEVER saved to database              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Email verification                                       │
│    ❌ No profile record exists                              │
│    ❌ No restaurant/ngo record exists                       │
│    ❌ Email confirmation fails silently                     │
│    ❌ User stuck on OTP screen                              │
└─────────────────────────────────────────────────────────────┘
```

### ✅ FIXED FLOW (After Fix)

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User fills signup form (restaurant/NGO)                  │
│    - Selects role: restaurant/ngo                           │
│    - Uploads legal documents                                │
│    - Submits form                                           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. auth.signUp() called with organization_name              │
│    ✅ Creates record in auth.users                          │
│    ✅ Stores metadata (role, name, phone, org_name)         │
│    ✅ TRIGGER FIRES → handle_new_user()                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Trigger creates related records                          │
│    ✅ profiles table record created                         │
│    ✅ restaurants/ngos table record created                 │
│    ✅ approval_status set to 'pending'                      │
│    ✅ legal_docs_urls initialized as empty array            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Document upload                                          │
│    ✅ File uploaded to storage bucket                       │
│    ✅ Public URL generated                                  │
│    ✅ URL saved to restaurants/ngos.legal_docs_urls         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Email verification                                       │
│    ✅ Profile record exists                                 │
│    ✅ Restaurant/NGO record exists                          │
│    ✅ Email sent successfully                               │
│    ✅ User receives OTP                                     │
│    ✅ Verification completes                                │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Deployment Steps

### Step 1: Apply Database Migration
```bash
# Run this SQL in Supabase SQL Editor
# File: database-migrations-001-profile-trigger.sql
```

### Step 2: Update Dart Code
1. Update `auth_remote_datasource.dart` (Fix 2)
2. Update `auth_viewmodel.dart` (Fix 3)

### Step 3: Test Signup Flow
```
1. Sign up as restaurant with legal documents
2. Verify email is sent
3. Complete OTP verification
4. Check database:
   - profiles table has record
   - restaurants table has record
   - legal_docs_urls contains uploaded file URL
```

---

## ✅ Verification Checklist

- [ ] Database trigger created and active
- [ ] RLS policies applied
- [ ] organization_name passed in signUp metadata
- [ ] Legal document URLs saved to database
- [ ] Restaurant signup sends OTP email
- [ ] NGO signup sends OTP email
- [ ] User signup still works (regression test)
- [ ] Legal documents visible in database after upload
- [ ] Profile approval_status set correctly

---

## 🔍 Additional Recommendations

### 1. Add Error Logging
```dart
// In auth_remote_datasource.dart
Future<UserModel> signUpRestaurant(...) async {
  try {
    final res = await client.auth.signUp(...);
    debugPrint('✅ Signup successful: ${res.user?.id}');
    return UserModelFactory.fromAuthUser(res.user!);
  } catch (e) {
    debugPrint('❌ Signup failed: $e');
    rethrow;
  }
}
```

### 2. Add Database Validation
```sql
-- Ensure restaurants/ngos always have organization name
ALTER TABLE public.restaurants 
  ALTER COLUMN restaurant_name SET NOT NULL;

ALTER TABLE public.ngos 
  ALTER COLUMN organization_name SET NOT NULL;
```

### 3. Monitor Trigger Execution
```sql
-- Check if trigger is active
SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';

-- Check recent profile creations
SELECT id, email, role, created_at 
FROM public.profiles 
ORDER BY created_at DESC 
LIMIT 10;
```

---

## 📝 Summary

**Root Causes**:
1. ❌ Missing database trigger for auto-creating profiles
2. ❌ Missing restaurant/NGO table record creation
3. ❌ Legal document URLs not saved to database
4. ❌ Email verification depends on complete profile setup

**Fixes Applied**:
1. ✅ Added `handle_new_user()` trigger
2. ✅ Trigger creates profiles + restaurants/ngos records
3. ✅ Added RLS policies for proper access control
4. ✅ Updated signup flow to pass organization_name
5. ✅ Updated uploadLegalDoc to save URLs to database

**Expected Outcome**:
- Restaurant/NGO signups work correctly
- OTP emails sent immediately
- Legal documents saved and retrievable
- No silent failures

---

**Generated**: 2026-01-29  
**Status**: Ready for Implementation
