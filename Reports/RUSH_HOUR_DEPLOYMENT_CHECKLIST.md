# Rush Hour Feature - Deployment Checklist

## Pre-Deployment

### ✅ Database Setup

- [ ] **Run Migration**
  ```bash
  psql -h your-supabase-host -U postgres -d postgres -f migrations/rush-hour-feature.sql
  ```

- [ ] **Verify Unique Index Created**
  ```sql
  SELECT indexname FROM pg_indexes 
  WHERE tablename = 'rush_hours' 
  AND indexname = 'idx_rush_hours_one_active_per_restaurant';
  ```
  Expected: 1 row

- [ ] **Verify RPC Functions Created**
  ```sql
  SELECT routine_name FROM information_schema.routines 
  WHERE routine_schema = 'public' 
  AND routine_name IN (
    'set_rush_hour_settings',
    'get_my_rush_hour',
    'get_meals_with_effective_discount',
    'calculate_effective_price'
  );
  ```
  Expected: 4 rows

- [ ] **Verify View Created**
  ```sql
  SELECT table_name FROM information_schema.views 
  WHERE table_schema = 'public' 
  AND table_name = 'meals_with_effective_discount';
  ```
  Expected: 1 row

- [ ] **Test get_my_rush_hour**
  ```sql
  SELECT * FROM get_my_rush_hour();
  ```
  Expected: Returns default config or existing config

- [ ] **Test set_rush_hour_settings (activate)**
  ```sql
  SELECT * FROM set_rush_hour_settings(
    true,
    NOW() + INTERVAL '1 hour',
    NOW() + INTERVAL '3 hours',
    50
  );
  ```
  Expected: Returns activated config

- [ ] **Test set_rush_hour_settings (deactivate)**
  ```sql
  SELECT * FROM set_rush_hour_settings(false, NULL, NULL, 0);
  ```
  Expected: Returns deactivated config

- [ ] **Test get_meals_with_effective_discount**
  ```sql
  SELECT * FROM get_meals_with_effective_discount(NULL, NULL, 10, 0);
  ```
  Expected: Returns meals with effective_price and rush_hour_active_now

- [ ] **Test calculate_effective_price**
  ```sql
  SELECT calculate_effective_price('meal-uuid-here');
  ```
  Expected: Returns numeric price

- [ ] **Test Unique Constraint**
  ```sql
  -- Activate rush hour
  SELECT * FROM set_rush_hour_settings(true, NOW(), NOW() + INTERVAL '2 hours', 50);
  
  -- Try to insert duplicate (should fail)
  INSERT INTO rush_hours (restaurant_id, is_active, start_time, end_time, discount_percentage)
  VALUES (auth.uid(), true, NOW(), NOW() + INTERVAL '2 hours', 50);
  ```
  Expected: Second insert fails with unique constraint error

### ✅ Flutter Setup

- [ ] **Clean Build**
  ```bash
  flutter clean
  flutter pub get
  ```

- [ ] **Check for Errors**
  ```bash
  flutter analyze
  ```
  Expected: No issues found

- [ ] **Run App in Debug Mode**
  ```bash
  flutter run
  ```

- [ ] **Verify Route Works**
  - Navigate to `/restaurant-dashboard/surplus-settings`
  - Should load without errors

### ✅ Code Review

- [ ] **All Files Created**
  - `migrations/rush-hour-feature.sql`
  - `lib/features/restaurant_dashboard/domain/entities/rush_hour_config.dart`
  - `lib/features/restaurant_dashboard/data/services/rush_hour_service.dart`
  - `lib/features/restaurant_dashboard/presentation/screens/restaurant_surplus_settings_screen.dart`
  - `lib/features/restaurant_dashboard/domain/entities/meal_with_effective_discount.dart`
  - `lib/features/restaurant_dashboard/data/services/meals_effective_discount_service.dart`
  - `lib/features/restaurant_dashboard/presentation/widgets/meal_card_with_rush_hour.dart`

- [ ] **Files Updated**
  - `lib/features/_shared/router/app_router.dart` (route added)

- [ ] **No Syntax Errors**
  - All files pass `flutter analyze`
  - No diagnostics found

## Testing

### ✅ Database Tests

- [ ] **Create Rush Hour (Active)**
  ```sql
  SELECT * FROM set_rush_hour_settings(
    true,
    NOW() + INTERVAL '1 hour',
    NOW() + INTERVAL '3 hours',
    50
  );
  ```

- [ ] **Create Rush Hour (Inactive)**
  ```sql
  SELECT * FROM set_rush_hour_settings(false, NULL, NULL, 0);
  ```

- [ ] **Update Rush Hour (Change Times)**
  ```sql
  SELECT * FROM set_rush_hour_settings(
    true,
    NOW() + INTERVAL '2 hours',
    NOW() + INTERVAL '4 hours',
    50
  );
  ```

