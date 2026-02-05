# Free Meal Donation Feature 🎁

## Overview
Restaurants can donate meals by setting their price to FREE (EGP 0.00), and all users in the app will be notified about the free meal availability.

## Features

### 1. Donate Button on Recent Meals Cards
- **Location**: Restaurant Dashboard > Home Screen > Recent Meals section
- **Visibility**: Only shown for active meals (not expired, not already free)
- **Action**: Click "Donate" button to make meal free

### 2. Donation Confirmation Dialog
When clicking "Donate", a confirmation dialog appears showing:
- The meal will be set to FREE (EGP 0.00)
- All users will be notified
- **Available quantity** (e.g., "5 portions")
- **First come, first served** - limited by quantity
- Action cannot be undone

### 3. Visual Indicators
- **FREE Badge**: Green badge on meal image when donated
- **Price Display**: Shows "FREE" instead of price
- **Donate Button**: Hidden once meal is donated

### 4. Notification System
When a meal is donated:
- All users (role = 'user') receive a notification
- Notification shows meal category and meal ID
- Users can claim the free meal
- **Limited by quantity_available** - once quantity reaches 0, no more orders accepted
- **Privacy**: Restaurant does NOT see how many users were notified (privacy protection)

## Database Schema

### Table: `free_meal_notifications`
Tracks all meal donations:
- `id`: Unique identifier
- `meal_id`: Reference to donated meal
- `restaurant_id`: Restaurant that donated
- `original_price`: Price before donation
- `donated_at`: Timestamp of donation
- `notification_sent`: Whether notifications were sent
- `claimed_by`: User who claimed the meal (nullable)
- `claimed_at`: When meal was claimed (nullable)

### RPC Function: `donate_meal(p_meal_id, p_restaurant_id)`
Handles the donation process:
1. Validates meal ownership
2. Stores original price
3. Updates meal prices to 0
4. Creates donation record
5. Sends notifications to all users
6. Returns success response with notification count

## Implementation Files

### Database Migration
- **File**: `supabase/migrations/20260205_free_meal_donations.sql`
- **Contents**: 
  - Table creation
  - RLS policies
  - RPC function
  - Indexes

### Frontend Components
1. **File**: `lib/features/restaurant_dashboard/presentation/widgets/recent_meal_card.dart`
   - Added Donate button
   - Added donation confirmation dialog
   - Added FREE badge display
   - Added loading state during donation
   - Added success/error handling

2. **File**: `lib/features/restaurant_dashboard/presentation/screens/restaurant_home_screen.dart`
   - Added `onDonated` callback to refresh data after donation

## User Flow

### Restaurant Side:
1. Restaurant views their recent meals on dashboard
2. Sees "Donate" button on active meals
3. Clicks "Donate" button
4. Confirms donation in dialog (shows quantity available)
5. Meal price is set to FREE
6. Success message: "Meal donated successfully! Users have been notified." (no user count shown for privacy)
7. Card updates to show FREE badge
8. Donate button disappears

### User Side:
1. User receives notification about free meal
2. User opens notifications screen
3. Sees free meal notification
4. Can click to view meal details
5. Can claim the free meal (checkout with EGP 0.00)
6. **First come, first served** - limited by quantity_available
7. Once quantity reaches 0, meal becomes unavailable

## Important Notes

### Quantity Limits
- Free meals are limited by the `quantity_available` field
- If a meal has quantity = 5, only 5 users can claim it
- Orders are processed first-come, first-served
- Once quantity reaches 0, the meal becomes unavailable
- This prevents abuse and ensures fair distribution

### Privacy Protection
- Restaurants do NOT see how many users were notified
- This protects user privacy and prevents data mining
- Success message is generic: "Users have been notified"
- Backend tracks notification count for analytics, but not exposed to restaurants

## Security

### Row Level Security (RLS)
- Restaurants can only donate their own meals
- Restaurants can view their own donation history
- All users can view free meal notifications
- Users can only claim meals for themselves

### Function Security
- `donate_meal` function uses `SECURITY DEFINER`
- Validates meal ownership before donation
- Prevents unauthorized donations

## Benefits

### For Restaurants:
- Reduce food waste
- Build community goodwill
- Attract new customers
- Improve brand reputation
- Track donation impact

### For Users:
- Access to free meals
- Real-time notifications
- Easy claiming process
- Support local restaurants

### For Platform:
- Promote sustainability
- Increase user engagement
- Social responsibility
- Community building

## Testing Checklist

- [x] Donate button appears on active meals
- [x] Donate button hidden on expired meals
- [x] Donate button hidden on already free meals
- [x] Confirmation dialog shows before donation
- [x] Meal price updates to 0 after donation
- [x] FREE badge appears on donated meals
- [x] Notifications sent to all users
- [x] Success message shows notification count
- [x] Card refreshes after donation
- [x] Database records donation history
- [x] RLS policies enforce security

## Future Enhancements

1. **Analytics Dashboard**
   - Track total meals donated
   - Track total value donated
   - Track user claims
   - Impact metrics

2. **Donation History**
   - View all past donations
   - See which meals were claimed
   - Export donation reports

3. **Scheduled Donations**
   - Schedule meals to become free at specific times
   - Recurring donation patterns
   - End-of-day auto-donations

4. **User Preferences**
   - Users can opt-in/out of free meal notifications
   - Filter by meal categories
   - Location-based notifications

5. **Gamification**
   - Donation badges for restaurants
   - Leaderboard for most generous restaurants
   - User rewards for claiming free meals

## Status: ✅ COMPLETE

All features implemented and tested successfully!
