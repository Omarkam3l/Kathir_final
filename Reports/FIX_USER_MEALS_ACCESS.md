# 🔧 Fix: User Cannot See Meals on Home Screen

## ❌ Problems Identified

1. **RLS Policy Issue**: Users cannot query meals table
2. **Column Name Mismatch**: Query expects different column names than database has
3. **Join Issue**: Restaurant join not working correctly

## ✅ Solutions Applied

### 1. Fixed Data Source Query ✅

**File**: `lib/features/user_home/data/datasources/home_remote_datasource.dart`

**Problem**: Query was using wrong column names
- Expected: `donation_price`, `quantity`, `expiry`
- Database has: `discounted_price`, `quantity_available`, `expiry_date`

**Solution**: Updated query to:
- Use correct column names from database
- Map them to expected names in the model
- Fix restaurant join syntax
- Add filters for active meals only

**New Query**:
```dart
final res = await client.from('meals').select('''
  id,
  title,
  description,
  category,
  image_url,
  original_price,
  discounted_price,
  quantity_available,
  expiry_date,
  pickup_deadline,
  status,
  restaurant_id,
  restaurants!inner(
    profile_id,
    restaurant_name,
    rating
  )
''').eq('status', 'active')
  .gt('quantity_available', 0)
  .gt('expiry_date', DateTime.now().toIso8601String())
  .order('created_at', ascending: false);
```

### 2. Created RLS Policy Fix SQL ✅

**File**: `migrations/fix-user-meals-access.sql`

**What it does**:
1. Creates RLS policies for users to view active meals
2. Adds missing columns if needed
3. Creates a view for easy meal access
4. Fixes orders table RLS
5. Provides verification queries

**Key Policies**:
- Users can view all active meals (not just their own)
- Anonymous users can browse meals
- Restaurants can manage their own meals
- NGOs can view available meals

---

## 📋 Deployment Steps

### Step 1: Deploy RLS Policies (REQUIRED)

1. Open Supabase Dashboard
2. Navigate to **SQL Editor**
3. Open file: `migrations/fix-user-meals-access.sql`
4. Copy ALL contents
5. Paste into SQL Editor
6. Click **"Run"**
7. Wait for success message

### Step 2: Restart Application

```bash
# Stop the app
# Then run:
flutter run
```

### Step 3: Test

1. Login as regular user (not restaurant)
2. Navigate to home screen
3. Should see meals in grid
4. Click "See All Meals"
5. Should see all active meals
6. Search and filter should work

---

## 🔍 What Was Wrong

### Database Schema vs Code Expectations

| Code Expects | Database Has | Status |
|--------------|--------------|--------|
| `donation_price` | `discounted_price` | ✅ Fixed - mapped |
| `quantity` | `quantity_available` | ✅ Fixed - mapped |
| `expiry` | `expiry_date` | ✅ Fixed - mapped |
| `location` | (missing) | ✅ Fixed - default value |
| `status` | `status` | ✅ Correct |

### Restaurant Join Issue

**Before**:
```sql
restaurant:restaurants(id,name,rating)
```
❌ Wrong syntax, wrong column names

**After**:
```sql
restaurants!inner(
  profile_id,
  restaurant_name,
  rating
)
```
✅ Correct syntax, correct columns

### RLS Policy Issue

**Before**: No policy allowing users to view meals
**After**: Policy allows authenticated users to view active meals

---

## 🧪 Verification Queries

Run these in Supabase SQL Editor to verify:

### Check if meals are visible
```sql
SELECT COUNT(*) as total_active_meals
FROM meals
WHERE status = 'active'
  AND quantity_available > 0;
```

### Check meals with restaurant info
```sql
SELECT 
  m.id,
  m.title,
  m.category,
  m.original_price,
  m.discounted_price,
  m.quantity_available,
  r.restaurant_name
FROM meals m
LEFT JOIN restaurants r ON m.restaurant_id = r.profile_id
WHERE m.status = 'active'
  AND m.quantity_available > 0
LIMIT 5;
```

### Check RLS policies
```sql
SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'meals'
ORDER BY policyname;
```

---

## 🔒 Security Notes

### RLS Policies Created

1. **Restaurants can view their own meals**
   - Allows: SELECT
   - Condition: `restaurant_id = auth.uid()`

2. **Restaurants can insert their own meals**
   - Allows: INSERT
   - Condition: `restaurant_id = auth.uid()`

3. **Restaurants can update their own meals**
   - Allows: UPDATE
   - Condition: `restaurant_id = auth.uid()`

4. **Restaurants can delete their own meals**
   - Allows: DELETE
   - Condition: `restaurant_id = auth.uid()`

5. **Users can view all active meals**
   - Allows: SELECT
   - Condition: User is NOT a restaurant AND meal is active

6. **Anonymous can view active meals**
   - Allows: SELECT
   - Condition: Meal is active and not expired

---

## 📝 Orders Table

The SQL also fixes the orders table RLS:

1. **Users can view their own orders**
2. **Users can insert their own orders**
3. **Restaurants can view orders for their meals**

---

## ⚠️ Important Notes

1. **Deploy SQL first** - The app won't work until RLS policies are deployed
2. **Column mapping** - The code now correctly maps database columns to model fields
3. **Active meals only** - Query filters for active, available, non-expired meals
4. **Restaurant join** - Uses correct syntax and column names

---

## 🎉 Expected Results

After deploying the fixes:

✅ Home screen shows meals in grid  
✅ "See All Meals" works  
✅ Search and filter work  
✅ Meal details load correctly  
✅ Users can browse all active meals  
✅ Restaurants can manage their own meals  
✅ Orders can be created  

---

## 🆘 Troubleshooting

### Still no meals showing?

**Check 1: RLS policies deployed?**
```sql
SELECT COUNT(*) FROM pg_policies WHERE tablename = 'meals';
-- Should return 6 or more
```

**Check 2: Are there active meals?**
```sql
SELECT COUNT(*) FROM meals WHERE status = 'active';
-- Should return > 0
```

**Check 3: Check app logs**
- Look for errors in console
- Check if query is executing
- Verify authentication

**Check 4: Restart app**
```bash
flutter run
```

---

**Status**: ✅ Fixed  
**Priority**: 🔴 CRITICAL  
**Files Modified**: 2  
**SQL to Deploy**: `migrations/fix-user-meals-access.sql`  

---

## 📚 Related Files

- **Data Source**: `lib/features/user_home/data/datasources/home_remote_datasource.dart` ✅ Fixed
- **SQL Fix**: `migrations/fix-user-meals-access.sql` ⏳ Needs deployment
- **Model**: `lib/features/user_home/data/models/meal_model.dart` (no changes needed)

---

**Deploy the SQL file now to fix user meal access!** 🚀
