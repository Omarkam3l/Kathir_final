# Meal Search Fields Update

## ✅ Complete

Meal search now returns ALL meal data except for the excluded fields: `embedding`, `created_at`, `updated_at`, and `restaurant_id`.

## Changes Made

### 1. Database Query (`meals.py`)

**Before:**
```python
.select("id, title, description, category, discounted_price, allergens, restaurants(restaurant_name)")
```

**After:**
```python
.select(
    "id, title, description, category, discounted_price, allergens, "
    "status, expiry_date, quantity_available, restaurant_id, "
    "restaurants(restaurant_name)"
)
```

### 2. Response Formatter (`formatters.py`)

**Before:**
```python
return {
    "id": row["id"],
    "title": row["title"],
    "description": (row.get("description") or "")[:140],  # Truncated!
    "category": row.get("category"),
    "price": float(row["discounted_price"]),
    "restaurant_name": restaurant_name,
    "allergens": row.get("allergens") or [],
    "score": score_map.get(row["id"]),
}
```

**After:**
```python
return {
    "id": row["id"],
    "title": row["title"],
    "description": row.get("description") or "",  # Full description!
    "category": row.get("category"),
    "price": float(row["discounted_price"]),
    "restaurant_name": restaurant_name,
    "allergens": row.get("allergens") or [],
    "status": row.get("status"),
    "expiry_date": row.get("expiry_date"),
    "quantity_available": row.get("quantity_available"),
    "score": score_map.get(row["id"]),
}
```

## Output Format

### Included Fields

All meal data is now returned:

```json
{
  "id": "meal-uuid",
  "title": "Grilled Chicken Platter",
  "description": "Tender grilled chicken served with rice and vegetables. Full description without truncation.",
  "category": "Meat & Poultry",
  "price": 75.0,
  "restaurant_name": "Malfoof Restaurant",
  "allergens": ["gluten"],
  "status": "active",
  "expiry_date": "2026-02-28T00:00:00+00:00",
  "quantity_available": 10,
  "score": 0.85
}
```

### Excluded Fields

These fields are NOT included in the response:

- ❌ `embedding` - Vector embedding (large binary data, not useful for users)
- ❌ `created_at` - Internal timestamp
- ❌ `updated_at` - Internal timestamp
- ❌ `restaurant_id` - Internal UUID (security - use restaurant_name instead)

## Key Changes

### 1. Full Description
**Before:** Description was truncated to 140 characters
```python
"description": (row.get("description") or "")[:140]
```

**After:** Full description is returned
```python
"description": row.get("description") or ""
```

### 2. Additional Fields
Now includes:
- `status` - Meal status (e.g., "active", "inactive")
- `expiry_date` - When the meal expires
- `quantity_available` - How many portions are available

### 3. Security
`restaurant_id` is still fetched internally for filtering but never exposed in the response. Only `restaurant_name` is returned.

## API Response Example

### Search Request
```bash
curl "http://localhost:8000/meals/search?query=chicken&limit=2"
```

### Response
```json
{
  "ok": true,
  "query": "chicken",
  "count": 2,
  "results": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Grilled Chicken Platter",
      "description": "Tender grilled chicken breast served with seasoned rice, grilled vegetables, and garlic sauce. A healthy and delicious meal perfect for lunch or dinner.",
      "category": "Meat & Poultry",
      "price": 75.0,
      "restaurant_name": "Malfoof Restaurant",
      "allergens": ["gluten"],
      "status": "active",
      "expiry_date": "2026-02-28T23:59:59+00:00",
      "quantity_available": 15,
      "score": 0.92
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "title": "Chicken Souvlaki Skewers",
      "description": "Greek-style marinated chicken skewers with tzatziki sauce, pita bread, and fresh salad. Authentic Mediterranean flavors.",
      "category": "Meat & Poultry",
      "price": 65.0,
      "restaurant_name": "Mediterranean Grill House",
      "allergens": ["gluten", "dairy"],
      "status": "active",
      "expiry_date": "2026-02-27T23:59:59+00:00",
      "quantity_available": 8,
      "score": 0.87
    }
  ],
  "sort": "relevance"
}
```

## Benefits

### 1. Complete Information
Users now get all relevant meal data in a single request:
- Full descriptions (not truncated)
- Availability information
- Expiry dates
- Status

### 2. Better UX
Frontend applications can:
- Display full meal descriptions
- Show stock availability
- Warn about expiring meals
- Filter by status

### 3. Reduced API Calls
No need for additional requests to get complete meal details.

### 4. Maintained Security
Sensitive fields are still excluded:
- No internal timestamps
- No vector embeddings
- No restaurant IDs

## Use Cases

### Display Full Meal Details
```javascript
// Frontend can now show complete information
meals.forEach(meal => {
  console.log(`${meal.title} - ${meal.price} EGP`);
  console.log(`Description: ${meal.description}`);  // Full text!
  console.log(`Available: ${meal.quantity_available} portions`);
  console.log(`Expires: ${meal.expiry_date}`);
  console.log(`Status: ${meal.status}`);
});
```

### Check Availability
```javascript
// Filter by availability
const availableMeals = meals.filter(m => 
  m.status === 'active' && 
  m.quantity_available > 0 &&
  new Date(m.expiry_date) > new Date()
);
```

### Show Allergen Warnings
```javascript
// Display allergen information
if (meal.allergens.length > 0) {
  console.log(`⚠️ Contains: ${meal.allergens.join(', ')}`);
}
```

## Agent Integration

The AI agent now receives complete meal data and can:
- Provide detailed meal descriptions
- Check availability before suggesting
- Warn about expiring meals
- Consider stock levels when building carts

## Testing

Run the test to verify fields:
```bash
python test_meal_fields.py
```

Expected output shows all included fields and confirms excluded fields are not present.

## Migration Notes

If you were relying on truncated descriptions:
- Descriptions are now full-length
- You may want to truncate on the frontend if needed
- Use CSS `text-overflow: ellipsis` or JavaScript `.substring(0, 140)` for display

## Files Modified

- `meals.py` - Updated select query to fetch all fields
- `formatters.py` - Updated formatter to include all fields except excluded ones

## Summary

Meal search now returns complete meal information (except embedding, timestamps, and restaurant_id) with full descriptions, availability data, and status information. This provides a better user experience while maintaining security and performance.
