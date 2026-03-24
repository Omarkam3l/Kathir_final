# User Onboarding Role Filtering Implementation

## Overview
Updated the onboarding screens to be user-specific by adding `user_` prefix to file names and implementing role-based access control to ensure only users with `role='user'` can access these screens.

## Changes Made

### 1. File Renaming
All onboarding screens have been renamed with `user_` prefix to indicate they are user-specific:

| Old Name | New Name |
|----------|----------|
| `profile_setup_screen.dart` | `user_profile_setup_screen.dart` |
| `onboarding_address_selector_screen.dart` | `user_address_selector_screen.dart` |
| `category_selection_screen.dart` | `user_category_selection_screen.dart` |

### 2. Class Renaming
All class names have been updated to match the new file names:

| Old Class Name | New Class Name |
|----------------|----------------|
| `ProfileSetupScreen` | `UserProfileSetupScreen` |
| `OnboardingAddressSelectorScreen` | `UserAddressSelectorScreen` |
| `CategorySelectionScreen` | `UserCategorySelectionScreen` |

### 3. Role-Based Access Control
Added redirect logic to each onboarding route to ensure only users with `role='user'` can access these screens:

```dart
redirect: (context, state) {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final user = auth.user;
  
  // Only allow users with role='user' to access this screen
  if (user?.role != 'user') {
    if (user?.role == 'restaurant') {
      return '/restaurant-dashboard';
    } else if (user?.role == 'ngo') {
      return '/ngo/home';
    } else if (user?.role == 'admin') {
      return '/admin-dashboard';
    }
    return '/';
  }
  return null;
}
```

## Protected Routes

The following routes are now protected and only accessible to users with `role='user'`:

1. `/onboarding/profile` - User Profile Setup Screen
2. `/onboarding/categories` - User Category Selection Screen
3. `/onboarding/select-address` - User Address Selector Screen

## Behavior by Role

### User (role='user')
- ✅ Can access all onboarding screens
- ✅ Will be redirected through profile setup and category selection based on completion flags
- ✅ After completion, redirected to `/home`

### Restaurant (role='restaurant')
- ❌ Cannot access onboarding screens
- ↪️ Redirected to `/restaurant-dashboard` if they try to access
- ✅ No profile setup or category selection required

### NGO (role='ngo')
- ❌ Cannot access onboarding screens
- ↪️ Redirected to `/ngo/home` if they try to access
- ✅ No profile setup or category selection required

### Admin (role='admin')
- ❌ Cannot access onboarding screens
- ↪️ Redirected to `/admin-dashboard` if they try to access
- ✅ No profile setup or category selection required

## Routing Logic (User Role Only)

The onboarding flow only applies to users with `role='user'`:

### Case 1: Profile Completed (T), Categories Not Completed (F)
- **Flow**: Categories → Home
- **Screens**: `UserCategorySelectionScreen` → Home

### Case 2: Profile Not Completed (F), Categories Not Completed (F)
- **Flow**: Profile → Categories → Home
- **Screens**: `UserProfileSetupScreen` → `UserCategorySelectionScreen` → Home

### Case 3: Profile Not Completed (F), Categories Completed (T)
- **Flow**: Profile → Home
- **Screens**: `UserProfileSetupScreen` → Home

### Case 4: Both Completed (T, T)
- **Flow**: Home (Direct)
- **Screens**: None (direct to home)

## Security Benefits

1. **Role Isolation**: Restaurant, NGO, and Admin users cannot access user-specific onboarding screens
2. **Automatic Redirection**: Users with wrong roles are automatically redirected to their appropriate dashboards
3. **No Data Leakage**: User-specific data (categories, addresses) are only collected from actual users
4. **Clear Separation**: File naming convention (`user_` prefix) makes it clear these are user-specific screens

## Testing Scenarios

### Scenario 1: User tries to access onboarding
- ✅ Allowed
- Shows appropriate onboarding screens based on completion flags

### Scenario 2: Restaurant tries to access `/onboarding/profile`
- ❌ Blocked
- Redirected to `/restaurant-dashboard`

### Scenario 3: NGO tries to access `/onboarding/categories`
- ❌ Blocked
- Redirected to `/ngo/home`

### Scenario 4: Admin tries to access `/onboarding/select-address`
- ❌ Blocked
- Redirected to `/admin-dashboard`

### Scenario 5: Unauthenticated user tries to access onboarding
- ❌ Blocked
- Redirected to `/auth` (handled by main redirect logic)

## Updated Files

1. **Renamed Files**:
   - `user_profile_setup_screen.dart` (formerly `profile_setup_screen.dart`)
   - `user_address_selector_screen.dart` (formerly `onboarding_address_selector_screen.dart`)
   - `user_category_selection_screen.dart` (formerly `category_selection_screen.dart`)

2. **Updated Files**:
   - `app_router.dart` - Added role-based redirect logic to onboarding routes
   - All three renamed screen files - Updated class names

## Database Schema
No changes to database schema. The `is_profile_completed` and `is_onboarding_completed` flags are only checked for users with `role='user'`.

## Migration Notes
- No breaking changes for existing users
- Restaurant, NGO, and Admin users will never see these screens
- Only regular users (role='user') will go through the onboarding flow
- Existing user data remains unchanged

## Code Example

### Before (No Role Filtering)
```dart
GoRoute(
  path: '/onboarding/profile',
  builder: (context, state) => const ProfileSetupScreen(),
),
```

### After (With Role Filtering)
```dart
GoRoute(
  path: '/onboarding/profile',
  builder: (context, state) => const UserProfileSetupScreen(),
  redirect: (context, state) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user?.role != 'user') {
      if (user?.role == 'restaurant') return '/restaurant-dashboard';
      if (user?.role == 'ngo') return '/ngo/home';
      if (user?.role == 'admin') return '/admin-dashboard';
      return '/';
    }
    return null;
  },
),
```

## Summary
- ✅ Files renamed with `user_` prefix
- ✅ Classes renamed to match file names
- ✅ Role-based access control implemented
- ✅ Only users with `role='user'` can access onboarding screens
- ✅ Other roles are automatically redirected to their dashboards
- ✅ No breaking changes for existing functionality
- ✅ Clear separation of user-specific features
