# Quantity Display and Meal Detail Screen Fixes

## Issues Fixed

### 1. Quantity Display Showing "0 portions"
**Problem**: The quantity was always showing as "0 portions" in meal cards and dialogs.

**Root Cause**: Database field mismatch - the database uses `quantity_available` but the model expects `quantity`.

**Solution**: Updated both viewmodels to properly map the database field:
```dart
json['quantity'] = json['quantity_available']; // Fix quantity mapping
```

**Files Modified**:
- `lib/features/ngo_dashboard/presentation/viewmodels/ngo_home_viewmodel.dart`
- `lib/features/ngo_dashboard/presentation/viewmodels/ngo_map_viewmodel.dart`

### 2. View Details Button - Full Screen UI
**Problem**: "View Details" button was showing a simple AlertDialog instead of a full-screen detail page like the user's meal detail screen.

**Solution**: 
1. Created new full-screen detail screen: `ngo_meal_detail_screen.dart`
2. Replicated the user's `ProductDetailPage` UI but adapted for NGO context
3. Changed "Add to Cart" button to "Claim Now" button
4. Updated all meal cards to navigate to the full detail screen

**New File Created**:
- `lib/features/ngo_dashboard/presentation/screens/ngo_meal_detail_screen.dart`

**Files Modified**:
- `lib/features/ngo_dashboard/presentation/widgets/ngo_meal_card.dart` - Changed from dialog to navigation
- `lib/features/ngo_dashboard/presentation/widgets/ngo_map_meal_card.dart` - Added "Details" button
- `lib/features/ngo_dashboard/presentation/widgets/ngo_urgent_card.dart` - Added "Details" button
- `lib/features/_shared/router/app_router.dart` - Added route `/ngo/meal/:id`

## Features of New Detail Screen

### UI Components
1. **Hero Image** with back button overlay
2. **Title and Price** section with original price strikethrough
3. **Restaurant Info** with rating and verification badge
4. **Info Cards**:
   - Pickup time with orange badge
   - CO2 impact with green badge
5. **Quantity Alert** showing available portions
6. **Description** section
7. **Ingredients & Allergens** tags (if available)
8. **Pickup Location** display
9. **Sticky Bottom Bar** with "Claim Now" button

### Key Differences from User Screen
- Uses `AppColors.primaryGreen` instead of `AppColors.primary`
- Button text is "Claim Now" instead of "Add to Cart"
- Shows "DONATION" label instead of "TOTAL"
- Removed favorite button (not needed for NGO)
- Removed quantity selector (NGOs claim full portions)
- Shows "Available: X portions" instead of "Only X portions left"

## Navigation Flow

### From Home Screen
1. User taps "View Details" on any meal card
2. Navigates to `/ngo/meal/:id` with meal data
3. Full-screen detail page opens with Hero animation
4. User can view all details and claim meal

### From Map Screen
1. User taps "Details" button on carousel card
2. Same navigation flow as home screen
3. Returns to map after claiming or going back

### From Urgent Section
1. User taps "Details" button on urgent card
2. Same navigation flow
3. Shows expiring meals with time remaining

## Database Field Mappings

```dart
// Database → Model mappings
json['donation_price'] = json['discounted_price'];
json['quantity'] = json['quantity_available'];
json['expiry'] = json['expiry_date'];
```

## Testing Checklist

- [x] Quantity displays correctly (not 0)
- [x] View Details navigates to full screen
- [x] Hero animation works on image
- [x] Claim button shows loading state
- [x] Price displays correctly (EGP or Free)
- [x] All navigation works from all screens
- [x] Back button returns to previous screen
- [x] No compilation errors

## Route Configuration

```dart
GoRoute(
  path: '/ngo/meal/:id',
  builder: (context, state) {
    final extra = state.extra;
    if (extra is Meal) {
      return NgoMealDetailScreen(meal: extra);
    }
    return const Scaffold(
      body: Center(child: Text('Meal not found')),
    );
  },
),
```

## Summary

Both issues have been resolved:
1. ✅ Quantity now displays actual available portions from database
2. ✅ View Details shows professional full-screen UI matching user experience
3. ✅ All meal cards (home, map, urgent) have consistent navigation
4. ✅ NGO-specific branding and terminology throughout

The NGO dashboard now provides a complete, professional meal viewing and claiming experience that matches the quality of the user interface.
