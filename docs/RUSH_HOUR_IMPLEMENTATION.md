# Rush Hour Feature - Complete Implementation Guide

## Overview

The Rush Hour feature allows restaurants to set time-based discount periods that override individual meal discounts. When active, ALL meals from that restaurant display and charge the rush hour discount instead of their original discount.

## Key Design Decisions

### 1. Computed Effective Discount (No Bulk Updates)

**Decision**: Calculate effective discount on-the-fly using SQL views/RPCs instead of updating meal rows.

**Why**:
- **Data Consistency**: Avoids stale data and synchronization issues
- **Instant Activation**: Rush hour takes effect immediately without batch updates
- **Preserves Original Data**: Meal discounts remain unchanged
- **Automatic Reversion**: When rush hour ends, meals automatically revert to original discount
- **No Race Conditions**: No conflicts between meal updates and rush hour changes

**How It Works**:
```sql
-- Computed in SQL
CASE 
  WHEN rush_hour_active THEN
    original_price * (1 - rush_hour_discount / 100)
  ELSE
    discounted_price  -- Original meal discount
END AS effective_price
```

### 2. Unique Partial Index (One Active Rush Hour)

**Decision**: Use a unique partial index to enforce one active rush hour per restaurant.

**Why**:
- **Prevents Duplicates**: Database-level constraint prevents multiple active rows
- **Race-Safe**: Handles concurrent updates without application logic
- **Efficient**: Index only includes active rows (small, fast)
- **Allows History**: Multiple inactive rows can exist for history/reactivation

**Implementation**:
```sql
CREATE UNIQUE INDEX idx_rush_hours_one_active_per_restaurant
ON rush_hours (restaurant_id)
WHERE is_active = true;
```

**Edge Case Handling**:
- If two requests try to activate simultaneously, one succeeds, one fails
- RPC function handles this by deactivating existing active row first
- Transaction ensures atomicity

### 3. SECURITY DEFINER for RPC Functions

**Decision**: Use SECURITY DEFINER for set/get rush hour functions.

**Why**:
- **Bypass RLS Safely**: Allows reading/writing across tables without complex RLS
- **Centralized Logic**: All business rules in one place (server-side)
- **Validation**: Server validates all inputs before database changes
- **Audit Trail**: All changes go through controlled functions

**Security Considerations**:
- Functions validate `auth.uid()` matches restaurant
- Only authenticated users can execute
- No sensitive data exposed
- Functions are read-only or owner-only

### 4. TIMESTAMPTZ for Scheduling

**Decision**: Use `timestamptz` (timestamp with timezone) for start/end times.

**Why**:
- **Timezone Aware**: Handles restaurants in different timezones
- **DST Safe**: Automatically adjusts for daylight saving time
- **Future Scheduling**: Can schedule rush hours in advance
- **Accurate Comparisons**: `NOW() BETWEEN start_time AND end_time` works correctly

**Example**:
```sql
-- Restaurant in PST schedules rush hour
start_time: '2024-01-15 21:00:00-08'  -- 9 PM PST
end_time:   '2024-01-15 23:00:00-08'  -- 11 PM PST

-- User in EST sees correct times
-- Database handles conversion automatically
```

### 5. View + RPC for Meals

**Decision**: Provide both a view and RPC function for fetching meals.

**Why**:
- **View**: Simple queries, no parameters needed
- **RPC**: Filtered/paginated queries, better performance
- **Flexibility**: Choose based on use case
- **Consistency**: Both compute effective discount the same way

**When to Use**:
- **View**: Simple "get all meals" queries
- **RPC**: Filtering by restaurant, category, pagination

## Business Rules Implementation

### Rule 1: One Active Rush Hour Per Restaurant

**Enforcement**:
```sql
-- Unique partial index
CREATE UNIQUE INDEX idx_rush_hours_one_active_per_restaurant
ON rush_hours (restaurant_id)
WHERE is_active = true;

-- RPC function deactivates existing before activating new
UPDATE rush_hours SET is_active = false
WHERE restaurant_id = v_restaurant_id AND is_active = true;
```

**Edge Cases**:
- Concurrent activations: First wins, second fails (handled by RPC retry logic)
- Reactivation: Updates existing row instead of creating duplicate
- Deactivation: Sets is_active=false, preserves settings

### Rule 2: Rush Hour Active When is_active=true AND NOW() BETWEEN times

