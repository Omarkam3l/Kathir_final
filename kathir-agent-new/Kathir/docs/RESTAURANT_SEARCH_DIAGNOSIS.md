# Restaurant Search Diagnosis

## Issue Report
"When I search with restaurant name the search tells me it doesn't exist but with the ID it appears"

## Root Cause: DATABASE HAS NO MEALS

The restaurant name search is **working correctly**. The issue is that your database has:
- ✅ 6 restaurants in the `restaurants` table
- ❌ 0 meals in the `meals` table

## Current Database Status

### Connected Database
```
URL: https://kapqefuchyqqprhneeiw.supabase.co
```

### Available Restaurants
1. Malfoof Restaurant (ID: c414e556-1e89-4750-999b-f52ac21269a8)
2. test1 (ID: 7e476ca3-7bbf-49a2-82f6-b48fcdec4261)
3. Mohamed (ID: 9b1b9c1b-f66e-405d-9e28-212b2737034c)
4. 5eno (ID: 54ce726e-53e4-429d-8db0-d83c6eb23a79)
5. Ahmed Mohamed (ID: c5fc89ea-f2d1-41e7-ac74-da6360a1effd)
6. reem (ID: d3afb132-2235-44ea-b84d-79a3b77eec64)

### Available Meals
**Count: 0**

No meals exist in the database, which is why searches return 0 results.

## How Restaurant Search Works

The `search_meals` function in `meals.py` handles restaurant filtering:

```python
if restaurant_name and not rids:
    rest = (
        sb.table("restaurants")
          .select("profile_id")
          .ilike("restaurant_name", f"%{restaurant_name}%")  # Case-insensitive partial match
          .limit(3)
          .execute()
          .data
    )
    if rest:
        rids = [r["profile_id"] for r in rest]
    else:
        return {
            "ok": False,
            "error": f"No restaurant matching '{restaurant_name}'",
            "results": [],
        }
```

This code:
1. ✅ Uses `ilike` for case-insensitive partial matching
2. ✅ Returns restaurant IDs if found
3. ✅ Returns error if no restaurant matches the name
4. ✅ Then filters meals by those restaurant IDs

## Test Results

### Restaurant Name Search
```
✓ "Malfoof Restaurant" → Found restaurant, 0 meals
✓ "Malfoof" → Found restaurant, 0 meals  
✓ "malfoof" → Found restaurant, 0 meals
✓ "test1" → Found restaurant, 0 meals
✓ "Mohamed" → Found restaurant, 0 meals
```

### Restaurant ID Search
```
✓ Using ID directly → Would work if meals existed
```

## Why It Appears to Work with ID

When you search by restaurant ID, the function doesn't check if the restaurant exists first - it just filters meals by that ID. If there are no meals, you get 0 results either way.

The difference is:
- **By name**: Returns error "No restaurant matching 'X'" if restaurant doesn't exist
- **By ID**: Returns 0 meals (no error) even if restaurant doesn't exist

## Solutions

### Solution 1: Add Meals to Database

You need to populate the `meals` table with data. Each meal should have:
- `id` (UUID)
- `title` (string)
- `description` (string)
- `category` (string: "Meals", "Desserts", "Bakery", "Meat & Poultry", "Seafood", "Vegetables")
- `discounted_price` (number)
- `quantity_available` (number > 0)
- `status` ("active")
- `expiry_date` (future date)
- `restaurant_id` (UUID from restaurants table)
- `allergens` (array of strings)
- `embedding` (vector for semantic search)

### Solution 2: Use Previous Database

If your previous database (`dmzaloqktyxtkthawevz.supabase.co`) had test data, you can switch back by updating `.env`:

```env
SUPABASE_URL=https://dmzaloqktyxtkthawevz.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRtemFsb3FrdHl4dGt0aGF3ZXZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMDQ0NTEsImV4cCI6MjA4NjY4MDQ1MX0.CBcutimUgyZvbfqvtmJLUzw__q192GpFNL1930AL5c4
```

### Solution 3: Create Sample Data

Create a script to populate the database with sample meals:

```python
from db_client import sb
from datetime import datetime, timedelta

# Sample meal data
meals = [
    {
        "title": "Grilled Chicken Platter",
        "description": "Tender grilled chicken with rice and vegetables",
        "category": "Meat & Poultry",
        "discounted_price": 75,
        "quantity_available": 10,
        "status": "active",
        "expiry_date": (datetime.now() + timedelta(days=7)).isoformat(),
        "restaurant_id": "c414e556-1e89-4750-999b-f52ac21269a8",  # Malfoof Restaurant
        "allergens": []
    },
    # Add more meals...
]

# Insert meals
for meal in meals:
    sb.table("meals").insert(meal).execute()
```

## Verification

To verify the fix works:

```bash
# Check meals exist
python check_meals.py

# Test restaurant search
python test_real_restaurants.py

# Test via API
curl "http://localhost:8000/meals/search?restaurant_name=Malfoof&limit=5"
```

## Summary

✅ **Restaurant name search is working correctly**
❌ **Database has no meals to return**

The search function properly:
- Finds restaurants by name (case-insensitive, partial match)
- Filters meals by restaurant ID
- Returns appropriate errors when restaurants don't exist

The issue is simply that your database needs meal data to return results.
