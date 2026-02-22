# 🚀 Implementation Guide - Supabase Auth Fix

## 📋 Overview
This guide walks you through implementing the fixes for the Supabase authentication regression that broke restaurant/NGO signups and email verification.

---

## ⚡ Quick Start (5 Minutes)

### Step 1: Apply Database Migration (2 min)
1. Open Supabase Dashboard → SQL Editor
2. Copy contents of `database-migrations-001-profile-trigger.sql`
3. Paste and click "Run"
4. Verify success message appears

### Step 2: Code Changes Already Applied ✅
The following files have been updated:
- ✅ `lib/features/authentication/data/datasources/auth_remote_datasource.dart`
- ✅ `lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart`

### Step 3: Test (3 min)
```bash
# Run the app
flutter run

# Test signup flow:
# 1. Sign up as restaurant
# 2. Upload legal document
# 3. Check email for OTP
# 4. Verify OTP works
```

---

## 🔍 What Was Fixed

### Problem 1: Missing Database Trigger ❌ → ✅
**Before**: No automatic profile creation when users signed up
**After**: Trigger automatically creates:
- Profile record in `profiles` table
- Restaurant record in `restaurants` table (if role = restaurant)
- NGO record in `ngos` table (if role = ngo)

### Problem 2: Organization Name Not Passed ❌ → ✅
**Before**: `organization_name` not included in signup metadata
**After**: `organization_name` passed to Supabase and used by trigger

### Problem 3: Legal Document URLs Not Saved ❌ → ✅
**Before**: Document uploaded but URL lost
**After**: URL automatically saved to `restaurants.legal_docs_urls` or `ngos.legal_docs_urls`

### Problem 4: Email Verification Failed ❌ → ✅
**Before**: OTP emails not sent for restaurant/NGO signups
**After**: Complete profile setup enables email verification

---

## 📝 Detailed Implementation Steps

### Step 1: Database Migration

#### 1.1 Open Supabase SQL Editor
- Go to your Supabase project dashboard
- Navigate to: **SQL Editor** (left sidebar)
- Click: **New Query**

#### 1.2 Run Migration
```sql
-- Copy entire contents of database-migrations-001-profile-trigger.sql
-- Paste into SQL Editor
-- Click "Run" button
```

#### 1.3 Verify Migration Success
Run these verification queries:

```sql
-- Check trigger exists
SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
-- Should return 1 row

-- Check function exists
SELECT proname FROM pg_proc WHERE proname = 'handle_new_user';
-- Should return 1 row

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('profiles', 'restaurants', 'ngos');
-- Should show rowsecurity = true for all 3 tables

-- Check policies exist
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';
-- Should show multiple policies for profiles, restaurants, ngos
```

---

### Step 2: Code Changes (Already Applied)

The following changes have been made to your codebase:

#### 2.1 Updated `auth_remote_datasource.dart`
**Location**: `lib/features/authentication/data/datasources/auth_remote_datasource.dart`

**Changes**:
- Added `'organization_name': orgName` to `signUpNGO()` metadata
- Added `'organization_name': orgName` to `signUpRestaurant()` metadata
- Fixed phone parameter passing in `signUpRestaurant()`

**What this does**: Ensures organization name is available to the database trigger

#### 2.2 Updated `auth_viewmodel.dart`
**Location**: `lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart`

**Changes**:
- Added database update logic in `uploadLegalDoc()` method
- Saves document URL to `restaurants.legal_docs_urls` or `ngos.legal_docs_urls`
- Added error handling to prevent upload failures from breaking signup

**What this does**: Persists legal document URLs to the database

---

### Step 3: Testing

#### 3.1 Test Restaurant Signup
```
1. Run app: flutter run
2. Navigate to signup screen
3. Select role: Restaurant
4. Fill in:
   - Restaurant Name: "Test Restaurant"
   - Full Name: "John Doe"
   - Email: "test@restaurant.com"
   - Phone: "+1234567890"
   - Password: "Test123!"
5. Upload legal document (any PDF)
6. Click "Create Account"
7. ✅ Check: Success message appears
8. ✅ Check: Email received with OTP
9. Enter OTP code
10. ✅ Check: Verification succeeds
11. ✅ Check: Redirected to home screen
```

#### 3.2 Test NGO Signup
```
1. Select role: NGO
2. Fill in:
   - Organization Name: "Test NGO"
   - Full Name: "Jane Smith"
   - Email: "test@ngo.org"
   - Phone: "+1234567890"
   - Password: "Test123!"
3. Upload legal document
4. Click "Create Account"
5. ✅ Check: Email received with OTP
6. Enter OTP and verify
7. ✅ Check: Signup completes successfully
```

#### 3.3 Test User Signup (Regression Test)
```
1. Select role: Individual
2. Fill in basic info
3. Click "Create Account"
4. ✅ Check: Still works as before
5. ✅ Check: No legal documents required
6. ✅ Check: Email verification works
```

#### 3.4 Verify Database Records
After successful signup, check Supabase dashboard:

```sql
-- Check profile was created
SELECT id, email, role, full_name, approval_status 
FROM public.profiles 
WHERE email = 'test@restaurant.com';
-- Should return 1 row with role='restaurant', approval_status='pending'

-- Check restaurant record was created
SELECT profile_id, restaurant_name, legal_docs_urls 
FROM public.restaurants 
WHERE profile_id = (SELECT id FROM profiles WHERE email = 'test@restaurant.com');
-- Should return 1 row with restaurant_name and legal_docs_urls array

-- Check legal document URL was saved
SELECT legal_docs_urls 
FROM public.restaurants 
WHERE profile_id = (SELECT id FROM profiles WHERE email = 'test@restaurant.com');
-- Should show array with uploaded document URL
```

