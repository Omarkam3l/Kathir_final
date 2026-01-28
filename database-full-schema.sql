-- PROFILES
-- تفعيل الـ Extensions المطلوبة
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector"; -- لو هتعمل AI Search

-- فنكشن لتحديث الـ updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';
create table public.profiles (
  id uuid not null,
  role text null,
  email text null,
  full_name text null,
  phone_number text null,
  avatar_url text null,
  is_verified boolean null default false,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  approval_status text not null default 'pending'::text,
  constraint profiles_pkey primary key (id),
  constraint profiles_email_key unique (email),
  constraint profiles_id_fkey foreign KEY (id) references auth.users (id) on delete CASCADE,
  constraint profiles_approval_status_check check (
    (
      approval_status = any (
        array[
          'pending'::text,
          'approved'::text,
          'rejected'::text
        ]
      )
    )
  ),
  constraint profiles_role_check check (
    (
      role = any (
        array[
          'user'::text,
          'restaurant'::text,
          'ngo'::text,
          'admin'::text
        ]
      )
    )
  )
) TABLESPACE pg_default;

-- RESTAURANTS (One-to-One with Profiles)
CREATE TABLE public.restaurants (
    profile_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    restaurant_name text NOT NULL,
    address_text text,
    legal_docs_urls text[], -- Array storing URLs
    rating float DEFAULT 0,
    min_order_price decimal(12,2) DEFAULT 0,
    rush_hour_active boolean DEFAULT false
);

-- NGOS (One-to-One with Profiles)
CREATE TABLE public.ngos (
    profile_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    organization_name text NOT NULL,
    address_text text,
    legal_docs_urls text[]
);
-- USER ADDRESSES
CREATE TABLE public.user_addresses (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    label text, -- Home, Office, etc.
    address_text text NOT NULL,
    location_lat float,
    location_long float,
    is_default boolean DEFAULT false
);

-- MEALS
CREATE TABLE public.meals (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id uuid REFERENCES public.restaurants(profile_id) ON DELETE CASCADE,
    title text NOT NULL,
    description text,
    constraint meals_category_check check (
    category = any (
        array[
        'Meals'::text,          
        'Bakery'::text,         
        'Meat & Poultry'::text, 
        'Seafood'::text,        
        'Vegetables'::text,    
        'Desserts'::text,      
        'Groceries'::text       
        ]
    )
    )
    image_url text,
    original_price decimal(12,2) NOT NULL,
    discounted_price decimal(12,2) NOT NULL,
    quantity_available int NOT NULL DEFAULT 0,
    expiry_date timestamptz NOT NULL,
    pickup_deadline timestamptz,
    embedding vector(1536), -- Assuming OpenAI dimensions
    created_at timestamptz DEFAULT now()
);

-- RUSH HOURS
CREATE TABLE public.rush_hours (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id uuid REFERENCES public.restaurants(profile_id) ON DELETE CASCADE,
    start_time timestamptz NOT NULL,
    end_time timestamptz NOT NULL,
    discount_percentage int CHECK (discount_percentage BETWEEN 0 AND 100),
    is_active boolean DEFAULT true
);
-- CART ITEMS
CREATE TABLE public.cart_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    meal_id uuid REFERENCES public.meals(id) ON DELETE CASCADE,
    quantity int DEFAULT 1,
    created_at timestamptz DEFAULT now(),
    UNIQUE(user_id, meal_id) -- تمنع تكرار نفس الوجبة لنفس المستخدم
);

-- ORDERS
CREATE TABLE public.orders (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_code serial, -- كود سهل للقراءة (1, 2, 3...)
    user_id uuid REFERENCES public.profiles(id),
    restaurant_id uuid REFERENCES public.restaurants(profile_id),
    ngo_id uuid REFERENCES public.ngos(profile_id), -- اختياري في حالة التبرع
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'processing', 'ready_for_pickup', 'out_for_delivery', 'completed', 'cancelled')),
    delivery_type text CHECK (delivery_type IN ('pickup', 'delivery', 'donation')),
    subtotal decimal(12,2),
    service_fee decimal(12,2),
    delivery_fee decimal(12,2),
    platform_commission decimal(12,2),
    total_amount decimal(12,2),
    otp_code text,
    delivery_address text,
    created_at timestamptz DEFAULT now()
);

-- ORDER ITEMS
CREATE TABLE public.order_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id uuid REFERENCES public.orders(id) ON DELETE CASCADE,
    meal_id uuid REFERENCES public.meals(id),
    meal_title text, -- لتسجيل الاسم في حالة مسح الوجبة مستقبلاً
    quantity int NOT NULL,
    unit_price decimal(12,2) NOT NULL
);

-- PAYMENTS
CREATE TABLE public.payments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id uuid REFERENCES public.orders(id) ON DELETE CASCADE,
    transaction_id text,
    provider text, -- Stripe, Paymob, etc.
    amount decimal(12,2),
    status text CHECK (status IN ('pending', 'success', 'failed', 'refunded')),
    created_at timestamptz DEFAULT now()
);

-- FAVORITES
CREATE TABLE public.favorites (
    user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    meal_id uuid REFERENCES public.meals(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    PRIMARY KEY (user_id, meal_id)
);
-- تحديث الوقت تلقائياً في جدول البروفايل
CREATE TRIGGER trg_update_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- الاندكسات المهمة للأداء
CREATE INDEX idx_meals_restaurant_id ON public.meals(restaurant_id);
CREATE INDEX idx_orders_user_id ON public.orders(user_id);
CREATE INDEX idx_orders_restaurant_id ON public.orders(restaurant_id);
CREATE INDEX idx_meals_expiry_date ON public.meals(expiry_date) WHERE (expiry_date > now());