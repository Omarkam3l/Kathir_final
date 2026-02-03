# Restaurant Leaderboard - Architecture Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  RestaurantLeaderboardScreen (StatefulWidget)          │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │  State:                                           │  │    │
│  │  │  - _selectedPeriod: String                       │  │    │
│  │  │  - _leaderboard: List<LeaderboardEntry>          │  │    │
│  │  │  - _myRank: MyRestaurantRank?                    │  │    │
│  │  │  - _isLoading: bool                              │  │    │
│  │  │  - _error: String?                               │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │                         │                               │    │
│  │                         ▼                               │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │  UI Components:                                   │  │    │
│  │  │  - Period Filter Chips (week/month/all)          │  │    │
│  │  │  - Podium (Top 3)                                 │  │    │
│  │  │  - List (Rank 4+)                                 │  │    │
│  │  │  - MyRankCard (Sticky)                            │  │    │
│  │  │  - RestaurantBottomNav                            │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  └────────────────────────────────────────────────────────┘    │
│                         │                                        │
│                         ▼                                        │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  LeaderboardService                                     │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │  Methods:                                         │  │    │
│  │  │  - fetchLeaderboard(period, forceRefresh)        │  │    │
│  │  │  - fetchMyRank(period)                           │  │    │
│  │  │  - clearCache()                                  │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │  Cache:                                           │  │    │
│  │  │  - _cache: Map<String, List<LeaderboardEntry>>   │  │    │
│  │  │  - _cacheTimestamp: DateTime?                    │  │    │
│  │  │  - TTL: 5 minutes                                │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  └────────────────────────────────────────────────────────┘    │
│                         │                                        │
└─────────────────────────┼────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Supabase Client                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  RPC Call:                                                │  │
│  │  supabase.rpc('get_restaurant_leaderboard',              │  │
│  │               params: {'period_filter': 'week'})         │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  RPC Call:                                                │  │
│  │  supabase.rpc('get_my_restaurant_rank',                  │  │
│  │               params: {'period_filter': 'week'})         │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PostgreSQL Database                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  RPC Function: get_restaurant_leaderboard(period)      │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │  1. Determine date threshold based on period     │  │    │
│  │  │  2. Join restaurants + profiles + orders         │  │    │
│  │  │  3. Aggregate order_items.quantity (SUM)         │  │    │
│  │  │  4. Filter: approved restaurants, status paid    │  │    │
│  │  │  5. Rank using ROW_NUMBER() OVER (ORDER BY)     │  │    │
│  │  │  6. Return sorted results                        │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  RPC Function: get_my_restaurant_rank(period)          │    │
│  │  ┌──────────────────────────────────────────────────┐  │    │
│  │  │  1. Call get_restaurant_leaderboard(period)      │  │    │
│  │  │  2. Filter WHERE restaurant_id = auth.uid()      │  │    │
│  │  │  3. Return single row or NULL                    │  │    │
│  │  └──────────────────────────────────────────────────┘  │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Tables Used:                                           │    │
│  │  - restaurants (profile_id, restaurant_name)           │    │
│  │  - profiles (id, avatar_url, approval_status, role)    │    │
│  │  - orders (id, restaurant_id, status, created_at)      │    │
│  │  - order_items (order_id, quantity)                    │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Indexes:                                               │    │
│  │  - idx_orders_created_at                               │    │
│  │  - idx_orders_restaurant_status                        │    │
│  │  - idx_order_items_order_id                            │    │
│  │  - idx_profiles_approval_role                          │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Sequence

