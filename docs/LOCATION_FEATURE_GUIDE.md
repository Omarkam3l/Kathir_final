# Location Selection Feature - Implementation Guide

## Overview
This document describes the location selection feature implemented for Restaurants and NGOs in the Kathir app using OpenStreetMap and PostGIS.

## Features Implemented

### 1. Database Schema (PostGIS)
- **Tables Updated**: `restaurants` and `ngos`
- **New Columns**:
  - `latitude` (DOUBLE PRECISION) - Latitude coordinate
  - `longitude` (DOUBLE PRECISION) - Longitude coordinate
  - `location` (GEOGRAPHY(POINT, 4326)) - PostGIS geography point for spatial queries
  - `location_updated_at` (TIMESTAMPTZ) - Timestamp of last location update

### 2. Database Features
- **PostGIS Extension**: Enabled for advanced spatial queries
- **Automatic Triggers**: Auto-update `location` geography from lat/lng
- **Spatial Indexes**: GIST indexes for fast nearby searches
- **Helper Functions**:
  - `find_nearby_restaurants(lat, lng, radius, limit)` - Find restaurants within radius
  - `find_nearby_ngos(lat, lng, radius, limit)` - Find NGOs within radius

### 3. Flutter Services

#### LocationService (`lib/core/services/location_service.dart`)
Handles device location and permissions:
- Check location service status
- Request location permissions
- Get current GPS location
- Handle permission denied scenarios
- Open app/location settings
- Calculate distance between coordinates

#### GeocodingService (`lib/core/services/geocoding_service.dart`)
Handles address search and reverse geocoding:
- Search places by text query (OpenStreetMap Nominatim)
- Reverse geocode (coordinates → address)
- Debounced search for search-as-you-type
- No API key required

### 4. UI Components

#### LocationSelectorWidget (`lib/features/_shared/widgets/location_selector_widget.dart`)
Interactive map widget for location selection:
- **OpenStreetMap** integration via flutter_map
- **Three selection methods**:
  1. Tap on map
  2. Use current GPS location
  3. Search for address
- **Features**:
  - Real-time marker placement
  - Address search with suggestions
  - Reverse geocoding on map tap
  - Save location with address

### 5. Profile Integration

#### Restaurant Profile
- Location card in profile screen
- Shows current location or prompt to set
- Opens location selector on tap
- Saves to `restaurants` table

#### NGO Profile
- Location card in profile screen
- Shows current location or prompt to set
- Opens location selector on tap
- Saves to `ngos` table

### 6. Security (RLS Policies)
- Restaurant owners can update only their own location
- NGO users can update only their own location
- Everyone can read locations (for nearby search)
- Policies use `auth.uid()` for authentication

## Dependencies Added

```yaml
geolocator: ^13.0.2          # GPS location and permissions
permission_handler: ^11.3.1   # Permission handling
dio: ^5.7.0                   # HTTP client for geocoding
flutter_map: ^8.2.2           # Already present - OpenStreetMap
latlong2: ^0.9.1              # Already present - Coordinates
```

## Platform Configuration Required

### Android (`android/app/src/main/AndroidManifest.xml`)
Add permissions:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (`ios/Runner/Info.plist`)
Add permission descriptions:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby restaurants and set your location</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to show nearby restaurants</string>
```

## Usage Examples

### 1. Get Current Location
```dart
final locationService = LocationService();
final position = await locationService.getCurrentLocation();
if (position != null) {
  print('Lat: ${position.latitude}, Lng: ${position.longitude}');
}
```

### 2. Search for Places
```dart
final geocodingService = GeocodingService();
final results = await geocodingService.searchPlaces('Chennai');
for (var result in results) {
  print('${result.displayName}: ${result.latitude}, ${result.longitude}');
}
```

### 3. Find Nearby Restaurants (SQL)
```sql
SELECT * FROM find_nearby_restaurants(
  13.0827,  -- user latitude
  80.2707,  -- user longitude
  5000,     -- radius in meters (5km)
  20        -- limit results
);
```

### 4. Use Location Selector Widget
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LocationSelectorWidget(
      initialLatitude: 13.0827,
      initialLongitude: 80.2707,
      initialAddress: 'Chennai, India',
      onLocationSelected: (lat, lng, address) {
        // Save location
        print('Selected: $lat, $lng - $address');
      },
    ),
  ),
);
```

## Future Enhancements

### 1. Nearby Restaurant Search
Use the `find_nearby_restaurants` function to show restaurants near user:
```dart
final response = await supabase.rpc('find_nearby_restaurants', params: {
  'user_lat': userLatitude,
  'user_lng': userLongitude,
  'radius_meters': 5000,
  'limit_count': 20,
});
```

### 2. Distance Display
Show distance to restaurants in meal cards:
```dart
final distance = locationService.calculateDistance(
  userLat, userLng,
  restaurantLat, restaurantLng,
);
final formatted = locationService.formatDistance(distance); // "2.5km"
```

### 3. Map View for NGOs
Show all nearby restaurants on a map for NGOs to browse.

### 4. Delivery Radius
Restaurants can set a delivery radius, and only show meals to NGOs within that radius.

### 5. Route Planning
Integrate with navigation apps for NGOs to get directions to restaurants.

## Testing Checklist

- [ ] Run migration: `supabase migration up`
- [ ] Install dependencies: `flutter pub get`
- [ ] Test location permissions (allow/deny/permanently deny)
- [ ] Test GPS location retrieval
- [ ] Test map tap selection
- [ ] Test address search
- [ ] Test save location (restaurant)
- [ ] Test save location (NGO)
- [ ] Verify data in database
- [ ] Test on Android
- [ ] Test on iOS
- [ ] Test on Web (GPS may not work)

## Troubleshooting

### Location Permission Denied
- Check platform-specific permissions in manifest/plist
- Guide user to app settings
- Show clear error messages

### Geocoding Not Working
- Check internet connection
- Nominatim has rate limits (1 request/second)
- Consider caching results

### PostGIS Not Available
- Fallback to lat/lng columns works automatically
- Distance calculations will be less accurate
- Enable PostGIS extension in Supabase dashboard

### Map Not Loading
- Check internet connection
- OpenStreetMap tiles require internet
- Consider offline map tiles for production

## Architecture Notes

### Clean Architecture
- **Services**: Core location and geocoding logic
- **Widgets**: Reusable UI components
- **ViewModels**: State management for profiles
- **Repository Pattern**: Can be added for location data access

### State Management
- Uses `ChangeNotifier` for NGO profile
- Direct state management for restaurant profile
- Consider migrating to consistent pattern

### Error Handling
- All services return null on error (graceful degradation)
- UI shows appropriate error messages
- Permission flows guide user to settings

## Performance Considerations

1. **Debounced Search**: Prevents excessive API calls
2. **Spatial Indexes**: Fast nearby queries with GIST
3. **Lazy Loading**: Location only loaded when needed
4. **Caching**: Consider caching geocoding results

## Security Considerations

1. **RLS Policies**: Enforce user can only update own location
2. **Public Read**: Locations are public for nearby search
3. **No API Keys**: OpenStreetMap Nominatim is free (with rate limits)
4. **User Agent**: Required by Nominatim, set to app name

## Compliance

### OpenStreetMap Usage
- Attribution required when displaying maps
- Nominatim usage policy: https://operations.osmfoundation.org/policies/nominatim/
- Rate limit: 1 request per second
- User-Agent header required

## Support

For issues or questions:
1. Check Supabase logs for database errors
2. Check Flutter console for service errors
3. Verify PostGIS extension is enabled
4. Test with sample coordinates first
