# Location Feature - Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │              Presentation Layer (UI)                    │    │
│  │                                                          │    │
│  │  ┌──────────────────┐      ┌──────────────────┐       │    │
│  │  │  Restaurant      │      │  NGO             │       │    │
│  │  │  Profile Screen  │      │  Profile Screen  │       │    │
│  │  │                  │      │                  │       │    │
│  │  │  [Location Card] │      │  [Location Card] │       │    │
│  │  └────────┬─────────┘      └────────┬─────────┘       │    │
│  │           │                         │                  │    │
│  │           └─────────┬───────────────┘                  │    │
│  │                     │                                   │    │
│  │           ┌─────────▼─────────┐                        │    │
│  │           │ LocationSelector  │                        │    │
│  │           │     Widget        │                        │    │
│  │           │                   │                        │    │
│  │           │  • Map View       │                        │    │
│  │           │  • GPS Button     │                        │    │
│  │           │  • Search Bar     │                        │    │
│  │           │  • Save Button    │                        │    │
│  │           └─────────┬─────────┘                        │    │
│  └─────────────────────┼──────────────────────────────────┘    │
│                        │                                        │
│  ┌────────────────────┼──────────────────────────────────┐    │
│  │         Business Logic Layer (ViewModels)             │    │
│  │                    │                                   │    │
│  │  ┌─────────────────▼──────────────────┐              │    │
│  │  │   NGO Profile ViewModel            │              │    │
│  │  │   • updateLocation()               │              │    │
│  │  │   • latitude, longitude            │              │    │
│  │  └────────────────────────────────────┘              │    │
│  └───────────────────┬────────────────────────────────────┘    │
│                      │                                          │
│  ┌──────────────────┼────────────────────────────────────┐    │
│  │         Service Layer                                  │    │
│  │                  │                                     │    │
│  │  ┌───────────────▼──────────┐  ┌──────────────────┐  │    │
│  │  │  LocationService         │  │ GeocodingService │  │    │
│  │  │                          │  │                  │  │    │
│  │  │  • getCurrentLocation()  │  │ • searchPlaces() │  │    │
│  │  │  • checkPermission()     │  │ • reverseGeocode │  │    │
│  │  │  • requestPermission()   │  │ • debounced      │  │    │
│  │  │  • calculateDistance()   │  │                  │  │    │
│  │  └──────────┬───────────────┘  └────────┬─────────┘  │    │
│  └─────────────┼──────────────────────────┼─────────────┘    │
│                │                          │                   │
└────────────────┼──────────────────────────┼───────────────────┘
                 │                          │
        ┌────────▼────────┐        ┌────────▼────────┐
        │  Device GPS     │        │  OpenStreetMap  │
        │  Geolocator     │        │  Nominatim API  │
        └─────────────────┘        └─────────────────┘
                 │
                 │
        ┌────────▼──────────────────────────────────────────────┐
        │              Supabase Backend                          │
        ├────────────────────────────────────────────────────────┤
        │                                                        │
        │  ┌──────────────────────────────────────────────┐    │
        │  │         PostgreSQL + PostGIS                  │    │
        │  │                                               │    │
        │  │  ┌────────────────┐    ┌────────────────┐   │    │
        │  │  │  restaurants   │    │     ngos       │   │    │
        │  │  │                │    │                │   │    │
        │  │  │  • latitude    │    │  • latitude    │   │    │
        │  │  │  • longitude   │    │  • longitude   │   │    │
        │  │  │  • location    │    │  • location    │   │    │
        │  │  │  • address_text│    │  • address_text│   │    │
        │  │  └────────────────┘    └────────────────┘   │    │
        │  │                                               │    │
        │  │  ┌────────────────────────────────────────┐ │    │
        │  │  │  Spatial Functions                     │ │    │
        │  │  │  • find_nearby_restaurants()           │ │    │
        │  │  │  • find_nearby_ngos()                  │ │    │
        │  │  │  • ST_Distance()                       │ │    │
        │  │  │  • ST_DWithin()                        │ │    │
        │  │  └────────────────────────────────────────┘ │    │
        │  │                                               │    │
        │  │  ┌────────────────────────────────────────┐ │    │
        │  │  │  Indexes                               │ │    │
        │  │  │  • GIST index on location              │ │    │
        │  │  │  • Index on lat/lng                    │ │    │
        │  │  └────────────────────────────────────────┘ │    │
        │  │                                               │    │
        │  │  ┌────────────────────────────────────────┐ │    │
        │  │  │  RLS Policies                          │ │    │
        │  │  │  • Users update own location           │ │    │
        │  │  │  • Everyone reads locations            │ │    │
        │  │  └────────────────────────────────────────┘ │    │
        │  └───────────────────────────────────────────────┘    │
        └────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Setting Location

