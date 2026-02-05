# Free Meal Notifications - Separate System

## Overview
Free meal notifications are now completely separate from regular category notifications, with their own table, special visual design, and priority placement.

## Database Changes

### New Table: `free_meal_user_notifications`
```sql
- id: uuid (primary key)
- user_id: uuid (who receives notification)
- meal_id: uuid (the free meal)
- donation_id: uuid (links to donation record)
- restaurant_id: uuid (who donated)
- sent_at: timestamp
- is_read: boolean
- claimed: boolean (did user claim this meal?)
- claimed_at: timestamp (when they claimed it)
```

### Key Differences from Category Notifications:
1. **Separate table** - not mixed with regular notifications
2. **Tracks claims** - knows if user claimed the meal
3. **Links to donation** - full audit trail
4. **Restaurant info** - includes who donated

## Visual Design Differences

### Free Meal Notifications:
- 🎁 **Special Icon**: Gift/heart icon instead of category icon
- 🟢 **Green accent**: Uses AppColors.primaryGreen
- ⭐ **Priority badge**: "FREE" badge prominently displayed
- 📍 **Top of list**: Always shown before regular notifications
- ⏰ **Urgency indicator**: Shows quantity remaining
- 🏃 **Action button**: "Claim Now" button (not just view)

### Regular Category Notifications:
- 📦 Standard category icon
- 🔵 Blue/neutral accent
- 📝 Simple text
- 📅 Chronological order
- 👁️ "View" button

## UI Implementation Plan

### Notifications Screen Structure:
```
┌─────────────────────────────────────┐
│  Notifications                   ← │
├─────────────────────────────────────┤
│                                     │
│  🎁 FREE MEALS (2)                  │
│  ┌───────────────────────────────┐ │
│  │ 🎁 [Image] FREE                │ │
│  │ Grilled Chicken Salad          │ │
│  │ From: Shankes Restaurant       │ │
│  │ ⚡ Only 3 left!                │ │
│  │ [Claim Now →]                  │ │
│  └───────────────────────────────┘ │
│                                     │
│  📬 CATEGORY UPDATES (5)            │
│  ┌───────────────────────────────┐ │
│  │ 📦 [Image]                     │ │
│  │ New Meals Available            │ │
│  │ 2 hours ago                    │ │
│  │ [View →]                       │ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

### Free Meal Notification Card Features:
1. **Large prominent card** (taller than regular)
2. **Gradient background** (subtle green gradient)
3. **FREE badge** on image
4. **Quantity indicator** with urgency colors:
   - Green: 5+ available
   - Orange: 2-4 available  
   - Red: 1 available
5. **Restaurant name** with logo
6. **"Claim Now" button** (green, prominent)
7. **Countdown** if expiring soon

## Backend Functions

### 1. `donate_meal(meal_id, restaurant_id)`
- Sets meal price to 0
- Creates donation record
- Sends free meal notifications to ALL users
- Returns success (no user count for privacy)

### 2. `get_free_meal_notifications(user_id, limit)`
- Returns user's free meal notifications
- Includes meal details (title, image, quantity)
- Includes restaurant details (name, logo)
- Ordered by sent_at DESC
- Shows claimed status

## Flutter Implementation Steps

### 1. Update Notifications Screen
```dart
// Fetch both types of notifications
final freeMealNotifications = await _supabase.rpc(
  'get_free_meal_notifications',
  params: {'p_user_id': userId, 'p_limit': 50}
);

final categoryNotifications = await _supabase
  .from('category_notifications')
  .select(...)
  .eq('user_id', userId);
```

### 2. Create FreeMealNotificationCard Widget
```dart
class FreeMealNotificationCard extends StatelessWidget {
  final FreeMealNotification notification;
  
  // Special design with:
  // - Green gradient background
  // - FREE badge
  // - Quantity indicator
  // - Claim Now button
}
```

### 3. Update Notifications List
```dart
ListView(
  children: [
    // Free meals section (if any)
    if (freeMealNotifications.isNotEmpty) ...[
      SectionHeader(title: '🎁 FREE MEALS', count: freeMealNotifications.length),
      ...freeMealNotifications.map((n) => FreeMealNotificationCard(n)),
      SizedBox(height: 16),
    ],
    
    // Regular notifications section
    if (categoryNotifications.isNotEmpty) ...[
      SectionHeader(title: '📬 CATEGORY UPDATES', count: categoryNotifications.length),
      ...categoryNotifications.map((n) => CategoryNotificationCard(n)),
    ],
  ],
)
```

### 4. Handle Claim Action
```dart
Future<void> _claimFreeMeal(FreeMealNotification notification) async {
  // Navigate to meal detail
  context.push('/meal/${notification.mealId}');
  
  // Mark as claimed when user completes checkout
  await _supabase
    .from('free_meal_user_notifications')
    .update({'claimed': true, 'claimed_at': DateTime.now().toIso8601String()})
    .eq('id', notification.id);
}
```

## Benefits

### For Users:
✅ **Immediate visibility** - free meals stand out
✅ **Clear urgency** - quantity indicators
✅ **Quick action** - "Claim Now" button
✅ **No confusion** - separate from regular notifications
✅ **Track claims** - know what they've claimed

### For Restaurants:
✅ **Privacy protected** - no user count shown
✅ **Impact tracking** - can see donation history
✅ **Fair distribution** - first-come, first-served
✅ **Quantity control** - limited by availability

### For Platform:
✅ **Better engagement** - special treatment increases claims
✅ **Analytics** - track donation impact
✅ **Scalability** - separate tables perform better
✅ **Flexibility** - can add features without affecting regular notifications

## Migration Order

1. Run `20260205_free_meal_donations.sql` (creates base tables)
2. Run `20260205_free_meal_notifications_system.sql` (creates notification system)
3. Update Flutter notifications screen
4. Test donation flow
5. Test notification display
6. Test claim tracking

## Next Steps

1. ✅ Database migration created
2. ⏳ Update notifications screen UI
3. ⏳ Create FreeMealNotificationCard widget
4. ⏳ Add claim tracking
5. ⏳ Add analytics dashboard for restaurants
6. ⏳ Add push notifications for free meals

## Status: 🟡 Database Ready, UI Pending
