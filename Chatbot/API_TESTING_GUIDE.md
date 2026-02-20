# Boss Food Ordering API - Testing Guide

## Quick Start

Your API is running at: `http://localhost:8000`

- **Swagger UI (Interactive)**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI Schema**: http://localhost:8000/openapi.json

## Test Scripts

### Run All Tests
```bash
python test_api.py
```

### Run Interactive Tests
```bash
python interactive_test.py
```

## Manual Testing with curl

### 1. Health Checks

**Health Check**
```bash
curl http://localhost:8000/health
```

**Readiness Check**
```bash
curl http://localhost:8000/ready
```

### 2. Search Meals

**Basic Search**
```bash
curl "http://localhost:8000/meals/search?query=chicken&limit=5"
```

**Search by Category**
```bash
curl "http://localhost:8000/meals/search?category=Desserts&limit=5"
```

**Search with Price Filter**
```bash
curl "http://localhost:8000/meals/search?query=seafood&max_price=100&limit=5"
```

**Search Excluding Allergens**
```bash
curl "http://localhost:8000/meals/search?query=pasta&exclude_allergens=gluten&limit=5"
```

**Sort by Price**
```bash
curl "http://localhost:8000/meals/search?category=Bakery&sort=price_asc&limit=10"
```

### 3. Favorites

**Search Favorites**
```bash
curl "http://localhost:8000/favorites/search?user_id=YOUR_USER_ID&query=pizza&limit=5"
```

### 4. Cart Operations

**Get Cart**
```bash
curl http://localhost:8000/cart/
```

**Get Cart for Specific Restaurant**
```bash
curl "http://localhost:8000/cart/?restaurant_id=YOUR_RESTAURANT_ID"
```

**Add to Cart**
```bash
curl -X POST http://localhost:8000/cart/add \
  -H "Content-Type: application/json" \
  -d '{"meal_id": "YOUR_MEAL_ID", "quantity": 2}'
```

**Build Cart with Budget**
```bash
curl -X POST http://localhost:8000/cart/build \
  -H "Content-Type: application/json" \
  -d '{
    "budget": 500,
    "restaurant_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    "target_meal_count": 5,
    "max_qty_per_meal": 3
  }'
```

**Build Cart by Restaurant Name**
```bash
curl -X POST http://localhost:8000/cart/build \
  -H "Content-Type: application/json" \
  -d '{
    "budget": 300,
    "restaurant_name": "Egypt",
    "target_meal_count": 4
  }'
```

## PowerShell Testing

If using PowerShell, use `Invoke-RestMethod` instead:

**GET Request**
```powershell
Invoke-RestMethod -Uri "http://localhost:8000/meals/search?query=chicken&limit=5" | ConvertTo-Json -Depth 10
```

**POST Request**
```powershell
$body = @{
    budget = 500
    restaurant_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    target_meal_count = 5
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8000/cart/build" -Method Post -Body $body -ContentType "application/json" | ConvertTo-Json -Depth 10
```

## Available Categories

- Meals
- Desserts
- Meat & Poultry
- Seafood
- Bakery
- Vegetables

## Common Allergens

- gluten
- dairy
- eggs
- tree nuts
- peanuts
- shellfish
- fish
- soy
- sesame

## Test Results Summary

✅ **Working Endpoints:**
- Health check
- Readiness check
- Meal search (with all filters)
- Favorites search
- Get cart
- Build cart

⚠️ **Notes:**
- Add to cart requires valid meal IDs from your database
- Build cart requires a restaurant ID or name
- Favorites require valid user IDs

## Tips

1. **Get Real IDs**: Use the search endpoint to get actual meal and restaurant IDs
2. **Use Swagger UI**: The interactive docs at `/docs` are great for testing
3. **Check Logs**: Watch the server terminal for detailed error messages
4. **Test Incrementally**: Start with simple searches, then add filters

## Example Workflow

1. Search for meals:
   ```bash
   curl "http://localhost:8000/meals/search?query=chicken&limit=3"
   ```

2. Copy a `meal_id` from the results

3. Add to cart:
   ```bash
   curl -X POST http://localhost:8000/cart/add \
     -H "Content-Type: application/json" \
     -d '{"meal_id": "556afc2c-edf5-4551-86e5-b469bbcba27d", "quantity": 2}'
   ```

4. Check your cart:
   ```bash
   curl http://localhost:8000/cart/
   ```

5. Build a budget cart:
   ```bash
   curl -X POST http://localhost:8000/cart/build \
     -H "Content-Type: application/json" \
     -d '{"budget": 500, "restaurant_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"}'
   ```

## Troubleshooting

**Server not responding?**
- Check if it's running: `curl http://localhost:8000/health`
- Restart: Stop the server (Ctrl+C) and run `python -m uvicorn main:app --reload`

**Import errors?**
- Make sure you're in the project directory
- Check that all dependencies are installed: `pip install -r requirements.txt`

**Database errors?**
- Verify your `.env` file has correct Supabase credentials
- Check the readiness endpoint: `curl http://localhost:8000/ready`
