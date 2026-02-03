# Rush Hour Feature - Quick Start Guide

## 🚀 5-Minute Setup

### Step 1: Run Migration

```bash
psql -h your-supabase-host -U postgres -d postgres -f migrations/rush-hour-feature.sql
```

Or via Supabase Dashboard:
1. Go to SQL Editor
2. Copy contents of `migrations/rush-hour-feature.sql`
3. Click "Run"

### Step 2: Verify Installation

```sql
-- Should return 4 functions
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%rush%' OR routine_name LIKE '%effective%';

-- Should return 1 view
SELECT table_name FROM information_schema.views 
WHERE table_name = 'meals_with_effective_discount';
```

### Step 3: Test Functions

```sql
-- Get current rush hour config (returns default if none)
SELECT * FROM get_my_rush_hour();

-- Activate rush hour (50% discount, 9 PM - 11 PM today)
SELECT * FROM set_rush_hour_settings(
  true,
  NOW() + INTERVAL '1 hour',
  NOW() + INTERVAL '3 hours',
  50
);

-- Get meals with effective discount
SELECT * FROM get_meals_with_effective_discount(NULL, NULL, 10, 0);
```

### Step 4: Run Flutter App

```bash
flutter clean
flutter pub get
flutter run
```

### Step 5: Access Surplus Settings

1. Login as restaurant
2. Navigate to `/restaurant-dashboard/surplus-settings`
3. Configure rush hour
4. Save

---

## 📱 Usage

### For Restaurants

**Activate Rush Hour**:
1. Open Surplus Settings
2. Toggle switch to ON
3. Select start date/time
4. Select end date/time
5. Adjust discount slider (10-80%)
6. Tap "Save Settings"

**Deactivate Rush Hour**:
1. Open Surplus Settings
2. Toggle switch to OFF
3. Tap "Save Settings"

### For Developers

**Fetch Meals with Correct Pricing**:
```dart
// Use this service instead of querying meals directly
final service = MealsEffectiveDiscountService(Supabase.instance.client);

// Get all meals with effective discount
final meals = await service.getAllActiveMeals(limit: 50);

// Get meals for specific restaurant
final myMeals = await service.getMyMealsWithEffectiveDiscount();

// Calculate effective price for checkout
final price = await service.calculateEffectivePrice(mealId);
```

**Display Meals with Rush Hour Indicator**:
```dart
MealCardWithRushHour(
  meal: meal,
  onTap: () => navigateToDetails(meal.id),
)
```

---

## 🎯 Key Concepts

### Effective Discount

The discount actually applied to a meal:
- **Rush Hour Active**: Uses rush hour discount (overrides meal discount)
- **Rush Hour Inactive**: Uses meal's original discount

### Active Now

Rush hour is "active now" when:
- `is_active = true` AND
- `NOW() BETWEEN start_time AND end_time`

### Computed Pricing

Prices are computed on-the-fly, never stored:
```
effective_price = rush_hour_active 
  ? original_price * (1 - rush_hour_discount / 100)
  : discounted_price
```

---

## ⚠️ Important Rules

1. **Always use `get_meals_with_effective_discount`** - Never query meals table directly
2. **Calculate price at checkout** - Don't cache prices in cart
3. **One active rush hour per restaurant** - Enforced by database
4. **End time must be after start time** - Validated server-side
5. **Discount range: 0-100%** - Validated server-side

---

## 🐛 Troubleshooting

### "Duplicate key value violates unique constraint"

**Solution**: Deactivate existing rush hour first
```sql
UPDATE rush_hours SET is_active = false 
WHERE restaurant_id = auth.uid() AND is_active = true;
```

### "Meals not showing rush hour discount"

**Checklist**:
- [ ] Rush hour is active (`is_active = true`)
- [ ] Current time is within range (`NOW() BETWEEN start_time AND end_time`)
- [ ] Using `get_meals_with_effective_discount` RPC
- [ ] Not caching stale prices

### "Permission denied"

**Solution**: Grant execute permissions
```sql
GRANT EXECUTE ON FUNCTION set_rush_hour_settings(boolean, timestamptz, timestamptz, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION get_my_rush_hour() TO authenticated;
GRANT EXECUTE ON FUNCTION get_meals_with_effective_discount(uuid, text, integer, integer) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION calculate_effective_price(uuid) TO authenticated;
```

---

## 📊 Testing Checklist

- [ ] Activate rush hour
- [ ] Deactivate rush hour
- [ ] Change discount percentage
- [ ] Change time range
- [ ] Meals show rush hour discount when active
- [ ] Meals revert to original discount when inactive
- [ ] "Active Now" banner shows when rush hour active
- [ ] Checkout uses current effective price
- [ ] Can't create duplicate active rush hour

---

## 🔗 Related Files

| File | Purpose |
|------|---------|
| `migrations/rush-hour-feature.sql` | Database schema |
| `lib/features/restaurant_dashboard/domain/entities/rush_hour_config.dart` | Data model |
| `lib/features/restaurant_dashboard/data/services/rush_hour_service.dart` | Rush hour service |
| `lib/features/restaurant_dashboard/data/services/meals_effective_discount_service.dart` | Meals service |
| `lib/features/restaurant_dashboard/presentation/screens/restaurant_surplus_settings_screen.dart` | Settings UI |
| `lib/features/restaurant_dashboard/presentation/widgets/meal_card_with_rush_hour.dart` | Meal card widget |

---

## 📚 Full Documentation

For detailed information, see: `docs/RUSH_HOUR_IMPLEMENTATION.md`
