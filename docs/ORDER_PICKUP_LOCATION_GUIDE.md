# Order Pickup Location - Implementation Guide

## Overview

This document explains how pickup locations are automatically set for orders based on the fulfillment method (delivery type).

## Pickup Location Logic

### Rule: Pickup Location = Where Food is Picked Up From

For all order types, the pickup location represents **where the food is physically picked up from**, which is always the **restaurant location**.

### By Delivery Type

| Delivery Type | Pickup Location | Delivery Location | Description |
|---------------|----------------|-------------------|-------------|
| **pickup** | Restaurant | N/A | Customer picks up from restaurant |
| **delivery** | Restaurant | Customer address | Delivery driver picks up from restaurant, delivers to customer |
| **donation** | Restaurant | NGO address | NGO picks up from restaurant |

### Detailed Explanation

#### 1. Pickup Orders (`delivery_type = 'pickup'`)
- **Pickup Location**: Restaurant location
- **Flow**: Customer → Restaurant (pickup)
- **Use Case**: Customer goes to restaurant to collect their order
- **Example**: 
  ```
  Order #1234
  Type: Pickup
  Pickup Location: Restaurant A (13.0827, 80.2707)
  Customer picks up from: Restaurant A
  ```

#### 2. Delivery Orders (`delivery_type = 'delivery'`)
- **Pickup Location**: Restaurant location
- **Delivery Location**: Customer address (stored in `delivery_address`)
- **Flow**: Restaurant → Delivery Driver → Customer
- **Use Case**: Delivery driver picks up from restaurant, delivers to customer
- **Example**:
  ```
  Order #1235
  Type: Delivery
  Pickup Location: Restaurant B (13.0418, 80.2341)
  Delivery Location: 123 Main St, Chennai
  Driver picks up from: Restaurant B
  Driver delivers to: Customer address
  ```

#### 3. Donation Orders (`delivery_type = 'donation'`)
- **Pickup Location**: Restaurant location
- **NGO Location**: NGO address (can be used for routing)
- **Flow**: Restaurant → NGO (pickup)
- **Use Case**: NGO goes to restaurant to collect donated meals
- **Example**:
  ```
  Order #1236
  Type: Donation
  Pickup Location: Restaurant C (13.0067, 80.2206)
  NGO Location: NGO Office (13.0339, 80.2619)
  NGO picks up from: Restaurant C
  ```

## Database Schema

### Orders Table (Updated)

```sql
orders (
  id uuid PRIMARY KEY,
  order_number text,
  delivery_type text,  -- 'pickup', 'delivery', 'donation'
  
  -- Pickup location (always restaurant)
  pickup_latitude double precision,
  pickup_longitude double precision,
  pickup_location geography(point, 4326),
  pickup_address_text text,
  
  -- Delivery location (for delivery orders)
  delivery_address text,
  
  -- References
  restaurant_id uuid,  -- Where food is picked up from
  user_id uuid,        -- Customer
  ngo_id uuid,         -- For donation orders
  
  ...
)
```

### Automatic Trigger

The `set_order_pickup_location()` trigger automatically sets pickup location when:
- A new order is created
- `delivery_type` is updated
- `restaurant_id` is updated

```sql
-- Trigger fires on INSERT or UPDATE
CREATE TRIGGER orders_pickup_location_trigger
  BEFORE INSERT OR UPDATE OF delivery_type, restaurant_id, ngo_id
  ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION set_order_pickup_location();
```

## Implementation Details

### Trigger Logic

