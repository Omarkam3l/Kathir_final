# 🚨 CRITICAL: 2 SQL Files Must Be Deployed

## ⚠️ Current Issues

1. ❌ Restaurants cannot add/view meals (RLS policy error)
2. ❌ Users cannot see meals on home screen (RLS + query mismatch)

---

## ✅ Quick Fix (5 minutes)

### Step 1: Deploy RLS Policies for Restaurants

**File**: `migrations/fix-meals-rls-policies.sql`

1. Open Supabase Dashboard → SQL Editor
2. Copy ALL contents from `migrations/fix-meals-rls-policies.sql`
3. Paste and click **"Run"**
4. Wait for ✅ Success

**This fixes**:
- ✅ Restaurants can view their meals
- ✅ Restaurants can add new meals
- ✅ Restaurants can edit meals
- ✅ Restaurants can delete meals

---

### Step 2: Deploy User Access Policies

**File**: `migrations/fix-user-meals-access.sql`

1. In same SQL Editor
2. Copy ALL contents from `migrations/fix-user-meals-access.sql`
3. Paste and click **"Run"**
4. Wait for ✅ Success

**This fixes**:
- ✅ Users can see meals on home screen
- ✅ "See All Meals" works
- ✅ Search and filter work
- ✅ Orders can be created

---

### Step 3: Restart App

```bash
flutter run
```

---

## 🧪 Test Checklist

### As Restaurant User:
- [ ] Login as restaurant
- [ ] Navigate to meals list
- [ ] See existing meals
- [ ] Click "Add Meal"
- [ ] Fill form and submit
- [ ] Meal appears in list ✅

### As Regular User:
- [ ] Login as user
- [ ] Navigate to home screen
- [ ] See meals in grid
- [ ] Click "See All Meals"
- [ ] Search for meals
- [ ] Filter meals
- [ ] Click meal to view details ✅

---

## 📋 What Each SQL File Does

### File 1: `fix-meals-rls-policies.sql`
Creates 6 policies:
1. Restaurants can SELECT their meals
2. Restaurants can INSERT their meals
3. Restaurants can UPDATE their meals
4. Restaurants can DELETE their meals
5. Public can view active meals
6. NGOs can view available meals

### File 2: `fix-user-meals-access.sql`
- Updates RLS policies for users
- Adds missing columns if needed
- Creates view for easy access
- Fixes orders table RLS
- Provides verification queries

---

## ⚠️ IMPORTANT

**Both SQL files MUST be deployed before the app will work properly!**

Without these:
- ❌ Restaurants cannot manage meals
- ❌ Users cannot see any meals
- ❌ Orders cannot be created
- ❌ App is essentially broken

---

## 🔍 Verify Deployment

Run this in SQL Editor after deploying both files:

```sql
-- Should return 6+ policies
SELECT COUNT(*) FROM pg_policies WHERE tablename = 'meals';

-- Should show active meals
SELECT COUNT(*) FROM meals WHERE status = 'active';

-- Should show restaurant info
SELECT 
  m.title,
  r.restaurant_name
FROM meals m
LEFT JOIN restaurants r ON m.restaurant_id = r.profile_id
LIMIT 3;
```

---

## 📚 Detailed Documentation

- **Restaurant Issues**: `Reports/FIX_RLS_POLICY_ERROR.md`
- **User Access Issues**: `Reports/FIX_USER_MEALS_ACCESS.md`
- **Category Fix**: `Reports/FIX_CATEGORY_CONSTRAINT.md`

---

**Priority**: 🔴 CRITICAL  
**Time to Fix**: ⏱️ 5 minutes  
**Impact**: Blocks all meal functionality  

---

## ✅ After Deployment

Everything will work:
- ✅ Restaurants can manage meals
- ✅ Users can browse meals
- ✅ Search and filter work
- ✅ Orders can be placed
- ✅ Complete CRUD operations
- ✅ Secure data access

---

**Deploy both SQL files now!** 🚀
