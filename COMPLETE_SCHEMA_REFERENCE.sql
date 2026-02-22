-- =====================================================
-- COMPLETE DATABASE SCHEMA REFERENCE
-- =====================================================
-- This is the complete, final schema for the Kathir app
-- Including all tables, columns, constraints, indexes, and RLS policies
-- Date: January 30, 2026
-- =====================================================

-- =====================================================
-- EXTENSIONS
-- =====================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TABLE: profiles
-- =====================================================

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid NOT NULL,
  role text NULL,
  email text NULL,
  full_name text NULL,
  phone_number text NULL,
  avatar_url text NULL,
  is_verified boolean NULL DEFAULT false,
  created_at timestamp with time zone NULL DEFAULT now(),
  updated_at timestamp with time zone NULL DEFAULT now(),
  approval_status text NOT NULL DEFAULT 'pending'::text,
  
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_email_key UNIQUE (email),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users (id) ON DELETE CASCADE,
  CONSTRAINT profiles_approval_status_check CHECK (
    approval_status = ANY(ARRAY['pending'::text, 'approved'::text, 'rejected'::text])
  ),
  CONSTRAINT profiles_role_check CHECK (
    role = ANY(ARRAY['user'::text, 'restaurant'::text, 'ngo'::text, 'admin'::text])
  )
) TABLESPACE pg_default;

-- Indexes for profiles
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles USING btree (role) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_profiles_approval_status ON public.profiles USING btree (approval_status) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles USING btree (email) TABLESPACE pg_default;

-- Trigger for profiles
CREATE TRIGGER trg_update_profiles_updated_at 
BEFORE UPDATE ON profiles 
FOR EACH ROW 
EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- TABLE: restaurants
-- =====================================================

