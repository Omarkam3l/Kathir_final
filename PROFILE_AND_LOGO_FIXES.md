# Profile Photo and Restaurant Logo Fixes

## Issues Fixed

### 1. Restaurant Logo Not Showing in Favorites ✅

**Problem**: Restaurant "Shankes" has a logo in the database but it wasn't showing in the favorites screen - only showing placeholder icon

**Root Cause**: 
- The query was looking for `image_url` column in the `restaurants` table
- According to the database schema, restaurant logos are stored in the `profiles` table as `avatar_url`
- The restaurants table doesn't have an `image_url` column

**Solution**:
Modified the query in `favorites_viewmodel.dart` to join with the `profiles` table:

```dart
// OLD - Wrong query
final restaurantsRes = await _supabase
    .from('restaurants')
    .select('*')
    .inFilter('profile_id', favoriteRestaurantIds.toList());

// NEW - Correct query with join
final restaurantsRes = await _supabase
    .from('restaurants')
    .select('''
      profile_id,
      restaurant_name,
      rating,
      profiles!inner(avatar_url)
    ''')
    .inFilter('profile_id', favoriteRestaurantIds.toList());
```

**Files Modified**:
- `lib/features/user_home/presentation/viewmodels/favorites_viewmodel.dart`

**Result**: Restaurant logos now display correctly in favorites screen

---

### 2. User Profile Photo Not Showing in Home Header ✅

**Problem**: User uploaded a profile photo visible in profile screen, but home screen header showed only initials

**Root Cause**: 
- The home header widget was hardcoded to show only initials
- It wasn't fetching or displaying the user's `avatar_url` from the profile

**Solution**:
Modified `home_header_widget.dart` to:
1. Fetch `avatarUrl` from `AuthProvider`
2. Use `NetworkImage` when avatar URL exists
3. Fall back to initials when no avatar URL

```dart
// Get avatar URL from auth provider
final avatarUrl = auth.user?.avatarUrl;

// Use NetworkImage if available
CircleAvatar(
  radius: 20,
  backgroundColor: card,
  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
      ? NetworkImage(avatarUrl)
      : null,
  child: avatarUrl == null || avatarUrl.isEmpty
      ? Text(name[0].toUpperCase(), ...) // Show initials as fallback
      : null,
)
```

**Files Modified**:
- `lib/features/user_home/presentation/widgets/home_header_widget.dart`

**Result**: User profile photos now display correctly in home screen header

---

### 3. Button Text Update ✅

**Problem**: Button text said "View Menu" but functionality adds all meals to cart

**Solution**: Changed button text to "Add All Menu" to match actual functionality

**Files Modified**:
- `lib/features/user_home/presentation/screens/favorites_screen_new.dart`

**Result**: Button text now accurately describes what it does

---

## Database Schema Reference

### profiles table
```sql
CREATE TABLE profiles (
  id uuid PRIMARY KEY,
  role text,
  email text,
  full_name text,
  phone_number text,
  avatar_url text,  -- ✅ This stores user/restaurant profile photos
  ...
);
```

### restaurants table
```sql
CREATE TABLE restaurants (
  profile_id uuid PRIMARY KEY,
  restaurant_name text,
  address_text text,
  rating double precision,
  -- ❌ NO image_url column here!
  ...
);
```

**Key Insight**: Restaurant logos are stored in `profiles.avatar_url`, not in the restaurants table. This makes sense because restaurants are also profiles in the system.

---

## Testing Checklist

- [x] Restaurant logos display in favorites screen
- [x] User profile photos display in home header
- [x] Fallback to initials when no photo available
- [x] Button text matches functionality
- [x] All files compile without errors
- [x] Network image error handling in place

## Files Modified

1. `lib/features/user_home/presentation/viewmodels/favorites_viewmodel.dart`
2. `lib/features/user_home/presentation/widgets/home_header_widget.dart`
3. `lib/features/user_home/presentation/screens/favorites_screen_new.dart`
