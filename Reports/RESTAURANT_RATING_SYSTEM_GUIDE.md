# Restaurant Rating System - Complete Implementation Guide

## Overview

Complete rating system where users can rate restaurants after order completion. Ratings are automatically aggregated and displayed throughout the app.

---

## Database Changes

### 1. New Table: `restaurant_ratings`

Stores individual ratings from users:

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

### 2. Updated Table: `restaurants`

Added rating count column:

```sql
ALTER TABLE restaurants 
ADD COLUMN rating_count integer DEFAULT 0;

-- Existing columns:
-- rating double precision DEFAULT 0  (average rating)
```

---

## How It Works

### 1. User Rates Restaurant

```dart
// In Flutter app
final result = await supabase.rpc('submit_restaurant_rating', params: {
  'p_order_id': orderId,
  'p_rating': 5,  // 1-5 stars
  'p_review_text': 'Great food!',  // Optional
});
```

### 2. Automatic Rating Calculation

When a rating is submitted:
1. ✅ Rating saved to `restaurant_ratings` table
2. ✅ Trigger fires automatically
3. ✅ Calculates new average rating for restaurant
4. ✅ Updates `restaurants.rating` and `restaurants.rating_count`
5. ✅ New rating appears everywhere instantly

### 3. Rating Display

Restaurant rating is shown in:
- ✅ Home screen (meal cards)
- ✅ Restaurant profile
- ✅ Meal details
- ✅ Search results
- ✅ Favorites
- ✅ Anywhere restaurants are displayed

---

## Flutter Implementation

### Step 1: Create Rating Dialog Widget

```dart
// lib/features/orders/presentation/widgets/rating_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingDialog extends StatefulWidget {
  final String orderId;
  final String restaurantName;
  final Function(int rating, String? review) onSubmit;

  const RatingDialog({
    Key? key,
    required this.orderId,
    required this.restaurantName,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 5.0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);
    
    try {
      await widget.onSubmit(_rating.toInt(), _reviewController.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rate ${widget.restaurantName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How was your experience?'),
            const SizedBox(height: 20),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() => _rating = rating);
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                hintText: 'Write a review (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitRating,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
```

### Step 2: Add Rating Service

```dart
// lib/features/orders/data/services/rating_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class RatingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Submit or update restaurant rating
  Future<void> submitRating({
    required String orderId,
    required int rating,
    String? reviewText,
  }) async {
    try {
      final response = await _supabase.rpc('submit_restaurant_rating', params: {
        'p_order_id': orderId,
        'p_rating': rating,
        'p_review_text': reviewText,
      });

      if (response['success'] != true) {
        throw Exception(response['error'] ?? 'Failed to submit rating');
      }
    } catch (e) {
      print('Error submitting rating: $e');
      rethrow;
    }
  }

  /// Check if user can rate an order
  Future<Map<String, dynamic>> canRateOrder(String orderId) async {
    try {
      final response = await _supabase.rpc('can_rate_order', params: {
        'p_order_id': orderId,
      });

      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error checking rating eligibility: $e');
      return {
        'can_rate': false,
        'reason': 'Error checking eligibility',
      };
    }
  }

  /// Get restaurant ratings
  Future<List<Map<String, dynamic>>> getRestaurantRatings({
    required String restaurantId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.rpc('get_restaurant_ratings', params: {
        'p_restaurant_id': restaurantId,
        'p_limit': limit,
        'p_offset': offset,
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching ratings: $e');
      return [];
    }
  }
}
```

### Step 3: Update My Orders Screen

```dart
// In lib/features/orders/presentation/screens/my_orders_screen_new.dart

// Add this method to show rating dialog
void _showRatingDialog(BuildContext context, Map<String, dynamic> order) {
  showDialog(
    context: context,
    builder: (context) => RatingDialog(
      orderId: order['id'],
      restaurantName: order['restaurant_name'] ?? 'Restaurant',
      onSubmit: (rating, review) async {
        final ratingService = RatingService();
        await ratingService.submitRating(
          orderId: order['id'],
          rating: rating,
          reviewText: review,
        );
        // Refresh orders list
        setState(() {});
      },
    ),
  );
}

// Update the Rate button onPressed
TextButton(
  onPressed: () => _showRatingDialog(context, order),
  child: const Text('Rate'),
)
```

### Step 4: Display Rating in Restaurant Cards

```dart
// Wherever you display restaurant info, add:

Row(
  children: [
    const Icon(Icons.star, color: Colors.amber, size: 16),
    const SizedBox(width: 4),
    Text(
      restaurant['rating']?.toStringAsFixed(1) ?? '0.0',
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    const SizedBox(width: 4),
    Text(
      '(${restaurant['rating_count'] ?? 0})',
      style: TextStyle(color: Colors.grey[600], fontSize: 12),
    ),
  ],
)
```

---

## Database Functions (RPC)

### 1. `submit_restaurant_rating()`

Submit or update a rating:

