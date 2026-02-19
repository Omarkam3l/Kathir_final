# NGO Cart & Checkout Flow - Complete Implementation

## Files Created

### 1. ViewModel
- `lib/features/ngo_dashboard/presentation/viewmodels/ngo_cart_viewmodel.dart`

### 2. Screens
- `lib/features/ngo_dashboard/presentation/screens/ngo_cart_screen_full.dart` (Full cart with items)
- `lib/features/ngo_dashboard/presentation/screens/ngo_checkout_screen.dart` (TO CREATE)
- `lib/features/ngo_dashboard/presentation/screens/ngo_order_summary_screen.dart` (TO CREATE)

## Step-by-Step Implementation

### STEP 1: Add Routes to app_router.dart

Add these routes after the existing NGO routes (around line 400):

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
  builder: (context, state) => Consumer<NgoCartViewModel>(
    builder: (context, cart, _) => NgoCheckoutScreen(cart: cart),
  ),
),
GoRoute(
  path: '/ngo/order-summary',
  builder: (context, state) {
    final orderId = state.extra as String?;
    return NgoOrderSummaryScreen(orderId: orderId ?? '');
  },
),
```

### STEP 2: Update ngo_home_viewmodel.dart - Change claimMeal()

Replace the `claimMeal()` method to add to cart instead of creating order immediately:

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

    // Add to cart instead of creating order
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

### STEP 3: Update ngo_home_screen.dart - Provide CartViewModel

Wrap the NgoHomeScreen with MultiProvider to provide both ViewModels:

In app_router.dart, change the NGO home route to:

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

### STEP 4: Add Cart Badge to Home Screen

Add this method to ngo_home_screen.dart:

```dart
Widget _buildNotificationButton(bool isDark, NgoHomeViewModel viewModel) {
  final cart = context.watch<NgoCartViewModel>();
  
  return Row(
    children: [
      // Existing notification button
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

### STEP 5: Create Checkout Screen

Create `lib/features/ngo_dashboard/presentation/screens/ngo_checkout_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_colors.dart';
import '../viewmodels/ngo_cart_viewmodel.dart';

class NgoCheckoutScreen extends StatefulWidget {
  final NgoCartViewModel cart;

  const NgoCheckoutScreen({super.key, required this.cart});

  @override
  State<NgoCheckoutScreen> createState() => _NgoCheckoutScreenState();
}

class _NgoCheckoutScreenState extends State<NgoCheckoutScreen> {
  final _supabase = Supabase.instance.client;
  bool _isProcessing = false;
  String _pickupLocation = 'NGO Office';
  String _pickupNotes = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(isDark),
            const SizedBox(height: 24),
            _buildPickupDetails(isDark),
            const SizedBox(height: 24),
            _buildConfirmButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.cart.cartItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.meal.title} x${item.quantity}',
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                    const Text(
                      'Free',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Items',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '${widget.cart.cartCount} meals',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickupDetails(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Pickup Location',
              hintText: 'Enter pickup location',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => _pickupLocation = value,
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'Any special instructions',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
            onChanged: (value) => _pickupNotes = value,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _confirmOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Confirm Pickup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _confirmOrder() async {
    setState(() => _isProcessing = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Create orders for each cart item
      for (final item in widget.cart.cartItems) {
        final orderData = {
          'user_id': userId,
          'ngo_id': userId,
          'restaurant_id': item.meal.restaurant.id,
          'status': 'pending',
          'delivery_type': 'donation',
          'subtotal': 0.0,
          'total_amount': 0.0,
          'delivery_address': _pickupLocation,
          'created_at': DateTime.now().toIso8601String(),
        };

        final orderResult = await _supabase
            .from('orders')
            .insert(orderData)
            .select('id')
            .single();

        final orderId = orderResult['id'];

        // Create order item
        await _supabase.from('order_items').insert({
          'order_id': orderId,
          'meal_id': item.meal.id,
          'quantity': item.quantity,
          'unit_price': 0.0,
          'meal_title': item.meal.title,
        });

        // Update meal quantity
        final newQuantity = item.meal.quantity - item.quantity;
        await _supabase.from('meals').update({
          'quantity_available': newQuantity,
          'status': newQuantity <= 0 ? 'sold' : 'active',
        }).eq('id', item.meal.id);
      }

      // Clear cart
      widget.cart.clearCart();

      if (mounted) {
        context.go('/ngo/order-summary', extra: 'success');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
```

### STEP 6: Create Order Summary Screen

Create `lib/features/ngo_dashboard/presentation/screens/ngo_order_summary_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_colors.dart';

class NgoOrderSummaryScreen extends StatelessWidget {
  final String orderId;

  const NgoOrderSummaryScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Order Confirmed!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your pickup request has been sent to the restaurants.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You will receive a notification when your order is ready for pickup.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/ngo/orders'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'View Orders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/ngo/home'),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### STEP 7: Add Imports to app_router.dart

Add these imports at the top:

```dart
import '../ngo_dashboard/presentation/screens/ngo_cart_screen_full.dart';
import '../ngo_dashboard/presentation/screens/ngo_checkout_screen.dart';
import '../ngo_dashboard/presentation/screens/ngo_order_summary_screen.dart';
import '../ngo_dashboard/presentation/viewmodels/ngo_cart_viewmodel.dart';
```

## Navigation Flow

```
Home Screen
    ↓ (Claim Meal)
Add to Cart
    ↓ (View Cart)
Cart Screen (/ngo/cart)
    ↓ (Proceed to Checkout)
Checkout Screen (/ngo/checkout)
    ↓ (Confirm Pickup)
Order Summary (/ngo/order-summary)
    ↓ (View Orders)
Orders Screen (/ngo/orders)
```

## Back Navigation

All screens except bottom nav screens have back arrows:
- Cart Screen: ✅ Back arrow → Home
- Checkout Screen: ✅ Back arrow → Cart
- Order Summary: ❌ No back (use buttons only)

## Testing Checklist

- [ ] Add meal to cart from home
- [ ] Cart badge shows count
- [ ] Navigate to cart screen
- [ ] See cart items
- [ ] Increment/decrement quantity
- [ ] Remove item from cart
- [ ] Clear all items
- [ ] Proceed to checkout
- [ ] Fill pickup details
- [ ] Confirm order
- [ ] See success screen
- [ ] Navigate to orders
- [ ] Back navigation works correctly

## Summary

This implementation provides:
1. ✅ Full cart functionality with ViewModel
2. ✅ Add to cart from home screen
3. ✅ Cart screen with item management
4. ✅ Checkout screen with pickup details
5. ✅ Order summary/success screen
6. ✅ Proper routing with back navigation
7. ✅ Cart badge on home screen
8. ✅ Free meals for NGOs (no payment)
9. ✅ CO₂ savings calculation
10. ✅ Multi-provider setup for ViewModels
