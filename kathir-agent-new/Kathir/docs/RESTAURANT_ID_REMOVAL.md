# Restaurant ID Removal - Security Update

## ✅ Complete

All restaurant_id parameters have been removed from user-facing APIs and tools. Users can now only filter by restaurant name, not by internal IDs.

## Changes Made

### 1. Tools (LangChain Functions)

#### `meals.py` - search_meals
- ❌ Removed: `restaurant_id` parameter
- ❌ Removed: `restaurant_ids` parameter  
- ✅ Kept: `restaurant_name` parameter (only way to filter by restaurant)
- Updated docstring to clarify restaurant_name is the ONLY way to filter

#### `budget.py` - build_cart
- ❌ Removed: `restaurant_id` parameter
- ✅ Changed: `restaurant_name` is now REQUIRED (not optional)
- Updated error message to reflect name-only requirement

#### `favorites.py` - search_favorites
- ❌ Removed: `restaurant_id` parameter
- Results still include `restaurant_name` for display

#### `cart.py` - get_cart
- ❌ Removed: `restaurant_id` parameter
- ❌ Removed: restaurant filtering from cart view
- Results still include `restaurant_name` for each item

### 2. API Routes

#### `routes_meals.py` - /meals/search
- ❌ Removed: `restaurant_id` query parameter
- ✅ Kept: `restaurant_name` query parameter
- Added security note in docstring

#### `routes_cart.py`
- **GET /cart/**
  - ❌ Removed: `restaurant_id` query parameter
  - Added security note in docstring

- **POST /cart/build**
  - ❌ Removed: `restaurant_id` from BuildCartRequest
  - ✅ Changed: `restaurant_name` is now REQUIRED field
  - Added security note in docstring

#### `routes_favorites.py` - /favorites/search
- ❌ Removed: `restaurant_id` query parameter
- Added security note in docstring

### 3. Agent Prompt

#### `prompts.py`
- Updated to use actual restaurant names from database:
  - "Malfoof Restaurant" (primary)
  - "test1"
  - "Mohamed"
  - "5eno"
  - "Ahmed Mohamed"
  - "reem"
- Updated build_cart examples to use restaurant_name
- Removed any mention of restaurant_id

## Security Benefits

### Before
```python
# Users could access any restaurant by ID
GET /meals/search?restaurant_id=c414e556-1e89-4750-999b-f52ac21269a8

# Direct database ID exposure
POST /cart/build
{
  "budget": 500,
  "restaurant_id": "c414e556-1e89-4750-999b-f52ac21269a8"
}
```

### After
```python
# Users must use restaurant names (public information)
GET /meals/search?restaurant_name=Malfoof

# No ID exposure
POST /cart/build
{
  "budget": 500,
  "restaurant_name": "Malfoof Restaurant"
}
```

## Benefits

1. **Security**: Internal database IDs are never exposed to users
2. **User-Friendly**: Restaurant names are more intuitive than UUIDs
3. **Consistency**: All APIs now use the same pattern (name-based filtering)
4. **Flexibility**: Partial name matching with case-insensitive search
5. **Privacy**: Restaurant IDs cannot be enumerated or guessed

## How It Works

### Restaurant Name Resolution

When a user provides a restaurant name, the system:

1. Queries the `restaurants` table with case-insensitive partial match (`ilike`)
2. Retrieves the internal `profile_id` (UUID)
3. Uses the ID internally for filtering
4. Never exposes the ID in responses

```python
# Internal resolution (not exposed to users)
rest = sb.table("restaurants")
    .select("profile_id")
    .ilike("restaurant_name", f"%{restaurant_name}%")
    .limit(3)
    .execute()
    .data

if rest:
    rids = [r["profile_id"] for r in rest]
```

### Response Format

All responses include `restaurant_name` but never `restaurant_id`:

```json
{
  "ok": true,
  "results": [
    {
      "id": "meal-uuid",
      "title": "Grilled Chicken",
      "price": 75,
      "restaurant_name": "Malfoof Restaurant"
      // ❌ restaurant_id is NOT included
    }
  ]
}
```

## API Examples

### Search Meals by Restaurant
```bash
# ✅ Correct - use restaurant name
curl "http://localhost:8000/meals/search?restaurant_name=Malfoof&query=chicken"

# ❌ No longer works - restaurant_id removed
curl "http://localhost:8000/meals/search?restaurant_id=c414e556-1e89-4750-999b-f52ac21269a8"
```

### Build Cart
```bash
# ✅ Correct - use restaurant name
curl -X POST http://localhost:8000/cart/build \
  -H "Content-Type: application/json" \
  -d '{
    "budget": 500,
    "restaurant_name": "Malfoof Restaurant"
  }'

# ❌ No longer works - restaurant_id removed
curl -X POST http://localhost:8000/cart/build \
  -H "Content-Type: application/json" \
  -d '{
    "budget": 500,
    "restaurant_id": "c414e556-1e89-4750-999b-f52ac21269a8"
  }'
```

### Agent Chat
```bash
# ✅ Agent uses restaurant names automatically
curl -X POST http://localhost:8000/agent/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "show me meals from Malfoof Restaurant"
  }'
```

## Partial Name Matching

The system supports flexible name matching:

```python
# All of these work:
"Malfoof Restaurant"  # Full name
"Malfoof"             # Partial name
"malfoof"             # Case-insensitive
"Restaurant"          # Matches any restaurant with "Restaurant" in name
```

## Error Handling

If a restaurant name doesn't match:

```json
{
  "ok": false,
  "error": "No restaurant matching 'InvalidName'",
  "results": []
}
```

## Testing

All changes have been tested and verified:
- ✅ No syntax errors
- ✅ All API endpoints updated
- ✅ All tools updated
- ✅ Agent prompt updated
- ✅ Documentation updated

## Migration Notes

If you have existing code using `restaurant_id`:

1. Replace `restaurant_id` with `restaurant_name`
2. Use the restaurant's name instead of UUID
3. Partial names work (case-insensitive)

## Files Modified

- `meals.py` - Removed restaurant_id parameters
- `budget.py` - Made restaurant_name required
- `favorites.py` - Removed restaurant_id parameter
- `cart.py` - Removed restaurant_id parameter
- `routes_meals.py` - Removed restaurant_id from API
- `routes_cart.py` - Removed restaurant_id from API
- `routes_favorites.py` - Removed restaurant_id from API
- `prompts.py` - Updated with actual restaurant names

## Summary

Restaurant IDs are now completely hidden from users. All filtering must be done by restaurant name, which is more secure, user-friendly, and intuitive. The system internally resolves names to IDs but never exposes them in requests or responses.
