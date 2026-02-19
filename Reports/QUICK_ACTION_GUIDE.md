# Quick Action Guide - NGO Home Screen Fix

## 🚨 The Problem
Error: `invalid input value for enum order_status: "paid"`

## ✅ The Fix (Already Applied)
Changed code to use correct database enum values.

## 🎯 What You Need to Do Now

### Step 1: Hot Restart (30 seconds)
```bash
# Stop the app completely
# Then restart
flutter run
```

**Important:** Must be a full restart, not hot reload!

### Step 2: Test (1 minute)
1. Login as NGO user
2. Navigate to NGO home screen
3. Check console logs

### Step 3: Verify Success
Look for this in console:
```
✅ Stats loaded: Orders=X, Claimed=Y, Carbon=Zkg
✅ Loaded X meals, Y expiring soon
```

**No more error message!** ✅

## 🎉 Expected Result

### Before Fix:
```
❌ Error loading stats: PostgrestException(message: invalid input value for enum order_status: "paid"
```

### After Fix:
```
✅ Stats loaded: Orders=2, Claimed=5, Carbon=12.5kg
✅ Loaded 15 meals, 3 expiring soon
```

## 📋 What Was Changed

### File 1: `ngo_home_viewmodel.dart`
```dart
// Line ~140
// Changed from: ['pending', 'paid', 'processing', 'ready_for_pickup']
// Changed to:   ['pending', 'confirmed', 'preparing', 'ready_for_pickup']
```

### File 2: `ngo_profile_viewmodel.dart`
```dart
// Line ~79
// Changed from: ['completed', 'paid']
// Changed to:   ['completed', 'delivered']
```

## 🔍 Quick Verification

If you want to double-check the database:

```sql
-- Run in Supabase SQL Editor
SELECT enumlabel 
FROM pg_enum 
WHERE enumtypid = 'order_status'::regtype 
ORDER BY enumsortorder;
```

Should return:
- pending
- confirmed
- preparing
- ready_for_pickup
- out_for_delivery
- delivered
- completed
- cancelled

## 🆘 If Still Not Working

1. **Check console for different error**
2. **Verify you did hot restart (not hot reload)**
3. **Check if RLS policies are applied** (run migration 005)
4. **Check if meals exist in database**

## 📚 Reference Documents

- `FINAL_FIX_SUMMARY.md` - Complete details
- `ORDER_STATUS_REFERENCE.md` - Valid status values
- `TEST_NGO_HOME_FIX.md` - Detailed testing guide

---

## ⚡ TL;DR

1. **Hot restart** the app
2. **Login as NGO**
3. **Check** - no more error!
4. **Done** ✅

**Estimated time: 2 minutes**
