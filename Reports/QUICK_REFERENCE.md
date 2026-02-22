# 📍 Location Feature - Quick Reference Card

## 🚀 Setup (One-Time)

```bash
# 1. Install dependencies (already done)
flutter pub get

# 2. Apply migration
supabase migration up
# OR run SQL manually in Supabase Dashboard

# 3. Verify
# Run VERIFY_LOCATION_SETUP.sql in Supabase
```

## 📱 User Flow

```
Profile → Location Card → Map Selector → Select → Save
```

### Three Ways to Select Location:
1. **Tap on Map** → Marker moves → Address updates
2. **GPS Button** → Gets current location → Map moves
3. **Search Bar** → Type address → Select from suggestions

## 💻 Code Examples

### Get Current Location
```dart
final locationService = LocationService();
final position = await locationService.getCurrentLocation();
// Returns: Position(latitude, longitude) or null
```

### Search Places
```dart
final geocodingService = GeocodingService();
final results = await geocodingService.searchPlaces('Chennai');
// Returns: List<GeocodingResult>
```

### Calculate Distance
```dart
final distance = locationService.calculateDistance(
  lat1, lng1, lat2, lng2
);
final formatted = locationService.formatDistance(distance);
// Returns: "2.5km" or "850m"
```

### Find Nearby Restaurants (SQL)
```sql
SELECT * FROM find_nearby_restaurants(
  13.0827,  -- latitude
  80.2707,  -- longitude
  5000,     -- radius (meters)
  20        -- limit
);
```

### Find Nearby Restaurants (Dart)
```dart
final response = await supabase.rpc('find_nearby_restaurants', params: {
  'user_lat': 13.0827,
  'user_lng': 80.2707,
  'radius_meters': 5000,
  'limit_count': 20,
});
```

## 🗄️ Database Schema

### Restaurants
```sql
restaurants (
  latitude double precision,
  longitude double precision,
  location geography(point, 4326),
  address_text text,
  location_updated_at timestamptz
)
```

### NGOs
```sql
ngos (
  latitude double precision,
  longitude double precision,
  location geography(point, 4326),
  address_text text,
  location_updated_at timestamptz
)
```

## 🔍 Verification Queries

### Check if locations are set
```sql
-- Restaurants
SELECT restaurant_name, latitude, longitude, address_text
FROM restaurants
WHERE latitude IS NOT NULL;

-- NGOs
SELECT organization_name, latitude, longitude, address_text
FROM ngos
WHERE latitude IS NOT NULL;
```

### Test nearby search
```sql
-- Find restaurants within 5km of Chennai center
SELECT * FROM find_nearby_restaurants(13.0827, 80.2707, 5000, 10);
```

## 🛠️ Troubleshooting

| Problem | Solution |
|---------|----------|
| GPS not working | Check permissions in device settings |
| Map not loading | Check internet connection |
| Search no results | Try more specific terms |
| Location not saving | Check Supabase logs, verify migration |
| PostGIS error | Enable PostGIS extension manually |

## 📂 Key Files

### Created
```
lib/core/services/
  ├── location_service.dart
  └── geocoding_service.dart

lib/features/_shared/widgets/
  └── location_selector_widget.dart

supabase/migrations/
  ├── 20260216_add_location_support.sql
  ├── VERIFY_LOCATION_SETUP.sql
  └── TEST_DATA_LOCATIONS.sql
```

### Modified
```
pubspec.yaml
android/app/src/main/AndroidManifest.xml
ios/Runner/Info.plist
lib/features/restaurant_dashboard/.../restaurant_profile_screen.dart
lib/features/ngo_dashboard/.../ngo_profile_screen.dart
lib/features/ngo_dashboard/.../ngo_profile_viewmodel.dart
```

## 🎯 Testing Checklist

- [ ] Apply migration
- [ ] Run verification script
- [ ] Test restaurant location selection
- [ ] Test NGO location selection
- [ ] Test GPS location
- [ ] Test map tap
- [ ] Test address search
- [ ] Test permissions (allow/deny)
- [ ] Verify data in database
- [ ] Test on Android
- [ ] Test on iOS

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| `FINAL_IMPLEMENTATION_SUMMARY.md` | Start here! |
| `docs/LOCATION_SETUP_QUICK_START.md` | Setup guide |
| `docs/LOCATION_FEATURE_GUIDE.md` | Technical details |
| `docs/LOCATION_ARCHITECTURE.md` | Architecture diagrams |
| `README_LOCATION_FEATURE.md` | Complete overview |
| `IMPLEMENTATION_CHECKLIST.md` | Progress tracking |

