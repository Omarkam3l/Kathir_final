# NGO Dashboard - Professional Implementation

## Overview
A complete, production-ready NGO dashboard implementation for the Kathir app, featuring dynamic meal listings, interactive maps, and comprehensive profile management.

## Features Implemented

### 1. NGO Home Screen (`ngo_home_screen.dart`)
- **Dynamic Meal Listings**: Real-time data from Supabase
- **Search & Filters**: Search by name, filter by category (vegetarian, nearby, large quantity)
- **Expiring Soon Section**: Highlights meals expiring within 2 hours
- **Stats Dashboard**: Shows meals claimed, carbon saved, and active orders
- **Claim Functionality**: One-tap meal claiming with order creation

### 2. NGO Map Screen (`ngo_map_screen.dart`)
- **Interactive Map**: Using flutter_map with OpenStreetMap tiles
- **Meal Markers**: Visual markers for each available meal location
- **Selected Meal Highlight**: Animated marker selection
- **Meal Carousel**: Swipeable cards at the bottom showing meal details
- **Location-based**: Centers on Chennai with dynamic meal locations

### 3. NGO Profile Screen (`ngo_profile_screen.dart`)
- **Organization Profile**: Display NGO name, location, verification status
- **Statistics Grid**: Meals claimed and carbon savings
- **Settings Menu**: Edit profile, legal documents, notifications
- **Logout Functionality**: Secure sign-out with Supabase

## Architecture

### Clean Architecture Pattern
```
presentation/
├── screens/          # UI screens
├── viewmodels/       # Business logic & state management
└── widgets/          # Reusable UI components

data/
├── datasources/      # Supabase data sources
└── repositories/     # Data repository implementations

domain/
├── entities/         # Business entities
├── repositories/     # Repository interfaces
└── usecases/         # Business use cases
```

### State Management
- **Provider**: Used for state management across all screens
- **ChangeNotifier**: ViewModels extend ChangeNotifier for reactive updates
- **Consumer**: Widgets consume ViewModels for automatic UI updates

## Database Integration

### Tables Used
1. **meals**: Surplus food listings
   - Filters: `is_donation_available = true`, `status = 'active'`
   - Joins with `restaurants` for restaurant details
   
2. **orders**: NGO meal claims
   - Creates orders with `delivery_type = 'donation'`
   - Tracks order status and history

3. **ngos**: NGO profile information
   - Organization details and verification status

### Queries Implemented
```sql
-- Load available meals
SELECT meals.*, restaurants.*
FROM meals
INNER JOIN restaurants ON meals.restaurant_id = restaurants.profile_id
WHERE meals.is_donation_available = true
  AND meals.status = 'active'
  AND meals.quantity_available > 0
  AND meals.expiry_date > NOW()
ORDER BY meals.expiry_date ASC;

-- Create claim order
INSERT INTO orders (user_id, ngo_id, restaurant_id, meal_id, status, delivery_type, total_amount)
VALUES ($1, $2, $3, $4, 'pending', 'donation', $5);

-- Update meal status
UPDATE meals SET status = 'reserved' WHERE id = $1;

-- Get NGO stats
SELECT COUNT(*) FROM orders
WHERE ngo_id = $1 AND status = 'completed';
```

## Widgets Created

### Core Widgets
1. **NgoStatCard**: Displays statistics (meals, carbon, orders)
2. **NgoMealCard**: List view meal card with claim button
3. **NgoUrgentCard**: Horizontal scroll card for expiring meals
4. **NgoMapMealCard**: Map carousel card with location info
5. **NgoBottomNav**: Bottom navigation bar with 5 tabs

### Features
- Dark mode support
- Responsive design
- Smooth animations
- Loading states
- Error handling

## ViewModels

### NgoHomeViewModel
- `loadData()`: Fetches meals and stats
- `setFilter(String)`: Applies category filters
- `setSearchQuery(String)`: Filters by search text
- `claimMeal(Meal, BuildContext)`: Claims a meal and creates order

### NgoMapViewModel
- `loadMeals()`: Fetches meals with location data
- `selectMeal(Meal)`: Highlights selected meal on map
- `claimMeal(Meal, BuildContext)`: Claims meal from map view

### NgoProfileViewModel
- `loadProfile()`: Fetches NGO profile and statistics
- `logout()`: Signs out user from Supabase

## Navigation Routes

Add these routes to your router configuration:

