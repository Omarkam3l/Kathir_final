# Rush Hour Feature - Key Decisions & Explanations

## C) Explanation of Key Decisions

### 1. Why Computed Effective Discount Avoids Data Inconsistency

**Problem**: If we bulk-update meal rows when rush hour activates:
```sql
-- BAD APPROACH (don't do this)
UPDATE meals 
SET discounted_price = original_price * (1 - 0.50)
WHERE restaurant_id = 'restaurant-123';
```

**Issues**:
1. **Lost Original Data**: Can't revert to original discount when rush hour ends
2. **Race Conditions**: What if meal is updated while rush hour is activating?
3. **Stale Data**: What if rush hour ends while user is browsing?
4. **Synchronization**: Need to track which meals were updated
5. **Performance**: Bulk updates on thousands of meals are slow

**Solution**: Compute effective discount on-the-fly:
```sql
-- GOOD APPROACH (what we do)
SELECT 
  m.*,
  CASE 
    WHEN rh.is_active AND NOW() BETWEEN rh.start_time AND rh.end_time THEN
      ROUND(m.original_price * (1 - rh.discount_percentage / 100.0), 2)
    ELSE
      m.discounted_price  -- Original meal discount
  END AS effective_price
FROM meals m
LEFT JOIN rush_hours rh ON m.restaurant_id = rh.restaurant_id 
  AND rh.is_active = true;
```

**Benefits**:
1. **Always Accurate**: Computed at query time, never stale
2. **Preserves Original Data**: Meal discounts unchanged
3. **Instant Activation**: No bulk updates needed
4. **Automatic Reversion**: When rush hour ends, meals automatically revert
5. **No Race Conditions**: Single atomic query
6. **Performance**: Single LEFT JOIN is fast with proper indexes

**Real-World Example**:
```
Meal A: original_price=$10, discounted_price=$8 (20% off)
Rush Hour: 50% off

Without Rush Hour:
  effective_price = $8 (meal's 20% discount)

With Rush Hour Active:
  effective_price = $5 (rush hour's 50% discount)

Rush Hour Ends:
  effective_price = $8 (automatically reverts)
```

### 2. How Unique Partial Index + Upsert Prevents Multiple Active Rows

**Problem**: Restaurant tries to activate rush hour twice:
```sql
-- Request 1: Activate rush hour
INSERT INTO rush_hours (restaurant_id, is_active, ...) 
VALUES ('restaurant-123', true, ...);

-- Request 2: Activate rush hour (concurrent)
INSERT INTO rush_hours (restaurant_id, is_active, ...) 
VALUES ('restaurant-123', true, ...);

-- Result: Two active rush hours! ❌
```

**Solution 1: Unique Partial Index**
```sql
CREATE UNIQUE INDEX idx_rush_hours_one_active_per_restaurant
ON rush_hours (restaurant_id)
WHERE is_active = true;
```

