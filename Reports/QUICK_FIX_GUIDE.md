# Quick Fix Guide - NGO Home Screen

## 🚀 5-Minute Deployment

### Step 1: Apply Database Migration (2 min)

1. Open Supabase Dashboard
2. Go to SQL Editor
3. Copy contents of `Migrations/004_fix_ngo_home_screen_data_loading.sql`
4. Click "Run"
5. Wait for success message

### Step 2: Verify (1 min)

Run this query in SQL Editor:

```sql
-- Should return matching numbers
SELECT 
  (SELECT COUNT(*) FROM profiles WHERE role = 'ngo') as profiles,
  (SELECT COUNT(*) FROM ngos) as records,
  (SELECT COUNT(*) FROM order_items) as order_items;
```

### Step 3: Test (2 min)

1. Login as NGO user
2. Navigate to home screen
3. Verify meals load
4. Try claiming a meal
5. Check success message

## ✅ Success Indicators

You'll see these in console:
```
✅ Loaded 15 meals, 3 expiring soon
✅ Stats loaded: Orders=2, Claimed=5, Carbon=12.5kg
✅ Successfully claimed: [Meal Title]
```

## ❌ If Something Goes Wrong

### Meals Not Loading?
```sql
-- Check if meals exist
SELECT COUNT(*) FROM meals 
WHERE is_donation_available = true 
  AND status = 'active' 
  AND quantity_available > 0;
```

### Stats Showing 0?
```sql
-- Check if NGO record exists
SELECT * FROM ngos WHERE profile_id = '[YOUR_USER_ID]';
```

### Claim Fails?
```sql
-- Check if order_items table exists
SELECT COUNT(*) FROM order_items;
```

## 🔧 What Changed

### Code Changes
- `ngo_home_viewmodel.dart`: Better error handling, null safety, validation

### Database Changes
- Added `created_at`, `updated_at` to `ngos` table
- Created `order_items` table
- Auto-create missing NGO records
- Updated signup trigger

## 📊 Expected Performance

- Load time: < 1 second
- Claim time: < 1 second
- Error rate: Near zero
- User feedback: Clear and helpful

## 🆘 Need Help?

1. Check `docs/ngo_home_screen_fix_guide.md` for detailed info
2. Check `Reports/NGO_HOME_SCREEN_FIX_SUMMARY.md` for quick reference
3. Look at console logs for debug messages
4. Verify migration applied successfully

---

**That's it! Your NGO home screen should now work perfectly.** 🎉
