# Enhanced Orders System Implementation

## Overview
Complete redesign of the My Orders screen with order tracking, QR code pickup, and enhanced database schema.

## Database Changes

### Migration: `20260206_enhanced_orders_system.sql`

**New Order Status Enum:**
- `pending` - Order placed, awaiting confirmation
- `confirmed` - Order confirmed by restaurant
- `preparing` - Restaurant is preparing the order
- `ready_for_pickup` - Order ready for customer pickup
- `out_for_delivery` - Order is being delivered
- `delivered` - Order delivered to customer
- `completed` - Order completed (picked up or delivered)
- `cancelled` - Order cancelled

**New Columns in `orders` table:**
- `status` - Current order status (order_status enum)
- `qr_code` - QR code data (JSON string) for pickup verification
- `pickup_code` - 6-character alphanumeric code for pickup
- `estimated_ready_time` - When order is estimated to be ready
- `actual_ready_time` - When order was actually ready
- `picked_up_at` - When order was picked up
- `delivered_at` - When order was delivered
- `cancelled_at` - When order was cancelled
- `cancellation_reason` - Reason for cancellation
- `special_instructions` - Customer instructions
- `rating` - Customer rating (1-5 stars)
- `review_text` - Customer review
- `reviewed_at` - When review was submitted

**New Table: `order_status_history`**
Tracks all status changes for orders:
- `id` - UUID primary key
- `order_id` - Reference to orders table
- `status` - Status at this point
- `changed_by` - User who changed the status
- `changed_at` - When status was changed
- `notes` - Additional notes
- `created_at` - Record creation time

**Functions:**
1. `generate_pickup_code()` - Generates unique 6-digit alphanumeric codes
2. `generate_qr_code_data(order_uuid)` - Generates QR code JSON data
3. `verify_pickup_code(order_id, pickup_code)` - Verifies pickup code
4. `complete_pickup(order_id, pickup_code)` - Completes pickup process

**Triggers:**
1. `auto_generate_order_codes` - Auto-generates pickup code and QR data on order creation
2. `log_order_status_change` - Logs all status changes to history table

## New UI Screens

### 1. My Orders Screen (`my_orders_screen_new.dart`)

**Features:**
- Tab-based interface (Active / Past)
- Active orders show current status with badges
- Action buttons based on order status:
  - "Track Order" for preparing/out for delivery
  - "View Pickup QR" for ready_for_pickup
- Past orders with rating and reorder options
- Pull-to-refresh functionality
- Real-time order updates

**Design Elements:**
- Clean card-based layout
- Status badges with color coding
- Restaurant info with images
- Order items summary
- Total amount display

### 2. Order QR Screen (`order_qr_screen.dart`)

**Features:**
- Large QR code display for scanning
- 6-digit pickup code display
- Restaurant information
- Estimated ready time
- Pickup instructions

**Design Elements:**
- Success icon and confirmation message
- White card with QR code
- Monospace font for pickup code
- Restaurant card with address
- Info banner with instructions

### 3. Order Tracking Screen (`order_tracking_screen.dart`)

**Features:**
- Real-time order status updates (Supabase realtime)
- Visual timeline showing order progress
- Different timelines for pickup vs delivery
- Restaurant contact information
- Order items list
- Order summary with pricing breakdown
- Pull-to-refresh

**Design Elements:**
- Status header with icon and color
- Vertical timeline with checkpoints
- Restaurant card with call button
- Itemized order list
- Summary card with totals

## Status Flow

### Pickup Orders:
1. `pending` → Order placed
2. `confirmed` → Restaurant confirmed
3. `preparing` → Restaurant preparing food
4. `ready_for_pickup` → Ready for customer pickup (QR code shown)
5. `completed` → Customer picked up order

### Delivery Orders:
1. `pending` → Order placed
2. `confirmed` → Restaurant confirmed
3. `preparing` → Restaurant preparing food
4. `out_for_delivery` → Order being delivered
5. `delivered` → Order delivered to customer
6. `completed` → Order completed

### Cancellation:
- Any status → `cancelled` (with reason)

## Integration Steps

### 1. Run Database Migration
```bash
# Apply the migration to your Supabase project
supabase db push
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Update Router
Add routes in `app_router.dart`:
```dart
GoRoute(
  path: '/my-orders',
  builder: (context, state) => const MyOrdersScreenNew(),
),
GoRoute(
  path: '/order-qr/:orderId',
  builder: (context, state) {
    final orderId = state.pathParameters['orderId']!;
    return OrderQRScreen(orderId: orderId);
  },
),
GoRoute(
  path: '/order-tracking/:orderId',
  builder: (context, state) {
    final orderId = state.pathParameters['orderId']!;
    return OrderTrackingScreen(orderId: orderId);
  },
),
```

### 4. Update Navigation
Replace old my_orders_screen references with my_orders_screen_new

## Restaurant Side Integration

For restaurants to update order status, you'll need to:

1. Add status update buttons in restaurant dashboard
2. Call Supabase update:
```dart
await supabase
    .from('orders')
    .update({'status': 'preparing'})
    .eq('id', orderId);
```

3. Scan QR codes to verify pickup:
```dart
final result = await supabase.rpc('complete_pickup', params: {
  'p_order_id': orderId,
  'p_pickup_code': scannedCode,
});
```

## Features to Implement Later

1. **Push Notifications** - Notify users of status changes
2. **Live Delivery Tracking** - Show delivery person location on map
3. **Rating System** - Allow users to rate orders
4. **Reorder Functionality** - Quick reorder from past orders
5. **Order Cancellation** - Allow users to cancel orders
6. **Restaurant Call** - Direct call to restaurant from tracking screen
7. **Estimated Time Updates** - Restaurant can update estimated ready time

## Testing Checklist

- [ ] Create new order and verify pickup code generation
- [ ] Check QR code displays correctly
- [ ] Test order status progression
- [ ] Verify real-time updates in tracking screen
- [ ] Test pickup code verification
- [ ] Check order history logging
- [ ] Test both pickup and delivery flows
- [ ] Verify RLS policies work correctly
- [ ] Test on different screen sizes
- [ ] Check error handling

## Notes

- QR codes contain JSON data with order info for verification
- Pickup codes are unique across active orders only
- Status history is automatically logged on every status change
- Real-time subscriptions auto-update tracking screen
- All timestamps are in UTC (convert to local for display)
