# NGO Home Screen - Complete Debug Guide

## Current Issue
NGO home screen shows infinite loading spinner with no meals displayed.

## Comprehensive Logging Added

### What to Check in Console

When you open the NGO home screen, you should see this sequence of logs:

```
🔍 ========== NGO HOME: loadData START ==========
hasListeners: true
forceRefresh: false
meals.length: 0
_isDataStale: true
✅ NGO: Starting data load...
📊 NGO: Calling Future.wait for stats and meals...

📊 NGO: _loadStats START
User ID: [your-ngo-user-id]
🔍 NGO: Fetching active orders...
✅ NGO: Active orders: X
🔍 NGO: Fetching completed orders...
✅ NGO: Meals claimed: X
✅ NGO: Carbon saved: X kg
✅ NGO: _loadStats COMPLETE

🔍 ========== NGO: _loadMeals START ==========
📊 Step 1: Fetching meals from database...
✅ Step 1: Got X meals from database
📊 Step 2: Extracting restaurant IDs...
✅ Step 2: Found X unique restaurants
Restaurant IDs: [list of IDs]
📊 Step 3: Fetching restaurants from database...
✅ Step 3: Got X restaurants from database
📊 Step 4: Creating restaurant lookup map...
  - [restaurant-id]: [restaurant-name]
✅ Step 4: Restaurant map created with X entries
📊 Step 5: Transforming meals with restaurant data...
✅ Step 5: Transformed X meals successfully
📊 Step 6: Filtering expiring meals...
✅ Step 6: Found X expiring meals
🎉 ========== NGO: _loadMeals END (success) ==========

✅ NGO: Data load complete
✅ NGO: Notifying listeners
🎉 ========== NGO HOME: loadData END ==========
```

## Debugging Steps

### Step 1: Check if loadData is Called
Look for:
```
🔍 ========== NGO HOME: loadData START ==========
```

**If NOT present**: The viewmodel is not being initialized properly.
- Check if Provider is set up correctly in the widget tree
- Check if `loadIfNeeded()` is being called in `initState`

### Step 2: Check hasListeners
Look for:
```
hasListeners: true
```

**If false**: The widget is not listening to the viewmodel.
- Check if you're using `Consumer<NgoHomeViewModel>` or `context.watch<NgoHomeViewModel>()`
- Make sure the Provider is above the widget in the tree

### Step 3: Check User Authentication
Look for:
```
User ID: [some-uuid]
```

**If null**: User is not authenticated.
- Check if user is logged in
- Check if auth state is properly maintained
- Try logging out and back in

### Step 4: Check Meals Query
Look for:
```
✅ Step 1: Got X meals from database
```

**If 0 meals**: No meals match the criteria.
Possible reasons:
- No meals with `is_donation_available = true`
- No meals with `status = 'active'`
- No meals with `quantity_available > 0`
- All meals are expired (`expiry_date < now`)

**If error**: RLS policy issue or query syntax error.
- Check the error message
- Verify RLS policies allow NGO to read meals

### Step 5: Check Restaurant Query
Look for:
```
✅ Step 3: Got X restaurants from database
```

**If 0 restaurants**: Restaurant IDs don't match any restaurants.
- Check if `restaurant_id` in meals table matches `profile_id` in restaurants table
- Check RLS policies on restaurants table

**If error**: RLS policy issue.
- NGO might not have permission to read restaurants table
- Apply the RLS fix migrations

### Step 6: Check for Warnings
Look for:
```
⚠️ Warning: No restaurant data for meal [meal-id]
```

This means a meal has a `restaurant_id` that doesn't exist in the restaurants table.
- Data integrity issue
- Restaurant was deleted but meals remain

### Step 7: Check Final Result
Look for:
```
✅ Step 5: Transformed X meals successfully
```

**If 0 meals after transformation**: All meals were filtered out or transformation failed.

## Common Issues and Solutions

### Issue 1: No Logs Appear
**Problem**: Console shows nothing when opening NGO home.

**Solutions**:
1. Make sure you're running in debug mode
2. Check if `print()` statements are being captured
3. Try using `flutter run` from terminal instead of IDE
4. Check if logs are being filtered in your IDE

### Issue 2: "No meals available (empty result)"
**Problem**: Query returns 0 meals.

**Solutions**:
1. Check database - are there any meals with:
   ```sql
   SELECT * FROM meals 
   WHERE is_donation_available = true 
   AND status = 'active' 
   AND quantity_available > 0 
   AND expiry_date > NOW();
   ```