**Implementation**:
```sql
-- Computed in every query
(rh.is_active AND NOW() BETWEEN rh.start_time AND rh.end_time) AS rush_hour_active_now
```

**Edge Cases**:
- Rush hour ends while user browsing: Next page load shows updated prices
- Rush hour starts while user browsing: Next page load shows rush hour prices
- Timezone differences: Handled by timestamptz
- DST transitions: Handled by timestamptz

### Rule 3: When Active, ALL Meals Use Rush Hour Discount

**Implementation**:
```sql
-- Join meals with active rush hours
LEFT JOIN rush_hours rh ON m.restaurant_id = rh.restaurant_id 
  AND rh.is_active = true
  AND NOW() BETWEEN rh.start_time AND rh.end_time

-- Compute effective price
CASE 
  WHEN rh.id IS NOT NULL THEN
    ROUND(m.original_price * (1 - rh.discount_percentage / 100.0), 2)
  ELSE
    m.discounted_price
END AS effective_price
```

**Edge Cases**:
- Meal has 20% discount, rush hour has 50%: Shows 50%
- Meal has 60% discount, rush hour has 30%: Shows 30% (rush hour overrides)
- No rush hour: Shows meal's original discount

### Rule 4: When Inactive, Meals Revert to Original Discount

**Implementation**:
- No action needed! Computed on-the-fly
- When `rush_hour_active_now = false`, effective_price = discounted_price

**Edge Cases**:
- Rush hour deactivated: Immediate reversion (no delay)
- Rush hour time expires: Automatic reversion
- No bulk updates needed

### Rule 5: Prevent Multiple Active Rows

**Implementation**:
- Unique partial index (database level)
- RPC function deactivates existing before activating new (application level)
- Transaction ensures atomicity

**Edge Cases**:
- Race condition: Index prevents duplicate, RPC retries
- Manual database edits: Index prevents invalid state
- Concurrent deactivations: Safe (idempotent)

### Rule 6: RLS Security

**Implementation**:
```sql
-- Restaurants can CRUD their own rush hours
CREATE POLICY "Restaurants can view their own rush hours"
ON rush_hours FOR SELECT
TO authenticated
USING (restaurant_id = auth.uid());

-- Public can view active rush hours (for computing effective discounts)
CREATE POLICY "Public can view active rush hours"
ON rush_hours FOR SELECT
TO authenticated, anon
USING (is_active = true);
```

**Edge Cases**:
- Non-restaurant user: RPC function validates and rejects
- Unauthenticated user: Can view active rush hours (for pricing)
- Restaurant viewing other restaurant's rush hour: Blocked by RLS

## Performance Considerations

### Indexes

```sql
-- One active per restaurant (also enforces uniqueness)
CREATE UNIQUE INDEX idx_rush_hours_one_active_per_restaurant
ON rush_hours (restaurant_id) WHERE is_active = true;

-- Active rush hours lookup
CREATE INDEX idx_rush_hours_active_time
ON rush_hours (restaurant_id, is_active, start_time, end_time)
WHERE is_active = true;

-- Restaurant lookup
CREATE INDEX idx_rush_hours_restaurant_id
ON rush_hours (restaurant_id);
```

### Query Performance

**Meals with Effective Discount**:
- Single query with LEFT JOIN
- Index on `rush_hours.restaurant_id` + `is_active`
- No N+1 queries
- Efficient even with 10,000+ meals

**Benchmark** (estimated):
- 1,000 meals: ~50ms
- 10,000 meals: ~200ms
- 100,000 meals: ~1s (use pagination)

### Caching Strategy

**Client-Side**:
- Don't cache effective prices (they change when rush hour starts/ends)
- Cache meal metadata (title, description, image)
- Refresh prices on each page load

**Server-Side**:
- PostgreSQL query cache handles repeated queries
- Materialized view not recommended (stale data risk)

## Edge Cases & Solutions

### 1. Rush Hour Ends While User in Checkout

**Problem**: User adds meal to cart during rush hour, but rush hour ends before checkout.

**Solution**: Calculate effective price at checkout time, not cart time.

```dart
// In checkout
final effectivePrice = await mealsService.calculateEffectivePrice(mealId);
// Use this price, not cached cart price
```

**Alternative**: Show warning if price changed since cart addition.

### 2. Concurrent Rush Hour Activations

**Problem**: Two admins activate rush hour simultaneously.

**Solution**: 
1. Unique index prevents duplicate active rows
2. RPC function deactivates existing before activating new
3. Transaction ensures atomicity

