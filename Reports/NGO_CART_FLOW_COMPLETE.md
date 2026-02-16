# NGO Cart & Checkout Flow - COMPLETE ✅

## Issue Fixed
The checkout screen was throwing `ProviderNotFoundException` because it was creating a new `NgoCartViewModel` instance instead of using the existing one from the cart screen.

## Solution Applied
Updated the navigation to pass the cart instance via `extra` parameter:

### 1. Router Update (`app_router.dart`)
```dart
GoRoute(
  path: '/ngo/checkout',
  builder: (context, state) {
    final cart = state.extra as NgoCartViewModel?;
    if (cart != null) {
      return NgoCheckoutScreen(cart: cart);
    }
    // Fallback: create new instance and load
    return ChangeNotifierProvider(
      create: (_) => NgoCartViewModel()..loadCart(),
      child: Consumer<NgoCartViewModel>(
        builder: (context, cart, _) => NgoCheckoutScreen(cart: cart),
      ),
    );
  },
),
```

### 2. Cart Screen Update (`ngo_cart_screen_full.dart`)
```dart
ElevatedButton(
  onPressed: () => context.push('/ngo/checkout', extra: cart),
  // ...
)
```

## Complete Flow

### 1. Add to Cart
- **From Home Screen**: Click "Claim Now" → adds to cart
- **From All Meals Screen**: Click + button → adds to cart
- **From Meal Detail Screen**: Click "Add to Cart" → adds to cart

### 2. View Cart
- Click cart icon in header (any screen)
- Shows all cart items with quantities
- Can update quantities or remove items
- Shows CO₂ savings

### 3. Checkout
- Click "Proceed to Checkout" from cart
- Enter pickup location
- Add optional notes
- Review order summary
- Click "Confirm Pickup"

### 4. Order Creation
- Creates orders in database
- Updates meal quantities
- Clears cart
- Redirects to order summary

### 5. Order Summary
- Shows success message
- Displays order details
- Option to view orders or return home

## Database Migration Required

Run this migration to enable cart functionality:

```bash
# Via Supabase CLI
supabase db push

# Or copy/paste Migrations/007_refactor_cart_for_all_roles.sql into Supabase SQL Editor
```

### What the Migration Does:
1. Renames `user_id` → `profile_id` in cart_items table
2. Updates unique constraint to use profile_id
3. Creates RLS policies for all authenticated users (not just users)
4. Adds indexes for performance

## Testing Checklist

- [ ] Run migration `007_refactor_cart_for_all_roles.sql`
- [ ] Login as NGO user
- [ ] Add meal to cart from home screen
- [ ] View cart - should show 1 item
- [ ] Update quantity in cart
- [ ] Click "Proceed to Checkout"
- [ ] Should NOT see ProviderNotFoundException
- [ ] Enter pickup location
- [ ] Click "Confirm Pickup"
- [ ] Should see order summary
- [ ] Cart should be empty
- [ ] Check orders screen - should show new order

## Files Modified

1. `lib/features/_shared/router/app_router.dart` - Fixed checkout route
2. `lib/features/ngo_dashboard/presentation/screens/ngo_cart_screen_full.dart` - Pass cart to checkout
3. `Migrations/007_refactor_cart_for_all_roles.sql` - Ready to run

## Next Steps

1. Run the migration
2. Test the complete flow
3. Verify cart persists across app restarts
4. Verify cart clears after order confirmation

## Notes

- All cart operations are now database-backed
- Cart works for all roles (users, NGOs, restaurants)
- RLS policies ensure users only see their own cart
- Cart is automatically loaded when screens mount
- All operations are async and properly awaited
