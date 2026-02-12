# Donation Tracking - Complete Data Summary

## ✅ YES - You Already Have Complete Donation Tracking!

Your database already tracks **ALL** donation information. Here's what's stored:

---

## 📊 Database Tables Tracking Donations

### 1. `orders` Table - Main Donation Record

When a user donates meals to an NGO, a complete order record is created with:

```sql
CREATE TABLE orders (
  -- Core IDs
  id uuid PRIMARY KEY,
  order_number text,                    -- ✅ Unique order number (e.g., ORD20260212001)
  order_code integer,                   -- ✅ Sequential number
  
  -- Who donated to whom
  user_id uuid,                         -- ✅ The donor (user who paid)
  restaurant_id uuid,                   -- ✅ Which restaurant prepared the meals
  ngo_id uuid,                          -- ✅ Which NGO receives the donation
  
  -- Donation type
  delivery_type text,                   -- ✅ 'donation' for NGO donations
  
  -- Financial details
  subtotal numeric(12,2),               -- ✅ Total cost of meals
  service_fee numeric(12,2),            -- ✅ Platform service fee
  delivery_fee numeric(12,2),           -- ✅ Delivery fee (usually 0 for donations)
  platform_commission numeric(12,2),    -- ✅ Platform commission
  total_amount numeric(12,2),           -- ✅ Total amount paid by donor
  
  -- Payment tracking
  payment_method text,                  -- ✅ How donor paid (card, wallet, etc.)
  payment_status text,                  -- ✅ pending, paid, failed, refunded
  
  -- Order status & tracking
  status order_status,                  -- ✅ pending, confirmed, preparing, ready_for_pickup, completed, etc.
  pickup_code varchar(6),               -- ✅ Code for NGO to pickup meals
  qr_code text,                         -- ✅ QR code for verification
  
  -- Timestamps
  created_at timestamptz,               -- ✅ When donation was made
  estimated_ready_time timestamptz,     -- ✅ When meals will be ready
  actual_ready_time timestamptz,        -- ✅ When meals were actually ready
  picked_up_at timestamptz,             -- ✅ When NGO picked up the meals
  
  -- Additional info
  delivery_address text,                -- ✅ NGO address (if applicable)
  special_instructions text,            -- ✅ Any special notes
  
  -- Review (optional)
  rating integer,                       -- ✅ NGO can rate the donation experience
  review_text text,                     -- ✅ Review comments
  reviewed_at timestamptz               -- ✅ When reviewed
);
```

### 2. `order_items` Table - What Was Donated

Tracks each meal donated with quantities and prices:

```sql
CREATE TABLE order_items (
  id uuid PRIMARY KEY,
  order_id uuid,                        -- ✅ Links to orders table
  meal_id uuid,                         -- ✅ Which meal was donated
  meal_title text,                      -- ✅ Meal name (stored for history)
  quantity integer,                     -- ✅ How many of this meal
  unit_price numeric(12,2),             -- ✅ Price per meal
  subtotal numeric(12,2)                -- ✅ Total for this meal (quantity × unit_price)
);
```

---

## 🔍 Example: Complete Donation Record

When a user donates 5 pizzas and 3 burgers to "Food Bank NGO":

### Orders Table Record:
```sql
{
  id: "550e8400-e29b-41d4-a716-446655440000",
  order_number: "ORD20260212001",
  order_code: 1,
  user_id: "user-uuid-123",              -- Donor
  restaurant_id: "restaurant-uuid-456",  -- Pizza Palace
  ngo_id: "ngo-uuid-789",                -- Food Bank NGO
  delivery_type: "donation",             -- ✅ Marks this as donation
  subtotal: 400.00,
  service_fee: 20.00,
  delivery_fee: 0.00,
  platform_commission: 20.00,
  total_amount: 420.00,
  payment_method: "card",
  payment_status: "paid",
  status: "pending",
  pickup_code: "ABC123",
  created_at: "2026-02-12 10:30:00",
  estimated_ready_time: "2026-02-12 11:00:00"
}
```

### Order Items Table Records:
```sql
-- Item 1: Pizzas
{
  id: "item-uuid-1",
  order_id: "550e8400-e29b-41d4-a716-446655440000",
  meal_id: "pizza-uuid",
  meal_title: "Margherita Pizza",
  quantity: 5,
  unit_price: 50.00,
  subtotal: 250.00                       -- ✅ 5 × 50
}

-- Item 2: Burgers
{
  id: "item-uuid-2",
  order_id: "550e8400-e29b-41d4-a716-446655440000",
  meal_id: "burger-uuid",
  meal_title: "Beef Burger",
  quantity: 3,
  unit_price: 50.00,
  subtotal: 150.00                       -- ✅ 3 × 50
}
```

---

## 📋 What You Can Query

