# Order Status Reference

## Valid Database Enum Values

```
order_status ENUM:
├── pending
├── confirmed
├── preparing
├── ready_for_pickup
├── out_for_delivery
├── delivered
├── completed
└── cancelled
```

## Status Flow

```
pending → confirmed → preparing → ready_for_pickup → delivered → completed
                                                    ↓
                                              out_for_delivery
                                                    ↓
                                                delivered → completed

Any status can go to: cancelled
```

## Usage in Code

### Active Orders (In Progress)
```dart
.inFilter('status', [
  'pending',
  'confirmed', 
  'preparing',
  'ready_for_pickup'
])
```

### Completed Orders (Finished)
```dart
.inFilter('status', [
  'completed',
  'delivered'
])
```

### All Orders
```dart
.inFilter('status', [
  'pending',
  'confirmed',
  'preparing',
  'ready_for_pickup',
  'out_for_delivery',
  'delivered',
  'completed',
  'cancelled'
])
```

## Status Descriptions

| Status | Description | User Action |
|--------|-------------|-------------|
| `pending` | Order created, awaiting confirmation | Wait for restaurant |
| `confirmed` | Restaurant confirmed the order | Wait for preparation |
| `preparing` | Restaurant is preparing the meal | Wait for completion |
| `ready_for_pickup` | Meal ready for pickup | Go pick up |
| `out_for_delivery` | Delivery in progress | Wait for delivery |
| `delivered` | Meal delivered to location | Confirm receipt |
| `completed` | Order successfully completed | Done |
| `cancelled` | Order was cancelled | No action |

## Common Mistakes to Avoid

❌ **DON'T USE:**
- `'paid'` - Not in enum
- `'processing'` - Not in enum
- `'active'` - Not in enum
- `'reserved'` - Not in enum

✅ **USE INSTEAD:**
- `'confirmed'` - For paid/confirmed orders
- `'preparing'` - For processing orders
- `'pending'` - For new orders
- `'ready_for_pickup'` - For reserved/ready orders

## Quick Fix Guide

If you see this error:
```
PostgrestException(message: invalid input value for enum order_status: "XXX")
```

1. Check the status value you're using
2. Replace with correct enum value from list above
3. Hot restart the app

## Code Search Commands

Find all status references:
```bash
# Search for status filters
grep -r "inFilter.*status" lib/

# Search for status assignments
grep -r "status.*:" lib/
```

---

**Keep this reference handy when working with orders!**
