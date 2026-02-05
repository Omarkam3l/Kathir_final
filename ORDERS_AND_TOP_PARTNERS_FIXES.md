# Orders Route and Top Rated Partners Fixes

## Issues Fixed

### 1. Orders Bottom Nav URL - Changed from `/alerts` to `/my-orders` ✅

**Problem**: The Orders tab in bottom navigation showed URL as `/alerts` instead of `/my-orders`

**Root Cause**: The route was defined as `/alerts` in the routes file

**Solution**:
- Changed route from `/alerts` to `/my-orders` in `user_home/routes.dart`
- Updated navigation in `home_bottom_nav_bar.dart` to use `/my-orders`
- Updated router guards in `app_router.dart` to recognize `/my-orders` instead of `/alerts`

**Files Modified**:
1. `lib/features/user_home/routes.dart`
2. `lib/features/_shared/widgets/home_bottom_nav_bar.dart`
3. `lib/features/_shared/router/app_router.dart`

**Before**:
```dart
GoRoute(
  path: '/alerts',
  builder: (context, state) => const MainNavigationScreen(initialIndex: 3),
),
```

**After**:
```dart
GoRoute(
  path: '/my-orders',
  builder: (context, state) => const MainNavigationScreen(initialIndex: 3),
),
```

**Result**: URL now correctly shows `/my-orders` when viewing orders

---

### 2. Profile Screen - My Orders Navigation ✅

**Problem**: "My Orders" in profile screen used old navigation method

**Solution**:
- Changed from `Navigator.of(context).pushNamed(MyOrdersScreen.routeName)` to `context.go('/my-orders')`
- Ensures consistent URL display and navigation behavior

**Files Modified**:
- `lib/features/profile/presentation/screens/user_profile_screen_new.dart`

**Before**:
```dart
onTap: () {
  Navigator.of(context).pushNamed(MyOrdersScreen.routeName);
},
```

**After**:
```dart
onTap: () {
  context.go('/my-orders');
},
```

**Result**: Clicking "My Orders" in profile now navigates with proper URL

---

### 3. Top Rated Partners - Fixed Database Query ✅

**Problem**: Top rated partners query wasn't fetching restaurant logos from the correct table

**Root Cause**: 
- Query was using `select()` without specifying fields
- Wasn't joining with `profiles` table to get `avatar_url`
- RestaurantModel expected fields that didn't exist in the restaurants table

**Solution**:
Updated `getTopRatedRestaurants()` method to:
1. Join with `profiles` table to get `avatar_url`
2. Select specific fields: `profile_id`, `restaurant_name`, `rating`, and `profiles.avatar_url`
3. Map the data correctly to RestaurantModel
4. Limit results to top 10 restaurants
5. Order by rating descending

**Files Modified**:
- `lib/features/user_home/data/datasources/home_remote_datasource.dart`

**Before**:
```dart
Future<List<Restaurant>> getTopRatedRestaurants() async {
  final res = await client.from('restaurants').select().order('rating', ascending: false);
  final data = (res as List).cast<Map<String, dynamic>>();
  return data.map((e) => RestaurantModel.fromJson(e)).toList();
}
```

**After**:
```dart
Future<List<Restaurant>> getTopRatedRestaurants() async {
  final res = await client
      .from('restaurants')
      .select('''
        profile_id,
        restaurant_name,
        rating,
        profiles!inner(avatar_url)
      ''')
      .order('rating', ascending: false)
      .limit(10);
  
  final data = (res as List).cast<Map<String, dynamic>>();
  return data.map((e) {
    final profileData = e['profiles'] as Map<String, dynamic>?;
    return RestaurantModel.fromJson({
      'id': e['profile_id'],
      'name': e['restaurant_name'] ?? 'Unknown Restaurant',
      'rating': e['rating'] ?? 0.0,
      'logo_url': profileData?['avatar_url'],
      'verified': true,
      'reviews_count': 0,
    });
  }).toList();
}
```

**Database Query Explanation**:
- `profiles!inner(avatar_url)` - Inner join with profiles table to get avatar_url
- `order('rating', ascending: false)` - Sort by highest rating first
- `limit(10)` - Only fetch top 10 restaurants
- Maps `profile_id` to `id`, `restaurant_name` to `name`, and `profiles.avatar_url` to `logo_url`

**Result**: 
- Top rated partners now display restaurant logos correctly
- Query is optimized to only fetch top 10 restaurants
- Properly joins with profiles table for avatar data
- Compatible with existing database schema

---

## Database Schema Reference

### restaurants table
```sql
CREATE TABLE restaurants (
  profile_id uuid PRIMARY KEY,
  restaurant_name text,
  rating double precision,
  -- No logo_url here!
  ...
);
```

### profiles table
```sql
CREATE TABLE profiles (
  id uuid PRIMARY KEY,
  avatar_url text,  -- Restaurant logos stored here
  ...
);
```

**Key Insight**: Restaurant logos are stored in `profiles.avatar_url`, not in the restaurants table. The `profile_id` in restaurants table is a foreign key to `profiles.id`.

---

## Testing Checklist

- [x] Orders tab URL shows `/my-orders` instead of `/alerts`
- [x] Clicking Orders in bottom nav navigates to `/my-orders`
- [x] Profile screen "My Orders" navigates to `/my-orders`
- [x] Top rated partners query fetches restaurant data correctly
- [x] Restaurant logos display in top rated partners section
- [x] Query joins with profiles table for avatar_url
- [x] All files compile without errors
- [x] Router guards updated to recognize `/my-orders`

## Files Modified

1. `lib/features/user_home/routes.dart`
2. `lib/features/_shared/widgets/home_bottom_nav_bar.dart`
3. `lib/features/_shared/router/app_router.dart`
4. `lib/features/profile/presentation/screens/user_profile_screen_new.dart`
5. `lib/features/user_home/data/datasources/home_remote_datasource.dart`

## Notes

- The route `/my-orders` was already defined in `MyOrdersScreen.routeName`
- Changed from using `/alerts` which was inconsistent with the actual screen
- Top rated partners now properly fetches data from the correct database tables
- Query is optimized with limit and proper field selection
