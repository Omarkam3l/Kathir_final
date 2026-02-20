# NGO Donation Flow - Complete Verification Guide

## Overview
This document verifies that meals are only FREE for NGOs when restaurants explicitly donate them using the "Donate" button.

## How Restaurant Donation Works

### Restaurant Dashboard - Donate Button
1. Restaurant sees their meals in the home screen
2. Each meal has a "Donate" button (only shown if meal is not already free and not expired)
3. When clicked, shows confirmation dialog:
   ```
   Are you sure you want to donate this meal?
   
   This will:
   • Set the price to FREE (EGP 0.00)
   • Notify all users about this free meal
   • Available quantity: X portions
   • First come, first served
   • Cannot be undone
   ```

### Database Changes on Donation
When restaurant confirms donation, the `donate_meal()` function:
1. Sets `discounted_price = 0`
2. Sets `original_price = 0` (to preserve the original value before donation)
3. Creates a record in `free_meal_notifications` table
4. Notifies all users via `free_meal_user_notifications`

**Key Point:** Both prices become 0 ONLY when restaurant explicitly donates!

## NGO Pricing Logic

### Data Loading (ngo_home_viewmodel.dart)
```dart
// Map database fields to model fields
json['donation_price'] = json['discounted_price'];  // ✅ Uses actual discounted_price
json['quantity'] = json['quantity_available'];
json['expiry'] = json['expiry_date'];
// ... other fields
// Keep original_price from database - don't overwrite it!  ✅ CORRECT
```

**Result:**
- `meal.donationPrice` = `discounted_price` from database
- `meal.originalPrice` = `original_price` from database

### Display Logic (All NGO Screens)
```dart
meal.donationPrice == 0 ? 'FREE' : 'EGP ${meal.donationPrice}'
```

**Result:**
- Shows "FREE" ONLY when `discounted_price = 0` (restaurant donated)
- Shows actual price otherwise

### Cart Calculation (ngo_cart_viewmodel.dart)
```dart
double get subtotal {
  return _cartItems.fold(0.0, (sum, item) => 
    sum + (item.meal.donationPrice * item.quantity));
}
```

**Result:**
- Calculates actual total based on `donationPrice`
- If all items are free (donated), subtotal = 0
- If items have prices, subtotal = sum of prices

### Order Creation (ngo_checkout_screen.dart)
```dart
// Calculate totals for this restaurant
double subtotal = 0.0;
for (final item in items) {
  subtotal += item.meal.donationPrice * item.quantity;
}

final orderData = {
  'subtotal': subtotal,
  'total_amount': subtotal,
  // ...
};

// Create order items with actual prices
await _supabase.from('order_items').insert({
  'order_id': orderId,
  'meal_id': item.meal.id,
  'quantity': item.quantity,
  'unit_price': item.meal.donationPrice,  // ✅ Actual price
  'meal_title': item.meal.title,
});
```

**Result:**
- Orders created with actual prices
- `unit_price` = `meal.donationPrice` (0 if donated, actual price otherwise)
- `total_amount` = sum of all item prices

## Test Scenarios

### Scenario 1: Restaurant Creates Regular Meal (Not Donated)
**Setup:**
- Restaurant creates meal: Original Price = EGP 100, Discounted Price = EGP 30
- Meal is marked as `is_donation_available = true` (available for NGOs)
- Restaurant does NOT click "Donate" button

**Expected NGO Experience:**
1. **Home Screen:** Meal shows "EGP 30" in orange badge
2. **Meal Detail:** Shows "EGP 30.00" with strikethrough "EGP 100.00"
3. **Add to Cart:** Item added with price EGP 30
4. **Cart Screen:** Subtotal shows "EGP 30.00"
5. **Checkout:** Total shows "EGP 30.00"
6. **Order Created:** 
   - `unit_price = 30`
   - `subtotal = 30`
   - `total_amount = 30`

**Database State:**
```sql
SELECT original_price, discounted_price FROM meals WHERE id = 'meal_id';
-- Result: original_price = 100, discounted_price = 30
```

### Scenario 2: Restaurant Donates Meal (Clicks Donate Button)
**Setup:**
- Restaurant has meal: Original Price = EGP 100, Discounted Price = EGP 30
- Restaurant clicks "Donate" button and confirms
- `donate_meal()` function executes

**Expected NGO Experience:**
1. **Home Screen:** Meal shows "FREE" in green badge
2. **Meal Detail:** Shows "FREE" in green with strikethrough "Was EGP 100.00"
3. **Add to Cart:** Item added with price EGP 0
4. **Cart Screen:** Subtotal shows "FREE"
5. **Checkout:** Total shows "FREE"
6. **Order Created:**
   - `unit_price = 0`
   - `subtotal = 0`
   - `total_amount = 0`

**Database State:**
```sql
SELECT original_price, discounted_price FROM meals WHERE id = 'meal_id';
-- Result: original_price = 0, discounted_price = 0

SELECT * FROM free_meal_notifications WHERE meal_id = 'meal_id';
-- Result: Record exists with original_price = 30 (preserved before donation)
```

### Scenario 3: Mixed Cart (Donated + Regular Meals)
**Setup:**
- Meal A: Donated (price = 0)
- Meal B: Regular (price = 50)
- Meal C: Regular (price = 20)

