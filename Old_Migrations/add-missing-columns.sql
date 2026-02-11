-- =====================================================
-- Add Missing Columns to Match Code Expectations
-- =====================================================
-- This adds columns that the Flutter code expects but don't exist in the schema

-- =====================================================
-- MEALS TABLE - Add Missing Columns
-- =====================================================

-- Add status column (active, sold, expired)
ALTER TABLE meals 
ADD COLUMN IF NOT EXISTS status text DEFAULT 'active';

-- Add location column
ALTER TABLE meals 
ADD COLUMN IF NOT EXISTS location text DEFAULT 'Pickup at restaurant';

-- Add unit column (portions, kilograms, items, boxes)
ALTER TABLE meals 
ADD COLUMN IF NOT EXISTS unit text DEFAULT 'portions';

-- Add fulfillment_method column (pickup, delivery)
ALTER TABLE meals 
ADD COLUMN IF NOT EXISTS fulfillment_method text DEFAULT 'pickup';

-- Add is_donation_available column
ALTER TABLE meals 
ADD COLUMN IF NOT EXISTS is_donation_available boolean DEFAULT true;

-- Add ingredients column (array of text)
ALTER TABLE meals 
ADD COLUMN IF NOT EXISTS ingredients text[] DEFAULT array[]::text[];

-- Add allergens column (array of text)
ALTER TABLE meals 
ADD COLUMN IF NOT EXISTS allergens text[] DEFAULT array[]::text[];

-- Add co2_savings column
ALTER TABLE meals 
ADD COLUMN IF NOT EXISTS co2_savings numeric(12, 2) DEFAULT 0;

-- Add pickup_time column (different from pickup_deadline)
ALTER TABLE meals 
ADD COLUMN IF NOT EXISTS pickup_time timestamp with time zone;

-- =====================================================
-- Add Constraints for New Columns
-- =====================================================

-- Status constraint
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'meals_status_check'
  ) THEN
    ALTER TABLE meals 
    ADD CONSTRAINT meals_status_check 
    CHECK (status = ANY(ARRAY['active'::text, 'sold'::text, 'expired'::text]));
  END IF;
END $$;

-- Fulfillment method constraint
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'meals_fulfillment_method_check'
  ) THEN
    ALTER TABLE meals 
    ADD CONSTRAINT meals_fulfillment_method_check 
    CHECK (fulfillment_method = ANY(ARRAY['pickup'::text, 'delivery'::text]));
  END IF;
END $$;

-- Unit constraint
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'meals_unit_check'
  ) THEN
    ALTER TABLE meals 
    ADD CONSTRAINT meals_unit_check 
    CHECK (unit = ANY(ARRAY['portions'::text, 'kilograms'::text, 'items'::text, 'boxes'::text]));
  END IF;
END $$;

-- =====================================================
-- Create Indexes for New Columns
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_meals_status 
ON meals(status);

CREATE INDEX IF NOT EXISTS idx_meals_expiry_date 
ON meals(expiry_date);

CREATE INDEX IF NOT EXISTS idx_meals_created_at 
ON meals(created_at DESC);

-- =====================================================
-- Update Existing Meals with Default Values
-- =====================================================

-- Set status based on expiry_date and quantity
UPDATE meals 
SET status = CASE
  WHEN expiry_date < NOW() THEN 'expired'
  WHEN quantity_available = 0 THEN 'sold'
  ELSE 'active'
END
WHERE status IS NULL OR status = 'active';

-- =====================================================
-- RESTAURANTS TABLE - Verify Columns
-- =====================================================

-- Check if we need to add phone column
ALTER TABLE restaurants 
ADD COLUMN IF NOT EXISTS phone text;

-- Check if we need to add address column (different from address_text)
ALTER TABLE restaurants 
ADD COLUMN IF NOT EXISTS address text;

-- Copy address_text to address if address is null
UPDATE restaurants 
SET address = address_text 
WHERE address IS NULL AND address_text IS NOT NULL;

-- =====================================================
-- ORDERS TABLE - Add meal_id if missing
-- =====================================================

-- Check if orders table needs meal_id column
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS meal_id uuid;

-- Add foreign key if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'orders_meal_id_fkey'
  ) THEN
    ALTER TABLE orders 
    ADD CONSTRAINT orders_meal_id_fkey 
    FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE SET NULL;
  END IF;
END $$;

-- =====================================================
-- Verification Queries
-- =====================================================

-- Check meals table columns
SELECT 
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'meals'
ORDER BY ordinal_position;

-- Check restaurants table columns
SELECT 
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'restaurants'
ORDER BY ordinal_position;

-- Check constraints
SELECT 
  conname as constraint_name,
  contype as constraint_type
FROM pg_constraint
WHERE conrelid = 'meals'::regclass
ORDER BY conname;

-- Test query to verify all columns exist
SELECT 
  id,
  restaurant_id,
  title,
  description,
  category,
  image_url,
  original_price,
  discounted_price,
  quantity_available,
  expiry_date,
  pickup_deadline,
  status,
  location,
  unit,
  fulfillment_method,
  is_donation_available,
  created_at,
  updated_at
FROM meals
LIMIT 1;

-- =====================================================
-- Success Message
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE 'All missing columns have been added successfully!';
  RAISE NOTICE 'Meals table now has all required columns.';
  RAISE NOTICE 'Please verify the columns using the queries above.';
END $$;