**Result**: One activation succeeds, other gets error (can retry).

### 3. Invalid Time Range (End Before Start)

**Problem**: User sets end time before start time.

**Solution**:
- Client-side validation (Flutter)
- Server-side validation (RPC function)
- Database constraint (check constraint)

```sql
IF p_is_active AND p_end_time <= p_start_time THEN
  RAISE EXCEPTION 'End time must be after start time';
END IF;
```

### 4. Discount Percentage Out of Range

**Problem**: User sets discount to 150% or -10%.

**Solution**:
- Client-side validation (slider 10-80%)
- Server-side validation (RPC function)
- Database constraint (check constraint)

```sql
discount_percentage integer CHECK (discount_percentage >= 0 AND discount_percentage <= 100)
```

### 5. Restaurant Deleted

**Problem**: Restaurant deleted while rush hour active.

**Solution**: Cascade delete.

```sql
FOREIGN KEY (restaurant_id) REFERENCES restaurants(profile_id) ON DELETE CASCADE
```

### 6. Timezone Confusion

**Problem**: Restaurant in PST, user in EST, server in UTC.

**Solution**: Use `timestamptz` everywhere.

```dart
// Flutter: Always use DateTime (timezone-aware)
final startTime = DateTime(2024, 1, 15, 21, 0); // Local time
// Supabase converts to UTC automatically

// SQL: Always use timestamptz
start_time timestamptz NOT NULL
```

### 7. DST Transition

**Problem**: Rush hour scheduled during DST transition.

**Solution**: `timestamptz` handles DST automatically.

**Example**:
```
Scheduled: 9 PM - 11 PM (PST)
DST starts: 2 AM (clocks jump to 3 AM)
Result: Rush hour still 9 PM - 11 PM (no issue)
```

### 8. Future Scheduling

**Problem**: Restaurant wants to schedule rush hour for next week.

**Solution**: Allow future dates in date picker.

```dart
firstDate: DateTime.now(),
lastDate: DateTime.now().add(const Duration(days: 365)),
```

**Note**: Rush hour won't be active until start_time arrives.

### 9. Multiple Restaurants Same Owner

**Problem**: Owner has multiple restaurants, wants different rush hours.

**Solution**: Each restaurant has separate rush hour (keyed by restaurant_id).

### 10. Rush Hour Never Ends

**Problem**: User sets end time far in future (1 year).

**Solution**: Allow it (business decision).

**Alternative**: Add max duration validation (e.g., 24 hours).

## Testing Checklist

### Database Tests

- [ ] Create rush hour (active)
- [ ] Create rush hour (inactive)
- [ ] Update rush hour (change times)
- [ ] Update rush hour (change discount)
- [ ] Activate rush hour
- [ ] Deactivate rush hour
- [ ] Try to create duplicate active rush hour (should fail)
- [ ] Concurrent activations (one should fail)
- [ ] Invalid time range (should fail)
- [ ] Invalid discount (should fail)
- [ ] Delete restaurant (rush hour should cascade delete)
- [ ] Query meals with effective discount (rush hour active)
- [ ] Query meals with effective discount (rush hour inactive)
- [ ] Calculate effective price (rush hour active)
- [ ] Calculate effective price (rush hour inactive)

### Flutter Tests

- [ ] Load rush hour settings
- [ ] Toggle switch (activate/deactivate)
- [ ] Select start time
- [ ] Select end time
- [ ] Adjust discount slider
- [ ] Save settings (success)
- [ ] Save settings (validation error)
- [ ] Save settings (network error)
- [ ] Show "Active Now" banner when rush hour active
- [ ] Hide "Active Now" banner when rush hour inactive
- [ ] Fetch meals with effective discount
- [ ] Display effective price in meal card
- [ ] Display rush hour badge when active
- [ ] Calculate effective price in checkout

### Integration Tests

- [ ] Activate rush hour → Meals show rush hour discount
- [ ] Deactivate rush hour → Meals revert to original discount
- [ ] Rush hour ends (time expires) → Meals revert automatically
- [ ] Rush hour starts (time arrives) → Meals show rush hour discount
- [ ] Add meal to cart during rush hour → Checkout uses current price
- [ ] Rush hour ends during checkout → Checkout uses current price

## Deployment Steps

### 1. Run Migration

```bash
psql -h your-supabase-host -U postgres -d postgres -f migrations/rush-hour-feature.sql
```

### 2. Verify Installation

