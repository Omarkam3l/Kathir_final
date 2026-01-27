-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Profiles Table
create table public.profiles ( 
   id uuid not null default gen_random_uuid (), 
   role text not null default 'user'::text, 
   full_name text not null, 
   email text null, 
   organization_name text null, 
   phone_number text null, 
   is_verified boolean not null default false, 
   avatar_url text null, 
   legal_docs_url text null, 
   created_at timestamp with time zone not null default now(), 
   updated_at timestamp with time zone null, ِ
   status text null default 'pending'::text, 
   default_location text null, 
   approval_status text null default 'pending'::text, 
   constraint profiles_pkey primary key (id), 
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
           'rest'::text, 
           'ngo'::text, 
           'admin'::text 
         ] 
       ) 
     ) 
   ), 
   constraint profiles_status_check check ( 
     ( 
       status = any ( 
         array[ 
           'pending'::text, 
           'approved'::text, 
           'rejected'::text, 
           'suspended'::text 
         ] 
       ) 
     ) 
   ) 
 ) TABLESPACE pg_default; 
 
 create index IF not exists idx_profiles_is_verified_role on public.profiles using btree (is_verified, role) TABLESPACE pg_default 
 where 
   (is_verified = false); 
 
 create index IF not exists idx_profiles_email on public.profiles using btree (email) TABLESPACE pg_default 
 where 
   (email is not null); 

-- Restaurants Table
create table public.restaurants ( 
   id uuid not null default gen_random_uuid (), 
   name text not null, 
   rating double precision not null default 0, 
   logo_url text null, 
   verified boolean null default false, 
   reviews_count integer null default 0, 
   constraint restaurants_pkey primary key (id) 
 ) TABLESPACE pg_default; 
 
 create index IF not exists idx_restaurants_name on public.restaurants using btree (name) TABLESPACE pg_default;

-- NGOs Table
create table public.ngos ( 
   id uuid not null default gen_random_uuid (), 
   created_at timestamp with time zone not null default now(), 
   name text not null, 
   description text null, 
   logo_url text null, 
   verified boolean null default false, 
   owner_id uuid null, 
   constraint ngos_pkey primary key (id), 
   constraint ngos_owner_id_fkey foreign KEY (owner_id) references profiles (id) 
 ) TABLESPACE pg_default; 
 
 create index IF not exists idx_ngos_name on public.ngos using btree (name) TABLESPACE pg_default;

-- Meals Table
create table public.meals ( 
   id uuid not null default gen_random_uuid (), 
   title text not null, 
   location text not null, 
   image_url text not null, 
   original_price double precision not null, 
   donation_price double precision not null, 
   quantity integer not null, 
   expiry timestamp with time zone not null, 
   restaurant_id uuid not null, 
   description text null, 
   ingredients text[] null, 
   allergens text[] null, 
   co2_savings numeric(5, 2) null default 0.0, 
   pickup_time timestamp with time zone null, 
   is_donation_available boolean null default false, 
   category text null default 'meals'::text, 
   unit text null default 'portions'::text, 
   fulfillment_method text null default 'pickup'::text, 
   status text null default 'active'::text, 
   pickup_deadline timestamp with time zone null, 
   constraint meals_pkey primary key (id), 
   constraint meals_restaurant_id_fkey foreign KEY (restaurant_id) references restaurants (id) on delete CASCADE, 
   constraint meals_category_check check ( 
     ( 
       category = any ( 
         array[ 
           'meals'::text, 
           'bakery'::text, 
           'raw_ingredients'::text, 
           'vegan'::text, 
           'produce'::text 
         ] 
       ) 
     ) 
   ), 
   constraint meals_fulfillment_method_check check ( 
     ( 
       fulfillment_method = any ( 
         array['pickup'::text, 'delivery'::text, 'both'::text] 
       ) 
     ) 
   ), 
   constraint meals_status_check check ( 
     ( 
       status = any ( 
         array[ 
           'active'::text, 
           'reserved'::text, 
           'sold'::text, 
           'expired'::text, 
           'cancelled'::text 
         ] 
       ) 
     ) 
   ), 
   constraint meals_unit_check check ( 
     ( 
       unit = any ( 
         array[ 
           'portions'::text, 
           'kilograms'::text, 
           'items'::text, 
           'boxes'::text 
         ] 
       ) 
     ) 
   ) 
 ) TABLESPACE pg_default;

-- Offers Table
create table public.offers ( 
   id uuid not null default gen_random_uuid (), 
   discount numeric(5, 2) not null, 
   created_at timestamp with time zone not null default now(), 
   updated_at timestamp with time zone not null default now(), 
   constraint offers_pkey primary key (id), 
   constraint offers_discount_check check ( 
     ( 
       (discount >= (0)::numeric) 
       and (discount <= (100)::numeric) 
     ) 
   ) 
 ) TABLESPACE pg_default; 
 
 create trigger t_offers_set_updated_at BEFORE 
 update on offers for EACH row 
 execute FUNCTION set_updated_at ();

-- Triggers for Profiles
-- Note: Ensure functions like prevent_role_update, set_updated_at, ensure_restaurant_details_on_profile exist

-- create trigger on_profile_update BEFORE 
-- update on profiles for EACH row 
-- execute FUNCTION prevent_role_update (); 
 
-- create trigger trg_profiles_set_updated_at BEFORE 
-- update on profiles for EACH row 
-- execute FUNCTION set_updated_at (); 
 
-- create trigger trg_profiles_auto_restaurant_details 
-- after INSERT on profiles for EACH row 
-- execute FUNCTION ensure_restaurant_details_on_profile ();
