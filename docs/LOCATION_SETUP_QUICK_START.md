# Location Feature - Quick Start Guide

## 🚀 Setup Steps

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run Database Migration
Apply the migration to add location support to your Supabase database:

```bash
# If using Supabase CLI
supabase migration up

# Or manually run the SQL file in Supabase Dashboard:
# supabase/migrations/20260216_add_location_support.sql
```

### 3. Verify PostGIS Extension
In Supabase Dashboard → SQL Editor, run:
```sql
SELECT PostGIS_version();
```

If it returns an error, PostGIS is not enabled. The migration will enable it automatically, but you can also enable it manually:
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

### 4. Platform Configuration

#### Android
Already configured in `android/app/src/main/AndroidManifest.xml`:
- ✅ ACCESS_FINE_LOCATION
- ✅ ACCESS_COARSE_LOCATION
- ✅ INTERNET

#### iOS
Already configured in `ios/Runner/Info.plist`:
- ✅ NSLocationWhenInUseUsageDescription
- ✅ NSLocationAlwaysUsageDescription

### 5. Test the Feature

#### For Restaurant Users:
1. Login as a restaurant owner
2. Go to Profile tab
3. Scroll to "Location" section
4. Tap on the location card
5. Select location using:
   - Map tap
   - Current GPS location button
   - Search bar
6. Tap "Save Location"

#### For NGO Users:
1. Login as an NGO user
2. Go to Profile tab
3. Scroll to "Location" section
4. Tap on the location card
5. Select location (same as above)
6. Tap "Save Location"

### 6. Verify Data in Database

Check if location was saved:
```sql
-- For restaurants
SELECT 
  restaurant_name, 
  latitude, 
  longitude, 
  address_text,
  location_updated_at
FROM restaurants
WHERE latitude IS NOT NULL;

-- For NGOs
SELECT 
  organization_name, 
  latitude, 
  longitude, 
  address_text,
  location_updated_at
FROM ngos
WHERE latitude IS NOT NULL;
```

## 🧪 Testing Nearby Search (Future Feature)

Once locations are set, test the nearby search function:

```sql
-- Find restaurants near a location (e.g., Chennai)
SELECT * FROM find_nearby_restaurants(
  13.0827,  -- latitude
  80.2707,  -- longitude
  5000,     -- radius in meters (5km)
  20        -- limit
);

-- Find NGOs near a location
SELECT * FROM find_nearby_ngos(
  13.0827,  -- latitude
  80.2707,  -- longitude
  5000,     -- radius in meters
  20        -- limit
);
```

## 📱 User Flow

### Setting Location
```
Profile Screen
    ↓
Tap "Location" Card
    ↓
Location Selector Opens
    ↓
Choose Method:
  • Tap on map
  • Use GPS (button)
  • Search address
    ↓
Marker updates on map
    ↓
Tap "Save Location"
    ↓
Location saved to database
    ↓
Return to profile
```

### Permission Flow
```
User taps GPS button
    ↓
Check permission status
    ↓
If denied → Request permission
    ↓
If granted → Get location
    ↓
If permanently denied → Show dialog
    ↓
Dialog offers "Open Settings"
```

## 🔧 Troubleshooting

### Location Permission Issues
**Problem**: GPS button doesn't work
**Solution**: 
1. Check app permissions in device settings
2. Ensure location services are enabled
3. Try the "Open Settings" button in the permission dialog

### Map Not Loading
**Problem**: Map tiles don't appear
**Solution**:
1. Check internet connection
2. OpenStreetMap requires internet
3. Check for firewall/proxy issues

### Geocoding Not Working
**Problem**: Search doesn't return results
**Solution**:
1. Check internet connection
2. Nominatim has rate limits (1 req/sec)
3. Try more specific search terms

### Database Errors
**Problem**: Location not saving
**Solution**:
1. Check Supabase logs
2. Verify migration ran successfully
3. Check RLS policies are active
4. Verify user is authenticated

### PostGIS Not Available
**Problem**: `find_nearby_restaurants` function fails
**Solution**:
1. Enable PostGIS extension manually
2. Fallback: Use lat/lng columns directly
3. Check Supabase plan supports PostGIS

## 📊 Database Schema

### Restaurants Table
```sql
restaurants
├── profile_id (uuid, PK)
├── restaurant_name (text)
├── latitude (double precision) ← NEW
├── longitude (double precision) ← NEW
├── location (geography) ← NEW
├── address_text (text) ← UPDATED
└── location_updated_at (timestamptz) ← NEW
```

### NGOs Table
```sql
ngos
├── profile_id (uuid, PK)
├── organization_name (text)
├── latitude (double precision) ← NEW
├── longitude (double precision) ← NEW
├── location (geography) ← NEW
├── address_text (text) ← UPDATED
└── location_updated_at (timestamptz) ← NEW
```

## 🎯 Next Steps

### Implement Nearby Restaurant Search
```dart
// In NGO home screen or map view
final response = await supabase.rpc('find_nearby_restaurants', params: {
  'user_lat': ngoLatitude,
  'user_lng': ngoLongitude,
  'radius_meters': 5000,
  'limit_count': 20,
});

// Display results in a list or map
```

### Add Distance Display
```dart
final locationService = LocationService();
final distance = locationService.calculateDistance(
  userLat, userLng,
  restaurantLat, restaurantLng,
);
final formatted = locationService.formatDistance(distance);
// Shows: "2.5km" or "850m"
```

### Filter by Distance
```dart
// Show only restaurants within 3km
final nearbyRestaurants = allRestaurants.where((restaurant) {
  final distance = locationService.calculateDistance(
    userLat, userLng,
    restaurant.latitude, restaurant.longitude,
  );
  return distance <= 3000; // 3km in meters
}).toList();
```

## 📚 Additional Resources

- [Full Documentation](./LOCATION_FEATURE_GUIDE.md)
- [PostGIS Documentation](https://postgis.net/documentation/)
- [OpenStreetMap Nominatim](https://nominatim.org/release-docs/latest/)
- [Geolocator Package](https://pub.dev/packages/geolocator)
- [Flutter Map Package](https://pub.dev/packages/flutter_map)

## ✅ Checklist

- [ ] Dependencies installed (`flutter pub get`)
- [ ] Migration applied to Supabase
- [ ] PostGIS extension verified
- [ ] Android permissions configured
- [ ] iOS permissions configured
- [ ] Tested on restaurant profile
- [ ] Tested on NGO profile
- [ ] Verified data in database
- [ ] Tested GPS location
- [ ] Tested map tap selection
- [ ] Tested address search
- [ ] Tested permission flows

## 🎉 Success Criteria

You'll know the feature is working when:
1. ✅ Location card appears in both restaurant and NGO profiles
2. ✅ Tapping location card opens map selector
3. ✅ GPS button gets current location
4. ✅ Map tap updates marker and address
5. ✅ Search finds places and updates map
6. ✅ Save button stores location in database
7. ✅ Location persists after app restart
8. ✅ Nearby search function returns results

## 🆘 Need Help?

If you encounter issues:
1. Check the [Full Documentation](./LOCATION_FEATURE_GUIDE.md)
2. Review Supabase logs for database errors
3. Check Flutter console for service errors
4. Verify all setup steps completed
5. Test with sample coordinates first
