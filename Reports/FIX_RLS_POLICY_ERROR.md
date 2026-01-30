# 🔧 Fix: RLS Policy Error for Meals Table

## ❌ Problem

**Error Message:**
```
PostgrestException(message: new row violates row-level security policy for table "meals", code: 42501)
```

**Symptoms:**
1. Meals don't appear after re-login (even though they're in the database)
2. Cannot add new meals
3. RLS policy violation error

## 🔍 Root Cause

The `meals` table has Row-Level Security (RLS) enabled, but the policies are either:
1. Missing
2. Incorrectly configured
3. Not allowing restaurants to insert/select their own meals

## ✅ Solution

Deploy the RLS policies SQL file to fix this issue.

---

## 📋 Step-by-Step Fix

### Step 1: Deploy RLS Policies (REQUIRED)

1. Open Supabase Dashboard
2. Navigate to **SQL Editor**
3. Open the file: `migrations/fix-meals-rls-policies.sql`
4. Copy all contents
5. Paste into SQL Editor
6. Click **"Run"**
7. Wait for success message

### Step 2: Verify Policies

Run this query in SQL Editor to verify policies are created:

```sql
SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'meals'
ORDER BY policyname;
```

You should see 6 policies:
1. ✅ Restaurants can view their own meals
2. ✅ Restaurants can insert their own meals
3. ✅ Restaurants can update their own meals
4. ✅ Restaurants can delete their own meals
5. ✅ Public can view active meals
6. ✅ NGOs can view available meals

### Step 3: Test in Application

1. Logout and login again as restaurant
2. Navigate to meals list
3. You should now see your meals
4. Try adding a new meal
5. Should work without errors

---

## 🔒 What the Policies Do

### Policy 1: View Own Meals
```sql
Restaurants can view their own meals
- Allows: SELECT
- Condition: restaurant_id = auth.uid()
```

### Policy 2: Insert Own Meals
```sql
Restaurants can insert their own meals
- Allows: INSERT
- Condition: restaurant_id = auth.uid()
```

### Policy 3: Update Own Meals
```sql
Restaurants can update their own meals
- Allows: UPDATE
- Condition: restaurant_id = auth.uid()
```

### Policy 4: Delete Own Meals
```sql
Restaurants can delete their own meals
- Allows: DELETE
- Condition: restaurant_id = auth.uid()
```

### Policy 5: Public View Active Meals
```sql
Public can view active meals
- Allows: SELECT (for users/NGOs)
- Condition: status = 'active' AND quantity > 0 AND not expired
```

### Policy 6: NGOs View Available Meals
```sql
NGOs can view available meals
- Allows: SELECT (for NGOs)
- Condition: user role = 'ngo' AND status = 'active'
```

---

## 🧪 Testing Checklist

After deploying the policies:

- [ ] Login as restaurant user
- [ ] Navigate to meals list
- [ ] Verify existing meals appear
- [ ] Click "Add Meal"
- [ ] Fill form and upload image
- [ ] Submit form
- [ ] Verify meal is added successfully
- [ ] Click meal card to view details
- [ ] Edit meal
- [ ] Delete meal
- [ ] All operations should work without errors

---

## 🔍 Troubleshooting

### Still getting RLS error?

**Check 1: Verify user is authenticated**
```sql
SELECT auth.uid();
-- Should return your user ID, not null
```

**Check 2: Verify restaurant record exists**
```sql
SELECT * FROM restaurants WHERE profile_id = auth.uid();
-- Should return your restaurant record
```

**Check 3: Verify RLS is enabled**
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'meals';
-- rowsecurity should be true
```

**Check 4: Check existing meals**
```sql
SELECT id, title, restaurant_id, created_at 
FROM meals 
WHERE restaurant_id = auth.uid()
ORDER BY created_at DESC;
-- Should return your meals
```

### Meals still not appearing?

**Possible causes:**
1. RLS policies not deployed correctly
2. `restaurant_id` in meals table doesn't match `auth.uid()`
3. User session expired (logout and login again)

**Fix:**
```sql
-- Check if restaurant_id matches
SELECT 
  m.id,
  m.title,
  m.restaurant_id,
  auth.uid() as current_user_id,
  CASE 
    WHEN m.restaurant_id = auth.uid() THEN 'MATCH'
    ELSE 'MISMATCH'
  END as status
FROM meals m
WHERE m.restaurant_id = auth.uid();
```

---

## 📝 Important Notes

1. **RLS policies are required** - Without them, no one can access the meals table
2. **Policies are user-scoped** - Each restaurant can only see/edit their own meals
3. **Public policies** - Allow users and NGOs to view active meals
4. **Security** - RLS ensures data isolation between restaurants

---

## 🚀 After Fix

Once the policies are deployed:

✅ Restaurants can view their own meals  
✅ Restaurants can add new meals  
✅ Restaurants can edit their meals  
✅ Restaurants can delete their meals  
✅ Users can browse active meals  
✅ NGOs can view available meals  
✅ Data is secure and isolated  

---

## 📚 Related Files

- **SQL Fix**: `migrations/fix-meals-rls-policies.sql`
- **Add Meal Screen**: `lib/features/restaurant_dashboard/presentation/screens/add_meal_screen.dart`
- **Meals List Screen**: `lib/features/restaurant_dashboard/presentation/screens/meals_list_screen.dart`

---

**Status**: ⏳ Waiting for SQL deployment  
**Priority**: 🔴 CRITICAL - Must be deployed before testing  
**Impact**: Blocks all meal operations  

---

## ✅ Quick Fix Summary

1. Open Supabase SQL Editor
2. Run `migrations/fix-meals-rls-policies.sql`
3. Logout and login again
4. Test adding a meal
5. Done! ✅