```dart
GoRoute(
  path: '/ngo/home',
  builder: (context, state) => ChangeNotifierProvider(
    create: (_) => NgoHomeViewModel(),
    child: const NgoHomeScreen(),
  ),
),
GoRoute(
  path: '/ngo/map',
  builder: (context, state) => ChangeNotifierProvider(
    create: (_) => NgoMapViewModel(),
    child: const NgoMapScreen(),
  ),
),
GoRoute(
  path: '/ngo/profile',
  builder: (context, state) => ChangeNotifierProvider(
    create: (_) => NgoProfileViewModel(),
    child: const NgoProfileScreen(),
  ),
),
```

## Dependencies Required

Ensure these are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5
  supabase_flutter: ^2.5.6
  go_router: ^14.2.0
  flutter_map: ^8.2.2
  latlong2: ^0.9.1
```

## Supabase Setup

### Row Level Security (RLS) Policies
The following RLS policies are already defined in `COMPLETE_SCHEMA_REFERENCE.sql`:

1. **Meals**: NGOs can view active donation meals
2. **Orders**: NGOs can create and view their own orders
3. **NGOs**: NGOs can view and update their own profile

### Storage Bucket
- **meal-images**: Public bucket for meal images
- Authenticated users can upload
- Public read access

## Usage

### 1. Initialize ViewModels
In your main app or dependency injection:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => NgoHomeViewModel()),
    ChangeNotifierProvider(create: (_) => NgoMapViewModel()),
    ChangeNotifierProvider(create: (_) => NgoProfileViewModel()),
  ],
  child: MyApp(),
)
```

### 2. Navigate to NGO Dashboard
```dart
context.go('/ngo/home');
```

### 3. Claim a Meal
The claim functionality:
1. Creates an order in the `orders` table
2. Updates meal status to 'reserved'
3. Shows success/error snackbar
4. Refreshes the meal list

## Testing

### Manual Testing Checklist
- [ ] Home screen loads meals from Supabase
- [ ] Search filters meals correctly
- [ ] Category filters work (vegetarian, nearby, large)
- [ ] Expiring soon section shows urgent meals
- [ ] Stats display correct numbers
- [ ] Claim button creates order and updates meal
- [ ] Map screen shows meal markers
- [ ] Map markers are clickable and show details
- [ ] Meal carousel syncs with map selection
- [ ] Profile screen loads NGO data
- [ ] Stats grid shows correct numbers
- [ ] Logout functionality works

### Test Data
Create test meals in Supabase:
```sql
INSERT INTO meals (restaurant_id, title, description, category, original_price, discounted_price, quantity_available, expiry_date, is_donation_available, status)
VALUES 
  ('restaurant-uuid', 'Test Biryani', 'Surplus biryani', 'Meals', 500, 0, 15, NOW() + INTERVAL '1 hour', true, 'active'),
  ('restaurant-uuid', 'Test Bread', 'Fresh bread', 'Bakery', 100, 50, 20, NOW() + INTERVAL '3 hours', true, 'active');
```

## Performance Optimizations

1. **Lazy Loading**: Meals loaded on demand
2. **Pagination**: Limit queries to 20 items (can be extended)
3. **Caching**: ViewModels cache data until refresh
4. **Optimistic Updates**: UI updates before server confirmation
5. **Image Optimization**: NetworkImage with caching

## Future Enhancements

### Recommended Features
1. **Real-time Updates**: Use Supabase Realtime for live meal updates
2. **Push Notifications**: Notify NGOs of new donations
3. **Advanced Filters**: Distance-based, dietary restrictions
4. **Order History**: Detailed order tracking and history
5. **Analytics Dashboard**: Charts and insights
6. **Multi-language Support**: i18n implementation
7. **Offline Mode**: Local caching with sync

### Supabase Functions
Create edge functions for:
- Automated meal expiry notifications
- Carbon savings calculations
- Matching algorithm for NGO-restaurant pairing

## Troubleshooting

### Common Issues

**Issue**: Meals not loading
- **Solution**: Check Supabase RLS policies, ensure user is authenticated

**Issue**: Map not displaying
- **Solution**: Verify flutter_map and latlong2 dependencies

**Issue**: Images not showing
- **Solution**: Check storage bucket permissions and image URLs

**Issue**: Claim button not working
- **Solution**: Verify orders table permissions and foreign key constraints

## Support

For issues or questions:
1. Check the database schema in `COMPLETE_SCHEMA_REFERENCE.sql`
2. Review Supabase logs for errors
3. Verify authentication state
4. Check network connectivity

## License

This implementation follows the Kathir app architecture and design patterns.
