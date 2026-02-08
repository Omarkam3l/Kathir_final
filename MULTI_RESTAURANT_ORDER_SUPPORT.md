# Multi-Restaurant Order Support

## Overview
Updated the order system to support ordering from multiple restaurants in a single checkout session.

## Previous Limitation
The old system only supported ordering from **ONE restaurant at a time**:
```dart
// Old code - WRONG
final restaurantId = items.first.meal.restaurant.id; // Only first restaurant!
```

**Problem:** If you added meals from Restaurant A and Restaurant B to your cart, only Restaurant A would receive the order with ALL items (including Restaurant B's items).

## New Solution
The system now **automatically splits orders by restaurant**:

### How It Works

1. **Cart Grouping**
   - When you checkout, the system groups cart items by restaurant
   - Example: 3 items from Restaurant A + 2 items from Restaurant B = 2 separate orders

2. **Separate Orders Created**
   - Each restaurant gets their own order
   - Each order has its own:
     - Order ID
     - Order number
     - Pickup code
     - QR code
     - Status tracking

3. **Proportional Fee Distribution**
   - Service fees and delivery fees are split proportionally based on each restaurant's subtotal
   - Example:
     - Restaurant A: EGP 100 (67% of total)
     - Restaurant B: EGP 50 (33% of total)
     - Service fee EGP 15 → Restaurant A gets EGP 10, Restaurant B gets EGP 5

4. **Independent Status Updates**
   - Each restaurant can update their order status independently
   - Restaurant A can mark their order as "ready_for_pickup" while Restaurant B is still "preparing"
   - User sees separate orders in "My Orders" screen

## User Experience

### Checkout Flow
1. User adds meals from multiple restaurants to cart
2. User proceeds to checkout
3. System creates separate orders automatically
4. User sees confirmation:
   - **Single restaurant:** Navigate to order summary
   - **Multiple restaurants:** Show success message "2 orders created successfully!" and navigate to My Orders screen

### My Orders Screen
- User sees **separate order cards** for each restaurant
- Each order can be tracked independently
- Each order has its own QR code when ready for pickup

### Restaurant Dashboard
- Each restaurant only sees **their own orders**
- Restaurant A cannot see or modify Restaurant B's orders
- Each restaurant updates their order status independently

## Database Structure

### Orders Table
Each order belongs to ONE restaurant:
```sql
orders (
  id UUID,
  user_id UUID,
  restaurant_id UUID,  -- Single restaurant per order
  order_number TEXT,
  status order_status,
  subtotal NUMERIC,
  service_fee NUMERIC,
  delivery_fee NUMERIC,
  platform_fee NUMERIC,
  total_amount NUMERIC,
  ...
)
```

### Order Items Table
Links meals to their respective orders:
```sql
order_items (
  id UUID,
  order_id UUID,        -- Links to specific restaurant's order
  meal_id UUID,
  quantity INTEGER,
  unit_price NUMERIC,
  ...
)
```

## Real-Time Updates

### User Side
- Subscribes to ALL their orders
- Sees real-time status updates for each restaurant independently
- Can track multiple orders simultaneously

### Restaurant Side
- Each restaurant subscribes only to their own orders
- Updates their order status without affecting other restaurants' orders
- Sees only orders containing their meals

## Example Scenario

**User's Cart:**
- 2x Pizza from "Pizza Palace" (EGP 50)
- 1x Burger from "Burger King" (EGP 25)
- 1x Pasta from "Pizza Palace" (EGP 30)

**System Creates:**

**Order 1 - Pizza Palace:**
- Items: 2x Pizza, 1x Pasta
- Subtotal: EGP 80
- Service Fee: EGP 8 (proportional)
- Delivery Fee: EGP 16 (proportional)
- Total: EGP 104
- Status: Independent tracking
- QR Code: Unique for Pizza Palace

**Order 2 - Burger King:**
- Items: 1x Burger
- Subtotal: EGP 25
- Service Fee: EGP 2.5 (proportional)
- Delivery Fee: EGP 5 (proportional)
- Total: EGP 32.5
- Status: Independent tracking
- QR Code: Unique for Burger King

**User Experience:**
- Sees 2 separate orders in "My Orders"
- Can track each order independently
- Pizza Palace marks ready → User gets QR code for Pizza Palace
- Burger King still preparing → User sees "Preparing" status
- Each restaurant updates their order independently

## Benefits

### For Users
✅ Order from multiple restaurants in one session
✅ Track each order independently
✅ Get separate QR codes for each restaurant
✅ Clear visibility of each restaurant's order status

### For Restaurants
✅ Only see and manage their own orders
✅ Update status without affecting other restaurants
✅ Clear order items (only their meals)
✅ Accurate revenue tracking per restaurant

### For Platform
✅ Accurate fee distribution per restaurant
✅ Better analytics (orders per restaurant)
✅ Scalable architecture
✅ Clear audit trail

## Technical Implementation

### Files Modified
1. **`lib/features/checkout/data/services/order_service.dart`**
   - Changed return type from `Map` to `List<Map>` (multiple orders)
   - Added restaurant grouping logic
   - Added proportional fee calculation
   - Creates separate order for each restaurant

2. **`lib/features/checkout/presentation/screens/checkout_screen.dart`**
   - Updated to handle multiple order results
   - Shows appropriate success message
   - Navigates to correct screen based on order count

### Key Functions

**`createOrder()` - Updated**
```dart
Future<List<Map<String, dynamic>>> createOrder({...}) async {
  // Group items by restaurant
  final Map<String, List<CartItem>> itemsByRestaurant = {};
  
  // Create separate order for each restaurant
  for (final entry in itemsByRestaurant.entries) {
    // Calculate proportional fees
    // Create order
    // Create order items
    // Update meal quantities
  }
  
  return createdOrders; // List of all created orders
}
```

## Testing Checklist

- [ ] Add meals from single restaurant → Creates 1 order
- [ ] Add meals from 2 restaurants → Creates 2 orders
- [ ] Add meals from 3+ restaurants → Creates 3+ orders
- [ ] Verify fees are split proportionally
- [ ] Verify each restaurant sees only their order
- [ ] Verify user sees all orders separately
- [ ] Test status updates work independently
- [ ] Test QR codes are unique per order
- [ ] Test real-time updates work for each order
- [ ] Verify meal quantities are updated correctly
- [ ] Verify cart is cleared after all orders created

## Migration Notes

**No database migration required!** The existing schema already supports this:
- Orders table has `restaurant_id` (one restaurant per order)
- Order items table links to specific orders
- All relationships are already correct

The change is purely in the application logic - we now create multiple orders instead of one.

## Future Enhancements

1. **Batch Order Summary Screen**
   - Show all orders created in one checkout
   - Combined tracking view
   - Total amount across all orders

2. **Smart Fee Optimization**
   - Combine delivery if restaurants are nearby
   - Offer discounts for multi-restaurant orders

3. **Order Bundling**
   - Allow users to request combined delivery
   - Coordinate pickup times across restaurants

4. **Analytics Dashboard**
   - Track multi-restaurant order patterns
   - Identify popular restaurant combinations
   - Optimize platform fees