**How It Works**:
- Index only includes rows where `is_active = true`
- Prevents duplicate (restaurant_id, is_active=true) combinations
- Allows multiple inactive rows (not in index)
- Database-level enforcement (can't be bypassed)

**Example**:
```sql
-- First insert: Success ✓
INSERT INTO rush_hours (restaurant_id, is_active) 
VALUES ('restaurant-123', true);

-- Second insert: Fails ❌
INSERT INTO rush_hours (restaurant_id, is_active) 
VALUES ('restaurant-123', true);
-- ERROR: duplicate key value violates unique constraint

-- Inactive insert: Success ✓ (not in index)
INSERT INTO rush_hours (restaurant_id, is_active) 
VALUES ('restaurant-123', false);
```

**Solution 2: Upsert Logic in RPC**
```sql
-- Step 1: Deactivate existing active row
UPDATE rush_hours
SET is_active = false
WHERE restaurant_id = v_restaurant_id
  AND is_active = true;

-- Step 2: Check if any row exists
SELECT id INTO v_existing_id
FROM rush_hours
WHERE restaurant_id = v_restaurant_id
ORDER BY created_at DESC
LIMIT 1;

-- Step 3: Update existing or insert new
IF v_existing_id IS NOT NULL THEN
  UPDATE rush_hours SET ... WHERE id = v_existing_id;
ELSE
  INSERT INTO rush_hours (...) VALUES (...);
END IF;
```

**Why Both**:
- **Index**: Prevents duplicates at database level (safety net)
- **Upsert**: Handles activation gracefully (user experience)
- **Together**: Race-safe and user-friendly

**Concurrent Scenario**:
```
Time  | Request A                    | Request B
------|------------------------------|------------------------------
T1    | BEGIN TRANSACTION            |
T2    | UPDATE (deactivate existing) |
T3    |                              | BEGIN TRANSACTION
T4    | INSERT new active row        |
T5    | COMMIT ✓                     |
T6    |                              | UPDATE (deactivate existing)
T7    |                              | INSERT new active row
T8    |                              | ERROR: unique constraint ❌
T9    |                              | ROLLBACK
```

**Result**: Request A succeeds, Request B fails (can retry).

### 3. How to Avoid Redirect Loops in go_router

**Problem**: Navigating to surplus settings causes infinite redirects.

**Common Causes**:

1. **Redirect in redirect logic**:
```dart
// BAD
redirect: (context, state) {
  if (state.location == '/surplus-settings') {
    return '/surplus-settings'; // ❌ Infinite loop
  }
  return null;
}
```

2. **Conditional navigation in build**:
```dart
// BAD
@override
Widget build(BuildContext context) {
  if (someCondition) {
    context.go('/surplus-settings'); // ❌ Rebuilds trigger navigation
  }
  return Scaffold(...);
}
```

3. **Navigation in initState without check**:
```dart
// BAD
@override
void initState() {
  super.initState();
  context.go('/surplus-settings'); // ❌ May cause loop
}
```

**Solutions**:

1. **Return null in redirect when already at destination**:
```dart
// GOOD
redirect: (context, state) {
  final location = state.matchedLocation;
  
  // If already at surplus settings, don't redirect
  if (location == '/restaurant-dashboard/surplus-settings') {
    return null; // ✓ No redirect
  }
  
  // Other redirect logic...
  return null;
}
```

2. **Use context.go() only in event handlers**:
```dart
// GOOD
ElevatedButton(
  onPressed: () {
    context.go('/restaurant-dashboard/surplus-settings'); // ✓ User action
  },
  child: Text('Surplus Settings'),
)
```

3. **Check current location before navigating**:
```dart
// GOOD
void navigateToSurplusSettings() {
  final currentLocation = GoRouterState.of(context).matchedLocation;
  if (currentLocation != '/restaurant-dashboard/surplus-settings') {
    context.go('/restaurant-dashboard/surplus-settings'); // ✓ Conditional
  }
}
```

4. **Use WidgetsBinding for post-build navigation**:
```dart
// GOOD
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && someCondition) {
      context.go('/surplus-settings'); // ✓ After build
    }
  });
}
```

**Our Implementation**:
```dart
// In app_router.dart
GoRoute(
  path: '/restaurant-dashboard/surplus-settings',
  builder: (context, state) => const RestaurantSurplusSettingsScreen(),
),

// No redirect logic needed - direct route
// No navigation in build - only in event handlers
// No loops possible ✓
```

### 4. Additional Safeguards

**Prevent Stale Prices in Checkout**:
```dart
// BAD: Using cached cart price
final cartItem = cart.items[0];
final price = cartItem.price; // ❌ May be stale

// GOOD: Calculate at checkout time
final price = await mealsService.calculateEffectivePrice(mealId); // ✓ Current
```

**Prevent Caching Effective Prices**:
```dart
// BAD: Caching effective prices
final meals = await mealsService.getAllActiveMeals();
cache.set('meals', meals); // ❌ Prices may change

// GOOD: Cache metadata only
final meals = await mealsService.getAllActiveMeals();
cache.set('meal_metadata', meals.map((m) => {
  'id': m.id,
  'title': m.title,
  'image': m.imageUrl,
  // Don't cache prices
}));
```

**Prevent Race Conditions in Concurrent Updates**:
```sql
-- Transaction ensures atomicity
BEGIN;
  -- Step 1: Deactivate existing
  UPDATE rush_hours SET is_active = false WHERE ...;
  
  -- Step 2: Activate new
  INSERT INTO rush_hours (...) VALUES (...);
COMMIT;

-- If another transaction tries to insert between steps,
-- unique index prevents duplicate
```

## Summary

These design decisions ensure:
- ✅ **Data Consistency**: Computed prices are always accurate
- ✅ **Race Safety**: Unique index + transactions prevent duplicates
- ✅ **User Experience**: Instant activation, no delays
- ✅ **Performance**: Single efficient query with indexes
- ✅ **Maintainability**: Business logic in database, not scattered
- ✅ **Reliability**: No redirect loops, no stale data

The key insight: **Compute, don't store**. By computing effective prices on-the-fly instead of storing them, we eliminate an entire class of consistency and synchronization problems.
