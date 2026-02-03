# Data Source & Database Deliverables

## 1. Features and the data they require

| Feature | Screen/Widget | Data fields used | Data source (DB/UI) |
|---------|---------------|------------------|---------------------|
| **Home header** | HomeHeaderWidget | name, greeting (time-based) | `auth.users` / `profiles.full_name` via AuthProvider |
| **Location bar** | LocationBarWidget | location (city/area) | `profiles.default_location` (was mock: "Downtown, San Francisco") |
| **Search** | SearchBarWidget | query, hint | query: UI state; hint: static |
| **Category chips** | CategoryChipsWidget | selected, list | UI state; list: static |
| **Flash Deals** | FlashDealsSection | title, imageUrl, originalPrice, donationPrice, donationPrice==0, minutesLeft, restaurant.name | `meals` + `restaurants` (join) |
| **Top Rated Partners** | TopRatedPartnersSection | name, rating | `restaurants` |
| **Available Meals** | AvailableMealsGridSection, MealCardGrid | title, location, image_url, original_price, donation_price, quantity, expiry, restaurant.{name} | `meals` + `restaurants` (join) |
| **Offers** | (HighlightsSection / OfferBadgeCard – if used) | id, discount | `offers` |

---

## 2. Extracted columns (column name + type + purpose)

| Table | Column | Type | Purpose |
|-------|--------|------|---------|
| **profiles** | default_location | TEXT | User’s preferred / displayed location for the Home location bar |
| **meals** | id | UUID (PK) | Meal identifier |
| **meals** | title | TEXT | Meal title |
| **meals** | location | TEXT | Pickup / address text |
| **meals** | image_url | TEXT | Meal image URL |
| **meals** | original_price | NUMERIC | Original price |
| **meals** | donation_price | NUMERIC | Donation / surplus price |
| **meals** | quantity | INT | Portions left (“X left”) |
| **meals** | expiry | TIMESTAMPTZ | Expiry; used for “Pick up by HH:mm”, “Ends in Xmin” |
| **meals** | restaurant_id | UUID (FK→restaurants.id) | Link to restaurant for join |
| **restaurants** | id | UUID (PK) | Restaurant identifier |
| **restaurants** | name | TEXT | Partner/restaurant name |
| **restaurants** | rating | NUMERIC | Star rating (e.g. 4.5) |
| **offers** | id | UUID (PK) | Offer identifier |
| **offers** | discount | NUMERIC | Discount (e.g. 0.5 for 50% off) |

---

## 3. SQL ALTER TABLE queries

```sql
-- Add default_location to profiles (for Location bar)
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS default_location TEXT;

-- Ensure meals has restaurant_id for join (if missing)
ALTER TABLE meals
  ADD COLUMN IF NOT EXISTS restaurant_id UUID REFERENCES restaurants(id);
```

---

## 4. Sample INSERT / UPDATE queries

```sql
-- Update existing profile with a default location (replace USER_ID)
UPDATE profiles
SET default_location = 'Downtown, San Francisco'
WHERE id = 'USER_ID';

-- Or set for first user (example)
UPDATE profiles
SET default_location = 'Downtown, San Francisco'
WHERE id = (SELECT id FROM profiles LIMIT 1);

-- Restaurants (if needed)
INSERT INTO restaurants (id, name, rating) VALUES
  (gen_random_uuid(), 'Fresh Greens', 4.9),
  (gen_random_uuid(), 'Urban Cafe', 4.5),
  (gen_random_uuid(), 'Juice Press', 4.2),
  (gen_random_uuid(), 'Sushi Co.', 4.7)
ON CONFLICT (id) DO NOTHING;

-- Meals (replace RESTAURANT_ID with a real restaurants.id)
-- Expiry: use future timestamps for “available” meals
INSERT INTO meals (id, title, location, image_url, original_price, donation_price, quantity, expiry, restaurant_id) VALUES
  (gen_random_uuid(), 'Veggie Delight Bag', '2.5km from center', 'https://example.com/veggie.jpg', 12.00, 4.99, 3, NOW() + INTERVAL '2 hours', 'RESTAURANT_ID'),
  (gen_random_uuid(), 'Burger Surplus Box', '1.2km from center', 'https://example.com/burger.jpg', 15.00, 6.50, 5, NOW() + INTERVAL '3 hours', 'RESTAURANT_ID'),
  (gen_random_uuid(), 'Pastry Assortment', '0.5km from center', 'https://example.com/pastry.jpg', 10.00, 3.99, 1, NOW() + INTERVAL '1 hour', 'RESTAURANT_ID'),
  (gen_random_uuid(), 'Curry & Rice Bowl', '3.0km from center', 'https://example.com/curry.jpg', 14.00, 5.50, 4, NOW() + INTERVAL '5 hours', 'RESTAURANT_ID')
ON CONFLICT (id) DO NOTHING;

-- Offers (if offers table is used)
INSERT INTO offers (id, discount) VALUES
  (gen_random_uuid(), 0.50),
  (gen_random_uuid(), 0.30)
ON CONFLICT (id) DO NOTHING;
```

---

## 5. Code changes summary

- **TopRatedPartnersSection**: `SizedBox` height increased from 100 to 118 to remove “BOTTOM OVERFLOWED BY 17 PIXELS”.
- **LocationBarWidget**: `location` comes from `AuthProvider.user?.defaultLocation` (backed by `profiles.default_location`), with fallback `'Downtown, San Francisco'` when null.
- **ProfileEntity / ProfileModel**: added optional `defaultLocation`.
- **AuthProvider / AuthUserView**: added `defaultLocation` from `_userProfile['default_location']`.
- **home_remote_datasource.getAvailableMeals**: `select` updated to include  
  `restaurant:restaurants(id,name,rating)` so `MealModel.fromJson` receives a `restaurant` object.

---

## 6. Meals select (Home) – required shape

`getAvailableMeals` expects a row with an embedded `restaurant` object. Supabase/PostgREST example:

```http
GET /rest/v1/meals?select=id,title,location,image_url,original_price,donation_price,quantity,expiry,restaurant:restaurants(id,name,rating)
```

- `meals.restaurant_id` must reference `restaurants.id` so the `restaurant:restaurants(...)` join works.
