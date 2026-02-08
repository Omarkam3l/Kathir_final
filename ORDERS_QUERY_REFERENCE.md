# Orders System - Query Reference

## Correct Field Names for Queries

### Orders Table
- `delivery_type` (NOT `delivery_method`) - Values: 'pickup', 'delivery', 'donation'
- `status` - Order status enum
- `pickup_code` - 6-character alphanumeric code
- `qr_code` - QR code JSON data
- `special_instructions` - Customer instructions
- `estimated_ready_time` - Estimated ready time
- `actual_ready_time` - Actual ready time
- `picked_up_at` - Pickup timestamp
- `delivered_at` - Delivery timestamp
- `cancelled_at` - Cancellation timestamp
- `rating` - Customer rating (1-5)
- `review_text` - Customer review

### Restaurants Table (via foreign key join)
- `profile_id` - Restaurant's profile ID
- `restaurant_name` - Restaurant name
- `address_text` - Restaurant address
- `phone` (NOT `phone_number`) - Restaurant phone number
- `rating` - Restaurant rating
- `min_order_price` - Minimum order price

### Profiles Table (for user info)
- `id` - User ID
- `full_name` - User's full name
- `phone_number` - User's phone number
- `email` - User's email
- `avatar_url` - User's avatar URL

### Order Items Table
- `id` - Order item ID
- `order_id` - Reference to orders table
- `meal_id` - Reference to meals table
- `quantity` - Quantity ordered
- `unit_price` (NOT `price`) - Price per unit

### Meals Table (via foreign key join)
- `id` - Meal ID
- `title` - Meal title
- `image_url` - Meal image URL
- `description` - Meal description
- `category` - Meal category

## Correct Query Syntax

### User Orders Query (My Orders Screen)
```dart
final response = await _supabase
    .from('orders')
    .select('''
      *,
      restaurants!restaurant_id(profile_id, restaurant_name, address_text),
      order_items(
        id,
        quantity,
        unit_price,
        meals!meal_id(id, title, image_url)
      )
    ''')
    .eq('user_id', userId)
    .inFilter('status', ['pending', 'confirmed', 'preparing'])
    .order('created_at', ascending: false);
```

### Order Tracking Query
```dart
final response = await _supabase
    .from('orders')
    .select('''
      *,
      restaurants!restaurant_id(profile_id, restaurant_name, address_text, phone),
      order_items(
        id,
        quantity,
        unit_price,
        meals!meal_id(id, title, image_url)
      )
    ''')
    .eq('id', orderId)
    .single();
```

### Restaurant Orders Query
```dart
final response = await _supabase
    .from('orders')
    .select('''
      *,
      order_items(
        id,
        quantity,
        unit_price,
        meals!meal_id(title, image_url)
      ),
      profiles!user_id(full_name, phone_number)
    ''')
    .eq('restaurant_id', restaurantId)
    .order('created_at', ascending: false);
```

### Restaurant Order Detail Query
```dart
final response = await _supabase
    .from('orders')
    .select('''
      *,
      profiles!user_id(full_name, phone_number),
      order_items(
        id,
        quantity,
        unit_price,
        meals!meal_id(id, title, image_url)
      )
    ''')
    .eq('id', orderId)
    .single();
```

## Foreign Key Join Syntax

### Correct Syntax
- `restaurants!restaurant_id(...)` - Join restaurants table via restaurant_id foreign key
- `profiles!user_id(...)` - Join profiles table via user_id foreign key
- `meals!meal_id(...)` - Join meals table via meal_id foreign key

### Incorrect Syntax (DO NOT USE)
- `restaurant:restaurant_id(...)` - Old syntax, will fail
- `meal_id(...)` - Missing table name and `!`, will fail
- `user_id(...)` - Missing table name and `!`, will fail

## Common Errors and Solutions

### Error: "column restaurants_1.phone_number does not exist"
**Solution:** Use `phone` instead of `phone_number` in restaurants join

