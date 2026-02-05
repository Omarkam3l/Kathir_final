# Meal Category Notifications System

## Overview
Users can subscribe to meal categories they're interested in and receive automatic notifications when restaurants add new meals in those categories.

## Database Structure

### Tables Created

#### 1. `user_category_preferences`
Stores which categories each user has subscribed to.

**Columns:**
- `id` (uuid) - Primary key
- `user_id` (uuid) - References auth.users
- `category` (text) - One of: Meals, Bakery, Meat & Poultry, Seafood, Vegetables, Desserts, Groceries
- `notifications_enabled` (boolean) - Whether notifications are active
- `created_at`, `updated_at` (timestamptz)

**Unique constraint:** (user_id, category) - Users can only subscribe once per category

#### 2. `category_notifications`
Tracks notifications sent to users.

**Columns:**
- `id` (uuid) - Primary key
- `user_id` (uuid) - Who received the notification
- `meal_id` (uuid) - Which meal triggered it
- `category` (text) - The meal category
- `sent_at` (timestamptz) - When notification was created
- `is_read` (boolean) - Whether user has seen it

## How It Works

### 1. User Subscribes to Categories
- User goes to Favorites screen → Meal Categories tab
- Taps on category cards to subscribe/unsubscribe
- Green border + checkmark = subscribed
- Grey border + empty circle = not subscribed

### 2. Automatic Notification Trigger
When a restaurant adds a new meal or updates an existing meal to "active" status:

```sql
-- Trigger function runs automatically
CREATE TRIGGER trg_notify_category_subscribers
AFTER INSERT OR UPDATE ON meals
FOR EACH ROW
EXECUTE FUNCTION notify_category_subscribers();
```

The trigger:
1. Checks if meal is active, has quantity > 0, and not expired
2. Finds all users subscribed to that meal's category
3. Creates notification records for each subscribed user
4. Excludes the restaurant itself from notifications

### 3. Viewing Notifications
Users can view their notifications through the `category_notifications` table:
- Filter by `user_id` and `is_read = false` for unread notifications
- Join with `meals` table to get meal details
- Mark as read by updating `is_read = true`

## Implementation in Flutter

### FavoritesViewModel Methods

```dart
// Load user's subscribed categories
await vm.loadCategoryPreferences();

// Subscribe/unsubscribe from a category
await vm.toggleCategorySubscription('Bakery');

// Check if subscribed
bool isSubscribed = vm.isCategorySubscribed('Bakery');

// Get all available categories
List<Map<String, dynamic>> categories = vm.availableCategories;
```

### Available Categories
1. **Meals** - Ready-to-eat meals
2. **Bakery** - Fresh bread & pastries
3. **Meat & Poultry** - Fresh meat & poultry
4. **Seafood** - Fresh fish & seafood
5. **Vegetables** - Farm fresh produce
6. **Desserts** - Sweet treats
7. **Groceries** - Pantry essentials

## Migration Steps

### Apply the Migration
1. Go to Supabase Dashboard → SQL Editor
2. Copy content from `supabase/migrations/20260204_meal_category_notifications.sql`
3. Paste and run it

### What Gets Created
- 2 new tables with RLS policies
- 1 trigger function for automatic notifications
- 1 view for notification summaries
- Indexes for performance

## Future Enhancements

### Push Notifications (Optional)
To add real push notifications:

1. **Use Supabase Edge Functions:**
```typescript
// supabase/functions/send-push-notification/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  const { user_id, meal_id, category } = await req.json()
  
  // Send push notification via FCM or similar
  // ...
})
```

2. **Call from trigger:**
```sql
-- Add to notify_category_subscribers function
PERFORM net.http_post(
  url := 'https://your-project.supabase.co/functions/v1/send-push-notification',
  body := json_build_object('user_id', ucp.user_id, 'meal_id', NEW.id, 'category', NEW.category)
);
```

### In-App Notification Badge
Add unread count to UI:

```dart
// Get unread count
final unreadCount = await supabase
  .from('category_notifications')
  .select('id', const FetchOptions(count: CountOption.exact))
  .eq('user_id', userId)
  .eq('is_read', false);
```

## Security

### Row Level Security (RLS)
All tables have RLS enabled:
- Users can only view/modify their own preferences
- Users can only view their own notifications
- Trigger runs with elevated privileges to create notifications

### Indexes
Optimized for common queries:
- `idx_user_category_preferences_user_id`
- `idx_category_notifications_user_id`
- `idx_category_notifications_is_read`

## Testing

### Test the System
1. Subscribe to "Bakery" category
2. Have a restaurant add a new Bakery meal
3. Check `category_notifications` table for new record
4. Verify notification appears for subscribed user only

### SQL Query to Check
```sql
SELECT 
  cn.*,
  m.title as meal_title,
  m.category
FROM category_notifications cn
JOIN meals m ON cn.meal_id = m.id
WHERE cn.user_id = 'your-user-id'
ORDER BY cn.sent_at DESC;
```

## Summary

✅ **Fixed:** Segmented button background now fills properly
✅ **Created:** Dynamic meal category subscription system
✅ **Automated:** Notifications trigger when new meals are added
✅ **Secure:** RLS policies protect user data
✅ **Scalable:** Indexed for performance with many users

The system is ready to use once you apply the migration!
