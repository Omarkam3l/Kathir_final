# Restaurant Leaderboard - Deployment Checklist

## Pre-Deployment Checklist

### ✅ Database Setup

- [ ] **Run Migration**
  ```bash
  psql -h your-supabase-host -U postgres -d postgres -f migrations/restaurant-leaderboard-schema.sql
  ```

- [ ] **Verify RPC Functions Exist**
  ```sql
  SELECT routine_name FROM information_schema.routines 
  WHERE routine_schema = 'public' 
  AND routine_name IN ('get_restaurant_leaderboard', 'get_my_restaurant_rank');
  ```
  Expected: 2 rows returned

- [ ] **Verify Indexes Created**
  ```sql
  SELECT indexname FROM pg_indexes 
  WHERE schemaname = 'public' 
  AND indexname LIKE 'idx_orders%' OR indexname LIKE 'idx_profiles%';
  ```
  Expected: 4 indexes

- [ ] **Test RPC Functions**
  ```sql
  -- Test leaderboard (should return data or empty array)
  SELECT * FROM get_restaurant_leaderboard('week');
  
  -- Test my rank (should return data or NULL)
  SELECT * FROM get_my_restaurant_rank('week');
  ```

- [ ] **Grant Permissions**
  ```sql
  GRANT EXECUTE ON FUNCTION get_restaurant_leaderboard(text) TO authenticated;
  GRANT EXECUTE ON FUNCTION get_restaurant_leaderboard(text) TO anon;
  GRANT EXECUTE ON FUNCTION get_my_restaurant_rank(text) TO authenticated;
  ```

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
  - Navigate to `/restaurant-dashboard/leaderboard`
  - Should load without errors

### ✅ Code Review

- [ ] **All Files Created**
  - `migrations/restaurant-leaderboard-schema.sql`
  - `lib/features/restaurant_dashboard/domain/entities/leaderboard_entry.dart`
  - `lib/features/restaurant_dashboard/data/services/leaderboard_service.dart`
  - `lib/features/restaurant_dashboard/presentation/screens/restaurant_leaderboard_screen.dart`
  - `lib/features/restaurant_dashboard/presentation/widgets/my_rank_card.dart`

- [ ] **All Files Updated**
  - `lib/features/_shared/router/app_router.dart` (route added)
  - `lib/features/restaurant_dashboard/presentation/widgets/restaurant_bottom_nav.dart` (5 items)
  - All restaurant screens (navigation updated)

- [ ] **No TODOs or Placeholders**
  - No `PUT_RESTAURANT_ID_HERE`
  - No `TODO` comments
  - All functionality implemented

- [ ] **Proper Auth Integration**
  - Uses `auth.uid()` for current restaurant
  - Handles null auth state
  - No hardcoded IDs

### ✅ Testing

#### Database Testing

- [ ] **Test Weekly Leaderboard**
  ```sql
  SELECT * FROM get_restaurant_leaderboard('week');
  ```

- [ ] **Test Monthly Leaderboard**
  ```sql
  SELECT * FROM get_restaurant_leaderboard('month');
  ```

- [ ] **Test All-Time Leaderboard**
  ```sql
  SELECT * FROM get_restaurant_leaderboard('all');
  ```

- [ ] **Test My Rank**
  ```sql
  SELECT * FROM get_my_restaurant_rank('week');
  ```

- [ ] **Verify Data Accuracy**
  - Ranks are sequential (1, 2, 3, ...)
  - Scores are correct (sum of order_items.quantity)
  - Only approved restaurants included
  - Only restaurants with sales > 0 included

#### Flutter Testing

- [ ] **Screen Loads**
  - No errors in console
  - Loading state shows briefly
  - Data loads successfully

- [ ] **Period Selection**
  - "This Week" chip works
  - "This Month" chip works
  - "All Time" chip works
  - Data updates when period changes

- [ ] **Pull to Refresh**
  - Swipe down gesture works
  - Loading indicator shows
  - Data refreshes

- [ ] **Podium Display**
  - Top 3 restaurants shown
  - Rank 1 in center with crown
  - Rank 2 on left
  - Rank 3 on right
  - Correct borders (gold/silver/bronze)
  - "HERO" badge on rank 1

- [ ] **List Display**
  - Rank 4+ shown in list
  - Correct rank numbers
  - Avatars load (or show default)
  - Names and scores correct

- [ ] **Sticky Card**
  - Shows above bottom nav
  - Displays correct rank
  - Displays correct score
  - Shows motivational message if no sales

- [ ] **Bottom Navigation**
  - "Rank" tab added
  - Correct tab highlighted
  - Navigation works to all screens
  - No redirect loops

- [ ] **Loading State**
  - Spinner shows while loading
  - No content flicker

- [ ] **Error State**
  - Shows error message on failure
  - Retry button works

- [ ] **Empty State**
  - Shows when no data
  - Motivational message displayed

- [ ] **Dark Mode**
  - All colors correct
  - Text readable
  - Proper contrast

#### Performance Testing

- [ ] **Query Performance**
  - Leaderboard query < 100ms
  - My rank query < 50ms
  - Check Supabase Dashboard → Performance

- [ ] **Screen Load Time**
  - Initial load < 1 second
  - Subsequent loads < 500ms (cached)

- [ ] **Memory Usage**
  - No memory leaks
  - Check Flutter DevTools → Memory

- [ ] **Cache Works**
  - First load hits API
  - Second load uses cache
  - Cache expires after 5 minutes
  - Force refresh bypasses cache

### ✅ User Experience

- [ ] **Restaurant with Sales**
  - Can see leaderboard
  - Can see their rank
  - Rank card shows correct data