### Error: "Could not find a relationship between 'orders' and 'meal_id'"
**Solution:** Use `meals!meal_id(...)` instead of `meal_id(...)`

### Error: "column order_items_1.price does not exist"
**Solution:** Use `unit_price` instead of `price` in order_items

### Error: "The method 'in_' isn't defined"
**Solution:** Use `inFilter()` instead of `.in_()`

## Field Access in Dart Code

### Accessing Restaurant Data
```dart
final restaurant = order['restaurants'] as Map<String, dynamic>?;
final restaurantName = restaurant?['restaurant_name'] ?? 'Restaurant';
final restaurantPhone = restaurant?['phone'] ?? '';
final restaurantAddress = restaurant?['address_text'] ?? '';
```

### Accessing User/Customer Data
```dart
final customer = order['profiles'] as Map<String, dynamic>?;
final customerName = customer?['full_name'] ?? 'Customer';
final customerPhone = customer?['phone_number'] ?? '';
```

### Accessing Order Items
```dart
final orderItems = order['order_items'] as List<dynamic>? ?? [];
for (final item in orderItems) {
  final meal = item['meals'] as Map<String, dynamic>?;
  final mealTitle = meal?['title'] ?? 'Item';
  final quantity = item['quantity'] ?? 1;
  final price = item['unit_price'] ?? 0.0;
}
```

### Accessing Order Fields
```dart
final status = order['status'] as String;
final deliveryType = order['delivery_type'] as String?; // NOT delivery_method
final pickupCode = order['pickup_code'] as String?;
final qrCode = order['qr_code'] as String?;
final specialInstructions = order['special_instructions'] as String?;
final totalAmount = order['total_amount'] ?? 0.0;
```

## Status Values

### Order Status Enum
- `pending` - Order placed, awaiting confirmation
- `confirmed` - Order confirmed by restaurant
- `preparing` - Restaurant is preparing the order
- `ready_for_pickup` - Order ready for customer pickup
- `out_for_delivery` - Order is being delivered
- `delivered` - Order delivered to customer
- `completed` - Order completed (picked up or delivered)
- `cancelled` - Order cancelled

### Delivery Type Values
- `pickup` - Customer will pick up the order
- `delivery` - Order will be delivered to customer
- `donation` - Order is a donation to NGO

## Important Notes

1. **Always use `!` for foreign key joins**: `restaurants!restaurant_id`, not `restaurant:restaurant_id`
2. **Use correct field names**: `delivery_type` not `delivery_method`, `phone` not `phone_number` (for restaurants)
3. **Use `inFilter()` not `.in_()`**: The `.in_()` method doesn't exist in the current Supabase version
4. **Check nested data structure**: Restaurant data is nested under `restaurants` key, user data under `profiles` key
5. **Handle null values**: Always use null-aware operators (`??`, `?.`) when accessing nested data

## Testing Queries

To test if a query is correct, you can use the Supabase SQL editor:

```sql
-- Test user orders query
SELECT 
  o.*,
  r.restaurant_name,
  r.address_text,
  r.phone
FROM orders o
LEFT JOIN restaurants r ON o.restaurant_id = r.profile_id
WHERE o.user_id = 'user-uuid-here';

-- Test order items query
SELECT 
  oi.*,
  m.title,
  m.image_url
FROM order_items oi
LEFT JOIN meals m ON oi.meal_id = m.id
WHERE oi.order_id = 'order-uuid-here';
```

## Files Updated

All queries have been fixed in:
- `lib/features/orders/presentation/screens/my_orders_screen_new.dart`
- `lib/features/orders/presentation/screens/order_tracking_screen.dart`
- `lib/features/orders/presentation/screens/order_qr_screen.dart`
- `lib/features/restaurant_dashboard/presentation/screens/restaurant_orders_screen.dart`
- `lib/features/restaurant_dashboard/presentation/screens/restaurant_order_detail_screen.dart`
- `lib/features/restaurant_dashboard/presentation/widgets/active_order_card.dart`