- [ ] **Update Rush Hour (Change Discount)**
  ```sql
  SELECT * FROM set_rush_hour_settings(
    true,
    NOW() + INTERVAL '1 hour',
    NOW() + INTERVAL '3 hours',
    70
  );
  ```

- [ ] **Try Duplicate Active (Should Fail)**
  ```sql
  -- First activation
  SELECT * FROM set_rush_hour_settings(true, NOW(), NOW() + INTERVAL '2 hours', 50);
  
  -- Try to insert duplicate manually
  INSERT INTO rush_hours (restaurant_id, is_active, start_time, end_time, discount_percentage)
  VALUES (auth.uid(), true, NOW(), NOW() + INTERVAL '2 hours', 50);
  ```
  Expected: Second insert fails

- [ ] **Invalid Time Range (Should Fail)**
  ```sql
  SELECT * FROM set_rush_hour_settings(
    true,
    NOW() + INTERVAL '3 hours',
    NOW() + INTERVAL '1 hour',  -- End before start
    50
  );
  ```
  Expected: Error "End time must be after start time"

- [ ] **Invalid Discount (Should Fail)**
  ```sql
  SELECT * FROM set_rush_hour_settings(
    true,
    NOW() + INTERVAL '1 hour',
    NOW() + INTERVAL '3 hours',
    150  -- > 100
  );
  ```
  Expected: Error "Discount percentage must be between 0 and 100"

- [ ] **Meals Show Effective Discount (Active)**
  ```sql
  -- Activate rush hour
  SELECT * FROM set_rush_hour_settings(true, NOW() - INTERVAL '1 hour', NOW() + INTERVAL '1 hour', 50);
  
  -- Check meals
  SELECT title, original_price, discounted_price, effective_price, rush_hour_active_now
  FROM get_meals_with_effective_discount(auth.uid(), NULL, 10, 0);
  ```
  Expected: rush_hour_active_now = true, effective_price uses rush hour discount

- [ ] **Meals Revert (Inactive)**
  ```sql
  -- Deactivate rush hour
  SELECT * FROM set_rush_hour_settings(false, NULL, NULL, 0);
  
  -- Check meals
  SELECT title, original_price, discounted_price, effective_price, rush_hour_active_now
  FROM get_meals_with_effective_discount(auth.uid(), NULL, 10, 0);
  ```
  Expected: rush_hour_active_now = false, effective_price = discounted_price

### ✅ Flutter Tests

- [ ] **Load Rush Hour Settings**
  - Open Surplus Settings screen
  - Should load current config or defaults
  - No errors in console

- [ ] **Toggle Switch (Activate)**
  - Toggle switch to ON
  - Should enable time pickers and slider

- [ ] **Toggle Switch (Deactivate)**
  - Toggle switch to OFF
  - Should disable time pickers (optional)

- [ ] **Select Start Time**
  - Tap start time field
  - Date picker appears
  - Select date
  - Time picker appears
  - Select time
  - Time displays correctly

- [ ] **Select End Time**
  - Tap end time field
  - Date picker appears
  - Select date
  - Time picker appears
  - Select time
  - Time displays correctly

- [ ] **Adjust Discount Slider**
  - Drag slider
  - Percentage updates
  - Range: 10-80%

- [ ] **Save Settings (Success)**
  - Configure valid settings
  - Tap "Save Settings"
  - Loading indicator shows
  - Success snackbar appears
  - Settings saved

- [ ] **Save Settings (Validation Error)**
  - Set end time before start time
  - Tap "Save Settings"
  - Error snackbar appears
  - Settings not saved

- [ ] **Save Settings (Network Error)**
  - Disconnect network
  - Tap "Save Settings"
  - Error snackbar appears
  - Settings not saved

- [ ] **Show "Active Now" Banner**
  - Activate rush hour with current time in range
  - Banner appears at bottom
  - Shows "Rush Hour Active Now!"

- [ ] **Hide "Active Now" Banner**
  - Deactivate rush hour
  - Banner disappears

- [ ] **Fetch Meals with Effective Discount**
  - Use MealsEffectiveDiscountService
  - Fetch meals
  - Meals have effective_price field
  - Meals have rush_hour_active_now field

- [ ] **Display Effective Price in Meal Card**
  - Use MealCardWithRushHour widget
  - Effective price displays
  - Rush hour badge shows when active

- [ ] **Calculate Effective Price in Checkout**
  - Add meal to cart
  - Go to checkout
  - Price calculated using calculateEffectivePrice
  - Correct price charged

### ✅ Integration Tests

- [ ] **Activate Rush Hour → Meals Show Rush Hour Discount**
  1. Activate rush hour (50% off)
  2. Browse meals
  3. All meals show 50% discount
  4. Rush hour badge visible

- [ ] **Deactivate Rush Hour → Meals Revert**
  1. Deactivate rush hour
  2. Browse meals
  3. Meals show original discount
  4. Rush hour badge hidden