- [ ] **Restaurant without Sales**
  - Can see leaderboard
  - Rank card shows "Start selling" message
  - Not shown in leaderboard list

- [ ] **New Restaurant**
  - Can access screen
  - Sees empty state or other restaurants
  - Understands how to get ranked

### ✅ Security

- [ ] **RLS Bypass Safe**
  - Only public data exposed
  - Only approved restaurants shown
  - No sensitive data leaked

- [ ] **Auth Required**
  - Unauthenticated users handled
  - Auth errors handled gracefully

- [ ] **No SQL Injection**
  - All queries use parameterized inputs
  - RPC functions safe

### ✅ Documentation

- [ ] **Implementation Guide Complete**
  - `docs/RESTAURANT_LEADERBOARD_IMPLEMENTATION.md`

- [ ] **Quick Start Guide Complete**
  - `docs/LEADERBOARD_QUICK_START.md`

- [ ] **Architecture Diagram Complete**
  - `docs/LEADERBOARD_ARCHITECTURE_DIAGRAM.md`

- [ ] **UI Reference Complete**
  - `docs/LEADERBOARD_UI_REFERENCE.md`

- [ ] **Summary Complete**
  - `LEADERBOARD_FEATURE_SUMMARY.md`

### ✅ Edge Cases

- [ ] **No Orders in Database**
  - Empty state shows
  - No errors

- [ ] **Only 1 Restaurant**
  - Shows in podium
  - No errors

- [ ] **Only 2 Restaurants**
  - Shows in podium
  - Rank 3 position empty (handled)

- [ ] **1000+ Restaurants**
  - Query still fast (< 100ms)
  - UI handles long list

- [ ] **Restaurant Deleted**
  - Removed from leaderboard
  - No broken references

- [ ] **Order Status Changed**
  - Leaderboard updates (after cache expires)
  - Rank changes reflected

### ✅ Cross-Platform

- [ ] **Android**
  - Screen renders correctly
  - Navigation works
  - Pull-to-refresh works

- [ ] **iOS**
  - Screen renders correctly
  - Navigation works
  - Pull-to-refresh works

- [ ] **Web** (if applicable)
  - Screen renders correctly
  - Navigation works
  - Responsive layout

## Deployment Steps

### Step 1: Database Migration
```bash
# Production database
psql -h production-supabase-host -U postgres -d postgres -f migrations/restaurant-leaderboard-schema.sql
```

### Step 2: Verify Migration
```sql
-- Check functions
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_restaurant_leaderboard', 'get_my_restaurant_rank');

-- Check indexes
SELECT indexname FROM pg_indexes 
WHERE schemaname = 'public' 
AND (indexname LIKE 'idx_orders%' OR indexname LIKE 'idx_profiles%');

-- Test functions
SELECT * FROM get_restaurant_leaderboard('week');
SELECT * FROM get_my_restaurant_rank('week');
```

### Step 3: Build Flutter App
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web (if applicable)
flutter build web --release
```

### Step 4: Deploy App
- Upload to Google Play Store (Android)
- Upload to App Store (iOS)
- Deploy to hosting (Web)

### Step 5: Monitor
- Check Supabase logs for errors
- Check app analytics for crashes
- Monitor user feedback

## Post-Deployment Checklist

### ✅ Monitoring

- [ ] **Database Performance**
  - Query times acceptable
  - No slow queries
  - Indexes being used

- [ ] **App Performance**
  - No crashes reported
  - Screen loads fast
  - No memory leaks

- [ ] **User Feedback**
  - Users can access leaderboard
  - No confusion about features
  - Positive feedback

### ✅ Maintenance

- [ ] **Cache Duration**
  - 5 minutes appropriate?
  - Adjust if needed

- [ ] **Data Accuracy**
  - Ranks correct
  - Scores accurate
  - No duplicate entries

- [ ] **Future Enhancements**
  - Pagination needed?
  - Filters requested?
  - Real-time updates wanted?

## Rollback Plan

If issues occur:

### Step 1: Identify Issue
- Check Supabase logs
- Check app crash reports
- Check user feedback

### Step 2: Quick Fix
- If minor: Deploy hotfix
- If major: Proceed to rollback

### Step 3: Rollback Database
```sql
-- Drop RPC functions
DROP FUNCTION IF EXISTS get_restaurant_leaderboard(text);
DROP FUNCTION IF EXISTS get_my_restaurant_rank(text);

-- Drop indexes (optional, won't hurt to keep)
DROP INDEX IF EXISTS idx_orders_created_at;
DROP INDEX IF EXISTS idx_orders_restaurant_status;
DROP INDEX IF EXISTS idx_order_items_order_id;
DROP INDEX IF EXISTS idx_profiles_approval_role;
```

### Step 4: Rollback App
- Revert to previous version
- Remove leaderboard route
- Restore old bottom nav (4 items)

### Step 5: Communicate
- Notify users of issue
- Provide timeline for fix
- Apologize for inconvenience

## Success Criteria

✅ **Feature is successful if:**
- [ ] 90%+ of restaurants can access leaderboard
- [ ] Query times < 100ms
- [ ] No crashes related to leaderboard
- [ ] Positive user feedback
- [ ] Increased engagement (restaurants checking rank)

## Support

For issues:
1. Check troubleshooting in `docs/LEADERBOARD_QUICK_START.md`
2. Review implementation in `docs/RESTAURANT_LEADERBOARD_IMPLEMENTATION.md`
3. Check Supabase logs
4. Check Flutter console
5. Contact development team

---

**Deployment Date**: _____________

**Deployed By**: _____________

**Version**: _____________

**Notes**: _____________________________________________

_______________________________________________________

_______________________________________________________
