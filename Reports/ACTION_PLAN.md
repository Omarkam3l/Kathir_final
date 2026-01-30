# 🚨 ACTION PLAN: Fix Restaurant Signup Error

## Current Status

**Error**: `signUpRestaurant failed`  
**Root Cause**: Database migration NOT deployed yet  
**Solution**: Deploy `database-FINAL-AUTH-REBUILD.sql`

---

## ⚠️ CRITICAL: You Must Deploy the Database Migration

The code changes are complete and working, but the **database is not updated yet**.

### Why It's Failing

1. ❌ `restaurant_name` column still has `NOT NULL` constraint
2. ❌ Old trigger function (if exists) doesn't handle empty strings properly
3. ❌ RLS policies may be missing or incorrect
4. ❌ Storage policies may be blocking uploads

### What the Migration Does

✅ Makes `restaurant_name` and `organization_name` nullable with defaults  
✅ Creates robust trigger that NEVER fails signup  
✅ Adds comprehensive RLS policies for profiles, restaurants, ngos  
✅ Creates storage bucket with secure policies  
✅ Backfills existing users  
✅ Adds performance indexes  

---

## 📋 STEP-BY-STEP DEPLOYMENT

### Step 1: Open Supabase Dashboard

1. Go to https://supabase.com/dashboard
2. Select your project
3. Click **SQL Editor** in left sidebar

### Step 2: Deploy the Migration

1. Open the file `database-FINAL-AUTH-REBUILD.sql` in your code editor
2. **Copy the ENTIRE contents** (all ~600 lines)
3. Paste into Supabase SQL Editor
4. Click **Run** button (bottom right)

### Step 3: Verify Success

You should see output like:

```
✅ Trigger on_auth_user_created exists
✅ Function handle_new_user exists
✅ RLS enabled on auth tables
✅ Storage bucket legal-docs exists
Migration completed successfully
```

**If you see errors**: Share them immediately and I'll help fix.

### Step 4: Test Signup Again

1. Try restaurant signup with the same email
2. Check the logs for detailed error information
3. Look for these log lines:

```
[...] INFO AUTH: signUpRestaurant.metadata | email=..., fullName=..., orgName=..., role=restaurant
[...] INFO AUTH: signup.result | role=restaurant, email=..., userId=..., hasSession=false
[...] INFO AUTH: otp.requested | email=..., type=signup
```

**Expected behavior after migration**:
- ✅ Signup succeeds (no 500 error)
- ✅ OTP email arrives
- ✅ Profile + restaurant records created
- ✅ No RLS violations

---

## 🔍 Diagnostic Queries (Run BEFORE Migration)

To understand current state, run these in Supabase SQL Editor:

### Check if trigger exists
```sql
SELECT tgname, tgenabled 
FROM pg_trigger 
WHERE tgname = 'on_auth_user_created';
```

### Check restaurant_name constraint
```sql
SELECT 
  column_name,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'restaurants'
  AND column_name = 'restaurant_name';
```

**Expected BEFORE migration**: `is_nullable = 'NO'` (this is the problem!)  
**Expected AFTER migration**: `is_nullable = 'YES'` with default value

### Check if user already exists
```sql
SELECT id, email, created_at, email_confirmed_at
FROM auth.users 
WHERE email = 'mohamedelekhnawy324@gmail.com';
```

**If returns a row**: Email already registered. You need to either:
- Use a different email for testing, OR
- Delete the existing user (see below)

### Delete existing test user (ONLY if needed)
```sql
-- ⚠️ CAREFUL: Only run in development!
DELETE FROM auth.users 
WHERE email = 'mohamedelekhnawy324@gmail.com';
```

---

## 🎯 What Happens After Migration

### 1. Signup Flow (Restaurant/NGO)

```
User clicks "Sign Up" 
  ↓
App calls signUpRestaurant()
  ↓
Supabase creates auth.users record
  ↓
Trigger fires: handle_new_user()
  ↓
Creates profile (CRITICAL - must succeed)
  ↓
Creates restaurant record (NON-CRITICAL - wrapped in exception)
  ↓
Returns success to app
  ↓
App navigates to OTP screen
  ↓
Supabase sends OTP email
  ↓
User enters OTP
  ↓
App uploads pending legal documents (AFTER verification)
  ↓
Saves document URLs to restaurants.legal_docs_urls
  ↓
User sees "Pending Approval" screen
```

### 2. Approval Workflow

```
Restaurant/NGO signup → approval_status = 'pending'
  ↓
Admin reviews in dashboard
  ↓
Admin updates approval_status to 'approved' or 'rejected'
  ↓
Restaurant/NGO can access app features (if approved)
```

### 3. Document Upload Security

- ✅ Upload only when authenticated (after OTP)
- ✅ Path scoped to user ID: `{user_id}/{filename}`
- ✅ 10MB file size limit
- ✅ Only PDF and image files allowed
- ✅ Users can only access their own files

---

## 🐛 Troubleshooting

### Error: "User already registered"

**Cause**: Email exists in database  
**Fix**: Delete user (see diagnostic query above) or use different email

### Error: "Database error saving new user"

**Cause**: Trigger failing (old version or constraint violation)  
**Fix**: Deploy migration (Step 2 above)

### Error: "RLS policy violation"

**Cause**: Missing or incorrect RLS policies  
**Fix**: Deploy migration (includes RLS policies)

### Error: "Email rate limit exceeded"

**Cause**: Too many signup attempts  
**Fix**: Wait 1 hour or use different email

### No OTP Email Arriving

**Possible causes**:
1. Email in spam folder (check spam!)
2. Supabase email rate limit (wait 1 hour)
3. Invalid email address
4. Supabase email service issue (check dashboard)

**Fix**: 
- Check spam folder first
- Try with different email
- Check Supabase Dashboard → Authentication → Email Templates

---

## 📊 Verification Checklist

After deploying migration, verify:

- [ ] Trigger `on_auth_user_created` exists
- [ ] Function `handle_new_user` exists with exception blocks
- [ ] `restaurant_name` is nullable with default
- [ ] `organization_name` is nullable with default
- [ ] RLS enabled on profiles, restaurants, ngos
- [ ] Storage bucket `legal-docs` exists
- [ ] Storage policies allow authenticated uploads
- [ ] Test signup succeeds without 500 error
- [ ] OTP email arrives
- [ ] Profile + restaurant records created
- [ ] Document upload works after OTP verification

---

## 🚀 Next Steps

1. **Deploy migration** (Step 2 above) - THIS IS CRITICAL
2. **Test signup** with same or different email
3. **Share logs** if still failing:
   - Look for `signUpRestaurant.authException` with statusCode and message
   - Share complete error log
4. **Verify database** using diagnostic queries
5. **Test complete flow**: signup → OTP → document upload → approval

---

## 📞 Need Help?

If you encounter any issues:

1. Share the **complete error log** including:
   - `signUpRestaurant.metadata` line
   - `signUpRestaurant.authException` line with statusCode and message
   - Any database errors from Supabase logs

2. Share results of **diagnostic queries** (see above)

3. Share any **migration errors** if deployment fails

---

**Status**: ⏳ Waiting for migration deployment  
**Priority**: 🔴 CRITICAL - Must deploy before testing  
**ETA**: 5 minutes to deploy + test

