# NGO Dashboard Pricing Fix

## Problem
All meals were showing as FREE for NGOs, regardless of whether the restaurant actually donated them or set a discounted price. Additionally, the order workflow was hardcoding all prices to 0.

## Root Causes

### 1. Data Loading Issue
In `ngo_home_viewmodel.dart`, line 301 was overwriting the original price:
```dart
json['original_price'] = json['discounted_price'];  // ❌ WRONG
```

### 2. Order Workflow Issues
- Cart screen hardcoded "Free" for subtotal
- Checkout screen hardcoded all prices to 0.0
- Order creation always set `unit_price: 0.0` and `total_amount: 0.0`
- No grouping by restaurant (created separate orders for each item)

## Solution

### 1. Fixed Data Loading (ngo_home_viewmodel.dart)
**Removed the line that overwrites original_price:**
```dart
// Keep original_price from database - don't overwrite it!
// json['original_price'] = json['discounted_price'];  // REMOVED
```

### 2. Fixed Cart Display (ngo_cart_screen_full.dart)
**Updated subtotal to show actual price:**
```dart
_summaryRow(
  'Subtotal',
  cart.subtotal == 0 
      ? 'FREE' 
      : 'EGP ${cart.subtotal.toStringAsFixed(2)}',
  isDark,
  valueColor: cart.subtotal == 0 ? AppColors.primaryGreen : null,
),
```

### 3. Fixed Checkout Display (ngo_checkout_screen.dart)
**Updated item prices:**
```dart
Text(
  item.meal.donationPrice == 0
      ? 'FREE'
      : 'EGP ${(item.meal.donationPrice * item.quantity).toStringAsFixed(2)}',
  style: TextStyle(
    color: item.meal.donationPrice == 0 
        ? AppColors.primaryGreen 
        : (isDark ? Colors.white : Colors.black),
    fontWeight: FontWeight.bold,
  ),
),
```

**Added total amount display:**
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('Total Amount', ...),
    Text(
      widget.cart.total == 0
          ? 'FREE'
          : 'EGP ${widget.cart.total.toStringAsFixed(2)}',
      ...
    ),
  ],
),
```

### 4. Fixed Order Creation Logic (ngo_checkout_screen.dart)
**Key improvements:**
- Groups items by restaurant (one order per restaurant)
- Calculates actual subtotal from meal prices
- Uses actual `unit_price` from `meal.donationPrice`
- Properly sets `total_amount` based on calculation
- Includes special instructions in order

```dart
// Group cart items by restaurant
final Map<String, List<CartItem>> itemsByRestaurant = {};
for (final item in widget.cart.cartItems) {
  final restaurantId = item.meal.restaurant.id;
  itemsByRestaurant.putIfAbsent(restaurantId, () => []).add(item);
}

