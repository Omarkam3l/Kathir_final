# Restaurant Search Routing Fix

## Issue
The restaurant search screen was not opening when clicking the map icon in the search bar.

## Root Causes

### 1. Empty onFilterTap Callback
**File:** `lib/features/user_home/presentation/screens/home_dashboard_screen.dart`

**Problem:**
```dart
SearchBarWidget(
  onQueryChanged: (q) => setState(() => _query = q),
  onFilterTap: () {
    // Optional: navigate to advanced search
  },
),
```

The `onFilterTap` was provided but empty, so the SearchBarWidget's default navigation was never triggered.

**Fix:**
```dart
SearchBarWidget(
  onQueryChanged: (q) => setState(() => _query = q),
  onFilterTap: () => context.push('/restaurant-search'),
),
```

### 2. Route Redirect Blocking
**File:** `lib/features/_shared/router/app_router.dart`

**Problem:**
The redirect logic was blocking all routes starting with `/restaurant` for users:
```dart
// User trying to access Restaurant routes
if (role == 'user' && (location.startsWith('/restaurant') || location == '/restaurant-dashboard')) {
  return '/home';
}
```

This blocked:
- `/restaurant-search` ❌
- `/restaurant/:id/meals` ❌
- `/restaurant-dashboard` ✅ (should be blocked)

**Fix:**
Changed to only block the restaurant dashboard:
```dart
// User trying to access Restaurant dashboard (but allow restaurant-search and restaurant meals)
if (role == 'user' && location == '/restaurant-dashboard') {
  return '/home';
}
```

Now allows:
- `/restaurant-search` ✅
- `/restaurant/:id/meals` ✅
- `/restaurant-dashboard` ❌ (correctly blocked)

## Changes Made

### 1. home_dashboard_screen.dart
- Updated `onFilterTap` to navigate to `/restaurant-search`

### 2. app_router.dart
- Modified redirect logic to allow users to access:
  - `/restaurant-search` - Map-based restaurant search
  - `/restaurant/:id/meals` - Restaurant meals screen
- Still blocks users from accessing `/restaurant-dashboard`

## Testing

### Test Cases
1. ✅ User clicks map icon → Opens restaurant search screen
2. ✅ User searches for restaurants → Shows results
3. ✅ User clicks restaurant → Opens restaurant meals screen
4. ✅ User clicks meal → Opens meal detail screen
5. ✅ User cannot access `/restaurant-dashboard` → Redirects to `/home`
6. ✅ NGO cannot access `/restaurant-search` → Redirects to `/ngo/home`
7. ✅ Restaurant cannot access `/restaurant-search` → Redirects to `/restaurant-dashboard`

### Navigation Flow
```
User Home Screen
    ↓ (click map icon)
Restaurant Search Screen
    ↓ (click restaurant)
Restaurant Meals Screen
    ↓ (click meal)
Meal Detail Screen
```

## Role-Based Access Control

### User Role
- ✅ Can access `/restaurant-search`
- ✅ Can access `/restaurant/:id/meals`
- ❌ Cannot access `/restaurant-dashboard`
- ❌ Cannot access `/ngo/*` routes

### NGO Role
- ❌ Cannot access `/restaurant-search` (has own map)
- ❌ Cannot access `/restaurant/:id/meals`
- ❌ Cannot access `/restaurant-dashboard`
- ✅ Can access `/ngo/*` routes

### Restaurant Role
- ❌ Cannot access `/restaurant-search`
- ❌ Cannot access `/restaurant/:id/meals`
- ✅ Can access `/restaurant-dashboard`
- ❌ Cannot access `/ngo/*` routes

## Files Modified
1. `lib/features/user_home/presentation/screens/home_dashboard_screen.dart`
2. `lib/features/_shared/router/app_router.dart`

## Verification
- ✅ No diagnostic errors
- ✅ All routes properly configured
- ✅ Role-based access control working correctly
- ✅ Navigation flow tested