```
User Action: Open Leaderboard Screen
    │
    ▼
Screen: initState()
    │
    ▼
Screen: _loadLeaderboard()
    │
    ├─► Service: fetchLeaderboard('week')
    │       │
    │       ├─► Check Cache
    │       │   ├─ Cache Valid? → Return Cached Data
    │       │   └─ Cache Invalid? → Continue
    │       │
    │       ├─► Supabase: rpc('get_restaurant_leaderboard')
    │       │       │
    │       │       ▼
    │       │   Database: Execute RPC Function
    │       │       │
    │       │       ├─► Join Tables
    │       │       ├─► Aggregate Data
    │       │       ├─► Calculate Ranks
    │       │       └─► Return Results
    │       │       │
    │       │       ▼
    │       │   Supabase: Return JSON
    │       │       │
    │       │       ▼
    │       ├─► Service: Parse JSON → List<LeaderboardEntry>
    │       ├─► Service: Update Cache
    │       └─► Service: Return Data
    │           │
    │           ▼
    │   Screen: setState({ _leaderboard = data })
    │
    └─► Service: fetchMyRank('week')
            │
            ├─► Supabase: rpc('get_my_restaurant_rank')
            │       │
            │       ▼
            │   Database: Execute RPC Function
            │       │
            │       └─► Return Single Row or NULL
            │       │
            │       ▼
            │   Supabase: Return JSON
            │       │
            │       ▼
            ├─► Service: Parse JSON → MyRestaurantRank?
            └─► Service: Return Data
                │
                ▼
        Screen: setState({ _myRank = data })
            │
            ▼
        Screen: Build UI
            │
            ├─► Period Filters
            ├─► Podium (Top 3)
            ├─► List (Rank 4+)
            ├─► MyRankCard (Sticky)
            └─► RestaurantBottomNav
```

## Navigation Flow

```
RestaurantBottomNav
    │
    ├─► [0] Home → /restaurant-dashboard
    │       └─► RestaurantHomeScreen
    │
    ├─► [1] Meals → /restaurant-dashboard/meals
    │       └─► MealsListScreen
    │
    ├─► [2] Orders → /restaurant-dashboard/orders
    │       └─► RestaurantOrdersScreen
    │
    ├─► [3] Rank → /restaurant-dashboard/leaderboard
    │       └─► RestaurantLeaderboardScreen ◄── YOU ARE HERE
    │
    └─► [4] Profile → /restaurant-dashboard/profile
            └─► RestaurantProfileScreen
```

## Cache Strategy

```
Request Flow with Cache:

fetchLeaderboard('week')
    │
    ▼
Check Cache
    │
    ├─► Cache Exists?
    │   ├─ YES → Check Timestamp
    │   │   ├─ < 5 min? → Return Cached Data ✓
    │   │   └─ > 5 min? → Continue to API
    │   └─ NO → Continue to API
    │
    ▼
Call Supabase RPC
    │
    ▼
Parse Response
    │
    ▼
Update Cache
    │
    ├─ _cache['week'] = data
    └─ _cacheTimestamp = now()
    │
    ▼
Return Data

Pull-to-Refresh:
    │
    ▼
fetchLeaderboard('week', forceRefresh: true)
    │
    └─► Skip Cache Check → Call API Directly
```

## UI Component Hierarchy

```
RestaurantLeaderboardScreen
│
├─ SafeArea
│  │
│  └─ Stack
│     │
│     ├─ Column
│     │  │
│     │  ├─ _buildAppBar()
│     │  │  ├─ Back Button
│     │  │  ├─ Title: "Leaderboard"
│     │  │  └─ Filter Icon
│     │  │
│     │  └─ Expanded
│     │     │
│     │     └─ RefreshIndicator
│     │        │
│     │        └─ CustomScrollView
│     │           │
│     │           ├─ SliverToBoxAdapter: _buildPeriodFilters()
│     │           │  └─ Row of Chips (week/month/all)
│     │           │
│     │           ├─ SliverToBoxAdapter: _buildPodium()
│     │           │  └─ Row
│     │           │     ├─ Rank 2 (Left)
│     │           │     ├─ Rank 1 (Center, Crown)
│     │           │     └─ Rank 3 (Right)
│     │           │
│     │           ├─ SliverToBoxAdapter: _buildRestOfList()
│     │           │  └─ ListView
│     │           │     ├─ Rank 4
│     │           │     ├─ Rank 5
│     │           │     └─ ...
│     │           │
│     │           └─ SliverToBoxAdapter: Padding (for sticky card)
│     │
│     └─ Positioned (bottom: 80)
│        │
│        └─ MyRankCard
│           ├─ Rank Badge
│           ├─ "Your Impact" Text
│           └─ Score + Trend Icon
│
└─ RestaurantBottomNav
   ├─ Home
   ├─ Meals
   ├─ Orders
   ├─ Rank ◄── Selected
   └─ Profile
```

