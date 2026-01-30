# 🚨 URGENT: RLS Policy Fix Required

## ❌ Current Issue

**Error:** `new row violates row-level security policy for table "meals"`

**Impact:**
- ❌ Cannot view existing meals
- ❌ Cannot add new meals
- ❌ Cannot edit meals
- ❌ Cannot delete meals

---

## ✅ Quick Fix (2 minutes)

### Step 1: Open Supabase
1. Go to your Supabase Dashboard
2. Click on **SQL Editor**

### Step 2: Run SQL Fix
1. Open file: `migrations/fix-meals-rls-policies.sql`
2. Copy ALL contents (Ctrl+A, Ctrl+C)
3. Paste into SQL Editor
4. Click **"Run"** button
5. Wait for ✅ Success message

### Step 3: Test
1. Logout from app
2. Login again
3. Navigate to meals list
4. Meals should now appear
5. Try adding a new meal
6. Should work! ✅

---

## 📋 What This Fixes

The SQL file creates 6 security policies:

1. ✅ Restaurants can **view** their own meals
2. ✅ Restaurants can **add** new meals
3. ✅ Restaurants can **edit** their meals
4. ✅ Restaurants can **delete** their meals
5. ✅ Users can view active meals
6. ✅ NGOs can view available meals

---

## 🔍 Verify Fix Worked

Run this in SQL Editor after deploying:

```sql
SELECT policyname FROM pg_policies WHERE tablename = 'meals';
```

Should return 6 policy names.

---

## 📚 Detailed Guide

See: `Reports/FIX_RLS_POLICY_ERROR.md` for complete troubleshooting guide.

---

**Priority**: 🔴 CRITICAL  
**Time to Fix**: ⏱️ 2 minutes  
**File to Deploy**: `migrations/fix-meals-rls-policies.sql`  

---

## ⚠️ Why This Happened

Supabase has Row-Level Security (RLS) enabled on the `meals` table, but the policies weren't created. Without policies, **no one** can access the table, even though the data exists in the database.

---

**Deploy the SQL file now to fix this issue!** 🚀
