# ✅ Quick Fix Checklist - Supabase Auth Regression

## 🎯 Problem Summary
- ❌ Restaurant/NGO signups broken
- ❌ OTP emails not sent
- ❌ Legal documents uploaded but URLs not saved

## 🚀 Fix in 3 Steps (5 minutes)

### ☑️ Step 1: Run Database Migration
```
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Copy/paste: database-migrations-001-profile-trigger.sql
4. Click "Run"
5. Verify: "Success. No rows returned"
```

### ☑️ Step 2: Code Already Fixed ✅
These files have been updated:
- ✅ `lib/features/authentication/data/datasources/auth_remote_datasource.dart`
- ✅ `lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart`

No action needed - changes already applied!

### ☑️ Step 3: Test
```bash
flutter run
```

Test signup as:
1. Restaurant → Upload doc → Check email → Verify OTP ✅
2. NGO → Upload doc → Check email → Verify OTP ✅
3. User → Check email → Verify OTP ✅

---

## 🔍 Verify Database Changes

Run in Supabase SQL Editor:

```sql
-- 1. Check trigger exists
SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
-- Expected: 1 row

-- 2. Check function exists
SELECT proname FROM pg_proc WHERE proname = 'handle_new_user';
-- Expected: 1 row

-- 3. Check RLS enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('profiles', 'restaurants', 'ngos');
-- Expected: 3 rows, all with rowsecurity = true
```

---

## 🎯 What Got Fixed

| Issue | Before | After |
|-------|--------|-------|
| Profile creation | ❌ Manual | ✅ Automatic (trigger) |
| Restaurant record | ❌ Never created | ✅ Auto-created |
| NGO record | ❌ Never created | ✅ Auto-created |
| Organization name | ❌ Not passed | ✅ Passed in metadata |
| Legal doc URLs | ❌ Lost after upload | ✅ Saved to database |
| OTP emails | ❌ Not sent | ✅ Sent successfully |

---

## 🐛 Quick Troubleshooting

### Problem: "No rows returned" but no error
✅ **This is SUCCESS!** The migration ran correctly.

### Problem: OTP still not received
1. Check spam folder
2. Verify in Supabase: Dashboard → Authentication → Users
3. Check email template: Dashboard → Authentication → Email Templates

### Problem: Legal doc URL not saving
1. Check Flutter console for errors
2. Verify role in database:
```sql
SELECT id, role FROM profiles WHERE email = 'your-email@test.com';
```

### Problem: "Row violates RLS policy"
Re-run the RLS section of the migration:
```sql
-- Copy lines 95-200 from database-migrations-001-profile-trigger.sql
-- Run in SQL Editor
```

---

## 📋 Success Criteria

After implementation, you should see:

- [x] Trigger exists in database
- [x] RLS policies active
- [x] Restaurant signup → OTP email sent ✅
- [x] NGO signup → OTP email sent ✅
- [x] User signup → OTP email sent ✅
- [x] Legal docs upload → URL in database ✅
- [x] Profile auto-created on signup ✅
- [x] Restaurant/NGO record auto-created ✅

---

## 📚 Full Documentation

For detailed information, see:
- `SUPABASE_AUTH_DEBUG_REPORT.md` - Complete root cause analysis
- `IMPLEMENTATION_GUIDE.md` - Step-by-step implementation
- `database-migrations-001-profile-trigger.sql` - Database migration

---

## 🔄 Rollback (Emergency)

If something goes wrong:

```sql
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
```

Then:
```bash
git checkout lib/features/authentication/data/datasources/auth_remote_datasource.dart
git checkout lib/features/authentication/presentation/viewmodels/auth_viewmodel.dart
```

---

**Status**: ✅ Ready to Deploy  
**Time Required**: 5 minutes  
**Risk Level**: Low (includes rollback)
