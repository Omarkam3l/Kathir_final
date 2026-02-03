# Restaurant Leaderboard - Quick Start Guide

## 🚀 Quick Setup (5 Minutes)

### Step 1: Run Database Migration

```bash
# Connect to your Supabase database
psql -h your-supabase-host -U postgres -d postgres

# Run the migration
\i migrations/restaurant-leaderboard-schema.sql
```

Or via Supabase Dashboard:
1. Go to SQL Editor
2. Copy contents of `migrations/restaurant-leaderboard-schema.sql`
3. Click "Run"

### Step 2: Verify Installation

```sql
-- Check if RPC functions exist
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_restaurant_leaderboard', 'get_my_restaurant_rank');

-- Should return 2 rows
```

### Step 3: Test with Sample Data (Optional)

```sql
-- Get leaderboard (should work even if empty)
SELECT * FROM get_restaurant_leaderboard('week');

-- Get my rank (returns NULL if no sales)
SELECT * FROM get_my_restaurant_rank('week');
```

### Step 4: Run Flutter App

```bash
flutter clean
flutter pub get
flutter run
```

### Step 5: Navigate to Leaderboard

1. Login as a restaurant user
2. Tap "Rank" in bottom navigation
3. You should see the leaderboard screen

---

## 📱 Features

### Period Selection
- **This Week**: Last 7 days
- **This Month**: Last 30 days
- **All Time**: Since beginning

### Podium Display
- **Rank 1**: Center, gold border, crown, "HERO" badge
- **Rank 2**: Left, silver border
- **Rank 3**: Right, bronze border

### Your Impact Card
- Shows your current rank
- Shows total meals saved
- Sticky above bottom nav
- Shows motivational message if no sales

### Pull to Refresh
- Swipe down to refresh data
- Bypasses cache

---

## 🔧 Configuration

### Cache Duration

Default: 5 minutes

To change:
```dart
// In leaderboard_service.dart
static const _cacheDuration = Duration(minutes: 10); // Change to 10 minutes
```

### Period Options

To add new periods (e.g., "Today"):

1. Update RPC function:
```sql
CASE period_filter
  WHEN 'today' THEN
    date_threshold := NOW() - INTERVAL '1 day';
  -- ... existing cases
END CASE;
```

2. Update Flutter UI:
```dart
_buildPeriodChip('Today', 'today', isDark),
```

---

## 🐛 Troubleshooting

### "Function does not exist"
**Solution**: Run the migration again

### "Permission denied"
**Solution**: 
```sql
GRANT EXECUTE ON FUNCTION get_restaurant_leaderboard(text) TO authenticated;
GRANT EXECUTE ON FUNCTION get_my_restaurant_rank(text) TO authenticated;
```

### "Leaderboard is empty"
**Cause**: No orders with status 'paid' or 'completed'

**Solution**: Create test orders:
```sql
-- Insert test order
INSERT INTO orders (id, user_id, restaurant_id, status, created_at)
VALUES (gen_random_uuid(), 'user-uuid', auth.uid(), 'paid', NOW());

-- Insert order items
INSERT INTO order_items (order_id, meal_id, quantity, unit_price)
VALUES ('order-uuid', 'meal-uuid', 10, 5.00);
```

### "Slow performance"
**Solution**: Verify indexes exist:
```sql
SELECT indexname FROM pg_indexes WHERE tablename IN ('orders', 'order_items');
```

---

## 📊 Testing Checklist

- [ ] Database migration runs successfully
- [ ] RPC functions return data
- [ ] Screen loads without errors
- [ ] Period chips work
- [ ] Pull-to-refresh works
- [ ] Podium shows top 3
- [ ] List shows rank 4+
- [ ] "Your Impact" card shows rank
- [ ] Bottom nav navigates correctly
- [ ] Loading state shows
- [ ] Error state shows on failure
- [ ] Empty state shows when no data

---

## 🎯 Key Files

| File | Purpose |
|------|---------|
| `migrations/restaurant-leaderboard-schema.sql` | Database schema |
| `lib/features/restaurant_dashboard/data/services/leaderboard_service.dart` | Service layer |
| `lib/features/restaurant_dashboard/domain/entities/leaderboard_entry.dart` | Data models |
| `lib/features/restaurant_dashboard/presentation/screens/restaurant_leaderboard_screen.dart` | Main screen |
| `lib/features/restaurant_dashboard/presentation/widgets/my_rank_card.dart` | Sticky card |
| `lib/features/restaurant_dashboard/presentation/widgets/restaurant_bottom_nav.dart` | Bottom nav |

---

## 📞 Support

For detailed documentation, see: `docs/RESTAURANT_LEADERBOARD_IMPLEMENTATION.md`

For issues:
1. Check troubleshooting section above
2. Verify database migration ran successfully
3. Check Supabase logs for errors
4. Check Flutter console for errors