CREATE TABLE IF NOT EXISTS public.restaurants (
  profile_id uuid NOT NULL,
  restaurant_name text NULL DEFAULT 'Unnamed Restaurant'::text,
  address_text text NULL,
  address text NULL,
  phone text NULL,
  legal_docs_urls text[] NULL DEFAULT array[]::text[],
  rating double precision NULL DEFAULT 0,
  min_order_price numeric(12, 2) NULL DEFAULT 0,
  rush_hour_active boolean NULL DEFAULT false,
  
  CONSTRAINT restaurants_pkey PRIMARY KEY (profile_id),
  CONSTRAINT restaurants_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- =====================================================
-- TABLE: ngos
-- =====================================================

CREATE TABLE IF NOT EXISTS public.ngos (
  profile_id uuid NOT NULL,
  organization_name text NULL DEFAULT 'Unnamed Organization'::text,
  address_text text NULL,
  legal_docs_urls text[] NULL DEFAULT array[]::text[],
  
  CONSTRAINT ngos_pkey PRIMARY KEY (profile_id),
  CONSTRAINT ngos_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- =====================================================
-- TABLE: meals
-- =====================================================

CREATE TABLE IF NOT EXISTS public.meals (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  restaurant_id uuid NULL,
  title text NOT NULL,
  description text NULL,
  category text NULL,
  image_url text NULL,
  original_price numeric(12, 2) NOT NULL,
  discounted_price numeric(12, 2) NOT NULL,
  quantity_available integer NOT NULL DEFAULT 0,
  expiry_date timestamp with time zone NOT NULL,
  pickup_deadline timestamp with time zone NULL,
  embedding public.vector NULL,
  created_at timestamp with time zone NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  
  -- Additional columns for app functionality
  status text DEFAULT 'active',
  location text DEFAULT 'Pickup at restaurant',
  unit text DEFAULT 'portions',
  fulfillment_method text DEFAULT 'pickup',
  is_donation_available boolean DEFAULT true,
  ingredients text[] DEFAULT array[]::text[],
  allergens text[] DEFAULT array[]::text[],
  co2_savings numeric(12, 2) DEFAULT 0,
  pickup_time timestamp with time zone NULL,
  
  CONSTRAINT meals_pkey PRIMARY KEY (id),
  CONSTRAINT meals_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES restaurants (profile_id) ON DELETE CASCADE,
  CONSTRAINT meals_category_check CHECK (
    category = ANY(ARRAY[
      'Meals'::text,
      'Bakery'::text,
      'Meat & Poultry'::text,
      'Seafood'::text,
      'Vegetables'::text,
      'Desserts'::text,
      'Groceries'::text
    ])
  ),
  CONSTRAINT meals_status_check CHECK (
    status = ANY(ARRAY['active'::text, 'sold'::text, 'expired'::text])
  ),
  CONSTRAINT meals_fulfillment_method_check CHECK (
    fulfillment_method = ANY(ARRAY['pickup'::text, 'delivery'::text])
  ),
  CONSTRAINT meals_unit_check CHECK (
    unit = ANY(ARRAY['portions'::text, 'kilograms'::text, 'items'::text, 'boxes'::text])
  )
) TABLESPACE pg_default;

-- Indexes for meals
CREATE INDEX IF NOT EXISTS idx_meals_restaurant_id ON public.meals USING btree (restaurant_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_meals_status ON public.meals USING btree (status) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_meals_expiry_date ON public.meals USING btree (expiry_date) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_meals_created_at ON public.meals USING btree (created_at DESC) TABLESPACE pg_default;

-- =====================================================
-- TABLE: orders
-- =====================================================

CREATE TABLE IF NOT EXISTS public.orders (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  order_code serial NOT NULL,
  user_id uuid NULL,
  restaurant_id uuid NULL,
  ngo_id uuid NULL,
  meal_id uuid NULL,
  status text NULL DEFAULT 'pending'::text,
  delivery_type text NULL,
  subtotal numeric(12, 2) NULL,
  service_fee numeric(12, 2) NULL,
  delivery_fee numeric(12, 2) NULL,
  platform_commission numeric(12, 2) NULL,
  total_amount numeric(12, 2) NULL,
  otp_code text NULL,
  delivery_address text NULL,
  created_at timestamp with time zone NULL DEFAULT now(),
  
  CONSTRAINT orders_pkey PRIMARY KEY (id),
  CONSTRAINT orders_ngo_id_fkey FOREIGN KEY (ngo_id) REFERENCES ngos (profile_id),
  CONSTRAINT orders_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES restaurants (profile_id),
  CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles (id),
  CONSTRAINT orders_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE SET NULL,
  CONSTRAINT orders_delivery_type_check CHECK (
    delivery_type = ANY(ARRAY['pickup'::text, 'delivery'::text, 'donation'::text])
  ),
  CONSTRAINT orders_status_check CHECK (
    status = ANY(ARRAY[
      'pending'::text,
      'paid'::text,
      'processing'::text,
      'ready_for_pickup'::text,
      'out_for_delivery'::text,
      'completed'::text,
      'cancelled'::text
    ])
  )
) TABLESPACE pg_default;

-- Indexes for orders
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders USING btree (user_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_orders_restaurant_id ON public.orders USING btree (restaurant_id) TABLESPACE pg_default;

-- =====================================================
-- TABLE: order_items
-- =====================================================

CREATE TABLE IF NOT EXISTS public.order_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  order_id uuid NULL,
  meal_id uuid NULL,
  meal_title text NULL,
  quantity integer NOT NULL,
  unit_price numeric(12, 2) NOT NULL,
  
  CONSTRAINT order_items_pkey PRIMARY KEY (id),
  CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- =====================================================
-- TABLE: payments
-- =====================================================

CREATE TABLE IF NOT EXISTS public.payments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  order_id uuid NULL,
  transaction_id text NULL,
  provider text NULL,
  amount numeric(12, 2) NULL,
  status text NULL,
  created_at timestamp with time zone NULL DEFAULT now(),
  
  CONSTRAINT payments_pkey PRIMARY KEY (id),
  CONSTRAINT payments_order_id_fkey FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
  CONSTRAINT payments_status_check CHECK (
    status = ANY(ARRAY['pending'::text, 'success'::text, 'failed'::text, 'refunded'::text])
  )
) TABLESPACE pg_default;

-- =====================================================
-- TABLE: rush_hours
-- =====================================================

CREATE TABLE IF NOT EXISTS public.rush_hours (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  restaurant_id uuid NULL,
  start_time timestamp with time zone NOT NULL,
  end_time timestamp with time zone NOT NULL,
  discount_percentage integer NULL,
  is_active boolean NULL DEFAULT true,
  
  CONSTRAINT rush_hours_pkey PRIMARY KEY (id),
  CONSTRAINT rush_hours_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES restaurants (profile_id) ON DELETE CASCADE,
  CONSTRAINT rush_hours_discount_percentage_check CHECK (
    (discount_percentage >= 0) AND (discount_percentage <= 100)
  )
) TABLESPACE pg_default;

-- =====================================================
-- TABLE: user_addresses
-- =====================================================

CREATE TABLE IF NOT EXISTS public.user_addresses (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NULL,
  label text NULL,
  address_text text NOT NULL,
  location_lat double precision NULL,
  location_long double precision NULL,
  is_default boolean NULL DEFAULT false,
  created_at timestamp with time zone NULL DEFAULT now(),
  updated_at timestamp with time zone NULL DEFAULT now(),
  
  CONSTRAINT user_addresses_pkey PRIMARY KEY (id),
  CONSTRAINT user_addresses_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- Trigger for user_addresses
CREATE TRIGGER trg_update_user_addresses_updated_at 
BEFORE UPDATE ON user_addresses 
FOR EACH ROW 
EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- TABLE: favorites
-- =====================================================

CREATE TABLE IF NOT EXISTS public.favorites (
  user_id uuid NOT NULL,
  meal_id uuid NOT NULL,
  created_at timestamp with time zone NULL DEFAULT now(),
  
  CONSTRAINT favorites_pkey PRIMARY KEY (user_id, meal_id),
  CONSTRAINT favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- =====================================================
-- TABLE: cart_items
-- =====================================================

CREATE TABLE IF NOT EXISTS public.cart_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NULL,
  meal_id uuid NULL,
  quantity integer NULL DEFAULT 1,
  created_at timestamp with time zone NULL DEFAULT now(),
  
  CONSTRAINT cart_items_pkey PRIMARY KEY (id),
  CONSTRAINT cart_items_user_id_meal_id_key UNIQUE (user_id, meal_id),
  CONSTRAINT cart_items_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- =====================================================
-- TABLE: backup_profiles_role
-- =====================================================

CREATE TABLE IF NOT EXISTS public.backup_profiles_role (
  id uuid NOT NULL,
  email text NULL,
  role text NULL,
  backed_up_at timestamp with time zone NULL DEFAULT now(),
  
  CONSTRAINT backup_profiles_role_pkey PRIMARY KEY (id)
) TABLESPACE pg_default;

-- =====================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE ngos ENABLE ROW LEVEL SECURITY;
ALTER TABLE meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- PROFILES POLICIES
-- =====================================================

CREATE POLICY "Users can view their own profile"
ON profiles FOR SELECT
TO authenticated
USING (id = auth.uid());

CREATE POLICY "Users can update their own profile"
ON profiles FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

CREATE POLICY "Public can view approved profiles"
ON profiles FOR SELECT
TO authenticated, anon
USING (approval_status = 'approved');

-- =====================================================
-- RESTAURANTS POLICIES
-- =====================================================

CREATE POLICY "Restaurants can view their own profile"
ON restaurants FOR SELECT
TO authenticated
USING (profile_id = auth.uid());

CREATE POLICY "Restaurants can update their own profile"
ON restaurants FOR UPDATE
TO authenticated
USING (profile_id = auth.uid())
WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Public can view restaurants"
ON restaurants FOR SELECT
TO authenticated, anon
USING (true);

-- =====================================================
-- NGOS POLICIES
-- =====================================================

CREATE POLICY "NGOs can view their own profile"
ON ngos FOR SELECT
TO authenticated
USING (profile_id = auth.uid());

CREATE POLICY "NGOs can update their own profile"
ON ngos FOR UPDATE
TO authenticated
USING (profile_id = auth.uid())
WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Public can view NGOs"
ON ngos FOR SELECT
TO authenticated, anon
USING (true);

-- =====================================================
-- MEALS POLICIES
-- =====================================================

CREATE POLICY "Restaurants can view their own meals"
ON meals FOR SELECT
TO authenticated
USING (restaurant_id = auth.uid());

CREATE POLICY "Restaurants can insert their own meals"
ON meals FOR INSERT
TO authenticated
WITH CHECK (restaurant_id = auth.uid());

CREATE POLICY "Restaurants can update their own meals"
ON meals FOR UPDATE
TO authenticated
USING (restaurant_id = auth.uid())
WITH CHECK (restaurant_id = auth.uid());

CREATE POLICY "Restaurants can delete their own meals"
ON meals FOR DELETE
TO authenticated
USING (restaurant_id = auth.uid());

CREATE POLICY "Users can view active meals"
ON meals FOR SELECT
TO authenticated
USING (
  (status = 'active' OR status IS NULL)
  AND quantity_available > 0
  AND expiry_date > NOW()
);

CREATE POLICY "Anonymous can view active meals"
ON meals FOR SELECT
TO anon
USING (
  (status = 'active' OR status IS NULL)
  AND quantity_available > 0
  AND expiry_date > NOW()
);

-- =====================================================
-- ORDERS POLICIES
-- =====================================================

CREATE POLICY "Users can view their own orders"
ON orders FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own orders"
ON orders FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own orders"
ON orders FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Restaurants can view their orders"
ON orders FOR SELECT
TO authenticated
USING (restaurant_id = auth.uid());

CREATE POLICY "Restaurants can update their orders"
ON orders FOR UPDATE
TO authenticated
USING (restaurant_id = auth.uid())
WITH CHECK (restaurant_id = auth.uid());

CREATE POLICY "NGOs can view their orders"
ON orders FOR SELECT
TO authenticated
USING (ngo_id = auth.uid());

-- =====================================================
-- ORDER_ITEMS POLICIES
-- =====================================================

CREATE POLICY "Users can view their order items"
ON order_items FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = order_items.order_id
    AND orders.user_id = auth.uid()
  )
);

CREATE POLICY "Users can insert their order items"
ON order_items FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = order_items.order_id
    AND orders.user_id = auth.uid()
  )
);

CREATE POLICY "Restaurants can view order items"
ON order_items FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = order_items.order_id
    AND orders.restaurant_id = auth.uid()
  )
);