## State Management

```
RestaurantLeaderboardScreen State:

┌─────────────────────────────────────┐
│  _selectedPeriod: String            │  ← User Selection
│  Default: 'week'                    │
│  Options: 'week', 'month', 'all'    │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  _isLoading: bool                   │  ← Loading State
│  true: Show Spinner                 │
│  false: Show Content                │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  _error: String?                    │  ← Error State
│  null: No Error                     │
│  non-null: Show Error Message       │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  _leaderboard: List<LeaderboardEntry>│ ← Data
│  Empty: Show Empty State            │
│  Non-empty: Show Podium + List      │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  _myRank: MyRestaurantRank?         │  ← User's Rank
│  null: Show "Start Selling" Message │
│  non-null: Show Rank Card           │
└─────────────────────────────────────┘

State Transitions:

Initial → Loading
    │
    ├─► Success → Loaded (with data)
    │
    └─► Failure → Error (with message)
            │
            └─► Retry → Loading
```

## Performance Optimization

```
Database Level:
    │
    ├─► Indexes
    │   ├─ idx_orders_created_at (for period filtering)
    │   ├─ idx_orders_restaurant_status (for joins)
    │   ├─ idx_order_items_order_id (for aggregation)
    │   └─ idx_profiles_approval_role (for filtering)
    │
    ├─► RPC Functions
    │   ├─ Server-side computation
    │   ├─ Single query (no N+1)
    │   └─ Efficient joins
    │
    └─► Query Optimization
        ├─ Filter early (WHERE clauses)
        ├─ Aggregate efficiently (SUM, GROUP BY)
        └─ Limit results if needed

Application Level:
    │
    ├─► Caching
    │   ├─ In-memory cache (5 min TTL)
    │   ├─ Per-period caching
    │   └─ Force refresh on pull-to-refresh
    │
    ├─► Lazy Loading
    │   ├─ Load data on screen open
    │   └─ Don't load until needed
    │
    └─► UI Optimization
        ├─ Use const constructors
        ├─ Avoid rebuilds (setState scope)
        └─ Efficient list rendering
```

## Security Model

```
RLS Bypass with SECURITY DEFINER:

┌─────────────────────────────────────────────────────────┐
│  RPC Function: get_restaurant_leaderboard               │
│  Security: SECURITY DEFINER                             │
│  ┌───────────────────────────────────────────────────┐ │
│  │  Bypasses RLS to read across tables               │ │
│  │  BUT only exposes:                                 │ │
│  │  - Approved restaurants (approval_status='approved')│ │
│  │  - Public data (name, avatar, score)              │ │
│  │  - No sensitive data (legal docs, phone, etc.)    │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘

Why Safe:
    │
    ├─► Only reads public restaurant data
    ├─► Filters to approved restaurants only
    ├─► No write operations allowed
    ├─► No user-specific data exposed
    └─► Controlled by function logic (not client)

Alternative (Not Used):
    │
    └─► Complex RLS policies on each table
        ├─ Harder to maintain
        ├─ Performance overhead
        └─ More error-prone
```

This architecture ensures:
- ✅ Efficient data fetching (single RPC call)
- ✅ Secure data access (SECURITY DEFINER with controlled exposure)
- ✅ Good performance (indexes + caching)
- ✅ Clean separation of concerns (service layer)
- ✅ Maintainable code (typed models, clear structure)