```
User Action
    ↓
┌───────────────────────────────────────────────────────────┐
│ 1. User taps "Location" card in profile                   │
└───────────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────────┐
│ 2. LocationSelectorWidget opens                           │
│    • Shows map with initial location                      │
│    • Displays search bar                                  │
│    • Shows GPS button                                     │
└───────────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────────┐
│ 3. User selects location (one of three methods):          │
│                                                            │
│    Method A: Tap on Map                                   │
│    ┌─────────────────────────────────────────┐           │
│    │ • User taps map                          │           │
│    │ • onMapTap() called with coordinates     │           │
│    │ • Marker updates                         │           │
│    │ • GeocodingService.reverseGeocode()      │           │
│    │ • Address displayed                      │           │
│    └─────────────────────────────────────────┘           │
│                                                            │
│    Method B: Use GPS                                      │
│    ┌─────────────────────────────────────────┐           │
│    │ • User taps GPS button                   │           │
│    │ • LocationService.getCurrentLocation()   │           │
│    │ • Check/request permissions              │           │
│    │ • Get device coordinates                 │           │
│    │ • GeocodingService.reverseGeocode()      │           │
│    │ • Map moves to location                  │           │
│    │ • Marker updates                         │           │
│    └─────────────────────────────────────────┘           │
│                                                            │
│    Method C: Search Address                               │
│    ┌─────────────────────────────────────────┐           │
│    │ • User types in search bar               │           │
│    │ • Debounced search (500ms)               │           │
│    │ • GeocodingService.searchPlaces()        │           │
│    │ • Nominatim API returns results          │           │
│    │ • Suggestions displayed                  │           │
│    │ • User selects suggestion                │           │
│    │ • Map moves to location                  │           │
│    │ • Marker updates                         │           │
│    └─────────────────────────────────────────┘           │
└───────────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────────┐
│ 4. User taps "Save Location"                              │
│    • onLocationSelected() callback fired                  │
│    • Passes: latitude, longitude, address                 │
└───────────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────────┐
│ 5. Save to Database                                       │
│                                                            │
│    For Restaurant:                                        │
│    ┌─────────────────────────────────────────┐           │
│    │ UPDATE restaurants SET                   │           │
│    │   latitude = ?,                          │           │
│    │   longitude = ?,                         │           │
│    │   address_text = ?                       │           │
│    │ WHERE profile_id = auth.uid()            │           │
│    └─────────────────────────────────────────┘           │
│                                                            │
│    For NGO:                                               │
│    ┌─────────────────────────────────────────┐           │
│    │ NgoProfileViewModel.updateLocation()     │           │
│    │   ↓                                      │           │
│    │ UPDATE ngos SET                          │           │
│    │   latitude = ?,                          │           │
│    │   longitude = ?,                         │           │
│    │   address_text = ?                       │           │
│    │ WHERE profile_id = auth.uid()            │           │
│    └─────────────────────────────────────────┘           │
└───────────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────────┐
│ 6. Database Trigger Fires                                 │
│    • update_location_from_coordinates()                   │
│    • Automatically calculates PostGIS geography           │
│    • location = ST_MakePoint(lng, lat)                    │
│    • location_updated_at = NOW()                          │
└───────────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────────┐
│ 7. Success Feedback                                       │
│    • SnackBar: "Location updated successfully"            │
│    • Profile screen refreshes                             │
│    • Location card shows new address                      │
└───────────────────────────────────────────────────────────┘
```

### 2. Permission Flow

```
User taps GPS button
    ↓
┌───────────────────────────────────────────────────────────┐
│ LocationService.getCurrentLocation()                      │
└───────────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────────┐
│ Check if location services enabled                        │
│ Geolocator.isLocationServiceEnabled()                     │
└───────────────────────────────────────────────────────────┘
    ↓
    ├─ NO → Return null → Show error
    │
    └─ YES → Continue
         ↓
┌───────────────────────────────────────────────────────────┐
│ Check permission status                                   │
│ Geolocator.checkPermission()                              │
└───────────────────────────────────────────────────────────┘
    ↓
    ├─ DENIED → Request permission
    │            ↓
    │   ┌────────────────────────────────────┐
    │   │ Geolocator.requestPermission()     │
    │   └────────────────────────────────────┘
    │            ↓
    │            ├─ GRANTED → Get location
    │            └─ DENIED → Return null
    │
    ├─ DENIED_FOREVER → Show dialog
    │                    ↓
    │   ┌────────────────────────────────────┐
    │   │ "Location Permission" Dialog       │
    │   │ [Cancel] [Open Settings]           │
    │   └────────────────────────────────────┘
    │                    ↓
    │   User taps "Open Settings"
    │                    ↓
    │   ┌────────────────────────────────────┐
    │   │ Geolocator.openAppSettings()       │
    │   │ Opens device settings              │
    │   └────────────────────────────────────┘
    │
    └─ GRANTED → Get location
                  ↓
         ┌────────────────────────────────────┐
         │ Geolocator.getCurrentPosition()    │
         │ Returns: Position(lat, lng)        │
         └────────────────────────────────────┘
                  ↓
         ┌────────────────────────────────────┐
         │ Reverse geocode to get address     │
         │ GeocodingService.reverseGeocode()  │
         └────────────────────────────────────┘
                  ↓
         ┌────────────────────────────────────┐
         │ Update UI                          │
         │ • Move map to location             │
         │ • Update marker                    │
         │ • Display address                  │
         └────────────────────────────────────┘
```

