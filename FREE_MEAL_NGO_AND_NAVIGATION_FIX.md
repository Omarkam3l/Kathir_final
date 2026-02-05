# Free Meal Notifications - NGO Support & Navigation Fix ✅

## Issues Fixed

### Issue 1: NGOs Not Receiving Free Meal Notifications
**Problem:** Free meal notifications were only sent to users with role='user', not to NGOs.

**Solution:** Updated the `donate_meal()` function to include NGOs:
```sql
-- OLD: WHERE role = 'user'
-- NEW: WHERE role IN ('user', 'ngo')
```

**Files Modified:**
- `supabase/migrations/20260205_free_meal_notifications_system.sql`

### Issue 2: Meal Detail Screen Showing Empty/Old Data
**Problem:** When clicking "Claim Now" from notifications, the meal detail screen showed an empty meal object instead of the real meal data.

**Root Cause:** The navigation was only passing the meal ID (`context.push('/meal/${mealId}')`), but the route expected a full `MealOffer` object in the `extra` parameter. Without it, the route fallback created an empty meal object.

**Solution:** Fetch the complete meal data from the database before navigating:

**For User Notifications:**
```dart
// Fetch full meal data
final mealResponse = await _supabase
    .from('meals')
    .select('*, restaurants:restaurant_id (...)')
    .eq('id', notification.mealId)
    .single();

// Create MealOffer object
final mealOffer = MealOffer(...);

// Navigate with full data
context.push('/meal/${notification.mealId}', extra: mealOffer);
```

**For NGO Notifications:**
```dart
// Fetch full meal data
final mealResponse = await _supabase
    .from('meals')
    .select('*, restaurants:restaurant_id (...)')
    .eq('id', notification.mealId)
    .single();

// Create Meal map for NGO screen
final meal = {...};

// Navigate with full data
context.push('/ngo-meal-detail', extra: meal);
```

**Files Modified:**
- `lib/features/profile/presentation/screens/notifications_screen_new.dart`
  - Updated `_buildFreeMealCard()` GestureDetector onTap
  - Updated "Claim Now" button onPressed
- `lib/features/ngo_dashboard/presentation/screens/ngo_notifications_screen.dart`
  - Added `_freeMealNotifications` list
  - Updated `_loadNotifications()` to fetch free meals
  - Added `_markFreeMealAsRead()` function
  - Updated `_markAllAsRead()` for both types
  - Updated unread count calculation
  - Added free meal notifications section to UI
  - Added `_buildSectionHeader()` widget
  - Added `_buildFreeMealCard()` widget
  - Added `FreeMealNotification` class
  - Updated both navigation handlers to fetch full meal data

## Features Now Working

### For Users:
✅ Receive free meal notifications
✅ See special UI for free meals (gradient, FREE badge, quantity indicators)
✅ Click "Claim Now" to see correct meal details
✅ Navigate to meal detail with full data (price, image, restaurant, etc.)

### For NGOs:
✅ Receive free meal notifications (same as users)
✅ See special UI for free meals in notifications tab
✅ Click "Claim Now" to see correct meal details
✅ Navigate to NGO meal detail screen with full data
✅ Can claim free meals for distribution

## Database Changes

### Updated Function:
```sql
CREATE OR REPLACE FUNCTION public.donate_meal(...)
-- Now notifies both users AND NGOs
WHERE role IN ('user', 'ngo')  -- Changed from role = 'user'
```

## Testing Checklist

- [x] NGOs receive free meal notifications
- [x] Users receive free meal notifications
- [x] Free meal cards display correctly for both
- [x] "Claim Now" button fetches fresh meal data
- [x] Navigation to meal detail shows correct data
- [x] Free meals show EGP 0.00 price
- [x] Meal images display correctly
- [x] Restaurant info displays correctly
- [x] Quantity indicators work
- [x] Mark as read works for both users and NGOs
- [x] Unread count includes free meals

## Status: ✅ COMPLETE

Both issues are now fixed:
1. NGOs receive free meal notifications
2. Meal detail screen shows correct, fresh data when navigating from notifications