- [ ] **Rush Hour Ends (Time Expires) → Meals Revert**
  1. Activate rush hour (ends in 1 minute)
  2. Wait 1 minute
  3. Refresh meals
  4. Meals show original discount

- [ ] **Rush Hour Starts (Time Arrives) → Meals Show Discount**
  1. Activate rush hour (starts in 1 minute)
  2. Wait 1 minute
  3. Refresh meals
  4. Meals show rush hour discount

- [ ] **Add to Cart During Rush Hour → Checkout Uses Current Price**
  1. Activate rush hour
  2. Add meal to cart (rush hour price)
  3. Deactivate rush hour
  4. Go to checkout
  5. Price recalculated (original price)

## Deployment

### ✅ Production Database

- [ ] **Backup Database**
  ```bash
  pg_dump -h your-supabase-host -U postgres -d postgres > backup.sql
  ```

- [ ] **Run Migration on Production**
  ```bash
  psql -h production-supabase-host -U postgres -d postgres -f migrations/rush-hour-feature.sql
  ```

- [ ] **Verify Production Installation**
  - Run all verification queries from "Database Setup" section
  - Ensure all functions, views, indexes created

### ✅ Flutter App

- [ ] **Build Release**
  ```bash
  # Android
  flutter build apk --release
  
  # iOS
  flutter build ios --release
  ```

- [ ] **Test Release Build**
  - Install release build on device
  - Test all features
  - No crashes

- [ ] **Deploy to Stores**
  - Upload to Google Play (Android)
  - Upload to App Store (iOS)

### ✅ Monitoring

- [ ] **Set Up Monitoring**
  - Supabase Dashboard → Performance
  - Monitor RPC function calls
  - Monitor query performance

- [ ] **Set Up Alerts**
  - Alert on high error rate
  - Alert on slow queries (> 1s)

## Post-Deployment

### ✅ Verification

- [ ] **Test in Production**
  - Login as restaurant
  - Navigate to Surplus Settings
  - Activate rush hour
  - Verify meals show rush hour discount
  - Deactivate rush hour
  - Verify meals revert

- [ ] **Monitor Logs**
  - Check Supabase logs for errors
  - Check app crash reports
  - Check user feedback

- [ ] **Performance Check**
  - Query times < 100ms
  - No slow queries
  - No memory leaks

### ✅ Documentation

- [ ] **Update User Documentation**
  - Add Surplus Settings to user guide
  - Explain rush hour feature
  - Provide screenshots

- [ ] **Update Developer Documentation**
  - Document RPC functions
  - Document data models
  - Document service usage

## Rollback Plan

If issues occur:

### Step 1: Identify Issue
- Check Supabase logs
- Check app crash reports
- Check user feedback

### Step 2: Quick Fix or Rollback

**Quick Fix** (if minor):
- Deploy hotfix
- Test in production

**Rollback** (if major):

1. **Rollback Database**:
   ```sql
   -- Drop RPC functions
   DROP FUNCTION IF EXISTS set_rush_hour_settings(boolean, timestamptz, timestamptz, integer);
   DROP FUNCTION IF EXISTS get_my_rush_hour();
   DROP FUNCTION IF EXISTS get_meals_with_effective_discount(uuid, text, integer, integer);
   DROP FUNCTION IF EXISTS calculate_effective_price(uuid);
   
   -- Drop view
   DROP VIEW IF EXISTS meals_with_effective_discount;
   
   -- Drop indexes (optional)
   DROP INDEX IF EXISTS idx_rush_hours_one_active_per_restaurant;
   DROP INDEX IF EXISTS idx_rush_hours_active_time;
   DROP INDEX IF EXISTS idx_rush_hours_restaurant_id;
   
   -- Drop trigger (optional)
   DROP TRIGGER IF EXISTS trg_update_rush_hour_flag ON rush_hours;
   DROP FUNCTION IF EXISTS update_restaurant_rush_hour_flag();
   
   -- Remove column (optional)
   ALTER TABLE restaurants DROP COLUMN IF EXISTS rush_hour_active;
   ```

2. **Rollback App**:
   - Revert to previous version
   - Remove surplus settings route
   - Deploy to stores

3. **Restore Database** (if needed):
   ```bash
   psql -h your-supabase-host -U postgres -d postgres < backup.sql
   ```

### Step 3: Communicate
- Notify users of issue
- Provide timeline for fix
- Apologize for inconvenience

## Success Criteria

✅ **Feature is successful if:**
- [ ] 90%+ of restaurants can access surplus settings
- [ ] RPC function calls < 100ms
- [ ] No crashes related to rush hour
- [ ] Positive user feedback
- [ ] Increased sales during rush hour
- [ ] No data inconsistencies

---

**Deployment Date**: _____________

**Deployed By**: _____________

**Version**: _____________

**Notes**: _____________________________________________

_______________________________________________________