2. If no meals exist, create test data:
   ```sql
   INSERT INTO meals (
     restaurant_id, title, description, category,
     original_price, discounted_price, quantity_available,
     expiry_date, is_donation_available, status
   ) VALUES (
     '[restaurant-id]', 'Test Meal', 'Test Description', 'Meals',
     100, 50, 10,
     NOW() + INTERVAL '2 days', true, 'active'
   );
   ```

### Issue 3: RLS Policy Error
**Problem**: Error message contains "permission denied" or "policy".

**Solutions**:
1. Apply RLS fix migrations:
   ```bash
   psql -f supabase/migrations/20260212_continue_rls_cleanup.sql
   psql -f supabase/migrations/20260212_final_rls_verification.sql
   ```

2. Check if NGO can read meals:
   ```sql
   -- Run as NGO user
   SELECT * FROM meals LIMIT 1;
   ```

3. Check RLS policies:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'meals';
   ```

### Issue 4: Restaurant Data Missing
**Problem**: Meals load but show "Unknown Restaurant".

**Solutions**:
1. Check if restaurants exist:
   ```sql
   SELECT profile_id, restaurant_name FROM restaurants;
   ```

2. Check if `restaurant_id` in meals matches `profile_id` in restaurants:
   ```sql
   SELECT m.id, m.title, m.restaurant_id, r.restaurant_name
   FROM meals m
   LEFT JOIN restaurants r ON r.profile_id = m.restaurant_id
   WHERE m.is_donation_available = true;
   ```

3. Fix orphaned meals:
   ```sql
   -- Find meals without restaurants
   SELECT m.* FROM meals m
   LEFT JOIN restaurants r ON r.profile_id = m.restaurant_id
   WHERE r.profile_id IS NULL;
   ```

### Issue 5: Infinite Loading
**Problem**: Loading spinner never stops.

**Solutions**:
1. Check if `isLoading` is being set to false:
   - Look for `✅ NGO: Notifying listeners` in logs
   - If missing, there's an exception being swallowed

2. Check if error is being caught:
   - Look for `❌ NGO: Error` in logs
   - Check the error message and stack trace

3. Add breakpoint in `finally` block to ensure it executes

## Testing Checklist

Run through these tests:

### Test 1: Fresh Load
1. Clear app data / reinstall
2. Log in as NGO
3. Navigate to home
4. Check logs for complete sequence
5. Verify meals appear

### Test 2: Pull to Refresh
1. Pull down on home screen
2. Check logs show `forceRefresh: true`
3. Verify data reloads

### Test 3: Search and Filter
1. Type in search box
2. Verify filtered meals update
3. Click filter chips
4. Verify meals filter correctly

### Test 4: No Data Scenario
1. Delete all meals from database
2. Open NGO home
3. Should show "No surplus meals available"
4. Logs should show "No meals available (empty result)"

### Test 5: Error Scenario
1. Disable network
2. Open NGO home
3. Should show error message
4. Logs should show error details

## Performance Metrics

Expected timings:
- Stats load: 100-300ms
- Meals load: 200-500ms
- Total load: 300-800ms

If slower:
- Check network latency
- Check database performance
- Check if indexes exist on:
  - `meals(is_donation_available, status, quantity_available, expiry_date)`
  - `restaurants(profile_id)`

## SQL Queries to Run

### Check Meal Availability
```sql
SELECT 
  COUNT(*) as total_meals,
  COUNT(*) FILTER (WHERE is_donation_available = true) as donation_available,
  COUNT(*) FILTER (WHERE status = 'active') as active,
  COUNT(*) FILTER (WHERE quantity_available > 0) as has_quantity,
  COUNT(*) FILTER (WHERE expiry_date > NOW()) as not_expired
FROM meals;
```

### Check Restaurant Data
```sql
SELECT 
  COUNT(*) as total_restaurants,
  COUNT(*) FILTER (WHERE profile_id IS NOT NULL) as with_profile_id
FROM restaurants;
```

### Check Meal-Restaurant Links
```sql
SELECT 
  COUNT(*) as total_meals,
  COUNT(r.profile_id) as with_restaurant
FROM meals m
LEFT JOIN restaurants r ON r.profile_id = m.restaurant_id
WHERE m.is_donation_available = true;
```

### Check RLS Policies
```sql
SELECT 
  tablename,
  policyname,
  cmd,
  qual as using_clause
FROM pg_policies
WHERE tablename IN ('meals', 'restaurants')
ORDER BY tablename, cmd;
```

## Next Steps

1. **Run the app** and check console logs
2. **Copy the logs** and analyze them against this guide
3. **Identify which step fails** using the log sequence
4. **Apply the solution** for that specific issue
5. **Test again** to verify the fix

## Contact Points

If issue persists after following this guide:
1. Share the complete console logs
2. Share the SQL query results
3. Share any error messages
4. Describe what you see vs what you expect