```dart
await supabase.rpc('submit_restaurant_rating', params: {
  'p_order_id': 'order-uuid',
  'p_rating': 5,
  'p_review_text': 'Great food!',
});
```

**Returns:**
```json
{
  "success": true,
  "rating_id": "rating-uuid",
  "message": "Rating submitted successfully"
}
```

**Validations:**
- ✅ User must be authenticated
- ✅ Rating must be 1-5
- ✅ Order must belong to user
- ✅ Order must be completed/delivered
- ✅ Automatically updates restaurant average

### 2. `can_rate_order()`

Check if user can rate an order:

```dart
final result = await supabase.rpc('can_rate_order', params: {
  'p_order_id': 'order-uuid',
});
```

**Returns:**
```json
{
  "can_rate": true,
  "already_rated": false,
  "reason": "Can submit new rating"
}
```

### 3. `get_restaurant_ratings()`

Get all ratings for a restaurant:

```dart
final ratings = await supabase.rpc('get_restaurant_ratings', params: {
  'p_restaurant_id': 'restaurant-uuid',
  'p_limit': 50,
  'p_offset': 0,
});
```

**Returns:**
```json
[
  {
    "id": "rating-uuid",
    "rating": 5,
    "review_text": "Great food!",
    "user_name": "John Doe",
    "user_avatar": "https://...",
    "created_at": "2026-02-12T10:30:00Z",
    "order_id": "order-uuid"
  }
]
```

---

## Rating Calculation

### How Average is Calculated

```sql
-- Automatic calculation on every rating change
AVG(rating) FROM restaurant_ratings WHERE restaurant_id = 'xxx'
```

**Example:**
- User A rates 5 stars
- User B rates 4 stars
- User C rates 5 stars
- **Average: (5 + 4 + 5) / 3 = 4.7 stars**

### Display Format

- **Average:** Rounded to 1 decimal place (e.g., 4.7)
- **Count:** Total number of ratings (e.g., (234))
- **Display:** "4.7 ⭐ (234 ratings)"

---

## UI/UX Flow

### 1. User Completes Order

Order status changes to `delivered` or `completed`

### 2. Rate Button Appears

In "My Orders" screen, "Rate" button shows for completed orders

### 3. User Clicks Rate

Rating dialog opens with:
- Restaurant name
- 5-star rating selector
- Optional text review field
- Submit button

### 4. User Submits Rating

- Rating saved to database
- Restaurant average updated automatically
- Success message shown
- Dialog closes
- "Rate" button changes to "Update Rating" (if they want to change it later)

### 5. Rating Displayed Everywhere

New rating immediately appears in:
- Restaurant profile
- Meal cards
- Search results
- Leaderboard
- Anywhere restaurant info is shown

---

## Admin View (Question 1 Answer)

### ❌ Don't Create Separate Table

Instead, use a **database view** for admin dashboard:

```sql
-- Create admin view
CREATE VIEW admin_donation_summary AS
SELECT 
  o.id,
  o.order_number,
  o.created_at,
  o.status,
  o.total_amount,
  donor.full_name as donor_name,
  ngo.organization_name as ngo_name,
  r.restaurant_name,
  json_agg(
    json_build_object(
      'meal', oi.meal_title,
      'qty', oi.quantity,
      'subtotal', oi.subtotal
    )
  ) as meals
FROM orders o
JOIN profiles donor ON o.user_id = donor.id
JOIN ngos ngo ON o.ngo_id = ngo.profile_id
JOIN restaurants r ON o.restaurant_id = r.profile_id
JOIN order_items oi ON o.id = oi.order_id
WHERE o.delivery_type = 'donation'
GROUP BY o.id, donor.full_name, ngo.organization_name, r.restaurant_name;
```

Then query it:
```sql
SELECT * FROM admin_donation_summary ORDER BY created_at DESC;
```

**Benefits:**
- ✅ No data duplication
- ✅ Always up-to-date
- ✅ Single source of truth
- ✅ Easy to query

---

## Testing Checklist

- [ ] Run migration: `20260212_restaurant_rating_system.sql`
- [ ] Create test order and complete it
- [ ] Click "Rate" button in My Orders
- [ ] Submit 5-star rating with review
- [ ] Verify rating appears in restaurant profile
- [ ] Verify rating count increments
- [ ] Submit another rating from different user
- [ ] Verify average calculates correctly
- [ ] Try updating existing rating
- [ ] Verify updated rating recalculates average
- [ ] Check rating displays in all restaurant views

---

## Summary

✅ **Database:** New `restaurant_ratings` table + `rating_count` column
✅ **Automatic:** Rating average calculated automatically via triggers
✅ **Functions:** 3 RPC functions for submit, check, and fetch ratings
✅ **Flutter:** Rating dialog, service, and UI integration
✅ **Display:** Rating shows everywhere restaurants appear
✅ **Admin:** Use database views, not separate tables

The system is production-ready once you run the migration and implement the Flutter UI!