```sql
CREATE OR REPLACE FUNCTION set_order_pickup_location()
RETURNS TRIGGER AS $$
BEGIN
  -- For ALL order types: pickup location = restaurant location
  IF NEW.delivery_type IN ('pickup', 'delivery', 'donation') THEN
    -- Get restaurant location
    SELECT latitude, longitude, address_text
    INTO restaurant_lat, restaurant_lng, restaurant_address
    FROM restaurants
    WHERE profile_id = NEW.restaurant_id;
    
    -- Set pickup location
    IF restaurant_lat IS NOT NULL AND restaurant_lng IS NOT NULL THEN
      NEW.pickup_latitude := restaurant_lat;
      NEW.pickup_longitude := restaurant_lng;
      NEW.pickup_address_text := restaurant_address;
      NEW.pickup_location := ST_MakePoint(restaurant_lng, restaurant_lat);
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Backfill Existing Orders

The migration includes a backfill query to update existing orders:

```sql
UPDATE public.orders o
SET 
  pickup_latitude = r.latitude,
  pickup_longitude = r.longitude,
  pickup_address_text = r.address_text,
  pickup_location = ST_MakePoint(r.longitude, r.latitude)
FROM restaurants r
WHERE o.restaurant_id = r.profile_id
  AND o.pickup_latitude IS NULL
  AND r.latitude IS NOT NULL;
```

## Usage Examples

### 1. Get Order with Pickup Location

```dart
final order = await supabase
  .from('orders')
  .select('''
    *,
    pickup_latitude,
    pickup_longitude,
    pickup_address_text,
    restaurants (
      restaurant_name,
      latitude,
      longitude,
      address_text
    )
  ''')
  .eq('id', orderId)
  .single();

print('Pickup from: ${order['pickup_address_text']}');
print('Location: ${order['pickup_latitude']}, ${order['pickup_longitude']}');
```

### 2. Show Pickup Location on Map

```dart
// For pickup orders
if (order['delivery_type'] == 'pickup') {
  final pickupLocation = LatLng(
    order['pickup_latitude'],
    order['pickup_longitude'],
  );
  
  // Show marker on map
  Marker(
    point: pickupLocation,
    child: Icon(Icons.restaurant, color: Colors.red),
  );
  
  // Show address
  Text('Pickup at: ${order['pickup_address_text']}');
}

// For delivery orders
if (order['delivery_type'] == 'delivery') {
  final pickupLocation = LatLng(
    order['pickup_latitude'],
    order['pickup_longitude'],
  );
  
  // Show route: Restaurant → Customer
  // Pickup marker
  Marker(
    point: pickupLocation,
    child: Icon(Icons.restaurant, color: Colors.orange),
  );
  
  // Delivery marker (parse delivery_address or use user location)
  // ... show route between them
}

// For donation orders
if (order['delivery_type'] == 'donation') {
  final pickupLocation = LatLng(
    order['pickup_latitude'],
    order['pickup_longitude'],
  );
  
  // Show marker at restaurant
  Marker(
    point: pickupLocation,
    child: Icon(Icons.restaurant, color: Colors.green),
  );
  
  Text('NGO picks up from: ${order['pickup_address_text']}');
}
```

### 3. Calculate Distance to Pickup Location

```dart
final locationService = LocationService();

// Get user's current location
final userPosition = await locationService.getCurrentLocation();

if (userPosition != null) {
  // Calculate distance to pickup location
  final distance = locationService.calculateDistance(
    userPosition.latitude,
    userPosition.longitude,
    order['pickup_latitude'],
    order['pickup_longitude'],
  );
  
  final formatted = locationService.formatDistance(distance);
  print('Distance to pickup: $formatted');
}
```

### 4. Get Orders with Pickup Locations (SQL)

```sql
-- For users
SELECT * FROM get_user_orders_with_pickup('user-uuid', 20);

-- For restaurants
SELECT * FROM get_restaurant_orders_with_pickup('restaurant-uuid', 50);