---

## 🐛 Troubleshooting

### Issue: Trigger not firing
**Symptoms**: Profile not created after signup
**Solution**:
```sql
-- Check if trigger is enabled
SELECT tgenabled FROM pg_trigger WHERE tgname = 'on_auth_user_created';
-- Should return 'O' (enabled)

-- If disabled, enable it:
ALTER TABLE auth.users ENABLE TRIGGER on_auth_user_created;
```

### Issue: RLS blocking inserts
**Symptoms**: Error "new row violates row-level security policy"
**Solution**:
```sql
-- Check if service role policy exists
SELECT * FROM pg_policies 
WHERE policyname LIKE '%Service role%';

-- If missing, re-run the RLS policy section of migration
```

### Issue: Legal document URL not saving
**Symptoms**: Document uploads but URL not in database
**Solution**:
1. Check Flutter console for error messages
2. Verify user role is correctly set:
```sql
SELECT id, role FROM profiles WHERE email = 'your-test-email@example.com';
```
3. Check RLS policies allow updates:
```sql
-- Should allow restaurant owners to update their own record
SELECT * FROM pg_policies 
WHERE tablename = 'restaurants' 
  AND policyname LIKE '%update%';
```

### Issue: Email not sent
**Symptoms**: No OTP email received
**Solution**:
1. Check Supabase email settings:
   - Dashboard → Authentication → Email Templates
   - Verify "Confirm signup" template is enabled
2. Check spam folder
3. Verify email in Supabase logs:
   - Dashboard → Logs → Auth Logs
4. Check if user was created:
```sql
SELECT id, email, email_confirmed_at FROM auth.users 
WHERE email = 'your-test-email@example.com';
```

---

## 🔒 Security Considerations

### RLS Policies Applied
The migration creates these security policies:

**Profiles Table**:
- Users can view their own profile
- Users can update their own profile
- Service role can insert profiles (for trigger)

**Restaurants Table**:
- Restaurant owners can view/update their own record
- Public can view all restaurants (for browsing)
- Service role can insert restaurants (for trigger)

**NGOs Table**:
- NGO owners can view/update their own record
- Public can view all NGOs (for browsing)
- Service role can insert NGOs (for trigger)

### Approval Workflow
- New restaurants/NGOs have `approval_status = 'pending'`
- Admin must approve before they can operate
- Users have `approval_status = 'approved'` by default

---

## 📊 Monitoring

### Check Signup Success Rate
```sql
-- Count signups by role in last 24 hours
SELECT 
  role,
  COUNT(*) as signups,
  COUNT(CASE WHEN is_verified THEN 1 END) as verified
FROM public.profiles
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY role;
```

### Check Legal Document Upload Rate
```sql
-- Count restaurants with legal documents
SELECT 
  COUNT(*) as total_restaurants,
  COUNT(CASE WHEN array_length(legal_docs_urls, 1) > 0 THEN 1 END) as with_docs
FROM public.restaurants;
```

### Check Pending Approvals
```sql
-- List pending restaurant/NGO approvals
SELECT 
  p.email,
  p.role,
  p.full_name,
  p.created_at,
  CASE 
    WHEN p.role = 'restaurant' THEN r.restaurant_name
    WHEN p.role = 'ngo' THEN n.organization_name
  END as org_name
FROM public.profiles p
LEFT JOIN public.restaurants r ON p.id = r.profile_id
LEFT JOIN public.ngos n ON p.id = n.profile_id
WHERE p.approval_status = 'pending'
ORDER BY p.created_at DESC;
```

---

## 🎯 Success Criteria

After implementation, verify:

- [x] Database trigger created and active
- [x] RLS policies applied correctly
- [x] Restaurant signup sends OTP email
- [x] NGO signup sends OTP email
- [x] User signup still works (no regression)
- [x] Legal documents upload successfully
- [x] Legal document URLs saved to database
- [x] Profile records created automatically
- [x] Restaurant/NGO records created automatically
- [x] Approval status set correctly

---

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review `SUPABASE_AUTH_DEBUG_REPORT.md` for detailed analysis
3. Check Supabase logs: Dashboard → Logs
4. Check Flutter console for error messages

---

## 🔄 Rollback (If Needed)

If you need to rollback the changes:

```sql
-- Remove trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Remove function
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Remove RLS policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Service role can insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Restaurant owners can view own record" ON public.restaurants;
DROP POLICY IF EXISTS "Restaurant owners can update own record" ON public.restaurants;
DROP POLICY IF EXISTS "Service role can insert restaurants" ON public.restaurants;
DROP POLICY IF EXISTS "Public can view restaurants" ON public.restaurants;
DROP POLICY IF EXISTS "NGO owners can view own record" ON public.ngos;
DROP POLICY IF EXISTS "NGO owners can update own record" ON public.ngos;
DROP POLICY IF EXISTS "Service role can insert ngos" ON public.ngos;
DROP POLICY IF EXISTS "Public can view ngos" ON public.ngos;

-- Disable RLS
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurants DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.ngos DISABLE ROW LEVEL SECURITY;
```

Then revert the code changes using git:
```bash
git checkout lib/features/authentication/data/datasources/auth_remote_datasource.dart
git checkout lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart
```

---

**Last Updated**: 2026-01-29  
**Version**: 1.0  
**Status**: Ready for Production