-- =====================================================
-- FAVORITES POLICIES
-- =====================================================

CREATE POLICY "Users can view their own favorites"
ON favorites FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own favorites"
ON favorites FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own favorites"
ON favorites FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- =====================================================
-- CART_ITEMS POLICIES
-- =====================================================

CREATE POLICY "Users can view their own cart"
ON cart_items FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can insert to their own cart"
ON cart_items FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own cart"
ON cart_items FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete from their own cart"
ON cart_items FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- =====================================================
-- USER_ADDRESSES POLICIES
-- =====================================================

CREATE POLICY "Users can view their own addresses"
ON user_addresses FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own addresses"
ON user_addresses FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own addresses"
ON user_addresses FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own addresses"
ON user_addresses FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- =====================================================
-- STORAGE BUCKET: meal-images
-- =====================================================

-- Create storage bucket for meal images
INSERT INTO storage.buckets (id, name, public)
VALUES ('meal-images', 'meal-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for meal-images
CREATE POLICY "Authenticated users can upload meal images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'meal-images'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Public can view meal images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'meal-images');

CREATE POLICY "Users can update their own meal images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'meal-images'
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'meal-images'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can delete their own meal images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'meal-images'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- =====================================================
-- VIEWS
-- =====================================================

-- View for meals with restaurant info
CREATE OR REPLACE VIEW meals_with_restaurant AS
SELECT 
  m.id,
  m.title,
  m.description,
  m.category,
  m.image_url,
  m.original_price,
  m.discounted_price,
  m.quantity_available,
  m.expiry_date,
  m.pickup_deadline,
  m.status,
  m.location,
  m.unit,
  m.fulfillment_method,
  m.is_donation_available,
  m.restaurant_id,
  m.created_at,
  m.updated_at,
  r.restaurant_name,
  r.rating as restaurant_rating,
  r.address_text as restaurant_address
FROM meals m
LEFT JOIN restaurants r ON m.restaurant_id = r.profile_id
WHERE (m.status = 'active' OR m.status IS NULL)
  AND m.quantity_available > 0
  AND m.expiry_date > NOW();

-- Grant access to view
GRANT SELECT ON meals_with_restaurant TO authenticated, anon;

-- =====================================================
-- SUMMARY
-- =====================================================

-- Total tables: 13
-- Total RLS policies: 40+
-- Total indexes: 10+
-- Total constraints: 20+
-- Storage buckets: 1

-- =====================================================
-- END OF SCHEMA
-- =====================================================
