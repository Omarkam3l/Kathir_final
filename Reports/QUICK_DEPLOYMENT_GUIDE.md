# ⚡ QUICK DEPLOYMENT GUIDE

## 🎯 The Problem

Your error: `signUpRestaurant failed`

**Root cause**: Database migration not deployed yet.

---

## ✅ The Solution (3 Steps)

### 1️⃣ Open Supabase SQL Editor

- Go to: https://supabase.com/dashboard
- Select your project
- Click: **SQL Editor** (left sidebar)

### 2️⃣ Run the Migration

- Open file: `database-FINAL-AUTH-REBUILD.sql`
- Copy **ALL contents** (Ctrl+A, Ctrl+C)
- Paste into SQL Editor
- Click: **Run** button

### 3️⃣ Verify Success

Look for this output:

```
✅ Trigger on_auth_user_created exists
✅ Function handle_new_user exists
✅ RLS enabled on auth tables
✅ Storage bucket legal-docs exists
Migration completed successfully
```

---

## 🧪 Test Again

After deployment:

1. Try restaurant signup
2. Check logs for:
   ```
   [timestamp] INFO AUTH: signup.result | role=restaurant, userId=..., hasSession=false
   [timestamp] INFO AUTH: otp.requested | email=..., type=signup
   ```
3. Check email for OTP
4. Enter OTP
5. Upload document
6. Should see "Pending Approval" screen

---

## ⚠️ If Email Already Exists

Run this in SQL Editor:

```sql
-- Check if email exists
SELECT id, email FROM auth.users 
WHERE email = 'mohamedelekhnawy324@gmail.com';

-- If exists, delete it (development only!)
DELETE FROM auth.users 
WHERE email = 'mohamedelekhnawy324@gmail.com';
```

Then try signup again.

---

## 🆘 Still Failing?

Share these logs:

1. Complete error from app console
2. Result of this query:
   ```sql
   SELECT column_name, is_nullable, column_default
   FROM information_schema.columns
   WHERE table_name = 'restaurants' 
     AND column_name = 'restaurant_name';
   ```
3. Any errors from migration deployment

---

**Time to fix**: ~5 minutes  
**Difficulty**: Easy (just copy-paste SQL)  
**Impact**: Fixes all signup issues

