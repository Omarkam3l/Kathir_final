# NGO Cart & Checkout - Complete Implementation Guide

## ✅ Files Created

### ViewModels
1. `lib/features/ngo_dashboard/presentation/viewmodels/ngo_cart_viewmodel.dart` ✅

### Screens
2. `lib/features/ngo_dashboard/presentation/screens/ngo_cart_screen_full.dart` ✅
3. `lib/features/ngo_dashboard/presentation/screens/ngo_checkout_screen.dart` ✅
4. `lib/features/ngo_dashboard/presentation/screens/ngo_order_summary_screen.dart` ✅

## 🔧 Required Changes to Existing Files

### 1. Update `lib/features/_shared/router/app_router.dart`

**Add imports at the top:**
```dart
import '../ngo_dashboard/presentation/screens/ngo_cart_screen_full.dart';
import '../ngo_dashboard/presentation/screens/ngo_checkout_screen.dart';
import '../ngo_dashboard/presentation/screens/ngo_order_summary_screen.dart';
import '../ngo_dashboard/presentation/viewmodels/ngo_cart_viewmodel.dart';
```

**Replace the existing NGO home route (around line 327):**
```dart
GoRoute(
  path: '/ngo/home',
  builder: (context, state) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => NgoHomeViewModel()),
      ChangeNotifierProvider(create: (_) => NgoCartViewModel()),
    ],
    child: const NgoHomeScreen(),
  ),
),
```

**Add new routes after the existing NGO routes (around line 400):**
```dart
// NGO Cart Routes
GoRoute(
  path: '/ngo/cart',
  builder: (context, state) => ChangeNotifierProvider(
    create: (_) => NgoCartViewModel(),
    child: const NgoCartScreenFull(),
  ),
),
GoRoute(
  path: '/ngo/checkout',
  builder: (context, state) {
    final cart = context.read<NgoCartViewModel>();
    return NgoCheckoutScreen(cart: cart);
  },
),
GoRoute(
  path: '/ngo/order-summary',
  builder: (context, state) {
    final orderId = state.extra as String?;
    return NgoOrderSummaryScreen(orderId: orderId ?? '');
  },
),
```

### 2. Update `lib/features/ngo_dashboard/presentation/viewmodels/ngo_home_viewmodel.dart`

**Replace the entire `claimMeal()` method:**

```dart
Future<void> claimMeal(Meal meal, BuildContext context) async {
  try {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Verify NGO record exists
    final ngoCheck = await _supabase
        .from('ngos')
        .select('profile_id')
        .eq('profile_id', userId)
        .maybeSingle();

    if (ngoCheck == null) {
      throw Exception('NGO profile not found. Please complete your profile setup.');
    }

    // Check if meal is still available
    final mealCheck = await _supabase
        .from('meals')
        .select('id, quantity_available, status')
        .eq('id', meal.id)
        .maybeSingle();

    if (mealCheck == null) {
      throw Exception('Meal not found');
    }

    if (mealCheck['status'] != 'active') {
      throw Exception('This meal is no longer available');
    }

    if (((mealCheck['quantity_available'] as int?) ?? 0) <= 0) {
      throw Exception('This meal is out of stock');
    }

    // Add to cart instead of creating order immediately
    final cartViewModel = context.read<NgoCartViewModel>();
    cartViewModel.addToCart(meal);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Added to cart: ${meal.title}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () => context.go('/ngo/cart'),
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint('❌ Error adding to cart: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
```

### 3. Update `lib/features/ngo_dashboard/presentation/screens/ngo_home_screen.dart`

**Replace the `_buildNotificationButton()` method to add cart badge:**

```dart
Widget _buildNotificationButton(bool isDark, NgoHomeViewModel viewModel) {
  final cart = context.watch<NgoCartViewModel>();
  
  return Row(
    children: [
      // Notification button
      GestureDetector(
        onTap: () => context.go('/ngo-notifications'),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2E22) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
              ),
              child: const Icon(Icons.notifications_outlined, size: 20),
            ),
            if (viewModel.hasNotifications)
              Positioned(
                top: 8,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1A2E22) : Colors.white,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      // Cart button with badge
      GestureDetector(
        onTap: () => context.go('/ngo/cart'),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2E22) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
              ),
              child: const Icon(Icons.shopping_cart_outlined, size: 20),
            ),
            if (cart.cartCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    '${cart.cartCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
```