### 1. All Donations to a Specific NGO
```sql
SELECT 
  o.id,
  o.order_number,
  o.created_at,
  o.total_amount,
  o.status,
  o.pickup_code,
  p.full_name as donor_name,
  r.restaurant_name
FROM orders o
JOIN profiles p ON o.user_id = p.id
JOIN restaurants r ON o.restaurant_id = r.profile_id
WHERE o.ngo_id = 'your-ngo-uuid'
  AND o.delivery_type = 'donation'
ORDER BY o.created_at DESC;
```

### 2. All Donations by a Specific User
```sql
SELECT 
  o.id,
  o.order_number,
  o.created_at,
  o.total_amount,
  o.status,
  n.organization_name as ngo_name,
  r.restaurant_name
FROM orders o
JOIN ngos n ON o.ngo_id = n.profile_id
JOIN restaurants r ON o.restaurant_id = r.profile_id
WHERE o.user_id = 'your-user-uuid'
  AND o.delivery_type = 'donation'
ORDER BY o.created_at DESC;
```

### 3. Donation Details with All Meals
```sql
SELECT 
  o.order_number,
  o.created_at,
  o.total_amount,
  o.status,
  o.pickup_code,
  p.full_name as donor_name,
  n.organization_name as ngo_name,
  r.restaurant_name,
  oi.meal_title,
  oi.quantity,
  oi.unit_price,
  oi.subtotal
FROM orders o
JOIN profiles p ON o.user_id = p.id
JOIN ngos n ON o.ngo_id = n.profile_id
JOIN restaurants r ON o.restaurant_id = r.profile_id
JOIN order_items oi ON o.id = oi.order_id
WHERE o.id = 'your-order-uuid';
```

### 4. NGO Donation Statistics
```sql
SELECT 
  n.organization_name,
  COUNT(o.id) as total_donations,
  SUM(o.total_amount) as total_value,
  SUM(oi.quantity) as total_meals_received
FROM orders o
JOIN ngos n ON o.ngo_id = n.profile_id
JOIN order_items oi ON o.id = oi.order_id
WHERE o.delivery_type = 'donation'
  AND o.status = 'completed'
GROUP BY n.organization_name
ORDER BY total_donations DESC;
```

### 5. Pending Pickups for NGO
```sql
SELECT 
  o.order_number,
  o.pickup_code,
  o.estimated_ready_time,
  r.restaurant_name,
  r.address_text as restaurant_address,
  p.full_name as donor_name,
  o.total_amount,
  COUNT(oi.id) as item_count
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.profile_id
JOIN profiles p ON o.user_id = p.id
JOIN order_items oi ON o.id = oi.order_id
WHERE o.ngo_id = 'your-ngo-uuid'
  AND o.delivery_type = 'donation'
  AND o.status IN ('ready_for_pickup', 'confirmed', 'preparing')
GROUP BY o.id, r.restaurant_name, r.address_text, p.full_name
ORDER BY o.estimated_ready_time ASC;
```

---

## ✅ Summary: What's Tracked

| Data Point | Tracked? | Table | Column |
|------------|----------|-------|--------|
| **Who donated** | ✅ Yes | orders | user_id |
| **Which NGO received** | ✅ Yes | orders | ngo_id |
| **Which restaurant** | ✅ Yes | orders | restaurant_id |
| **Donation type** | ✅ Yes | orders | delivery_type = 'donation' |
| **Total amount paid** | ✅ Yes | orders | total_amount |
| **Subtotal** | ✅ Yes | orders | subtotal |
| **Service fee** | ✅ Yes | orders | service_fee |
| **Delivery fee** | ✅ Yes | orders | delivery_fee |
| **Payment method** | ✅ Yes | orders | payment_method |
| **Payment status** | ✅ Yes | orders | payment_status |
| **Order status** | ✅ Yes | orders | status |
| **Pickup code** | ✅ Yes | orders | pickup_code |
| **QR code** | ✅ Yes | orders | qr_code |
| **When donated** | ✅ Yes | orders | created_at |
| **When ready** | ✅ Yes | orders | estimated_ready_time, actual_ready_time |
| **When picked up** | ✅ Yes | orders | picked_up_at |
| **Meals donated** | ✅ Yes | order_items | meal_title |
| **Quantities** | ✅ Yes | order_items | quantity |
| **Unit prices** | ✅ Yes | order_items | unit_price |
| **Subtotals per meal** | ✅ Yes | order_items | subtotal |
| **Special instructions** | ✅ Yes | orders | special_instructions |
| **Rating/Review** | ✅ Yes | orders | rating, review_text |

---

## 🎯 Conclusion

**You already have COMPLETE donation tracking!**

Every donation creates:
1. ✅ One record in `orders` table with donor, NGO, restaurant, amounts, status, pickup code
2. ✅ Multiple records in `order_items` table with each meal, quantity, price, subtotal

You can track:
- ✅ Who donated what to which NGO
- ✅ Which meals and quantities
- ✅ All financial details (subtotal, fees, total)
- ✅ Pickup status and codes
- ✅ Complete timeline (created, ready, picked up)
- ✅ Payment information

No additional tables or columns needed - your schema is complete!
