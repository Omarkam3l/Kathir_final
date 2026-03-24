# Onboarding Profile Setup Implementation

## Overview
Added a new profile setup screen to the onboarding flow that allows users to complete their profile before selecting meal categories.

## New Features

### 1. Profile Setup Screen (`profile_setup_screen.dart`)
A comprehensive profile setup screen that includes:
- **Avatar Upload**: Users can select and upload a profile picture from their gallery
- **Full Name**: Required field for user's full name
- **Phone Number**: Optional phone number field
- **Default Address**: Optional address selection using an interactive map
- **Skip Option**: Users can skip profile setup and complete it later

### 2. Address Selector Screen (`onboarding_address_selector_screen.dart`)
An interactive map-based address selector that allows users to:
- Search for locations using text search
- Get current location automatically
- Tap on the map to select a location
- Add a label for the address (Home, Work, etc.)
- View reverse geocoded address from coordinates

### 3. Database Schema Update
Added `is_profile_completed` column to the `profiles` table:
```sql
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS is_profile_completed BOOLEAN DEFAULT FALSE;
```

## Routing Logic

The router now handles three distinct cases for user onboarding:

### Case 1: Profile Completed (T), Categories Not Completed (F)
- **Flow**: Categories → Home
- **Logic**: User has completed profile but not selected categories
- **Action**: Show category selection screen, then navigate to home

### Case 2: Profile Not Completed (F), Categories Not Completed (F)
- **Flow**: Profile → Categories → Home
- **Logic**: User needs to complete both profile and categories
- **Action**: Show profile setup first, then categories, then home

### Case 3: Profile Not Completed (F), Categories Completed (T)
- **Flow**: Profile → Home
- **Logic**: User has selected categories but not completed profile
- **Action**: Show profile setup, then navigate to home

### Case 4: Both Completed (T, T)
- **Flow**: Home (Direct)
- **Logic**: User has completed both steps
- **Action**: Navigate directly to home screen

## Updated Files

### 1. `auth_provider.dart`
- Added `isProfileCompleted` field to `AuthUserView`
- Updated user getter to include `is_profile_completed` from database

### 2. `app_router.dart`
- Added routes for `/onboarding/profile` and `/onboarding/select-address`
- Implemented complex routing logic to handle all 4 cases
- Removed unused `isCategorySelection` variable

### 3. `category_selection_screen.dart`
- Updated to refresh auth provider after saving preferences
- Fixed navigation to go to `/home` instead of `/`
- Added comprehensive logging for debugging

### 4. `profile_setup_screen.dart` (New)
- Complete profile setup form with validation
- Avatar upload functionality
- Address selection integration
- Skip functionality
- Auth provider refresh after save

### 5. `onboarding_address_selector_screen.dart` (New)
- Interactive map using flutter_map
- Location search with geocoding
- Current location detection
- Reverse geocoding for selected locations

## Key Features

### Profile Setup Screen
```dart
- Avatar upload with image picker
- Form validation for required fields
- Optional phone number
- Optional address selection via map
- Gradient continue button
- Skip option
- Loading states
- Error handling with retry
```

### Address Selector
```dart
- OpenStreetMap integration
- Search with debouncing
- Current location detection
- Tap to select on map
- Reverse geocoding
- Address labeling
- Responsive UI
```

## Data Flow

1. **User logs in** → Auth provider loads profile data
2. **Router checks** → `is_profile_completed` and `is_onboarding_completed`
3. **Redirects based on flags**:
   - Both false → Profile Setup
   - Profile true, Categories false → Categories
   - Profile false, Categories true → Profile Setup
   - Both true → Home

4. **Profile Setup Save**:
   - Upload avatar to Supabase storage
   - Update profile with name, phone, avatar_url
   - Save address to user_addresses table
   - Set `is_profile_completed = true`
   - Refresh auth provider
   - Navigate to categories or home

5. **Category Selection Save**:
   - Save selected categories
   - Set `is_onboarding_completed = true`
   - Refresh auth provider
   - Navigate to home

## Database Tables

### profiles
```sql
- id (uuid, primary key)
- full_name (text)
- phone_number (text, nullable)
- avatar_url (text, nullable)
- is_profile_completed (boolean, default false)
- is_onboarding_completed (boolean, default false)
```

### user_addresses
```sql
- id (uuid, primary key)
- user_id (uuid, foreign key)
- label (text)
- address_text (text)
- latitude (double precision)
- longitude (double precision)
- is_default (boolean)
```

## Testing Scenarios

### Scenario 1: New User
1. User signs up
2. Redirected to profile setup
3. Completes profile
4. Redirected to category selection
5. Selects categories
6. Redirected to home

### Scenario 2: User Skips Profile
1. User signs up
2. Redirected to profile setup
3. Clicks "Skip for now"
4. Redirected to category selection
5. Selects categories
6. Redirected to home

### Scenario 3: User Skips Both
1. User signs up
2. Redirected to profile setup
3. Clicks "Skip for now"
4. Redirected to category selection
5. Clicks "Skip for now"
6. Redirected to home

### Scenario 4: Returning User
1. User logs in
2. Both flags are true
3. Redirected directly to home

## Logging

All screens include comprehensive logging:
- `[ProfileSetup]` prefix for profile setup logs
- `[CategorySelection]` prefix for category selection logs
- Logs include: user actions, database operations, navigation events, errors

## Error Handling

- Image picker errors with user feedback
- Avatar upload failures (continues without avatar)
- Database operation failures with retry option
- Navigation failures with fallback
- Location permission denials (graceful degradation)

## UI/UX Features

- Gradient buttons using app colors
- Smooth animations
- Loading states
- Form validation
- Skip options
- Interactive map
- Search functionality
- Current location detection
- Responsive design
- Error messages with retry actions

## Dependencies

- `image_picker`: For avatar selection
- `flutter_map`: For interactive maps
- `latlong2`: For coordinate handling
- `geolocator`: For location services
- `provider`: For state management
- `supabase_flutter`: For backend operations
- `google_fonts`: For typography

## Migration Steps

1. Run the SQL migration to add `is_profile_completed` column
2. Existing users will have the flag set to `true` (backward compatibility)
3. New users will have the flag set to `false` and go through profile setup
4. No data loss or breaking changes for existing users