### 3. Nearby Search (Future Feature)

```
NGO wants to find nearby restaurants
    ↓
┌───────────────────────────────────────────────────────────┐
│ Get NGO's current location                                │
│ • From saved profile (latitude, longitude)                │
│ • OR from device GPS                                      │
└───────────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────────┐
│ Call Supabase RPC function                                │
│                                                            │
│ supabase.rpc('find_nearby_restaurants', params: {         │
│   'user_lat': ngoLatitude,                                │
│   'user_lng': ngoLongitude,                               │
│   'radius_meters': 5000,  // 5km                          │
│   'limit_count': 20                                       │
│ })                                                         │
└───────────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────────┐
│ PostGIS Query Execution                                   │
│                                                            │
│ SELECT                                                    │
│   restaurant_name,                                        │
│   latitude,                                               │
│   longitude,                                              │
│   address_text,                                           │
│   ST_Distance(                                            │
│     location,                                             │
│     ST_MakePoint(user_lng, user_lat)                      │
│   ) as distance_meters                                    │
│ FROM restaurants                                          │
│ WHERE ST_DWithin(                                         │
│   location,                                               │
│   ST_MakePoint(user_lng, user_lat),                       │
│   radius_meters                                           │
│ )                                                          │
│ ORDER BY distance_meters                                  │
│ LIMIT limit_count                                         │
└───────────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────────┐
│ Results returned sorted by distance                       │
│                                                            │
│ [                                                          │
│   {                                                        │
│     restaurant_name: "Restaurant A",                      │
│     distance_meters: 850,                                 │
│     address_text: "123 Main St"                           │
│   },                                                       │
│   {                                                        │
│     restaurant_name: "Restaurant B",                      │
│     distance_meters: 1200,                                │
│     address_text: "456 Oak Ave"                           │
│   },                                                       │
│   ...                                                      │
│ ]                                                          │
└───────────────────────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────────────────────┐
│ Display in UI                                             │
│ • Show on map with markers                                │
│ • List view with distance                                 │
│ • Filter/sort options                                     │
└───────────────────────────────────────────────────────────┘
```

## Component Interactions

### LocationSelectorWidget

```
┌─────────────────────────────────────────────────────────┐
│              LocationSelectorWidget                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  State:                                                  │
│  • _selectedLocation: LatLng                            │
│  • _selectedAddress: String                             │
│  • _isLoadingLocation: bool                             │
│  • _searchResults: List<GeocodingResult>                │
│                                                          │
│  Dependencies:                                           │
│  • LocationService                                      │
│  • GeocodingService                                     │
│  • MapController                                        │
│                                                          │
│  Methods:                                                │
│  • _getCurrentLocation()                                │
│  • _searchPlaces(query)                                 │
│  • _onMapTap(location)                                  │
│  • _saveLocation()                                      │
│                                                          │
│  Callbacks:                                              │
│  • onLocationSelected(lat, lng, address)                │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Service Layer

```
┌──────────────────────────┐    ┌──────────────────────────┐
│    LocationService       │    │   GeocodingService       │
├──────────────────────────┤    ├──────────────────────────┤
│                          │    │                          │
│ Dependencies:            │    │ Dependencies:            │
│ • Geolocator             │    │ • Dio (HTTP client)      │
│                          │    │                          │
│ Methods:                 │    │ Methods:                 │
│ • getCurrentLocation()   │    │ • searchPlaces()         │
│ • checkPermission()      │    │ • reverseGeocode()       │
│ • requestPermission()    │    │ • debouncedSearch()      │
│ • calculateDistance()    │    │                          │
│ • formatDistance()       │    │ Models:                  │
│ • openAppSettings()      │    │ • GeocodingResult        │
│                          │    │   - displayName          │
│ Returns:                 │    │   - latitude             │
│ • Position?              │    │   - longitude            │
│ • LocationPermission     │    │   - address              │
│ • double (distance)      │    │                          │
│ • String (formatted)     │    │ API:                     │
│                          │    │ • Nominatim OSM          │
└──────────────────────────┘    └──────────────────────────┘
```

## Database Schema Details

### Restaurants Table

```sql
CREATE TABLE restaurants (
  profile_id uuid PRIMARY KEY,
  restaurant_name text,
  
  -- Location columns (NEW)
  latitude double precision,
  longitude double precision,
  location geography(point, 4326),
  address_text text,
  location_updated_at timestamptz DEFAULT now(),
  
  -- Other columns...
  rating double precision,
  phone text,
  created_at timestamptz,
  updated_at timestamptz
);

