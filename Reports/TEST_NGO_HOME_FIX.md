# Test NGO Home Screen Fix

## Step 1: Apply Database Migration

1. Open Supabase Dashboard → SQL Editor
2. Run `Migrations/005_add_ngo_meals_rls_policy.sql`
3. Verify output shows: `✅ Migration 005 applied successfully`

## Step 2: Hot Restart App

**Important:** Do a full restart, not hot reload!

```bash
# Stop the app completely
# Then restart
flutter run
```

## Step 3: Check Console Logs

You should see these messages when navigating to NGO home screen:

```
🏗️ NgoHomeViewModel created
📊 Initial state - isLoading: false, meals: 0
🏠 NGO Home Screen - initState called
🔄 Post-frame callback - loading data...
📊 ViewModel state - isLoading: false, meals: 0
🔄 First load - fetching data...
📊 loadData called - forceRefresh: false, hasListeners: true
🔄 Starting data fetch...
✅ Stats loaded: Orders=X, Claimed=Y, Carbon=Zkg
✅ Loaded 15 meals, 3 expiring soon
✅ Data fetch complete - 15 meals loaded
🔔 Notifying listeners - meals: 15, error: null
```

## Step 4: Verify UI

You should see:
- ✅ Loading spinner appears briefly
- ✅ Stats cards show numbers (or 0)
- ✅ Meals list displays with images
- ✅ "Expiring Soon" section (if applicable)
- ✅ Pull-to-refresh works

## Step 5: Test Claiming

1. Click "Claim" on any meal
2. Should see success message
3. Meal should disappear or quantity decrease
4. Stats should update

## Troubleshooting

### If no data appears:

1. Check console for error messages
2. Verify RLS policy applied:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'meals';
   ```
3. Test direct query as NGO user:
   ```sql
   SELECT COUNT(*) FROM meals 
   WHERE is_donation_available = true 
   AND status = 'active';
   ```

### If error appears:

- Check the error message in the UI
- Click "Retry" button
- Check console logs for details

### If loading never stops:

- Check if `isLoading` is stuck at `true`
- Verify `notifyListeners()` is being called
- Check for exceptions in `_loadMeals()`

## Expected Behavior

**Before Fix:**
- Screen loads instantly
- No data appears
- No loading indicator
- No error message

**After Fix:**
- Loading indicator appears
- Data loads within 1-2 seconds
- Meals display with images
- Stats show correct numbers
- Errors display with retry button

## Success Criteria

- [ ] Console shows all debug messages
- [ ] Loading indicator appears
- [ ] Meals list populates
- [ ] Stats display correctly
- [ ] Pull-to-refresh works
- [ ] Claiming meals works
- [ ] Error handling works (test by disconnecting internet)

---

**If all checks pass, the fix is successful!** ✅
