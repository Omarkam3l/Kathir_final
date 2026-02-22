# 🔧 Fix Applied - Compilation Error Resolved

## ❌ Error Encountered

```
lib/features/_shared/router/app_router.dart:132:44: Error: Not a constant expression.
builder: (context, state) => const RestaurantProfileScreen(),
                             ^^^^^^^^^^^^^^^^^^^^^^^
```

## ✅ Fix Applied

**Issue**: The `const` keyword was used incorrectly in the route builder for `RestaurantProfileScreen`.

**Solution**: Removed the `const` keyword from the route builder.

### Before:
```dart
GoRoute(
  path: '/restaurant-dashboard/profile',
  builder: (context, state) => const RestaurantProfileScreen(),
),
```

### After:
```dart
GoRoute(
  path: '/restaurant-dashboard/profile',
  builder: (context, state) => RestaurantProfileScreen(),
),
```

## 🔍 Why This Happened

The `const` keyword can only be used when all constructor arguments are compile-time constants. Since `RestaurantProfileScreen` uses runtime dependencies (like `context.watch<AuthProvider>()`), it cannot be a const widget.

## ✅ Verification

All files now compile without errors:

```
✅ meals_list_screen.dart - No errors
✅ add_meal_screen.dart - No errors
✅ meal_details_screen.dart - No errors
✅ edit_meal_screen.dart - No errors
✅ restaurant_profile_screen.dart - No errors
✅ restaurant_dashboard_screen.dart - No errors
✅ app_router.dart - No errors
```

## 🚀 Next Steps

1. Run `flutter run` to test the application
2. The error should be resolved
3. All navigation should work correctly

## 📝 Note

This is a common issue when using `const` with widgets that have runtime dependencies. The fix is simple: remove the `const` keyword when the widget cannot be a compile-time constant.

---

**Status**: ✅ Fixed  
**Date**: January 30, 2026  
**Ready for**: Testing