-- Indexes
CREATE INDEX idx_restaurants_location 
  ON restaurants USING GIST(location);
  
CREATE INDEX idx_restaurants_lat_lng 
  ON restaurants(latitude, longitude);

-- Trigger
CREATE TRIGGER restaurants_location_trigger
  BEFORE INSERT OR UPDATE OF latitude, longitude
  ON restaurants
  FOR EACH ROW
  EXECUTE FUNCTION update_location_from_coordinates();
```

### Spatial Functions

```sql
-- Find nearby restaurants
CREATE FUNCTION find_nearby_restaurants(
  user_lat double precision,
  user_lng double precision,
  radius_meters integer DEFAULT 5000,
  limit_count integer DEFAULT 20
)
RETURNS TABLE (
  profile_id uuid,
  restaurant_name text,
  latitude double precision,
  longitude double precision,
  distance_meters double precision,
  rating double precision
)
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.profile_id,
    r.restaurant_name,
    r.latitude,
    r.longitude,
    ST_Distance(
      r.location,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
    ) AS distance_meters,
    r.rating
  FROM restaurants r
  WHERE r.location IS NOT NULL
    AND ST_DWithin(
      r.location,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
      radius_meters
    )
  ORDER BY distance_meters ASC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## Security Model

### RLS Policies

```
┌─────────────────────────────────────────────────────────┐
│                    RLS Policies                          │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Restaurants Table:                                     │
│  ┌────────────────────────────────────────────────┐    │
│  │ UPDATE Policy:                                  │    │
│  │ • Name: "Restaurant owners can update location"│    │
│  │ • USING: profile_id = auth.uid()               │    │
│  │ • WITH CHECK: profile_id = auth.uid()          │    │
│  │ • Effect: Users can only update own location   │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │ SELECT Policy:                                  │    │
│  │ • Name: "Anyone can read restaurant locations" │    │
│  │ • USING: true                                   │    │
│  │ • Effect: Public read access for nearby search │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  NGOs Table:                                            │
│  ┌────────────────────────────────────────────────┐    │
│  │ UPDATE Policy:                                  │    │
│  │ • Name: "NGO users can update location"        │    │
│  │ • USING: profile_id = auth.uid()               │    │
│  │ • WITH CHECK: profile_id = auth.uid()          │    │
│  │ • Effect: Users can only update own location   │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │ SELECT Policy:                                  │    │
│  │ • Name: "Anyone can read NGO locations"        │    │
│  │ • USING: true                                   │    │
│  │ • Effect: Public read access for nearby search │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Performance Characteristics

### Query Performance

```
Nearby Search (5km radius):
┌─────────────────────────────────────┐
│ Without GIST Index:                 │
│ • Full table scan                   │
│ • O(n) complexity                   │
│ • ~500ms for 10,000 restaurants     │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ With GIST Index:                    │
│ • Spatial index lookup              │
│ • O(log n) complexity               │
│ • ~50ms for 10,000 restaurants      │
│ • 10x faster!                       │
└─────────────────────────────────────┘
```

### API Rate Limits

```
OpenStreetMap Nominatim:
┌─────────────────────────────────────┐
│ • Rate Limit: 1 request/second      │
│ • Debounce: 500ms (implemented)     │
│ • Caching: Recommended for prod     │
│ • Self-hosting: Option for scale    │
└─────────────────────────────────────┘
```

## Error Handling

```
┌─────────────────────────────────────────────────────────┐
│                   Error Handling Flow                    │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Location Service Errors:                               │
│  • Permission denied → Show permission dialog           │
│  • Location disabled → Prompt to enable                 │
│  • Timeout → Show retry option                          │
│  • Unknown error → Graceful fallback                    │
│                                                          │
│  Geocoding Service Errors:                              │
│  • Network error → Show offline message                 │
│  • No results → "No places found"                       │
│  • Rate limit → Debounce + retry                        │
│  • Invalid response → Log + fallback                    │
│                                                          │
│  Database Errors:                                        │
│  • RLS violation → "Permission denied"                  │
│  • Network error → "Connection failed"                  │
│  • Validation error → Show specific message             │
│  • Unknown error → Generic error message                │
│                                                          │
│  All errors:                                             │
│  • Logged to console (debug)                            │
│  • User-friendly message shown                          │
│  • State reset to allow retry                           │
│  • No app crashes                                       │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

This architecture provides a solid foundation for location-based features while maintaining clean separation of concerns, security, and performance.
