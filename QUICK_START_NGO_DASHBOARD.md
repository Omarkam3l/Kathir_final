# 🚀 Quick Start - NGO Dashboard

## ⚡ 5-Minute Setup

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Apply Database Migration
1. Open Supabase Dashboard → SQL Editor
2. Copy & paste: `supabase/migrations/20260203_ngo_enhancements.sql`
3. Click "Run"

### 3. Add Test Data
Run this SQL in Supabase:
```sql
-- Create test restaurant
INSERT INTO profiles (id, role, email, full_name, approval_status)
VALUES (gen_random_uuid(), 'restaurant', 'test@restaurant.com', 'Test Restaurant', 'approved')
RETURNING id;

-- Use the returned ID in the next queries
-- Replace 'YOUR_RESTAURANT_ID' with the actual ID

INSERT INTO restaurants (profile_id, restaurant_name, address_text, rating)
VALUES ('YOUR_RESTAURANT_ID', 'Test Restaurant', 'Anna Nagar, Chennai', 4.5);

INSERT INTO meals (
  restaurant_id, title, description, category,
  original_price, discounted_price, quantity_available,
  expiry_date, is_donation_available, status
) VALUES
('YOUR_RESTAURANT_ID', 'Surplus Biryani', 'Delicious biryani', 'Meals',
 500, 0, 15, NOW() + INTERVAL '1 hour', true, 'active');
```

### 4. Update Routes
Add to your `app_router.dart`:
```dart
import 'package:provider/provider.dart';
import '../../ngo_dashboard/presentation/screens/ngo_home_screen.dart';
import '../../ngo_dashboard/presentation/viewmodels/ngo_home_viewmodel.dart';

// In your routes:
GoRoute(
  path: '/ngo/home',
  builder: (context, state) => ChangeNotifierProvider(
    create: (_) => NgoHomeViewModel(),
    child: const NgoHomeScreen(),
  ),
),
```

### 5. Run the App
```bash
flutter run
```

### 6. Navigate to Dashboard
```dart
context.go('/ngo/home');
```

## ✅ That's It!

You now have:
- ✅ Dynamic NGO Home Screen
- ✅ Interactive Map Screen
- ✅ Functional Profile Screen
- ✅ Real-time Supabase data
- ✅ Professional UI

## 📚 Full Documentation

- **Setup Guide**: `docs/NGO_DASHBOARD_SETUP.md`
- **Technical Docs**: `lib/features/ngo_dashboard/README.md`
- **Summary**: `docs/NGO_DASHBOARD_SUMMARY.md`

## 🐛 Issues?

Check the troubleshooting section in `docs/NGO_DASHBOARD_SETUP.md`

## 🎉 Enjoy!

Your professional NGO dashboard is ready to use!