**Update the header Row to use the new notification button:**

Find this line (around line 170):
```dart
Row(
  children: [
    _buildNotificationButton(isDark, viewModel),
    const SizedBox(width: 12),
    _buildMapButton(isDark),
  ],
),
```

It should now show: Notifications | Cart | Map

## 📱 Navigation Flow

```
┌─────────────────────────────────────────────────┐
│                  NGO Home Screen                 │
│  [Notifications] [Cart Badge] [Map]             │
│                                                  │
│  Click "Claim" on meal → Adds to cart           │
│  Shows snackbar with "View Cart" action         │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│              Cart Screen (/ngo/cart)             │
│  [← Back]  My Cart                  [Clear All] │
│                                                  │
│  • List of cart items                           │
│  • Quantity controls (+/-)                      │
│  • Remove items                                 │
│  • Bill summary                                 │
│  • [Proceed to Checkout] button                 │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│          Checkout Screen (/ngo/checkout)         │
│  [← Back]  Checkout                             │
│                                                  │
│  • Order summary                                │
│  • Pickup location input                        │
│  • Notes (optional)                             │
│  • [Confirm Pickup] button                      │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│      Order Summary (/ngo/order-summary)          │
│                                                  │
│  ✓ Order Confirmed!                             │
│                                                  │
│  Your pickup request has been sent              │
│                                                  │
│  [View Orders]                                  │
│  [Back to Home]                                 │
└─────────────────────────────────────────────────┘
```

## 🔙 Back Navigation

| Screen | Has Back Arrow | Action |
|--------|---------------|---------|
| Home | ❌ No | Bottom nav screen |
| Cart | ✅ Yes | → Home |
| Checkout | ✅ Yes | → Cart |
| Order Summary | ❌ No | Use buttons only |

## 🧪 Testing Steps

1. **Add to Cart**
   - [ ] Go to NGO home screen
   - [ ] Click "Claim" on a meal
   - [ ] See success snackbar
   - [ ] Cart badge shows count

2. **View Cart**
   - [ ] Click cart icon in header
   - [ ] See cart screen with items
   - [ ] Back arrow works

3. **Manage Cart**
   - [ ] Increment quantity
   - [ ] Decrement quantity
   - [ ] Remove item
   - [ ] Clear all items

4. **Checkout**
   - [ ] Click "Proceed to Checkout"
   - [ ] See checkout screen
   - [ ] Fill pickup location
   - [ ] Add notes (optional)
   - [ ] Click "Confirm Pickup"

5. **Order Confirmation**
   - [ ] See success screen
   - [ ] Click "View Orders"
   - [ ] Click "Back to Home"

6. **Navigation**
   - [ ] Back from cart → home
   - [ ] Back from checkout → cart
   - [ ] Bottom nav works on all screens

## 📊 Features Implemented

✅ Cart ViewModel with state management
✅ Add to cart from home screen
✅ Cart badge with item count
✅ Full cart screen with item management
✅ Quantity increment/decrement
✅ Remove items from cart
✅ Clear all items
✅ Checkout screen with pickup details
✅ Order creation for multiple items
✅ Order summary/success screen
✅ Proper back navigation
✅ Free meals for NGOs (no payment)
✅ CO₂ savings calculation
✅ Multi-provider setup
✅ Loading states
✅ Error handling
✅ Snackbar notifications

## 🚀 Deployment

1. **Apply all code changes above**
2. **Hot restart** the app (not hot reload)
3. **Test the complete flow**
4. **Verify back navigation**

## 📝 Notes

- All meals are FREE for NGOs (donation)
- No payment screen needed
- Cart persists during session only
- Orders created immediately on checkout
- Meal quantities updated in database
- Multiple orders created (one per restaurant)

## ✅ Summary

This implementation provides a complete cart and checkout flow for NGOs, matching the user experience but adapted for free meal donations. The flow is intuitive with proper back navigation and clear visual feedback at each step.

**Status:** Ready for Testing 🎉
