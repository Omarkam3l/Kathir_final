# Restaurant Leaderboard Implementation Guide

## Overview

This document explains the complete implementation of the Restaurant Leaderboard feature, including database schema, Flutter code, and key design decisions.

## Table of Contents

1. [Database Schema](#database-schema)
2. [Flutter Architecture](#flutter-architecture)
3. [Key Design Decisions](#key-design-decisions)
4. [How to Avoid Common Issues](#how-to-avoid-common-issues)
5. [Testing Guide](#testing-guide)

---

## Database Schema

### RPC Functions

#### `get_restaurant_leaderboard(period_filter text)`

**Purpose**: Computes restaurant rankings based on meals sold during a specified period.

**Parameters**:
- `period_filter`: 'week' | 'month' | 'all'

**Returns**: Table with columns:
- `restaurant_profile_id` (uuid): Restaurant's profile ID
- `restaurant_name` (text): Restaurant name
- `avatar_url` (text): Profile picture URL
- `score` (bigint): Total meals sold
- `rank` (bigint): Ranking position (1-based)

**Security**: Uses `SECURITY DEFINER` to allow reading across tables safely. Only exposes approved restaurant data.

**Performance**: 
- Uses efficient joins and aggregation
- Leverages indexes on `orders.created_at`, `orders.restaurant_id`, and `order_items.order_id`
- Single query returns all needed data (no N+1 queries)

**Example Usage**:
```sql
-- Get weekly leaderboard
SELECT * FROM get_restaurant_leaderboard('week');

-- Get all-time leaderboard
SELECT * FROM get_restaurant_leaderboard('all');
```

#### `get_my_restaurant_rank(period_filter text)`

**Purpose**: Returns the current authenticated user's restaurant rank and score.

**Parameters**:
- `period_filter`: 'week' | 'month' | 'all'

**Returns**: Single row with:
- `rank` (bigint): Current rank
- `score` (bigint): Total meals sold
- `restaurant_name` (text): Restaurant name

**Returns NULL if**: User is not a restaurant or has no sales.

**Example Usage**:
```sql
-- Get my current rank for this week
SELECT * FROM get_my_restaurant_rank('week');
```

### Indexes

The following indexes optimize leaderboard query performance:

```sql
-- Period filtering
CREATE INDEX idx_orders_created_at 
ON orders (created_at DESC) 
WHERE status IN ('paid', 'completed');

-- Efficient joins
CREATE INDEX idx_orders_restaurant_status 
ON orders (restaurant_id, status, created_at DESC);

-- Aggregation
CREATE INDEX idx_order_items_order_id 
ON order_items (order_id);

-- Profile filtering
CREATE INDEX idx_profiles_approval_role 
ON profiles (approval_status, role) 
WHERE approval_status = 'approved' AND role = 'restaurant';
```

### RLS Policies

The RPC functions use `SECURITY DEFINER` to bypass RLS, but they only expose:
- Approved restaurants (approval_status = 'approved')
- Public restaurant data (name, avatar, score)
- No sensitive information (legal docs, phone numbers, etc.)

This is safe because:
1. Only public data is returned
2. Only approved restaurants are included
3. No user-specific data is exposed

---

## Flutter Architecture

### Directory Structure

```
lib/features/restaurant_dashboard/
├── data/
│   └── services/
│       └── leaderboard_service.dart          # Service layer
├── domain/
│   └── entities/
│       └── leaderboard_entry.dart            # Data models
└── presentation/
    ├── screens/
    │   └── restaurant_leaderboard_screen.dart # Main screen
    └── widgets/
        ├── restaurant_bottom_nav.dart         # Updated nav bar
        └── my_rank_card.dart                  # Sticky rank card
```

### Data Flow

```
Screen → Service → Supabase RPC → Database
   ↓        ↓
Cache ← Response
```

### Components

#### 1. LeaderboardService

**Responsibilities**:
- Fetch leaderboard data from Supabase
- Fetch current user's rank
- In-memory caching (5-minute TTL)
- Error handling

**Key Methods**:
```dart
Future<List<LeaderboardEntry>> fetchLeaderboard(String period, {bool forceRefresh = false})
Future<MyRestaurantRank?> fetchMyRank(String period)
void clearCache()
```

**Caching Strategy**:
- In-memory cache with 5-minute TTL
- Per-period caching (week/month/all stored separately)
- Force refresh on pull-to-refresh
- Automatic cache invalidation after TTL

#### 2. LeaderboardEntry Model

```dart
class LeaderboardEntry {
  final String restaurantId;
  final String name;
  final int score;
  final int rank;
  final String? avatarUrl;
}
```

#### 3. RestaurantLeaderboardScreen

**Features**:
- Period selection (week/month/all)
- Pull-to-refresh
- Loading/error states
- Empty state handling
- Podium display for top 3
- List view for rank 4+
- Sticky "Your Impact" card

**State Management**:
- StatefulWidget with local state
- Async data loading
- Error handling with retry

#### 4. RestaurantBottomNav

**Updated Features**:
- 5 navigation items (added "Rank")
- Route-aware selection
- Uses go_router for navigation
- No redirect loops

**Navigation Items**:
1. Home → `/restaurant-dashboard`
2. Meals → `/restaurant-dashboard/meals`
3. Orders → `/restaurant-dashboard/orders`
4. Rank → `/restaurant-dashboard/leaderboard`
5. Profile → `/restaurant-dashboard/profile`

#### 5. MyRankCard

**Features**:
- Sticky positioning above bottom nav
- Shows rank, score, and restaurant name
- Gradient background with primary color
- Handles null state (no sales yet)

---

## Key Design Decisions

### 1. Why RPC Functions Instead of Client-Side Queries?

**Reasons**:
- **Performance**: Single query vs. multiple client-side joins
- **Security**: Controlled data exposure via SECURITY DEFINER
- **Maintainability**: Business logic in one place
- **Scalability**: Server-side computation handles large datasets better

**Alternative Considered**: Client-side joins using Supabase query builder
**Why Rejected**: Would require multiple queries, expose raw tables, and be slower

### 2. Why Exclude Restaurants with 0 Sales?

**Reasons**:
- **Better UX**: Cleaner leaderboard without long list of zeros
- **Motivation**: Only shows active participants
- **Simpler UI**: Easier to implement "Your Impact" card

**Alternative Considered**: Show all restaurants with rank
**Why Rejected**: Would clutter UI and demotivate restaurants with no sales

### 3. Why In-Memory Caching?

**Reasons**:
- **Performance**: Reduces API calls
- **Cost**: Fewer database queries
- **UX**: Faster screen loads

**Cache Duration**: 5 minutes
- Long enough to reduce API calls
- Short enough to show recent updates

**Alternative Considered**: No caching or persistent caching
**Why Rejected**: 
- No caching: Too many API calls
- Persistent caching: Stale data issues

### 4. Why SECURITY DEFINER?

**Reasons**:
- **RLS Bypass**: Allows reading across tables without complex RLS policies
- **Safety**: Only exposes public restaurant data
- **Performance**: Avoids RLS overhead for read-only operations

**Security Considerations**:
- Only approved restaurants included
- No sensitive data exposed
- No write operations allowed

### 5. Score Calculation: Why SUM(order_items.quantity)?

**Reasons**:
- **Accuracy**: Counts actual meals sold, not just orders
- **Fairness**: Restaurants selling multiple items per order get proper credit

**Alternative Considered**: COUNT(orders.id)
**Why Rejected**: Doesn't account for multiple items per order

---

## How to Avoid Common Issues

### 1. Redirect Loops

**Problem**: Bottom nav causes infinite redirects

**Solution**:
- Use `context.go()` instead of `context.push()`
- Check current route before navigating
- Don't navigate if already on target route

**Example**:
```dart
void _onBottomNavTap(int index) {
  switch (index) {
    case 0:
      context.go('/restaurant-dashboard');
      break;
    case 3:
      // Already on leaderboard - do nothing
      break;
  }
}
```

### 2. Null Auth Issues

**Problem**: `auth.uid()` returns null

**Solution**:
- Always check authentication state before calling RPC
- Handle null case in UI (show login prompt)
- Use `SECURITY DEFINER` to allow unauthenticated reads if needed

**Example**:
```dart
final user = Supabase.instance.client.auth.currentUser;
if (user == null) {
  // Show login prompt
  return;
}
```

### 3. RLS Policy Conflicts

**Problem**: RPC function blocked by RLS

**Solution**:
- Use `SECURITY DEFINER` to bypass RLS
- Ensure function only exposes public data
- Test with different user roles

### 4. Performance Issues with Large Datasets

**Problem**: Slow queries with many orders

**Solution**:
- Create proper indexes (see Database Schema section)
- Use server-side aggregation (RPC functions)
- Implement pagination if needed (future enhancement)

**Indexes to Create**:
```sql
CREATE INDEX idx_orders_created_at ON orders (created_at DESC);
CREATE INDEX idx_orders_restaurant_status ON orders (restaurant_id, status, created_at DESC);
CREATE INDEX idx_order_items_order_id ON order_items (order_id);
```

### 5. Stale Cache Data

**Problem**: Leaderboard shows outdated data

**Solution**:
- Implement pull-to-refresh
- Use reasonable cache TTL (5 minutes)
- Clear cache on critical actions (e.g., order completion)

**Example**:
```dart
Future<void> _onRefresh() async {
  await _loadLeaderboard(forceRefresh: true);
}
```

---

## Testing Guide

### 1. Database Testing

**Test the RPC functions**:

```sql
-- Test weekly leaderboard
SELECT * FROM get_restaurant_leaderboard('week');

-- Test monthly leaderboard
SELECT * FROM get_restaurant_leaderboard('month');

-- Test all-time leaderboard
SELECT * FROM get_restaurant_leaderboard('all');

-- Test my rank (as authenticated restaurant)
SELECT * FROM get_my_restaurant_rank('week');
```

**Expected Results**:
- Returns restaurants sorted by score (descending)
- Rank is sequential (1, 2, 3, ...)
- Only approved restaurants included
- Only restaurants with sales > 0 included

### 2. Flutter Testing

**Manual Testing Checklist**:

- [ ] Screen loads without errors
- [ ] Period chips work (week/month/all)
- [ ] Pull-to-refresh works
- [ ] Podium shows top 3 correctly
- [ ] List shows rank 4+ correctly
- [ ] "Your Impact" card shows correct rank
- [ ] "Your Impact" card handles null (no sales)
- [ ] Bottom nav navigates correctly
- [ ] Bottom nav highlights current tab
- [ ] Loading state shows spinner
- [ ] Error state shows error message
- [ ] Empty state shows when no data
- [ ] Avatar images load correctly
- [ ] Default avatars show when no image

**Test Scenarios**:

1. **New Restaurant (No Sales)**:
   - Should show empty leaderboard
   - "Your Impact" card should show "Start selling meals..."

2. **Restaurant with Sales**:
   - Should show in leaderboard
   - "Your Impact" card should show rank and score

3. **Top 3 Restaurant**:
   - Should appear in podium
   - Rank 1 should have crown and "HERO" badge

4. **Network Error**:
   - Should show error state
   - Retry button should work

### 3. Performance Testing

**Metrics to Monitor**:
- Query execution time (should be < 100ms)
- Screen load time (should be < 1s)
- Memory usage (should not leak)

**Tools**:
- Supabase Dashboard → Performance tab
- Flutter DevTools → Performance tab

---

## Deployment Checklist

### 1. Database Migration

```bash
# Run the migration
psql -h your-supabase-host -U postgres -d postgres -f migrations/restaurant-leaderboard-schema.sql
```

### 2. Verify RPC Functions

```sql
-- Check if functions exist
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_restaurant_leaderboard', 'get_my_restaurant_rank');
```

### 3. Verify Indexes

```sql
-- Check if indexes exist
SELECT indexname 
FROM pg_indexes 
WHERE schemaname = 'public' 
AND indexname LIKE 'idx_orders%';
```

### 4. Test with Real Data

```sql
-- Insert test orders
INSERT INTO orders (user_id, restaurant_id, status, created_at)
VALUES 
  ('user-uuid', 'restaurant-uuid', 'paid', NOW() - INTERVAL '2 days'),
  ('user-uuid', 'restaurant-uuid', 'completed', NOW() - INTERVAL '1 day');

-- Insert test order items
INSERT INTO order_items (order_id, meal_id, quantity, unit_price)
VALUES 
  ('order-uuid', 'meal-uuid', 5, 10.00),
  ('order-uuid', 'meal-uuid', 3, 10.00);

-- Verify leaderboard
SELECT * FROM get_restaurant_leaderboard('week');
```

### 5. Flutter Build

```bash
# Clean build
flutter clean
flutter pub get

# Run app
flutter run

# Build for production
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

---

## Future Enhancements

### 1. Pagination

**Why**: Handle large leaderboards (1000+ restaurants)

**Implementation**:
- Add `LIMIT` and `OFFSET` to RPC function
- Implement infinite scroll in Flutter
- Cache pages separately

### 2. Filters

**Why**: Allow filtering by region, category, etc.

**Implementation**:
- Add filter parameters to RPC function
- Add filter UI in Flutter
- Update cache key to include filters

### 3. Real-time Updates

**Why**: Show live leaderboard changes

**Implementation**:
- Use Supabase Realtime subscriptions
- Listen to `orders` table changes
- Update leaderboard automatically

### 4. Achievements/Badges

**Why**: Gamification to increase engagement

**Implementation**:
- Add `achievements` table
- Award badges for milestones (100 meals, 1000 meals, etc.)
- Display badges on leaderboard

### 5. Historical Trends

**Why**: Show restaurant performance over time

**Implementation**:
- Add `leaderboard_history` table
- Store daily snapshots
- Display trend charts

---

## Troubleshooting

### Issue: "Function does not exist"

**Cause**: Migration not run or function dropped

**Solution**:
```sql
-- Re-run migration
\i migrations/restaurant-leaderboard-schema.sql
```

### Issue: "Permission denied for function"

**Cause**: Missing GRANT statement

**Solution**:
```sql
GRANT EXECUTE ON FUNCTION get_restaurant_leaderboard(text) TO authenticated;
GRANT EXECUTE ON FUNCTION get_my_restaurant_rank(text) TO authenticated;
```

### Issue: "Slow query performance"

**Cause**: Missing indexes

**Solution**:
```sql
-- Check if indexes exist
SELECT indexname FROM pg_indexes WHERE tablename = 'orders';

-- Create missing indexes
CREATE INDEX idx_orders_created_at ON orders (created_at DESC);
```

### Issue: "Leaderboard shows wrong data"

**Cause**: Cache not cleared or wrong period

**Solution**:
```dart
// Clear cache
_leaderboardService.clearCache();

// Force refresh
await _loadLeaderboard(forceRefresh: true);
```

---

## Summary

The Restaurant Leaderboard feature provides:
- **Efficient**: Single RPC call, server-side computation, proper indexes
- **Secure**: SECURITY DEFINER with controlled data exposure
- **Scalable**: Handles large datasets with pagination-ready architecture
- **User-Friendly**: Clean UI, pull-to-refresh, loading/error states
- **Maintainable**: Clear separation of concerns, typed models, comprehensive docs

**Key Files**:
- Database: `migrations/restaurant-leaderboard-schema.sql`
- Service: `lib/features/restaurant_dashboard/data/services/leaderboard_service.dart`
- Screen: `lib/features/restaurant_dashboard/presentation/screens/restaurant_leaderboard_screen.dart`
- Models: `lib/features/restaurant_dashboard/domain/entities/leaderboard_entry.dart`
- Widget: `lib/features/restaurant_dashboard/presentation/widgets/my_rank_card.dart`
- Router: `lib/features/_shared/router/app_router.dart` (updated)

**Next Steps**:
1. Run database migration
2. Test RPC functions
3. Run Flutter app
4. Test all features manually
5. Deploy to production