**Expected NGO Experience:**
1. **Cart Items:**
   - Meal A: "FREE" in green
   - Meal B: "EGP 50.00"
   - Meal C: "EGP 20.00"
2. **Cart Subtotal:** "EGP 70.00"
3. **Checkout Total:** "EGP 70.00"
4. **Order Created:**
   - Item A: `unit_price = 0`
   - Item B: `unit_price = 50`
   - Item C: `unit_price = 20`
   - `total_amount = 70`

### Scenario 4: Multiple Restaurants with Mixed Donations
**Setup:**
- Restaurant A: Meal 1 (donated, price = 0), Meal 2 (regular, price = 30)
- Restaurant B: Meal 3 (donated, price = 0)

**Expected NGO Experience:**
1. **Cart Subtotal:** "EGP 30.00"
2. **Checkout:** Creates 2 separate orders:
   - Order 1 (Restaurant A): `total_amount = 30` (Meal 1: 0 + Meal 2: 30)
   - Order 2 (Restaurant B): `total_amount = 0` (Meal 3: 0)

## Verification Checklist

### Restaurant Side
- [ ] "Donate" button appears on non-free, non-expired meals
- [ ] Clicking "Donate" shows confirmation dialog
- [ ] Confirming donation calls `donate_meal()` RPC
- [ ] After donation, meal shows as FREE in restaurant dashboard
- [ ] Donation cannot be undone

### NGO Side - Display
- [ ] Donated meals (price = 0) show "FREE" in green
- [ ] Regular meals (price > 0) show actual price in orange
- [ ] Meal detail shows correct price
- [ ] Original price shows with strikethrough when applicable
- [ ] Cart items show correct individual prices
- [ ] Cart subtotal calculates correctly
- [ ] Checkout shows correct total

### NGO Side - Order Creation
- [ ] Orders created with correct `unit_price` for each item
- [ ] Orders created with correct `subtotal`
- [ ] Orders created with correct `total_amount`
- [ ] Multiple items from same restaurant grouped into one order
- [ ] Items from different restaurants create separate orders
- [ ] Mixed cart (free + paid) calculates correctly

### Database Verification
- [ ] Donated meals have `discounted_price = 0`
- [ ] Donated meals have `original_price = 0`
- [ ] Donation record exists in `free_meal_notifications`
- [ ] Order items have correct `unit_price`
- [ ] Orders have correct `total_amount`

## SQL Queries for Verification

### Check if meal is donated
```sql
SELECT 
  id,
  title,
  original_price,
  discounted_price,
  is_donation_available
FROM meals
WHERE id = 'meal_id';

-- If donated: original_price = 0, discounted_price = 0
-- If not donated: prices > 0
```

### Check donation record
```sql
SELECT 
  id,
  meal_id,
  restaurant_id,
  original_price,
  donated_at,
  notification_sent
FROM free_meal_notifications
WHERE meal_id = 'meal_id';

-- Should exist only if meal was donated
-- original_price shows the price before donation
```

### Check NGO order prices
```sql
SELECT 
  o.id,
  o.order_number,
  o.total_amount,
  oi.meal_title,
  oi.quantity,
  oi.unit_price,
  (oi.quantity * oi.unit_price) as item_total
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
WHERE o.ngo_id = 'ngo_user_id'
ORDER BY o.created_at DESC;

-- Verify unit_price matches meal's discounted_price
-- Verify total_amount = sum of (quantity * unit_price)
```

## Key Rules

1. ✅ **Meals are FREE for NGOs ONLY when restaurant clicks "Donate"**
2. ✅ **Donation sets both prices to 0 in database**
3. ✅ **NGO code uses `discounted_price` as `donationPrice`**
4. ✅ **Display logic: `donationPrice == 0` → "FREE", else show price**
5. ✅ **Cart calculates: `sum(donationPrice × quantity)`**
6. ✅ **Orders store actual prices in `unit_price` and `total_amount`**
7. ✅ **No hardcoded zeros - all prices come from database**

## Common Issues to Avoid

❌ **Don't hardcode prices to 0**
```dart
// WRONG
'unit_price': 0.0,
'total_amount': 0.0,
```

✅ **Use actual meal prices**
```dart
// CORRECT
'unit_price': item.meal.donationPrice,
'total_amount': subtotal,
```

❌ **Don't show "Free" for all meals**
```dart
// WRONG
Text('Free')
```

✅ **Check actual price**
```dart
// CORRECT
Text(meal.donationPrice == 0 ? 'FREE' : 'EGP ${meal.donationPrice}')
```

❌ **Don't overwrite original_price**
```dart
// WRONG
json['original_price'] = json['discounted_price'];
```

✅ **Keep original_price from database**
```dart
// CORRECT
// Don't set original_price - let it come from database
```

## Summary

The system now correctly implements:
- Restaurants can donate meals by clicking "Donate" button
- Donation sets prices to 0 in database
- NGOs see "FREE" only for donated meals
- NGOs pay actual prices for non-donated meals
- Cart and checkout calculate correct totals
- Orders store actual prices in database
- No hardcoded zeros anywhere in the flow