```sql
-- Check unique index
SELECT indexname FROM pg_indexes 
WHERE tablename = 'rush_hours' 
AND indexname = 'idx_rush_hours_one_active_per_restaurant';

-- Check RPC functions
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('set_rush_hour_settings', 'get_my_rush_hour', 'get_meals_with_effective_discount', 'calculate_effective_price');

-- Check view
SELECT table_name FROM information_schema.views 
WHERE table_schema = 'public' 
AND table_name = 'meals_with_effective_discount';
```

### 3. Test RPC Functions

```sql
-- Test get_my_rush_hour (as restaurant)
SELECT * FROM get_my_rush_hour();

-- Test set_rush_hour_settings (activate)
SELECT * FROM set_rush_hour_settings(
  true, 
  NOW() + INTERVAL '1 hour', 
  NOW() + INTERVAL '3 hours', 
  50
);

-- Test get_meals_with_effective_discount
SELECT * FROM get_meals_with_effective_discount(NULL, NULL, 10, 0);
```

### 4. Update Flutter App

```bash
flutter clean
flutter pub get
flutter run
```

### 5. Navigate to Surplus Settings

1. Login as restaurant
2. Go to Profile
3. Tap "Surplus Settings" (add button to profile screen)
4. Configure rush hour
5. Save

## Monitoring

### Key Metrics

- **Rush Hour Activations**: Count per day/week
- **Average Discount**: Mean discount percentage
- **Sales During Rush Hour**: Compare to non-rush hour
- **User Engagement**: Meals viewed/purchased during rush hour

### Queries

```sql
-- Active rush hours right now
SELECT r.restaurant_name, rh.discount_percentage, rh.start_time, rh.end_time
FROM rush_hours rh
JOIN restaurants r ON rh.restaurant_id = r.profile_id
WHERE rh.is_active = true
AND NOW() BETWEEN rh.start_time AND rh.end_time;

-- Rush hour usage stats
SELECT 
  COUNT(*) as total_rush_hours,
  AVG(discount_percentage) as avg_discount,
  COUNT(CASE WHEN is_active THEN 1 END) as active_count
FROM rush_hours;

-- Meals affected by rush hour
SELECT COUNT(*) as meals_with_rush_hour
FROM meals m
JOIN rush_hours rh ON m.restaurant_id = rh.restaurant_id
WHERE rh.is_active = true
AND NOW() BETWEEN rh.start_time AND rh.end_time;
```

## Troubleshooting

### Issue: "Duplicate key value violates unique constraint"

**Cause**: Trying to activate rush hour when one already active.

**Solution**: RPC function should handle this. If error persists:
```sql
-- Manually deactivate existing
UPDATE rush_hours SET is_active = false 
WHERE restaurant_id = 'your-restaurant-id' AND is_active = true;
```

### Issue: "End time must be after start time"

**Cause**: Invalid time range.

**Solution**: Check client-side validation. Ensure end time > start time.

### Issue: "Meals not showing rush hour discount"

**Cause**: Rush hour not active or query not using view/RPC.

**Solution**:
1. Check rush hour is active: `SELECT * FROM get_my_rush_hour();`
2. Check time range: `NOW() BETWEEN start_time AND end_time`
3. Use `get_meals_with_effective_discount` RPC, not direct meals query

### Issue: "Permission denied for function"

**Cause**: Missing GRANT statement.

**Solution**:
```sql
GRANT EXECUTE ON FUNCTION set_rush_hour_settings(boolean, timestamptz, timestamptz, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION get_my_rush_hour() TO authenticated;
```

## Summary

The Rush Hour feature provides:
- ✅ Safe concurrent updates (unique index + RPC)
- ✅ Computed effective discount (no data inconsistency)
- ✅ Instant activation/deactivation
- ✅ Timezone-aware scheduling
- ✅ Automatic reversion when inactive
- ✅ Efficient queries (single JOIN)
- ✅ Comprehensive validation
- ✅ RLS security

**Key Files**:
- Migration: `migrations/rush-hour-feature.sql`
- Entity: `lib/features/restaurant_dashboard/domain/entities/rush_hour_config.dart`
- Service: `lib/features/restaurant_dashboard/data/services/rush_hour_service.dart`
- Screen: `lib/features/restaurant_dashboard/presentation/screens/restaurant_surplus_settings_screen.dart`
- Meals Service: `lib/features/restaurant_dashboard/data/services/meals_effective_discount_service.dart`

Ready for production! 🚀