-- For NGOs
SELECT * FROM get_ngo_orders_with_pickup('ngo-uuid', 30);
```

## UI/UX Recommendations

### Order Detail Screen

```
┌─────────────────────────────────────┐
│  Order #1234                        │
│  Status: Pending                    │
├─────────────────────────────────────┤
│                                     │
│  📍 Pickup Location                 │
│  Restaurant Name                    │
│  123 Restaurant St, Chennai         │
│  [View on Map]                      │
│                                     │
│  ⏰ Estimated Ready: 6:30 PM        │
│                                     │
├─────────────────────────────────────┤
│  For Delivery Orders:               │
│  🚚 Delivery To                     │
│  456 Customer Ave, Chennai          │
│  [View Route]                       │
└─────────────────────────────────────┘
```

### Map View

For pickup orders:
- Show single marker at restaurant
- Show "Pickup Here" label

For delivery orders:
- Show two markers: Restaurant (pickup) and Customer (delivery)
- Show route between them
- Label: "Pickup from Restaurant" → "Deliver to Customer"

For donation orders:
- Show marker at restaurant
- Optionally show NGO location
- Label: "NGO picks up from Restaurant"

## Benefits

### 1. Consistency
- All orders have a pickup location
- Always represents where food is picked up from
- No confusion about location meaning

### 2. Routing
- Easy to calculate routes for delivery drivers
- NGOs know where to pick up donations
- Customers know where to go for pickup

### 3. Analytics
- Track pickup locations
- Analyze delivery distances
- Optimize restaurant locations

### 4. Future Features
- Delivery driver assignment based on proximity to pickup location
- Estimated pickup time based on distance
- Route optimization for multiple pickups
- Geofencing for pickup notifications

## Migration Steps

### 1. Apply Migration
```bash
supabase migration up
# OR run manually: supabase/migrations/20260217_add_pickup_location_to_orders.sql
```

### 2. Verify Setup
```sql
-- Check if columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND column_name LIKE 'pickup%';

-- Check if trigger exists
SELECT trigger_name 
FROM information_schema.triggers 
WHERE trigger_name = 'orders_pickup_location_trigger';

-- Check backfilled data
SELECT 
  COUNT(*) as total_orders,
  COUNT(pickup_latitude) as with_pickup_location
FROM orders;
```

### 3. Test Order Creation
```dart
// Create a test order
final order = await supabase.from('orders').insert({
  'user_id': userId,
  'restaurant_id': restaurantId,
  'delivery_type': 'pickup',
  'total_amount': 100.0,
  // ... other fields
}).select().single();

// Verify pickup location was set
print('Pickup location: ${order['pickup_latitude']}, ${order['pickup_longitude']}');
print('Pickup address: ${order['pickup_address_text']}');
```

## Troubleshooting

### Pickup Location Not Set

**Problem**: Order created but pickup location is null

**Possible Causes**:
1. Restaurant doesn't have location set
2. Trigger didn't fire
3. Restaurant ID is invalid

**Solution**:
```sql
-- Check if restaurant has location
SELECT restaurant_name, latitude, longitude, address_text
FROM restaurants
WHERE profile_id = 'restaurant-uuid';

-- Manually set pickup location
UPDATE orders
SET 
  pickup_latitude = (SELECT latitude FROM restaurants WHERE profile_id = orders.restaurant_id),
  pickup_longitude = (SELECT longitude FROM restaurants WHERE profile_id = orders.restaurant_id),
  pickup_address_text = (SELECT address_text FROM restaurants WHERE profile_id = orders.restaurant_id)
WHERE id = 'order-uuid';
```

### Trigger Not Firing

**Problem**: Trigger doesn't update pickup location

**Solution**:
```sql
-- Check if trigger exists
SELECT * FROM pg_trigger WHERE tgname = 'orders_pickup_location_trigger';

-- Recreate trigger
DROP TRIGGER IF EXISTS orders_pickup_location_trigger ON orders;
CREATE TRIGGER orders_pickup_location_trigger
  BEFORE INSERT OR UPDATE OF delivery_type, restaurant_id, ngo_id
  ON orders
  FOR EACH ROW
  EXECUTE FUNCTION set_order_pickup_location();
```

## Summary

- **Pickup Location** = Where food is picked up from = **Restaurant location**
- Automatically set by database trigger
- Works for all delivery types (pickup, delivery, donation)
- Enables routing, distance calculations, and map features
- Consistent and predictable behavior

---

**Implementation Date**: February 17, 2026  
**Status**: Ready for deployment  
**Breaking Changes**: None (adds new columns only)
