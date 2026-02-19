# Cart Items Fix - NGO Add to Cart Error

## Problem
When NGO users tried to add meals to cart, they received this error:
```
PostgrestException(message: null value in column "user_id" of relation "cart_items" violates not-null constraint, code: 23502)
```

## Root Cause
The `cart_items` table has both `profile_id` (nullable) and `user_id` (NOT NULL) columns. The NGO cart code was using `profile_id`, but the database requires `user_id` to be populated, causing the constraint violation.

## Solution
Changed the NGO cart viewmodel to use `user_id` instead of `profile_id` to match the existing database schema and other cart services.

### Fixed File:
**lib/features/ngo_dashboard/presentation/viewmodels/ngo_cart_viewmodel.dart**

Changed all database operations from `profile_id` to `user_id`:
- `loadCart()` - Changed `.eq('profile_id', userId)` to `.eq('user_id', userId)`
- `addToCart()` - Changed insert/update to use `'user_id': userId`
- `removeFromCart()` - Changed `.eq('profile_id', userId)` to `.eq('user_id', userId)`
- `updateQuantity()` - Changed `.eq('profile_id', userId)` to `.eq('user_id', userId)`
- `clearCart()` - Changed `.eq('profile_id', userId)` to `.eq('user_id', userId)`

## How to Apply the Fix

### Rebuild and Deploy
The Dart code changes are already applied. Just rebuild your Flutter app:
```bash
flutter clean
flutter pub get
flutter run
```

## Verification

After applying the fix, test NGO cart functionality:

1. **Login as NGO user**
2. **Browse meals**
3. **Click "Add to Cart"** - Should succeed without errors
4. **View cart** - Should display added items
5. **Update quantities** - Should work correctly
6. **Remove items** - Should work correctly
7. **Clear cart** - Should work correctly

## Database Schema
The `cart_items` table structure remains unchanged:
- `id` (uuid, NOT NULL) - Primary key
- `profile_id` (uuid, nullable) - Legacy column (not used)
- `meal_id` (uuid, nullable) - Foreign key to meals
- `quantity` (integer, default 1)
- `created_at` (timestamp)
- `updated_at` (timestamp)
- `user_id` (uuid, NOT NULL) - Foreign key to profiles (actively used)

## Consistency
All cart services now consistently use `user_id`:
- ✅ `cart_service.dart` - Uses `user_id`
- ✅ `ngo_cart_viewmodel.dart` - Now uses `user_id`
- ✅ `order_service.dart` - Uses `user_id`

## Files Modified
- `lib/features/ngo_dashboard/presentation/viewmodels/ngo_cart_viewmodel.dart`
