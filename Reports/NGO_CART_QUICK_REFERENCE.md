# NGO Cart Database Refactor - Quick Reference

## 🚀 Quick Start

### 1. Run Migration
```bash
# Via psql
psql -d your_database -f Migrations/007_refactor_cart_for_all_roles.sql

# Or via Supabase Dashboard SQL Editor
# Copy/paste migration content and run
```

### 2. Hot Restart App
```bash
# Not hot reload - full restart required
flutter run
```

### 3. Test Cart
- Add meal to cart
- Close app
- Reopen app
- Cart items should persist ✅

## 📋 What Changed

### Database
- `user_id` → `profile_id` (supports all roles)
- RLS policies updated for authenticated users
- Indexes added for performance

### Code
- All cart methods now `async`
- Cart loads from database
- Cart persists across sessions

## 🔧 API Changes

```dart
// OLD (in-memory)
cart.addToCart(meal);
cart.removeFromCart(mealId);
cart.clearCart();

// NEW (database)
await cart.addToCart(meal);
await cart.removeFromCart(mealId);
await cart.clearCart();
await cart.loadCart(); // New method
```

## ✅ Testing Checklist

- [ ] Migration runs successfully
- [ ] Add meal to cart
- [ ] Cart badge updates
- [ ] View cart screen
- [ ] Update quantities
- [ ] Remove items
- [ ] Clear cart
- [ ] Close and reopen app
- [ ] Cart items persist

## 🐛 Troubleshooting

### Cart is empty after migration
```dart
// Call loadCart() in initState
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<NgoCartViewModel>().loadCart();
  });
}
```

### RLS policy errors
```sql
-- Verify policies exist
SELECT policyname FROM pg_policies WHERE tablename = 'cart_items';

-- Should show 4 policies for 'authenticated' role
```

### Column not found: profile_id
```sql
-- Check if migration ran
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'cart_items';

-- Should show 'profile_id' not 'user_id'
```

## 📚 Files Modified

1. `Migrations/007_refactor_cart_for_all_roles.sql` - Database migration
2. `ngo_cart_viewmodel.dart` - Refactored to use database
3. `ngo_cart_screen_full.dart` - Added loadCart() call
4. `ngo_all_meals_screen.dart` - Made addToCart async
5. `ngo_meal_detail_screen.dart` - Made addToCart async
6. `ngo_home_viewmodel.dart` - Made claimMeal async

## 🎯 Key Benefits

✅ **Persistence** - Cart survives app restarts
✅ **Consistency** - Same system for users and NGOs  
✅ **Reliability** - Database-backed, no data loss
✅ **Scalability** - Supports multi-device sync

## 📞 Support

If issues persist:
1. Check migration ran successfully
2. Verify RLS policies active
3. Check Supabase logs for errors
4. Review `NGO_CART_DATABASE_REFACTOR_COMPLETE.md` for details
