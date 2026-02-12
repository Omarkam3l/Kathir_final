# Rating System - Fixes Applied

## Issues Fixed

### 1. ❌ Hardcoded Review Count (120 reviews)

**Problem:** The review count was hardcoded to `0` in the data source, so it always showed `0` instead of the real count from the database.

**Root Cause:**
```dart
// OLD CODE - lib/features/user_home/data/datasources/home_remote_datasource.dart
'reviews_count': 0,  // ❌ Hardcoded!
```

**Solution:**
```dart
// NEW CODE
.select('''
  profile_id,
  restaurant_name,
  rating,
  rating_count,  // ✅ Added this column
  profiles!inner(avatar_url)
''')

// Map to model
'reviews_count': e['rating_count'] ?? 0,  // ✅ Now fetches real count
```

**Result:** Now shows actual review count from database (e.g., "5.0 (15 reviews)")

---

### 2. ✅ Rating Display in Top Rated Partners

**Updated:** `lib/features/user_home/presentation/widgets/top_rated_partners_section.dart`

**Before:**
```dart
Text('${restaurant.rating.toStringAsFixed(1)} • Available meals')
```

**After:**
```dart
Text('${restaurant.rating.toStringAsFixed(1)} (${restaurant.reviewsCount} reviews)')
```

**Result:** Now displays: "4.7 (15 reviews)" instead of just "4.7"

---

## How the Rating System Works

### Database Flow:

1. **User submits rating** via My Orders screen
   ```dart
   await ratingService.submitRating(
     orderId: orderId,
     rating: 5,
     reviewText: 'Great food!',
   );
   ```

2. **Rating saved** to `restaurant_ratings` table
   ```sql
   INSERT INTO restaurant_ratings (order_id, user_id, restaurant_id, rating, review_text)
   VALUES ('order-uuid', 'user-uuid', 'restaurant-uuid', 5, 'Great food!');
   ```

3. **Trigger fires automatically**
   ```sql
   CREATE TRIGGER trigger_update_restaurant_rating_insert
     AFTER INSERT ON restaurant_ratings
     FOR EACH ROW
     EXECUTE FUNCTION update_restaurant_rating();
   ```

4. **Average calculated and saved**
   ```sql
   UPDATE restaurants
   SET 
     rating = AVG(all ratings),  -- e.g., 4.7
     rating_count = COUNT(*),     -- e.g., 15
     updated_at = NOW()
   WHERE profile_id = restaurant_id;
   ```

5. **Rating displays everywhere**
   - Home screen (Top Rated Partners)
   - Restaurant profiles
   - Meal cards
   - Search results
   - Favorites
   - Leaderboard

---

## Rating Display Format

### Current Format:
```
⭐ 4.7 (15 reviews)
```

### Components:
- **Star icon** (⭐)
- **Average rating** (4.7) - rounded to 1 decimal
- **Review count** (15) - total number of ratings

### Where It Appears:
1. ✅ Top Rated Partners section (home screen)
2. ✅ Restaurant profile header
3. ✅ Meal detail screens
4. ✅ Search results
5. ✅ Favorites list

---

## Testing the Rating System

### Test Scenario:

1. **Create test orders:**
   ```sql
   -- Update an order to 'delivered' status
   UPDATE orders 
   SET status = 'delivered' 
   WHERE id = 'your-order-id';
   ```

2. **Submit ratings:**
   - Go to My Orders → Past tab
   - Click "Rate" on delivered order
   - Submit 5-star rating with review

3. **Verify database:**
   ```sql
   -- Check rating was saved
   SELECT * FROM restaurant_ratings 
   WHERE order_id = 'your-order-id';
   
   -- Check restaurant average updated
   SELECT rating, rating_count 
   FROM restaurants 
   WHERE profile_id = 'restaurant-id';
   ```

4. **Verify UI:**
   - Go to Home screen
   - Check "Top Rated Partners" section
   - Should show: "⭐ 5.0 (1 review)"

5. **Submit more ratings:**
   - Rate with 4 stars
   - Check average updates: "⭐ 4.5 (2 reviews)"

---

## Database Schema

### `restaurant_ratings` Table:
```sql
CREATE TABLE restaurant_ratings (
  id uuid PRIMARY KEY,
  order_id uuid UNIQUE,              -- One rating per order
  user_id uuid,                      -- Who rated
  restaurant_id uuid,                -- Which restaurant
  rating integer (1-5),              -- Star rating
  review_text text,                  -- Optional review
  created_at timestamptz,
  updated_at timestamptz
);
```

### `restaurants` Table (Updated):
```sql
ALTER TABLE restaurants 
ADD COLUMN rating_count integer DEFAULT 0;

-- Existing columns:
-- rating double precision DEFAULT 0  (average rating)
```

---

## API Functions

### 1. Submit Rating
```dart
await supabase.rpc('submit_restaurant_rating', params: {
  'p_order_id': 'order-uuid',
  'p_rating': 5,
  'p_review_text': 'Great food!',
});
```

### 2. Check if Can Rate
```dart
final result = await supabase.rpc('can_rate_order', params: {
  'p_order_id': 'order-uuid',
});
// Returns: { can_rate: true, already_rated: false, reason: '...' }
```

### 3. Get Restaurant Ratings
```dart
final ratings = await supabase.rpc('get_restaurant_ratings', params: {
  'p_restaurant_id': 'restaurant-uuid',
  'p_limit': 50,
  'p_offset': 0,
});
```

---

## Summary

✅ **Fixed:** Hardcoded review count (was 0, now shows real count)
✅ **Fixed:** Rating display format (now shows "4.7 (15 reviews)")
✅ **Working:** Automatic rating calculation via database triggers
✅ **Working:** Rating displays everywhere restaurants appear
✅ **Working:** Users can rate completed orders
✅ **Working:** Users can update existing ratings

The rating system is now **fully functional** and displays real data from the database!
