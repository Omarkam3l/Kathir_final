# 📊 Actual Database Schema Analysis

## Meals Table (Actual Schema)

```sql
create table public.meals (
  id uuid not null default gen_random_uuid(),
  restaurant_id uuid null,
  title text not null,
  description text null,
  category text null,
  image_url text null,
  original_price numeric(12, 2) not null,
  discounted_price numeric(12, 2) not null,
  quantity_available integer not null default 0,
  expiry_date timestamp with time zone not null,
  pickup_deadline timestamp with time zone null,
  embedding public.vector null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone not null default now()
)
```

## Missing Columns in Actual Schema

The code expects these columns that DON'T exist:
- ❌ `location` - NOT in schema
- ❌ `donation_price` - NOT in schema (has `discounted_price`)
- ❌ `quantity` - NOT in schema (has `quantity_available`)
- ❌ `expiry` - NOT in schema (has `expiry_date`)
- ❌ `status` - NOT in schema
- ❌ `unit` - NOT in schema
- ❌ `fulfillment_method` - NOT in schema
- ❌ `is_donation_available` - NOT in schema
- ❌ `pickup_time` - NOT in schema
- ❌ `ingredients` - NOT in schema
- ❌ `allergens` - NOT in schema
- ❌ `co2_savings` - NOT in schema

## Restaurants Table (Actual Schema)

```sql
create table public.restaurants (
  profile_id uuid not null,
  restaurant_name text null default 'Unnamed Restaurant'::text,
  address_text text null,
  legal_docs_urls text[] null default array[]::text[],
  rating double precision null default 0,
  min_order_price numeric(12, 2) null default 0,
  rush_hour_active boolean null default false
)
```

## What Needs to Change

### Option 1: Add Missing Columns (Recommended)
Add columns to match code expectations

### Option 2: Update Code (Current Approach)
Update code to use only existing columns