## 🔐 Permissions

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby restaurants</string>
```

## 🎨 UI Components

### Location Card (Profile)
- Shows current location or "Set location" prompt
- Green border when location is set
- Tap to open selector

### Location Selector
- Full-screen map
- Search bar at top
- GPS button (bottom right)
- Save button (bottom, full width)
- Red marker shows selected location

## ⚡ Performance Tips

1. **Use Spatial Indexes**: Already implemented (GIST)
2. **Debounce Search**: Already implemented (500ms)
3. **Cache Results**: Consider for production
4. **Limit Results**: Use limit parameter in queries

## 🔄 Common Workflows

### Set Restaurant Location
```
1. Login as restaurant
2. Profile → Location card
3. Select location (map/GPS/search)
4. Save
5. Verify in database
```

### Set NGO Location
```
1. Login as NGO
2. Profile → Location card
3. Select location (map/GPS/search)
4. Save
5. Verify in database
```

### Find Nearby Restaurants
```
1. Get NGO location
2. Call find_nearby_restaurants()
3. Display results
4. Show distance
```

## 📊 Sample Data

### Add Test Locations
```sql
-- Run in Supabase SQL Editor
-- supabase/migrations/TEST_DATA_LOCATIONS.sql
```

### Sample Coordinates (Chennai, India)
```
T. Nagar:    13.0418, 80.2341
Anna Nagar:  13.0850, 80.2101
Adyar:       13.0067, 80.2206
Mylapore:    13.0339, 80.2619
Velachery:   12.9750, 80.2200
```

## 🚀 Next Steps

### Phase 2: Nearby Search
```dart
// Show nearby restaurants on map
final nearby = await supabase.rpc('find_nearby_restaurants', ...);
// Display on map with markers
```

### Phase 3: Distance Display
```dart
// Show distance in meal cards
final distance = locationService.calculateDistance(...);
final formatted = locationService.formatDistance(distance);
```

### Phase 4: Advanced Features
- Delivery radius
- Route planning
- Real-time updates
- Location-based notifications

## 💡 Pro Tips

1. **Test Permissions First**: Ensure location services enabled
2. **Use Verification Script**: Catches setup issues early
3. **Add Test Data**: Makes testing easier
4. **Check Logs**: Supabase logs show database errors
5. **Start Simple**: Test map tap before GPS
6. **Test Both Roles**: Restaurant and NGO
7. **Verify Data**: Always check database after save

## 🆘 Quick Help

### Location Not Saving?
```sql
-- Check if migration ran
SELECT * FROM information_schema.columns 
WHERE table_name = 'restaurants' 
AND column_name = 'latitude';
```

### PostGIS Not Working?
```sql
-- Enable PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- Verify
SELECT PostGIS_version();
```

### Permission Issues?
```dart
// Open app settings
await locationService.openAppSettings();
```

## 📞 Support

- **Setup Issues**: See `docs/LOCATION_SETUP_QUICK_START.md`
- **Technical Details**: See `docs/LOCATION_FEATURE_GUIDE.md`
- **Architecture**: See `docs/LOCATION_ARCHITECTURE.md`
- **Overview**: See `README_LOCATION_FEATURE.md`

---

**Quick Start**: Apply migration → Test → Verify → Done! 🎉


## 📍 Order Pickup Locations (NEW!)

### Automatic Pickup Location Tracking

Orders now automatically track pickup locations based on fulfillment method.

### Pickup Location Logic

| Order Type | Pickup Location | Description |
|------------|----------------|-------------|
| **pickup** | Restaurant | Customer picks up from restaurant |
| **delivery** | Restaurant | Driver picks up from restaurant |
| **donation** | Restaurant | NGO picks up from restaurant |

### Database Columns (orders table)

```sql
pickup_latitude DOUBLE PRECISION
pickup_longitude DOUBLE PRECISION
pickup_location GEOGRAPHY(POINT, 4326)
pickup_address_text TEXT
```

### Get Order with Pickup Location

```dart
final order = await supabase
  .from('orders')
  .select('*, pickup_latitude, pickup_longitude, pickup_address_text')
  .eq('id', orderId)
  .single();

print('Pickup: ${order['pickup_address_text']}');
```

### Show Pickup on Map

```dart
final pickupLocation = LatLng(
  order['pickup_latitude'],
  order['pickup_longitude'],
);

Marker(
  point: pickupLocation,
  child: Icon(Icons.restaurant, color: Colors.red),
);
```

### Calculate Distance to Pickup

```dart
final distance = locationService.calculateDistance(
  userLat, userLng,
  order['pickup_latitude'],
  order['pickup_longitude'],
);
final formatted = locationService.formatDistance(distance);
```

### Helper Functions (SQL)

```sql
-- Get user orders with pickup locations
SELECT * FROM get_user_orders_with_pickup('user-uuid', 20);

-- Get restaurant orders with pickup locations
SELECT * FROM get_restaurant_orders_with_pickup('restaurant-uuid', 50);

-- Get NGO orders with pickup locations
SELECT * FROM get_ngo_orders_with_pickup('ngo-uuid', 30);
```

### Migration

```bash
# Apply migration
supabase migration up
# OR run: supabase/migrations/20260217_add_pickup_location_to_orders.sql
```

### Verify

```sql
-- Check if columns exist
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'orders' AND column_name LIKE 'pickup%';

-- Check data
SELECT order_number, delivery_type, pickup_address_text
FROM orders
WHERE pickup_latitude IS NOT NULL
LIMIT 5;
```

### Documentation

- **Complete Guide**: `docs/ORDER_PICKUP_LOCATION_GUIDE.md`
- **Summary**: `ORDER_PICKUP_LOCATION_SUMMARY.md`
- **Full Implementation**: `COMPLETE_LOCATION_IMPLEMENTATION.md`

---

**Quick Start**: Apply migration → Orders automatically get pickup locations! 🎉