// Create one order per restaurant
for (final entry in itemsByRestaurant.entries) {
  final restaurantId = entry.key;
  final items = entry.value;

  // Calculate totals for this restaurant
  double subtotal = 0.0;
  for (final item in items) {
    subtotal += item.meal.donationPrice * item.quantity;
  }

  final orderData = {
    'user_id': userId,
    'ngo_id': userId,
    'restaurant_id': restaurantId,
    'status': 'pending',
    'delivery_type': 'donation',
    'subtotal': subtotal,
    'service_fee': 0.0,
    'delivery_fee': 0.0,
    'total_amount': subtotal,
    'delivery_address': _pickupLocation.trim(),
    'special_instructions': _notesController.text.trim(),
    'created_at': DateTime.now().toIso8601String(),
  };
  
  // ... create order and items with actual prices
  await _supabase.from('order_items').insert({
    'order_id': orderId,
    'meal_id': item.meal.id,
    'quantity': item.quantity,
    'unit_price': item.meal.donationPrice,  // ✅ Actual price
    'meal_title': item.meal.title,
  });
}
```

### 5. Fixed Price Display Logic in UI Components

Updated all NGO UI components to show "FREE" only when `donationPrice == 0`:

#### ngo_meal_detail_screen.dart
- Shows "FREE" in green when price is 0
- Shows actual price when > 0
- Displays strikethrough original price when discounted

#### ngo_meal_card.dart
- Added price badge to meal cards
- Color-coded: green for FREE, orange for paid

#### ngo_map_meal_card.dart
- Updated price badge styling
- Color-coded: green for FREE, primary for paid

## Expected Behavior After Fix

### Scenario 1: Restaurant Donates Meal (Sets Price to 0)
- Database: `original_price = 100`, `discounted_price = 0`
- NGO sees: **"FREE"** in green everywhere
- Cart subtotal: **"FREE"**
- Checkout total: **"FREE"**
- Order created with: `unit_price = 0`, `total_amount = 0`

### Scenario 2: Restaurant Offers Discounted Meal
- Database: `original_price = 100`, `discounted_price = 30`
- NGO sees: **"EGP 30.00"** in orange/primary color
- Cart subtotal: **"EGP 30.00"** (for 1 item)
- Checkout total: **"EGP 30.00"** (for 1 item)
- Order created with: `unit_price = 30`, `total_amount = 30`

### Scenario 3: Mixed Cart (Free + Paid Meals)
- Item 1: FREE (price = 0)
- Item 2: EGP 50.00 (price = 50)
- Cart subtotal: **"EGP 50.00"**
- Checkout shows:
  - Item 1: **"FREE"** in green
  - Item 2: **"EGP 50.00"**
  - Total: **"EGP 50.00"**
- Order created with: `total_amount = 50`

### Scenario 4: Multiple Restaurants
- Restaurant A: 2 items (EGP 30 + EGP 20)
- Restaurant B: 1 item (FREE)
- Creates 2 separate orders:
  - Order 1 (Restaurant A): `total_amount = 50`
  - Order 2 (Restaurant B): `total_amount = 0`

## Visual Indicators

- **FREE meals**: Green badge/text to highlight donations
- **Paid meals**: Orange/primary color badge with actual price
- **Original price**: Shown with strikethrough when there's a discount
- **Cart subtotal**: Shows actual total or "FREE"
- **Checkout total**: Shows actual total or "FREE"

## Files Modified

1. `lib/features/ngo_dashboard/presentation/viewmodels/ngo_home_viewmodel.dart`
   - Removed line that overwrites original_price

2. `lib/features/ngo_dashboard/presentation/screens/ngo_meal_detail_screen.dart`
   - Fixed price display logic in title area
   - Fixed price display logic in bottom bar
   - Added proper color coding (green for free, primary for paid)

3. `lib/features/ngo_dashboard/presentation/widgets/ngo_meal_card.dart`
   - Added price badge to meal cards
   - Color-coded: green for FREE, orange for paid

4. `lib/features/ngo_dashboard/presentation/widgets/ngo_map_meal_card.dart`
   - Updated price badge styling
   - Color-coded: green for FREE, primary for paid

5. `lib/features/ngo_dashboard/presentation/screens/ngo_cart_screen_full.dart`
   - Fixed subtotal display to show actual price or "FREE"

6. `lib/features/ngo_dashboard/presentation/screens/ngo_checkout_screen.dart`
   - Fixed item price display
   - Added total amount display
   - Fixed order creation to use actual prices
   - Groups items by restaurant (one order per restaurant)
   - Calculates correct subtotals and totals
   - Uses actual unit_price from meal.donationPrice

## Testing Checklist

- [ ] NGO home screen shows correct prices for all meals
- [ ] FREE meals display in green with "FREE" text
- [ ] Paid meals display actual price in orange/primary color
- [ ] Meal detail screen shows correct price
- [ ] Original price shows with strikethrough when discounted
- [ ] Map view shows correct prices
- [ ] Cart shows correct subtotal (actual price or "FREE")
- [ ] Cart items show individual prices
- [ ] Checkout shows correct item prices
- [ ] Checkout shows correct total amount
- [ ] Orders created with correct unit_price
- [ ] Orders created with correct total_amount
- [ ] Multiple items from same restaurant grouped into one order
- [ ] Items from different restaurants create separate orders
- [ ] Mixed cart (free + paid) calculates correctly

## Database Impact

Orders table will now have:
- `unit_price`: Actual meal price (0 for free, > 0 for paid)
- `subtotal`: Sum of (unit_price × quantity) for all items
- `total_amount`: Same as subtotal (no additional fees for NGOs)
- `service_fee`: 0 (waived for NGOs)
- `delivery_fee`: 0 (free for NGOs)

## Database Query
The NGO dashboard filters meals with:
```sql
.eq('is_donation_available', true)
```

This means NGOs only see meals that restaurants have marked as available for donation, regardless of price. The price can be:
- 0 (fully donated/free)
- Discounted (partial donation)
- Full price (available for NGO purchase)
