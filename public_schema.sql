--
-- PostgreSQL database dump
--

\restrict ntn6h8dTTI7vnJDI6o1WJMqijqg9Zfr7gxicuaCcy2JxK4Z6znsHyZzXHFD7Fqn

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: order_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.order_status AS ENUM (
    'pending',
    'confirmed',
    'preparing',
    'ready_for_pickup',
    'out_for_delivery',
    'delivered',
    'completed',
    'cancelled'
);


ALTER TYPE public.order_status OWNER TO postgres;

--
-- Name: user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role AS ENUM (
    'user',
    'organization',
    'restaurant',
    'admin'
);


ALTER TYPE public.user_role OWNER TO postgres;

--
-- Name: append_ngo_legal_doc(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.append_ngo_legal_doc(p_url text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_profile_id uuid;
  v_updated_urls text[];
  v_org_name text;
BEGIN
  -- Get current user ID
  v_profile_id := auth.uid();

  -- Validate user is authenticated
  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Validate URL is not empty
  IF p_url IS NULL OR btrim(p_url) = '' THEN
    RAISE EXCEPTION 'URL cannot be empty';
  END IF;

  -- ✅ NEW: Check if NGO record exists, create if not
  IF NOT EXISTS (SELECT 1 FROM public.ngos WHERE profile_id = v_profile_id) THEN
    RAISE NOTICE 'NGO record not found for user %, creating...', v_profile_id;
    
    -- Get organization name from profile
    SELECT full_name INTO v_org_name FROM public.profiles WHERE id = v_profile_id;
    
    -- Create NGO record
    INSERT INTO public.ngos (
      profile_id,
      organization_name,
      legal_docs_urls,
      created_at,
      updated_at
    )
    VALUES (
      v_profile_id,
      COALESCE(NULLIF(TRIM(v_org_name), ''), 'Organization ' || SUBSTRING(v_profile_id::text, 1, 8)),
      ARRAY[]::text[],
      NOW(),
      NOW()
    );
    
    RAISE NOTICE '✅ Created missing NGO record for user %', v_profile_id;
  END IF;

  -- Update NGO record (only if user owns it)
  UPDATE public.ngos
  SET
    legal_docs_urls = array_append(
      COALESCE(legal_docs_urls, ARRAY[]::text[]),
      p_url
    ),
    updated_at = NOW()
  WHERE profile_id = v_profile_id
  RETURNING legal_docs_urls INTO v_updated_urls;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NGO record not found for user % after creation attempt', v_profile_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'profile_id', v_profile_id,
    'url', p_url,
    'legal_docs_urls', v_updated_urls
  );
END;
$$;


ALTER FUNCTION public.append_ngo_legal_doc(p_url text) OWNER TO postgres;

--
-- Name: FUNCTION append_ngo_legal_doc(p_url text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.append_ngo_legal_doc(p_url text) IS 'Atomically appends a legal document URL to ngos.legal_docs_urls array. Auto-creates NGO record if missing. Only the authenticated user can update their own record.';


--
-- Name: append_restaurant_legal_doc(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.append_restaurant_legal_doc(p_url text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_profile_id uuid;
  v_updated_urls text[];
  v_restaurant_name text;
BEGIN
  -- Get current user ID
  v_profile_id := auth.uid();

  -- Validate user is authenticated
  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Validate URL is not empty
  IF p_url IS NULL OR btrim(p_url) = '' THEN
    RAISE EXCEPTION 'URL cannot be empty';
  END IF;

  -- ✅ NEW: Check if restaurant record exists, create if not
  IF NOT EXISTS (SELECT 1 FROM public.restaurants WHERE profile_id = v_profile_id) THEN
    RAISE NOTICE 'Restaurant record not found for user %, creating...', v_profile_id;
    
    -- Get restaurant name from profile
    SELECT full_name INTO v_restaurant_name FROM public.profiles WHERE id = v_profile_id;
    
    -- Create restaurant record
    INSERT INTO public.restaurants (
      profile_id,
      restaurant_name,
      legal_docs_urls,
      rating,
      min_order_price,
      rush_hour_active,
      created_at,
      updated_at
    )
    VALUES (
      v_profile_id,
      COALESCE(NULLIF(TRIM(v_restaurant_name), ''), 'Restaurant ' || SUBSTRING(v_profile_id::text, 1, 8)),
      ARRAY[]::text[],
      0,
      0,
      false,
      NOW(),
      NOW()
    );
    
    RAISE NOTICE '✅ Created missing restaurant record for user %', v_profile_id;
  END IF;

  -- Update restaurant record (only if user owns it)
  UPDATE public.restaurants
  SET
    legal_docs_urls = array_append(
      COALESCE(legal_docs_urls, ARRAY[]::text[]),
      p_url
    ),
    updated_at = NOW()
  WHERE profile_id = v_profile_id
  RETURNING legal_docs_urls INTO v_updated_urls;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Restaurant record not found for user % after creation attempt', v_profile_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'profile_id', v_profile_id,
    'url', p_url,
    'legal_docs_urls', v_updated_urls
  );
END;
$$;


ALTER FUNCTION public.append_restaurant_legal_doc(p_url text) OWNER TO postgres;

--
-- Name: FUNCTION append_restaurant_legal_doc(p_url text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.append_restaurant_legal_doc(p_url text) IS 'Atomically appends a legal document URL to restaurants.legal_docs_urls array. Auto-creates restaurant record if missing. Only the authenticated user can update their own record.';


--
-- Name: auto_generate_order_codes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.auto_generate_order_codes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Generate pickup code if not exists
    IF NEW.pickup_code IS NULL THEN
        NEW.pickup_code := generate_pickup_code();
    END IF;
    
    -- Generate QR code data
    IF NEW.qr_code IS NULL THEN
        NEW.qr_code := generate_qr_code_data(NEW.id);
    END IF;
    
    -- Set estimated ready time (30 minutes from now by default)
    IF NEW.estimated_ready_time IS NULL THEN
        NEW.estimated_ready_time := NOW() + INTERVAL '30 minutes';
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.auto_generate_order_codes() OWNER TO postgres;

--
-- Name: award_order_points(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.award_order_points() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_points int;
  v_user_role text;
  v_is_donation boolean;
BEGIN
  -- Only award points when order is completed
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    
    -- Check if user is a regular user (not restaurant/NGO)
    SELECT role INTO v_user_role FROM profiles WHERE id = NEW.user_id;
    
    IF v_user_role = 'user' THEN
      -- Calculate points: 1 point per EGP spent
      v_points := FLOOR(NEW.total_amount);
      
      -- Bonus points for donations
      v_is_donation := (NEW.delivery_type = 'donation' AND NEW.ngo_id IS NOT NULL);
      IF v_is_donation THEN
        v_points := v_points * 2; -- Double points for donations
      END IF;
      
      -- Award points
      INSERT INTO loyalty_transactions (
        user_id,
        points,
        transaction_type,
        source,
        order_id,
        description
      ) VALUES (
        NEW.user_id,
        v_points,
        'earned',
        CASE WHEN v_is_donation THEN 'donation' ELSE 'order' END,
        NEW.id,
        CASE 
          WHEN v_is_donation THEN 'Earned ' || v_points || ' points from donation (2x bonus!)'
          ELSE 'Earned ' || v_points || ' points from order'
        END
      );
      
      -- Update loyalty profile
      UPDATE user_loyalty
      SET 
        total_points = total_points + v_points,
        available_points = available_points + v_points,
        lifetime_points = lifetime_points + v_points,
        total_orders = total_orders + 1,
        total_donations = total_donations + CASE WHEN v_is_donation THEN 1 ELSE 0 END,
        updated_at = NOW()
      WHERE user_id = NEW.user_id;
      
      -- Check and award badges
      PERFORM check_and_award_badges(NEW.user_id);
      
      -- Check and update tier
      PERFORM update_user_tier(NEW.user_id);
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.award_order_points() OWNER TO postgres;

--
-- Name: calculate_effective_price(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_effective_price(p_meal_id uuid) RETURNS numeric
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
  v_effective_price numeric;
BEGIN
  SELECT 
    CASE 
      WHEN rh.id IS NOT NULL AND rh.is_active AND NOW() BETWEEN rh.start_time AND rh.end_time THEN
        ROUND(m.original_price * (1 - rh.discount_percentage / 100.0), 2)
      ELSE
        m.discounted_price
    END
  INTO v_effective_price
  FROM meals m
  LEFT JOIN rush_hours rh ON m.restaurant_id = rh.restaurant_id 
    AND rh.is_active = true
    AND NOW() BETWEEN rh.start_time AND rh.end_time
  WHERE m.id = p_meal_id;
  
  RETURN COALESCE(v_effective_price, 0);
END;
$$;


ALTER FUNCTION public.calculate_effective_price(p_meal_id uuid) OWNER TO postgres;

--
-- Name: FUNCTION calculate_effective_price(p_meal_id uuid); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.calculate_effective_price(p_meal_id uuid) IS 'Calculates the effective price for a meal considering rush hour discounts.
Use this in checkout/order processing to ensure correct pricing.';


--
-- Name: can_rate_order(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.can_rate_order(p_order_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_user_id uuid;
  v_order_status text;
  v_existing_rating integer;
BEGIN
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'can_rate', false,
      'reason', 'Not authenticated'
    );
  END IF;
  
  -- Check order status and ownership
  SELECT o.status::text
  INTO v_order_status
  FROM orders o
  WHERE o.id = p_order_id
    AND o.user_id = v_user_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'can_rate', false,
      'reason', 'Order not found'
    );
  END IF;
  
  IF v_order_status NOT IN ('delivered', 'completed') THEN
    RETURN jsonb_build_object(
      'can_rate', false,
      'reason', 'Order not yet completed'
    );
  END IF;
  
  -- Check if already rated
  SELECT rating
  INTO v_existing_rating
  FROM restaurant_ratings
  WHERE order_id = p_order_id;
  
  IF FOUND THEN
    RETURN jsonb_build_object(
      'can_rate', true,
      'already_rated', true,
      'existing_rating', v_existing_rating,
      'reason', 'Can update existing rating'
    );
  END IF;
  
  RETURN jsonb_build_object(
    'can_rate', true,
    'already_rated', false,
    'reason', 'Can submit new rating'
  );
END;
$$;


ALTER FUNCTION public.can_rate_order(p_order_id uuid) OWNER TO postgres;

--
-- Name: FUNCTION can_rate_order(p_order_id uuid); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.can_rate_order(p_order_id uuid) IS 'Check if the authenticated user can rate a specific order';


--
-- Name: check_and_award_badges(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_and_award_badges(p_user_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_total_orders int;
  v_total_donations int;
  v_lifetime_points int;
BEGIN
  -- Get user stats
  SELECT total_orders, total_donations, lifetime_points
  INTO v_total_orders, v_total_donations, v_lifetime_points
  FROM user_loyalty
  WHERE user_id = p_user_id;
  
  -- First Order Badge
  IF v_total_orders >= 1 THEN
    INSERT INTO user_badges (user_id, badge_type, badge_name, badge_description, icon)
    VALUES (p_user_id, 'first_order', 'First Order', 'Completed your first order', '🎉')
    ON CONFLICT (user_id, badge_type) DO NOTHING;
  END IF;
  
  -- Food Rescuer Badge (5+ orders)
  IF v_total_orders >= 5 THEN
    INSERT INTO user_badges (user_id, badge_type, badge_name, badge_description, icon)
    VALUES (p_user_id, 'food_rescuer', 'Food Rescuer', 'Rescued food 5+ times', '🦸')
    ON CONFLICT (user_id, badge_type) DO NOTHING;
  END IF;
  
  -- NGO Supporter Badge (3+ donations)
  IF v_total_donations >= 3 THEN
    INSERT INTO user_badges (user_id, badge_type, badge_name, badge_description, icon)
    VALUES (p_user_id, 'ngo_supporter', 'NGO Supporter', 'Donated to NGOs 3+ times', '❤️')
    ON CONFLICT (user_id, badge_type) DO NOTHING;
  END IF;
  
  -- Loyal Customer Badge (10+ orders)
  IF v_total_orders >= 10 THEN
    INSERT INTO user_badges (user_id, badge_type, badge_name, badge_description, icon)
    VALUES (p_user_id, 'loyal_customer', 'Loyal Customer', 'Completed 10+ orders', '⭐')
    ON CONFLICT (user_id, badge_type) DO NOTHING;
  END IF;
  
  -- Eco Warrior Badge (500+ points)
  IF v_lifetime_points >= 500 THEN
    INSERT INTO user_badges (user_id, badge_type, badge_name, badge_description, icon)
    VALUES (p_user_id, 'eco_warrior', 'Eco Warrior', 'Earned 500+ lifetime points', '🌱')
    ON CONFLICT (user_id, badge_type) DO NOTHING;
  END IF;
END;
$$;


ALTER FUNCTION public.check_and_award_badges(p_user_id uuid) OWNER TO postgres;

--
-- Name: complete_pickup(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.complete_pickup(p_order_id uuid, p_pickup_code text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    is_valid BOOLEAN;
    result JSONB;
BEGIN
    -- Verify pickup code
    is_valid := verify_pickup_code(p_order_id, p_pickup_code);
    
    IF NOT is_valid THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Invalid pickup code or order not ready'
        );
    END IF;
    
    -- Update order status
    UPDATE orders
    SET status = 'completed',
        picked_up_at = NOW()
    WHERE id = p_order_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Order picked up successfully'
    );
END;
$$;


ALTER FUNCTION public.complete_pickup(p_order_id uuid, p_pickup_code text) OWNER TO postgres;

--
-- Name: complete_restaurant_setup(uuid, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.complete_restaurant_setup(p_user_id uuid, p_full_name text, p_email text, p_org_name text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_profile record;
  v_restaurant record;
begin
  insert into public.profiles (id, email, full_name, role, organization_name, is_verified)
  values (p_user_id, p_email, p_full_name, 'restaurant', p_org_name, true)
  on conflict (id) do update
    set email = excluded.email,
        full_name = excluded.full_name,
        role = excluded.role,
        organization_name = excluded.organization_name;

  select * into v_profile from public.profiles where id = p_user_id;

  insert into public.restaurants (name, profile_id)
  values (p_org_name, p_user_id)
  on conflict (profile_id) do update set name = excluded.name;

  select * into v_restaurant from public.restaurants where profile_id = p_user_id;

  return jsonb_build_object(
    'profile', to_jsonb(v_profile),
    'restaurant', to_jsonb(v_restaurant)
  );
end;
$$;


ALTER FUNCTION public.complete_restaurant_setup(p_user_id uuid, p_full_name text, p_email text, p_org_name text) OWNER TO postgres;

--
-- Name: create_meal_notifications(uuid, text, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_meal_notifications(p_meal_id uuid, p_category text, p_restaurant_id uuid) RETURNS TABLE(notifications_created integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_count int := 0;
BEGIN
  -- Insert notifications for all subscribed users
  INSERT INTO category_notifications (user_id, meal_id, category)
  SELECT 
    ucp.user_id,
    p_meal_id,
    p_category
  FROM user_category_preferences ucp
  WHERE ucp.category = p_category
    AND ucp.notifications_enabled = true
    AND ucp.user_id != p_restaurant_id; -- Don't notify restaurant owner
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  
  RETURN QUERY SELECT v_count;
END;
$$;


ALTER FUNCTION public.create_meal_notifications(p_meal_id uuid, p_category text, p_restaurant_id uuid) OWNER TO postgres;

--
-- Name: decrement_meal_quantity(uuid, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.decrement_meal_quantity(meal_id uuid, qty integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  -- Update meal quantity
  UPDATE meals
  SET quantity_available = GREATEST(quantity_available - qty, 0),
      updated_at = now()
  WHERE id = meal_id;

  -- If quantity reaches 0, mark as sold
  UPDATE meals
  SET status = 'sold'
  WHERE id = meal_id
    AND quantity_available = 0;
END;
$$;


ALTER FUNCTION public.decrement_meal_quantity(meal_id uuid, qty integer) OWNER TO postgres;

--
-- Name: FUNCTION decrement_meal_quantity(meal_id uuid, qty integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.decrement_meal_quantity(meal_id uuid, qty integer) IS 'Safely decrements meal quantity when order is created';


--
-- Name: donate_meal(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.donate_meal(p_meal_id uuid, p_restaurant_id uuid) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_meal_record RECORD;
  v_original_price numeric(12,2);
  v_donation_id uuid;
  v_notification_count integer := 0;
  v_user RECORD;
BEGIN
  -- Get meal details
  SELECT * INTO v_meal_record
  FROM meals
  WHERE id = p_meal_id
    AND restaurant_id = p_restaurant_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Meal not found or unauthorized';
  END IF;

  -- Store original price
  v_original_price := v_meal_record.discounted_price;

  -- Update meal price to 0
  UPDATE meals
  SET discounted_price = 0,
      original_price = 0,
      updated_at = now()
  WHERE id = p_meal_id;

  -- Create donation record
  INSERT INTO free_meal_notifications (
    meal_id,
    restaurant_id,
    original_price,
    notification_sent
  )
  VALUES (
    p_meal_id,
    p_restaurant_id,
    v_original_price,
    true
  )
  RETURNING id INTO v_donation_id;

  -- Create FREE MEAL notifications for all users (separate from category notifications)
  FOR v_user IN
    SELECT id FROM profiles WHERE role = 'user'
  LOOP
    INSERT INTO free_meal_user_notifications (
      user_id,
      meal_id,
      donation_id,
      restaurant_id
    )
    VALUES (
      v_user.id,
      p_meal_id,
      v_donation_id,
      p_restaurant_id
    );

    v_notification_count := v_notification_count + 1;
  END LOOP;

  -- Return success response
  RETURN json_build_object(
    'success', true,
    'donation_id', v_donation_id,
    'meal_id', p_meal_id,
    'original_price', v_original_price,
    'notifications_sent', v_notification_count,
    'message', 'Meal donated successfully!'
  );

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error donating meal: %', SQLERRM;
END;
$$;


ALTER FUNCTION public.donate_meal(p_meal_id uuid, p_restaurant_id uuid) OWNER TO postgres;

--
-- Name: FUNCTION donate_meal(p_meal_id uuid, p_restaurant_id uuid); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.donate_meal(p_meal_id uuid, p_restaurant_id uuid) IS 'Donates a meal and creates special free meal notifications for all users';


--
-- Name: ensure_restaurant_details_on_profile(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ensure_restaurant_details_on_profile() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if new.role = 'RESTAURANT' then
    -- Insert default restaurant_details if missing
    insert into public.restaurant_details (id, is_verified, wallet_balance)
    values (new.id, false, 0)
    on conflict (id) do nothing;
  end if;
  return new;
end
$$;


ALTER FUNCTION public.ensure_restaurant_details_on_profile() OWNER TO postgres;

--
-- Name: generate_order_number(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_order_number() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  new_order_number text;
  counter integer := 0;
BEGIN
  LOOP
    -- Generate order number: ORD + timestamp + random 4 digits
    new_order_number := 'ORD' || 
                       to_char(now(), 'YYYYMMDD') || 
                       lpad(floor(random() * 10000)::text, 4, '0');
    
    -- Check if it exists
    IF NOT EXISTS (SELECT 1 FROM orders WHERE order_number = new_order_number) THEN
      RETURN new_order_number;
    END IF;
    
    counter := counter + 1;
    IF counter > 10 THEN
      -- Fallback to UUID if we can't generate unique number
      RETURN 'ORD' || replace(gen_random_uuid()::text, '-', '');
    END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION public.generate_order_number() OWNER TO postgres;

--
-- Name: FUNCTION generate_order_number(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.generate_order_number() IS 'Generates unique order number with format ORD + date + random digits';


--
-- Name: generate_pickup_code(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_pickup_code() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    code TEXT;
    exists BOOLEAN;
BEGIN
    LOOP
        -- Generate 6-digit alphanumeric code
        code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6));
        
        -- Check if code already exists in active orders
        SELECT EXISTS(
            SELECT 1 FROM orders 
            WHERE pickup_code = code 
            AND status IN ('pending', 'confirmed', 'preparing', 'ready_for_pickup')
        ) INTO exists;
        
        EXIT WHEN NOT exists;
    END LOOP;
    
    RETURN code;
END;
$$;


ALTER FUNCTION public.generate_pickup_code() OWNER TO postgres;

--
-- Name: generate_qr_code_data(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_qr_code_data(order_uuid uuid) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    qr_data JSONB;
BEGIN
    SELECT jsonb_build_object(
        'order_id', o.id,
        'pickup_code', o.pickup_code,
        'user_id', o.user_id,
        'restaurant_id', o.restaurant_id,
        'total', o.total_amount,
        'created_at', o.created_at
    ) INTO qr_data
    FROM orders o
    WHERE o.id = order_uuid;
    
    RETURN qr_data::TEXT;
END;
$$;


ALTER FUNCTION public.generate_qr_code_data(order_uuid uuid) OWNER TO postgres;

--
-- Name: get_approved_ngos(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_approved_ngos() RETURNS TABLE(profile_id uuid, organization_name text, avatar_url text)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT 
    n.profile_id,
    n.organization_name,
    p.avatar_url
  FROM ngos n
  INNER JOIN profiles p ON n.profile_id = p.id
  WHERE p.role = 'ngo' 
    AND p.approval_status = 'approved'
  ORDER BY n.organization_name;
$$;


ALTER FUNCTION public.get_approved_ngos() OWNER TO postgres;

--
-- Name: FUNCTION get_approved_ngos(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.get_approved_ngos() IS 'Returns list of approved NGOs with their profile information. Avoids recursion issues that occur with nested PostgREST queries.';


--
-- Name: get_free_meal_notifications(uuid, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_free_meal_notifications(p_user_id uuid, p_limit integer DEFAULT 50) RETURNS TABLE(id uuid, meal_id uuid, meal_title text, meal_image_url text, meal_category text, meal_quantity integer, restaurant_id uuid, restaurant_name text, restaurant_logo text, sent_at timestamp with time zone, is_read boolean, claimed boolean, claimed_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    fmn.id,
    fmn.meal_id,
    m.title as meal_title,
    m.image_url as meal_image_url,
    m.category as meal_category,
    m.quantity_available as meal_quantity,
    fmn.restaurant_id,
    r.restaurant_name,
    p.avatar_url as restaurant_logo,
    fmn.sent_at,
    fmn.is_read,
    fmn.claimed,
    fmn.claimed_at
  FROM free_meal_user_notifications fmn
  INNER JOIN meals m ON fmn.meal_id = m.id
  INNER JOIN restaurants r ON fmn.restaurant_id = r.profile_id
  LEFT JOIN profiles p ON r.profile_id = p.id
  WHERE fmn.user_id = p_user_id
  ORDER BY fmn.sent_at DESC
  LIMIT p_limit;
END;
$$;


ALTER FUNCTION public.get_free_meal_notifications(p_user_id uuid, p_limit integer) OWNER TO postgres;

--
-- Name: FUNCTION get_free_meal_notifications(p_user_id uuid, p_limit integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.get_free_meal_notifications(p_user_id uuid, p_limit integer) IS 'Get user free meal notifications with meal and restaurant details';


--
-- Name: get_meals_with_effective_discount(uuid, text, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_meals_with_effective_discount(p_restaurant_id uuid DEFAULT NULL::uuid, p_category text DEFAULT NULL::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0) RETURNS TABLE(id uuid, restaurant_id uuid, title text, description text, category text, image_url text, original_price numeric, discounted_price numeric, effective_price numeric, quantity_available integer, expiry_date timestamp with time zone, status text, location text, effective_discount_percentage integer, rush_hour_active_now boolean, restaurant_name text, restaurant_rating double precision)
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.id,
    m.restaurant_id,
    m.title,
    m.description,
    m.category,
    m.image_url,
    m.original_price,
    m.discounted_price,
    CASE 
      WHEN rh.id IS NOT NULL AND rh.is_active AND NOW() BETWEEN rh.start_time AND rh.end_time THEN
        ROUND(m.original_price * (1 - rh.discount_percentage / 100.0), 2)
      ELSE
        m.discounted_price
    END AS effective_price,
    m.quantity_available,
    m.expiry_date,
    m.status,
    m.location,
    COALESCE(rh.discount_percentage, 
      ROUND(((m.original_price - m.discounted_price) / m.original_price * 100)::numeric, 0)::integer
    ) AS effective_discount_percentage,
    (rh.id IS NOT NULL AND rh.is_active AND NOW() BETWEEN rh.start_time AND rh.end_time) AS rush_hour_active_now,
    r.restaurant_name,
    r.rating AS restaurant_rating
  FROM meals m
  LEFT JOIN restaurants r ON m.restaurant_id = r.profile_id
  LEFT JOIN rush_hours rh ON m.restaurant_id = rh.restaurant_id 
    AND rh.is_active = true
    AND NOW() BETWEEN rh.start_time AND rh.end_time
  WHERE 
    (m.status = 'active' OR m.status IS NULL)
    AND m.quantity_available > 0
    AND m.expiry_date > NOW()
    AND (p_restaurant_id IS NULL OR m.restaurant_id = p_restaurant_id)
    AND (p_category IS NULL OR m.category = p_category)
  ORDER BY m.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;


ALTER FUNCTION public.get_meals_with_effective_discount(p_restaurant_id uuid, p_category text, p_limit integer, p_offset integer) OWNER TO postgres;

--
-- Name: FUNCTION get_meals_with_effective_discount(p_restaurant_id uuid, p_category text, p_limit integer, p_offset integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.get_meals_with_effective_discount(p_restaurant_id uuid, p_category text, p_limit integer, p_offset integer) IS 'Returns meals with effective discount and price, with optional filtering and pagination.';


--
-- Name: get_my_restaurant_rank(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_my_restaurant_rank(period_filter text DEFAULT 'all'::text) RETURNS TABLE(rank bigint, score bigint, restaurant_name text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    lb.rank,
    lb.score,
    lb.restaurant_name
  FROM 
    get_restaurant_leaderboard(period_filter) lb
  WHERE 
    lb.restaurant_profile_id = auth.uid()
  LIMIT 1;
END;
$$;


ALTER FUNCTION public.get_my_restaurant_rank(period_filter text) OWNER TO postgres;

--
-- Name: FUNCTION get_my_restaurant_rank(period_filter text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.get_my_restaurant_rank(period_filter text) IS 'Returns the current authenticated user''s restaurant rank and score.
Returns NULL if user is not a restaurant or has no sales.';


--
-- Name: get_my_rush_hour(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_my_rush_hour() RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_restaurant_id uuid;
  v_result json;
BEGIN
  -- Get authenticated restaurant ID
  v_restaurant_id := auth.uid();
  
  IF v_restaurant_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Get the most recent rush hour configuration (active or inactive)
  SELECT json_build_object(
    'id', id,
    'restaurant_id', restaurant_id,
    'is_active', is_active,
    'start_time', start_time,
    'end_time', end_time,
    'discount_percentage', discount_percentage,
    'active_now', (is_active AND NOW() BETWEEN start_time AND end_time)
  ) INTO v_result
  FROM rush_hours
  WHERE restaurant_id = v_restaurant_id
  ORDER BY 
    CASE WHEN is_active THEN 0 ELSE 1 END,  -- Active first
    created_at DESC
  LIMIT 1;
  
  -- If no configuration exists, return default
  IF v_result IS NULL THEN
    v_result := json_build_object(
      'id', NULL,
      'restaurant_id', v_restaurant_id,
      'is_active', false,
      'start_time', NULL,
      'end_time', NULL,
      'discount_percentage', 50,  -- Default 50%
      'active_now', false
    );
  END IF;
  
  RETURN v_result;
END;
$$;


ALTER FUNCTION public.get_my_rush_hour() OWNER TO postgres;

--
-- Name: FUNCTION get_my_rush_hour(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.get_my_rush_hour() IS 'Returns the current rush hour configuration for the authenticated restaurant, 
including whether it is currently active (active_now).';


--
-- Name: get_pending_emails(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_pending_emails(p_limit integer DEFAULT 10) RETURNS TABLE(id uuid, order_id uuid, recipient_email text, recipient_type text, email_type text, email_data jsonb, attempts integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    eq.id,
    eq.order_id,
    eq.recipient_email,
    eq.recipient_type,
    eq.email_type,
    eq.email_data,
    eq.attempts
  FROM email_queue eq
  WHERE eq.status = 'pending'
    AND eq.attempts < 3
  ORDER BY eq.created_at ASC
  LIMIT p_limit;
END;
$$;


ALTER FUNCTION public.get_pending_emails(p_limit integer) OWNER TO postgres;

--
-- Name: get_restaurant_leaderboard(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_restaurant_leaderboard(period_filter text DEFAULT 'all'::text) RETURNS TABLE(restaurant_profile_id uuid, restaurant_name text, avatar_url text, score bigint, rank bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  date_threshold timestamptz;
BEGIN
  -- Determine date threshold based on period
  CASE period_filter
    WHEN 'week' THEN
      date_threshold := NOW() - INTERVAL '7 days';
    WHEN 'month' THEN
      date_threshold := NOW() - INTERVAL '30 days';
    ELSE
      date_threshold := '1970-01-01'::timestamptz; -- All time
  END CASE;

  -- Return ranked restaurants with their meal counts
  RETURN QUERY
  WITH restaurant_scores AS (
    SELECT 
      r.profile_id,
      r.restaurant_name,
      p.avatar_url,
      COALESCE(SUM(oi.quantity), 0)::bigint AS total_meals_sold
    FROM 
      restaurants r
    INNER JOIN 
      profiles p ON r.profile_id = p.id
    LEFT JOIN 
      orders o ON r.profile_id = o.restaurant_id 
      AND o.status IN ('delivered', 'completed')
      AND o.created_at >= date_threshold
    LEFT JOIN 
      order_items oi ON o.id = oi.order_id
    WHERE
      p.approval_status = 'approved'
      AND p.role = 'restaurant'
    GROUP BY 
      r.profile_id, r.restaurant_name, p.avatar_url
  )
  SELECT 
    rs.profile_id,
    rs.restaurant_name,
    rs.avatar_url,
    rs.total_meals_sold,
    ROW_NUMBER() OVER (ORDER BY rs.total_meals_sold DESC, rs.restaurant_name ASC)::bigint AS rank
  FROM 
    restaurant_scores rs
  WHERE
    rs.total_meals_sold > 0  -- Only include restaurants with sales
  ORDER BY 
    rank ASC;
END;
$$;


ALTER FUNCTION public.get_restaurant_leaderboard(period_filter text) OWNER TO postgres;

--
-- Name: FUNCTION get_restaurant_leaderboard(period_filter text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.get_restaurant_leaderboard(period_filter text) IS 'Computes restaurant leaderboard rankings based on meals sold. 
Period options: week, month, all. 
Counts orders with status delivered or completed.
Returns only restaurants with sales > 0.
Safe for public access - only exposes approved restaurant data.';


--
-- Name: get_restaurant_ratings(uuid, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_restaurant_ratings(p_restaurant_id uuid, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0) RETURNS TABLE(id uuid, rating integer, review_text text, user_name text, user_avatar text, created_at timestamp with time zone, order_id uuid)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rr.id,
    rr.rating,
    rr.review_text,
    p.full_name as user_name,
    p.avatar_url as user_avatar,
    rr.created_at,
    rr.order_id
  FROM restaurant_ratings rr
  JOIN profiles p ON rr.user_id = p.id
  WHERE rr.restaurant_id = p_restaurant_id
  ORDER BY rr.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;


ALTER FUNCTION public.get_restaurant_ratings(p_restaurant_id uuid, p_limit integer, p_offset integer) OWNER TO postgres;

--
-- Name: FUNCTION get_restaurant_ratings(p_restaurant_id uuid, p_limit integer, p_offset integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.get_restaurant_ratings(p_restaurant_id uuid, p_limit integer, p_offset integer) IS 'Get all ratings for a restaurant with user details';


--
-- Name: handle_address_deletion(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.handle_address_deletion() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- If the deleted address was default, clear the profile's default_location
  IF OLD.is_default = true THEN
    UPDATE profiles
    SET default_location = NULL
    WHERE id = OLD.user_id;
  END IF;
  
  RETURN OLD;
END;
$$;


ALTER FUNCTION public.handle_address_deletion() OWNER TO postgres;

--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_role text;
  v_full_name text;
  v_is_verified boolean;
  v_approval_status text;
BEGIN
  -- Get role from metadata
  v_role := COALESCE(NEW.raw_user_meta_data->>'role', 'user');
  v_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', 'User');

  -- Set is_verified based on role
  -- Regular users are verified after email confirmation
  -- Restaurant/NGO users need admin approval
  v_is_verified := CASE 
    WHEN v_role IN ('restaurant', 'ngo') THEN false
    ELSE true
  END;

  -- Set approval status based on role
  v_approval_status := CASE 
    WHEN v_role IN ('restaurant', 'ngo') THEN 'pending'
    ELSE 'approved'
  END;

  -- Create profile with correct is_verified value
  INSERT INTO public.profiles (
    id,
    role,
    email,
    full_name,
    is_verified,
    approval_status,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    v_role,
    NEW.email,
    v_full_name,
    v_is_verified,
    v_approval_status,
    NOW(),
    NOW()
  );

  -- Create NGO record if role is ngo
  IF v_role = 'ngo' THEN
    INSERT INTO public.ngos (
      profile_id,
      organization_name,
      legal_docs_urls,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      v_full_name,
      ARRAY[]::text[],
      NOW(),
      NOW()
    );
    
    RAISE NOTICE '✅ Created NGO record for user %', NEW.id;
  END IF;

  -- Create restaurant record if role is restaurant
  IF v_role = 'restaurant' THEN
    INSERT INTO public.restaurants (
      profile_id,
      restaurant_name,
      legal_docs_urls,
      rating,
      min_order_price,
      rush_hour_active
    )
    VALUES (
      NEW.id,
      v_full_name,
      ARRAY[]::text[],
      0,
      0,
      false
    );
    
    RAISE NOTICE '✅ Created restaurant record for user %', NEW.id;
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error in handle_new_user: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

--
-- Name: FUNCTION handle_new_user(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.handle_new_user() IS 'Trigger function to create profile and role-specific records (NGO/restaurant) when a new user signs up. Sets is_verified=false for restaurant/ngo roles.';


--
-- Name: increment_meal_quantity(uuid, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.increment_meal_quantity(meal_id uuid, qty integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  -- Update meal quantity
  UPDATE meals
  SET quantity_available = quantity_available + qty,
      status = 'active',  -- Reactivate if was sold
      updated_at = now()
  WHERE id = meal_id;
END;
$$;


ALTER FUNCTION public.increment_meal_quantity(meal_id uuid, qty integer) OWNER TO postgres;

--
-- Name: FUNCTION increment_meal_quantity(meal_id uuid, qty integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.increment_meal_quantity(meal_id uuid, qty integer) IS 'Safely increments meal quantity when order is cancelled';


--
-- Name: initialize_user_loyalty(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.initialize_user_loyalty() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  -- Only for regular users, not restaurants or NGOs
  IF NEW.role = 'user' THEN
    INSERT INTO user_loyalty (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.initialize_user_loyalty() OWNER TO postgres;

--
-- Name: is_admin(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_admin() RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
  );
$$;


ALTER FUNCTION public.is_admin() OWNER TO postgres;

--
-- Name: FUNCTION is_admin(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.is_admin() IS 'Returns true if current authenticated user has role=admin in public.profiles';


--
-- Name: log_order_status_change(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_order_status_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Only log if status actually changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO order_status_history (order_id, status, changed_by, notes)
        VALUES (NEW.id, NEW.status, auth.uid(), 'Status changed from ' || OLD.status::text || ' to ' || NEW.status::text);
        
        -- Update timestamp fields based on status
        CASE NEW.status
            WHEN 'ready_for_pickup' THEN
                NEW.actual_ready_time := NOW();
            WHEN 'delivered' THEN
                NEW.delivered_at := NOW();
            WHEN 'completed' THEN
                IF NEW.delivery_type = 'pickup' THEN
                    NEW.picked_up_at := NOW();
                ELSE
                    NEW.delivered_at := NOW();
                END IF;
            WHEN 'cancelled' THEN
                NEW.cancelled_at := NOW();
            ELSE
                NULL;
        END CASE;
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.log_order_status_change() OWNER TO postgres;

--
-- Name: notify_category_subscribers(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.notify_category_subscribers() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Only notify for new active meals
  IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.status != 'active' AND NEW.status = 'active'))
     AND NEW.status = 'active'
     AND NEW.quantity_available > 0
     AND NEW.expiry_date > NOW()
  THEN
    -- Insert notifications for all users subscribed to this category
    INSERT INTO category_notifications (user_id, meal_id, category)
    SELECT 
      ucp.user_id,
      NEW.id,
      NEW.category
    FROM user_category_preferences ucp
    WHERE ucp.category = NEW.category
      AND ucp.notifications_enabled = true
      AND ucp.user_id != NEW.restaurant_id;
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.notify_category_subscribers() OWNER TO postgres;

--
-- Name: notify_restaurant_of_issue(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.notify_restaurant_of_issue() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_user_name text;
  v_order_number text;
  v_notifications_exists boolean;
BEGIN
  -- Check if notifications table exists
  SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'notifications'
  ) INTO v_notifications_exists;
  
  -- Only create notification if table exists
  IF v_notifications_exists THEN
    -- Get user name and order number
    SELECT p.full_name, o.order_number
    INTO v_user_name, v_order_number
    FROM profiles p
    JOIN orders o ON o.id = NEW.order_id
    WHERE p.id = NEW.user_id;
    
    -- Create notification for restaurant (restaurant_id is already the profile_id)
    INSERT INTO notifications (
      user_id,
      title,
      message,
      type,
      data
    ) VALUES (
      NEW.restaurant_id,
      'Order Issue Reported',
      v_user_name || ' reported an issue with order #' || v_order_number,
      'order_issue',
      jsonb_build_object(
        'issue_id', NEW.id,
        'order_id', NEW.order_id,
        'issue_type', NEW.issue_type
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.notify_restaurant_of_issue() OWNER TO postgres;

--
-- Name: prevent_role_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_role_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    RAISE EXCEPTION 'Role modification is not allowed.';
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.prevent_role_update() OWNER TO postgres;

--
-- Name: process_email_queue_item(uuid, boolean, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.process_email_queue_item(p_email_id uuid, p_success boolean, p_error_message text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_order_id uuid;
  v_recipient_email text;
  v_email_type text;
BEGIN
  SELECT order_id, recipient_email, email_type
  INTO v_order_id, v_recipient_email, v_email_type
  FROM email_queue
  WHERE id = p_email_id;
  
  IF p_success THEN
    UPDATE email_queue
    SET status = 'sent', sent_at = NOW()
    WHERE id = p_email_id;
    
    INSERT INTO email_logs (
      email_queue_id, order_id, recipient_email, email_type, status
    ) VALUES (
      p_email_id, v_order_id, v_recipient_email, v_email_type, 'sent'
    );
  ELSE
    UPDATE email_queue
    SET 
      attempts = attempts + 1,
      last_error = p_error_message,
      status = CASE WHEN attempts + 1 >= 3 THEN 'failed' ELSE 'pending' END
    WHERE id = p_email_id;
    
    INSERT INTO email_logs (
      email_queue_id, order_id, recipient_email, email_type, status, error_message
    ) VALUES (
      p_email_id, v_order_id, v_recipient_email, v_email_type, 'failed', p_error_message
    );
  END IF;
END;
$$;


ALTER FUNCTION public.process_email_queue_item(p_email_id uuid, p_success boolean, p_error_message text) OWNER TO postgres;

--
-- Name: provision_auth_user(text, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.provision_auth_user(p_role text, p_full_name text DEFAULT NULL::text, p_phone_number text DEFAULT NULL::text, p_organization_name text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_uid uuid;
  v_email text;
  v_role text;
  v_full_name text;
  v_org_name text;
  v_is_verified boolean;
  v_approval_status text;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Email from JWT (Supabase puts it in the access token)
  v_email := COALESCE(NULLIF(TRIM(auth.jwt()->>'email'), ''), NULL);

  -- Normalize role
  v_role := COALESCE(NULLIF(TRIM(p_role), ''), 'user');

  -- Normalize full name
  v_full_name := COALESCE(NULLIF(TRIM(p_full_name), ''), 'User');

  -- Org name only for restaurant/ngo
  IF v_role IN ('restaurant', 'ngo') THEN
    v_org_name := COALESCE(
      NULLIF(TRIM(p_organization_name), ''),
      NULLIF(TRIM(v_full_name), ''),
      CASE
        WHEN v_role = 'restaurant' THEN 'Restaurant ' || SUBSTRING(v_uid::text, 1, 8)
        ELSE 'Organization ' || SUBSTRING(v_uid::text, 1, 8)
      END
    );
  ELSE
    v_org_name := NULL;
  END IF;

  -- Verified: after OTP verify you have a session, so mark verified true
  v_is_verified := true;

  -- Approval status logic (ORIGINAL VERSION)
  v_approval_status :=
    CASE
      WHEN v_role IN ('restaurant', 'ngo') THEN 'pending'
      WHEN v_role = 'admin' THEN 'approved'
      ELSE 'approved'
    END;

  -- 1) Upsert profile (ORIGINAL VERSION)
  INSERT INTO public.profiles (
    id, email, role, full_name, phone_number, is_verified, approval_status, created_at, updated_at
  )
  VALUES (
    v_uid, v_email, v_role, v_full_name, p_phone_number, v_is_verified, v_approval_status, NOW(), NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = COALESCE(EXCLUDED.email, public.profiles.email),
    role = EXCLUDED.role,
    full_name = EXCLUDED.full_name,
    phone_number = EXCLUDED.phone_number,
    is_verified = EXCLUDED.is_verified,
    approval_status = EXCLUDED.approval_status,
    updated_at = NOW();

  -- 2) Role tables (NON-CRITICAL)
  IF v_role = 'restaurant' THEN
    BEGIN
      INSERT INTO public.restaurants (
        profile_id, restaurant_name, legal_docs_urls, rating, min_order_price, rush_hour_active
      )
      VALUES (
        v_uid, v_org_name, ARRAY[]::text[], 0, 0, false
      )
      ON CONFLICT (profile_id) DO UPDATE SET
        restaurant_name = COALESCE(EXCLUDED.restaurant_name, public.restaurants.restaurant_name);
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'restaurants upsert failed for user %: % (SQLSTATE %)', v_uid, SQLERRM, SQLSTATE;
    END;

  ELSIF v_role = 'ngo' THEN
    BEGIN
      INSERT INTO public.ngos (
        profile_id, organization_name, legal_docs_urls
      )
      VALUES (
        v_uid, v_org_name, ARRAY[]::text[]
      )
      ON CONFLICT (profile_id) DO UPDATE SET
        organization_name = COALESCE(EXCLUDED.organization_name, public.ngos.organization_name);
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'ngos upsert failed for user %: % (SQLSTATE %)', v_uid, SQLERRM, SQLSTATE;
    END;
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'user_id', v_uid,
    'email', v_email,
    'role', v_role,
    'approval_status', v_approval_status
  );
END;
$$;


ALTER FUNCTION public.provision_auth_user(p_role text, p_full_name text, p_phone_number text, p_organization_name text) OWNER TO postgres;

--
-- Name: FUNCTION provision_auth_user(p_role text, p_full_name text, p_phone_number text, p_organization_name text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.provision_auth_user(p_role text, p_full_name text, p_phone_number text, p_organization_name text) IS 'Provision profile + role row AFTER authentication. Call from app after OTP verification. No auth.users triggers required.';


--
-- Name: queue_order_emails(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.queue_order_emails() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_user_email text;
  v_user_name text;
  v_restaurant_email text;
  v_restaurant_name text;
  v_ngo_email text;
  v_ngo_name text;
  v_order_data jsonb;
  v_email_id uuid;
  v_buyer_type text;
BEGIN
  -- Get user details
  SELECT email, full_name, role
  INTO v_user_email, v_user_name, v_buyer_type
  FROM profiles
  WHERE id = NEW.user_id;
  
  -- Get restaurant details
  SELECT p.email, r.restaurant_name 
  INTO v_restaurant_email, v_restaurant_name
  FROM restaurants r
  JOIN profiles p ON p.id = r.profile_id
  WHERE r.profile_id = NEW.restaurant_id;
  
  -- Get NGO details if donation order
  -- ✅ CRITICAL FIX: Use organization_name NOT ngo_name!
  IF NEW.delivery_type = 'donation' AND NEW.ngo_id IS NOT NULL THEN
    SELECT p.email, n.organization_name 
    INTO v_ngo_email, v_ngo_name
    FROM ngos n
    JOIN profiles p ON p.id = n.profile_id
    WHERE n.profile_id = NEW.ngo_id;
  END IF;
  
  -- Build order data with items
  -- ✅ CRITICAL FIX: Use COALESCE to handle empty items array
  SELECT jsonb_build_object(
    'order_id', NEW.id,
    'order_number', NEW.order_number,
    'buyer_name', v_user_name,
    'buyer_type', v_buyer_type,
    'restaurant_name', v_restaurant_name,
    'ngo_name', v_ngo_name,
    'delivery_type', NEW.delivery_type,
    'delivery_address', NEW.delivery_address,
    'total_amount', NEW.total_amount,
    'created_at', NEW.created_at,
    'items', COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'meal_title', oi.meal_title,
            'quantity', oi.quantity,
            'unit_price', oi.unit_price,
            'subtotal', oi.quantity * oi.unit_price
          )
        )
        FROM order_items oi
        WHERE oi.order_id = NEW.id
      ),
      '[]'::jsonb
    )
  ) INTO v_order_data;
  
  -- SCENARIO 1 & 2: User purchases (delivery/pickup or donate to NGO)
  IF v_buyer_type = 'user' THEN
    
    -- Email 1: Invoice to user
    IF v_user_email IS NOT NULL THEN
      INSERT INTO email_queue (
        order_id, recipient_email, recipient_type, email_type, email_data
      ) VALUES (
        NEW.id, 
        v_user_email, 
        'user', 
        CASE WHEN NEW.delivery_type = 'donation' THEN 'ngo_confirmation' ELSE 'invoice' END,
        v_order_data
      )
      RETURNING id INTO v_email_id;
      
      INSERT INTO email_logs (
        email_queue_id, order_id, recipient_email, email_type, status
      ) VALUES (
        v_email_id, NEW.id, v_user_email,
        CASE WHEN NEW.delivery_type = 'donation' THEN 'ngo_confirmation' ELSE 'invoice' END,
        'queued'
      );
    END IF;
    
    -- Email 2: New order notification to restaurant
    IF v_restaurant_email IS NOT NULL THEN
      INSERT INTO email_queue (
        order_id, recipient_email, recipient_type, email_type, email_data
      ) VALUES (
        NEW.id, v_restaurant_email, 'restaurant', 'new_order', v_order_data
      )
      RETURNING id INTO v_email_id;
      
      INSERT INTO email_logs (
        email_queue_id, order_id, recipient_email, email_type, status
      ) VALUES (
        v_email_id, NEW.id, v_restaurant_email, 'new_order', 'queued'
      );
    END IF;
    
    -- Email 3: If donation, notify NGO
    IF NEW.delivery_type = 'donation' AND v_ngo_email IS NOT NULL THEN
      INSERT INTO email_queue (
        order_id, recipient_email, recipient_type, email_type, email_data
      ) VALUES (
        NEW.id, v_ngo_email, 'ngo', 'ngo_pickup', v_order_data
      )
      RETURNING id INTO v_email_id;
      
      INSERT INTO email_logs (
        email_queue_id, order_id, recipient_email, email_type, status
      ) VALUES (
        v_email_id, NEW.id, v_ngo_email, 'ngo_pickup', 'queued'
      );
    END IF;

  -- SCENARIO 3: NGO purchases
  ELSIF v_buyer_type = 'ngo' THEN
    
    -- Email 1: New order notification to restaurant
    IF v_restaurant_email IS NOT NULL THEN
      INSERT INTO email_queue (
        order_id, recipient_email, recipient_type, email_type, email_data
      ) VALUES (
        NEW.id, v_restaurant_email, 'restaurant', 'new_order', v_order_data
      )
      RETURNING id INTO v_email_id;
      
      INSERT INTO email_logs (
        email_queue_id, order_id, recipient_email, email_type, status
      ) VALUES (
        v_email_id, NEW.id, v_restaurant_email, 'new_order', 'queued'
      );
    END IF;
    
    -- Email 2: Confirmation to NGO
    IF v_user_email IS NOT NULL THEN
      INSERT INTO email_queue (
        order_id, recipient_email, recipient_type, email_type, email_data
      ) VALUES (
        NEW.id, v_user_email, 'ngo', 'ngo_confirmation', v_order_data
      )
      RETURNING id INTO v_email_id;
      
      INSERT INTO email_logs (
        email_queue_id, order_id, recipient_email, email_type, status
      ) VALUES (
        v_email_id, NEW.id, v_user_email, 'ngo_confirmation', 'queued'
      );
    END IF;

  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.queue_order_emails() OWNER TO postgres;

--
-- Name: redeem_reward(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.redeem_reward(p_user_id uuid, p_reward_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_available_points int;
  v_points_cost int;
  v_current_tier text;
  v_min_tier text;
  v_valid_days int;
  v_transaction_id uuid;
  v_reward_id uuid;
BEGIN
  -- Get user loyalty info
  SELECT available_points, current_tier
  INTO v_available_points, v_current_tier
  FROM user_loyalty
  WHERE user_id = p_user_id;
  
  -- Get reward info
  SELECT points_cost, min_tier, valid_days
  INTO v_points_cost, v_min_tier, v_valid_days
  FROM rewards_catalog
  WHERE id = p_reward_id AND is_active = true;
  
  -- Validate reward exists
  IF v_points_cost IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Reward not found or inactive');
  END IF;
  
  -- Check if user has enough points
  IF v_available_points < v_points_cost THEN
    RETURN jsonb_build_object('success', false, 'error', 'Insufficient points');
  END IF;
  
  -- Check tier requirement
  IF v_min_tier IS NOT NULL THEN
    IF (v_current_tier = 'bronze' AND v_min_tier IN ('silver', 'gold', 'platinum')) OR
       (v_current_tier = 'silver' AND v_min_tier IN ('gold', 'platinum')) OR
       (v_current_tier = 'gold' AND v_min_tier = 'platinum') THEN
      RETURN jsonb_build_object('success', false, 'error', 'Tier requirement not met');
    END IF;
  END IF;
  
  -- Deduct points
  UPDATE user_loyalty
  SET available_points = available_points - v_points_cost,
      updated_at = NOW()
  WHERE user_id = p_user_id;
  
  -- Record transaction
  INSERT INTO loyalty_transactions (
    user_id,
    points,
    transaction_type,
    source,
    reward_id,
    description
  ) VALUES (
    p_user_id,
    -v_points_cost,
    'redeemed',
    'reward_redemption',
    p_reward_id,
    'Redeemed reward for ' || v_points_cost || ' points'
  )
  RETURNING id INTO v_transaction_id;
  
  -- Create user reward
  INSERT INTO user_rewards (
    user_id,
    reward_id,
    transaction_id,
    expires_at
  ) VALUES (
    p_user_id,
    p_reward_id,
    v_transaction_id,
    NOW() + (v_valid_days || ' days')::interval
  )
  RETURNING id INTO v_reward_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'reward_id', v_reward_id,
    'remaining_points', v_available_points - v_points_cost
  );
END;
$$;


ALTER FUNCTION public.redeem_reward(p_user_id uuid, p_reward_id uuid) OWNER TO postgres;

--
-- Name: safe_delete_meal(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.safe_delete_meal(p_meal_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_order_count INT;
  v_result jsonb;
BEGIN
  -- Check if meal is in any orders
  SELECT COUNT(*) INTO v_order_count
  FROM order_items
  WHERE meal_id = p_meal_id;
  
  IF v_order_count > 0 THEN
    -- Can't delete - meal is in orders
    v_result := jsonb_build_object(
      'success', false,
      'message', format('Cannot delete meal. It is in %s order(s). Mark as inactive instead.', v_order_count),
      'order_count', v_order_count
    );
  ELSE
    -- Safe to delete
    DELETE FROM meals WHERE id = p_meal_id;
    
    v_result := jsonb_build_object(
      'success', true,
      'message', 'Meal deleted successfully'
    );
  END IF;
  
  RETURN v_result;
END;
$$;


ALTER FUNCTION public.safe_delete_meal(p_meal_id uuid) OWNER TO postgres;

--
-- Name: FUNCTION safe_delete_meal(p_meal_id uuid); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.safe_delete_meal(p_meal_id uuid) IS 'Safely deletes a meal only if it is not in any orders. Otherwise suggests marking as inactive.';


--
-- Name: set_rush_hour_settings(boolean, timestamp with time zone, timestamp with time zone, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_rush_hour_settings(p_is_active boolean, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_discount_percentage integer) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_restaurant_id uuid;
  v_existing_id uuid;
  v_result json;
BEGIN
  -- Get authenticated restaurant ID
  v_restaurant_id := auth.uid();
  
  IF v_restaurant_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Verify user is a restaurant
  IF NOT EXISTS (
    SELECT 1 FROM restaurants WHERE profile_id = v_restaurant_id
  ) THEN
    RAISE EXCEPTION 'User is not a restaurant';
  END IF;
  
  -- Validate inputs
  IF p_discount_percentage < 0 OR p_discount_percentage > 100 THEN
    RAISE EXCEPTION 'Discount percentage must be between 0 and 100';
  END IF;
  
  IF p_is_active AND p_end_time <= p_start_time THEN
    RAISE EXCEPTION 'End time must be after start time';
  END IF;
  
  -- Handle based on is_active flag
  IF p_is_active THEN
    -- ACTIVATE: Upsert the active rush hour
    -- First, deactivate any existing active rush hour
    UPDATE rush_hours
    SET is_active = false
    WHERE restaurant_id = v_restaurant_id
      AND is_active = true;
    
    -- Check if there's an existing row (active or inactive)
    SELECT id INTO v_existing_id
    FROM rush_hours
    WHERE restaurant_id = v_restaurant_id
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_existing_id IS NOT NULL THEN
      -- Update existing row
      UPDATE rush_hours
      SET 
        is_active = true,
        start_time = p_start_time,
        end_time = p_end_time,
        discount_percentage = p_discount_percentage
      WHERE id = v_existing_id
      RETURNING json_build_object(
        'id', id,
        'restaurant_id', restaurant_id,
        'is_active', is_active,
        'start_time', start_time,
        'end_time', end_time,
        'discount_percentage', discount_percentage,
        'active_now', (is_active AND NOW() BETWEEN start_time AND end_time)
      ) INTO v_result;
    ELSE
      -- Insert new row
      INSERT INTO rush_hours (
        restaurant_id,
        is_active,
        start_time,
        end_time,
        discount_percentage
      )
      VALUES (
        v_restaurant_id,
        true,
        p_start_time,
        p_end_time,
        p_discount_percentage
      )
      RETURNING json_build_object(
        'id', id,
        'restaurant_id', restaurant_id,
        'is_active', is_active,
        'start_time', start_time,
        'end_time', end_time,
        'discount_percentage', discount_percentage,
        'active_now', (is_active AND NOW() BETWEEN start_time AND end_time)
      ) INTO v_result;
    END IF;
  ELSE
    -- DEACTIVATE: Set is_active = false for any active rush hour
    UPDATE rush_hours
    SET is_active = false
    WHERE restaurant_id = v_restaurant_id
      AND is_active = true
    RETURNING json_build_object(
      'id', id,
      'restaurant_id', restaurant_id,
      'is_active', is_active,
      'start_time', start_time,
      'end_time', end_time,
      'discount_percentage', discount_percentage,
      'active_now', false
    ) INTO v_result;
    
    -- If no active row existed, return the most recent inactive one
    IF v_result IS NULL THEN
      SELECT json_build_object(
        'id', id,
        'restaurant_id', restaurant_id,
        'is_active', is_active,
        'start_time', start_time,
        'end_time', end_time,
        'discount_percentage', discount_percentage,
        'active_now', false
      ) INTO v_result
      FROM rush_hours
      WHERE restaurant_id = v_restaurant_id
      ORDER BY created_at DESC
      LIMIT 1;
    END IF;
    
    -- If still no result, return a default inactive state
    IF v_result IS NULL THEN
      v_result := json_build_object(
        'id', NULL,
        'restaurant_id', v_restaurant_id,
        'is_active', false,
        'start_time', NULL,
        'end_time', NULL,
        'discount_percentage', 0,
        'active_now', false
      );
    END IF;
  END IF;
  
  RETURN v_result;
END;
$$;


ALTER FUNCTION public.set_rush_hour_settings(p_is_active boolean, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_discount_percentage integer) OWNER TO postgres;

--
-- Name: FUNCTION set_rush_hour_settings(p_is_active boolean, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_discount_percentage integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.set_rush_hour_settings(p_is_active boolean, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_discount_percentage integer) IS 'Creates or updates rush hour settings for the authenticated restaurant. 
Safely handles concurrent calls and prevents duplicate active rows.';


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_updated_at() OWNER TO postgres;

--
-- Name: submit_restaurant_rating(uuid, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.submit_restaurant_rating(p_order_id uuid, p_rating integer, p_review_text text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_user_id uuid;
  v_restaurant_id uuid;
  v_order_status text;
  v_rating_id uuid;
BEGIN
  -- Get authenticated user
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Validate rating value
  IF p_rating < 1 OR p_rating > 5 THEN
    RAISE EXCEPTION 'Rating must be between 1 and 5';
  END IF;
  
  -- Get order details and validate
  SELECT 
    o.restaurant_id,
    o.status::text
  INTO 
    v_restaurant_id,
    v_order_status
  FROM orders o
  WHERE o.id = p_order_id
    AND o.user_id = v_user_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found or does not belong to user';
  END IF;
  
  -- Check if order is completed/delivered
  IF v_order_status NOT IN ('delivered', 'completed') THEN
    RAISE EXCEPTION 'Can only rate completed or delivered orders';
  END IF;
  
  -- Insert or update rating
  INSERT INTO restaurant_ratings (
    order_id,
    user_id,
    restaurant_id,
    rating,
    review_text
  )
  VALUES (
    p_order_id,
    v_user_id,
    v_restaurant_id,
    p_rating,
    p_review_text
  )
  ON CONFLICT (order_id) 
  DO UPDATE SET
    rating = EXCLUDED.rating,
    review_text = EXCLUDED.review_text,
    updated_at = NOW()
  RETURNING id INTO v_rating_id;
  
  -- Also update the orders table rating columns (for backward compatibility)
  UPDATE orders
  SET 
    rating = p_rating,
    review_text = p_review_text,
    reviewed_at = NOW()
  WHERE id = p_order_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'rating_id', v_rating_id,
    'message', 'Rating submitted successfully'
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;


ALTER FUNCTION public.submit_restaurant_rating(p_order_id uuid, p_rating integer, p_review_text text) OWNER TO postgres;

--
-- Name: FUNCTION submit_restaurant_rating(p_order_id uuid, p_rating integer, p_review_text text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.submit_restaurant_rating(p_order_id uuid, p_rating integer, p_review_text text) IS 'Submit or update a restaurant rating for a completed order. 
Automatically updates restaurant average rating.';


--
-- Name: sync_profile_emails(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sync_profile_emails() RETURNS TABLE(profile_id uuid, old_email text, new_email text, updated boolean)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public', 'auth'
    AS $$
  WITH to_fix AS (
    SELECT
      p.id AS profile_id,
      p.email::text AS old_email,
      au.email::text AS new_email
    FROM public.profiles p
    JOIN auth.users au ON au.id = p.id
    WHERE p.email IS NULL OR p.email = ''
  ),
  upd AS (
    UPDATE public.profiles p
    SET email = to_fix.new_email,
        updated_at = NOW()
    FROM to_fix
    WHERE p.id = to_fix.profile_id
    RETURNING p.id
  )
  SELECT
    to_fix.profile_id,
    to_fix.old_email,
    to_fix.new_email,
    true AS updated
  FROM to_fix
  JOIN upd ON upd.id = to_fix.profile_id;
$$;


ALTER FUNCTION public.sync_profile_emails() OWNER TO postgres;

--
-- Name: FUNCTION sync_profile_emails(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.sync_profile_emails() IS 'Syncs missing emails from auth.users to profiles table';


--
-- Name: sync_user_verification(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sync_user_verification() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_role text;
BEGIN
  -- Only sync verification if email was just confirmed
  IF (OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL) THEN
    
    -- Get the user's role from profiles
    SELECT role INTO v_role
    FROM public.profiles
    WHERE id = NEW.id;
    
    -- Only set is_verified=true for regular users
    -- Restaurant/NGO users need admin approval first
    IF v_role NOT IN ('restaurant', 'ngo') THEN
      UPDATE public.profiles
      SET is_verified = true,
          updated_at = now()
      WHERE id = NEW.id;
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.sync_user_verification() OWNER TO postgres;

--
-- Name: FUNCTION sync_user_verification(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.sync_user_verification() IS 'Syncs email verification status from auth.users to profiles. Does NOT verify restaurant/ngo users - they need admin approval.';


--
-- Name: update_cart_items_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_cart_items_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_cart_items_updated_at() OWNER TO postgres;

--
-- Name: update_conversation_last_message(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_conversation_last_message() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE conversations
  SET last_message_at = NEW.created_at
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_conversation_last_message() OWNER TO postgres;

--
-- Name: update_order_issue_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_order_issue_timestamp() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  NEW.updated_at = NOW();
  
  -- Set resolved_at when status changes to resolved
  IF NEW.status = 'resolved' AND OLD.status != 'resolved' THEN
    NEW.resolved_at = NOW();
    NEW.resolved_by = auth.uid();
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_order_issue_timestamp() OWNER TO postgres;

--
-- Name: update_profile_default_location(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_profile_default_location() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- When an address is set as default, update the profile
  IF NEW.is_default = true THEN
    UPDATE profiles
    SET default_location = NEW.address_text
    WHERE id = NEW.user_id;
  END IF;
  
  -- When an address is unset as default, check if there are other defaults
  IF OLD.is_default = true AND NEW.is_default = false THEN
    -- Check if there's another default address
    DECLARE
      other_default TEXT;
    BEGIN
      SELECT address_text INTO other_default
      FROM user_addresses
      WHERE user_id = NEW.user_id 
        AND is_default = true 
        AND id != NEW.id
      LIMIT 1;
      
      -- Update profile with the other default, or NULL if none
      UPDATE profiles
      SET default_location = other_default
      WHERE id = NEW.user_id;
    END;
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_profile_default_location() OWNER TO postgres;

--
-- Name: update_restaurant_rating(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_restaurant_rating() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_avg_rating numeric;
  v_rating_count integer;
BEGIN
  -- Calculate new average rating and count
  SELECT 
    COALESCE(AVG(rating), 0),
    COUNT(*)
  INTO 
    v_avg_rating,
    v_rating_count
  FROM restaurant_ratings
  WHERE restaurant_id = COALESCE(NEW.restaurant_id, OLD.restaurant_id);
  
  -- Update restaurant table
  UPDATE restaurants
  SET 
    rating = ROUND(v_avg_rating::numeric, 1),
    rating_count = v_rating_count,
    updated_at = NOW()
  WHERE profile_id = COALESCE(NEW.restaurant_id, OLD.restaurant_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION public.update_restaurant_rating() OWNER TO postgres;

--
-- Name: FUNCTION update_restaurant_rating(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.update_restaurant_rating() IS 'Automatically recalculates restaurant average rating when a rating is added, updated, or deleted';


--
-- Name: update_restaurant_rush_hour_flag(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_restaurant_rush_hour_flag() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Update the restaurant's rush_hour_active flag
  UPDATE restaurants
  SET rush_hour_active = (
    EXISTS (
      SELECT 1 FROM rush_hours
      WHERE restaurant_id = COALESCE(NEW.restaurant_id, OLD.restaurant_id)
        AND is_active = true
        AND NOW() BETWEEN start_time AND end_time
    )
  )
  WHERE profile_id = COALESCE(NEW.restaurant_id, OLD.restaurant_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION public.update_restaurant_rush_hour_flag() OWNER TO postgres;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

--
-- Name: update_user_tier(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_user_tier(p_user_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_lifetime_points int;
  v_new_tier text;
  v_current_tier text;
BEGIN
  SELECT lifetime_points, current_tier
  INTO v_lifetime_points, v_current_tier
  FROM user_loyalty
  WHERE user_id = p_user_id;
  
  -- Determine tier based on lifetime points
  IF v_lifetime_points >= 1000 THEN
    v_new_tier := 'platinum';
  ELSIF v_lifetime_points >= 500 THEN
    v_new_tier := 'gold';
  ELSIF v_lifetime_points >= 200 THEN
    v_new_tier := 'silver';
  ELSE
    v_new_tier := 'bronze';
  END IF;
  
  -- Update tier if changed
  IF v_new_tier != v_current_tier THEN
    UPDATE user_loyalty
    SET current_tier = v_new_tier, updated_at = NOW()
    WHERE user_id = p_user_id;
  END IF;
END;
$$;


ALTER FUNCTION public.update_user_tier(p_user_id uuid) OWNER TO postgres;

--
-- Name: verify_pickup_code(uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.verify_pickup_code(p_order_id uuid, p_pickup_code text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    is_valid BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM orders
        WHERE id = p_order_id
        AND pickup_code = UPPER(p_pickup_code)
        AND status = 'ready_for_pickup'
    ) INTO is_valid;
    
    RETURN is_valid;
END;
$$;


ALTER FUNCTION public.verify_pickup_code(p_order_id uuid, p_pickup_code text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: backup_profiles_role; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.backup_profiles_role (
    id uuid NOT NULL,
    email text,
    role text,
    backed_up_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.backup_profiles_role OWNER TO postgres;

--
-- Name: cart_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cart_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    profile_id uuid,
    meal_id uuid,
    quantity integer DEFAULT 1,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    user_id uuid NOT NULL
);


ALTER TABLE public.cart_items OWNER TO postgres;

--
-- Name: TABLE cart_items; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.cart_items IS 'Shopping cart for all user types (users, NGOs). Uses profile_id to support all roles.';


--
-- Name: COLUMN cart_items.profile_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cart_items.profile_id IS 'Profile ID of cart owner (works for users, NGOs, and all roles)';


--
-- Name: COLUMN cart_items.meal_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cart_items.meal_id IS 'Meal being added to cart';


--
-- Name: COLUMN cart_items.quantity; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cart_items.quantity IS 'Quantity of this meal in cart (must be > 0)';


--
-- Name: COLUMN cart_items.updated_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cart_items.updated_at IS 'Timestamp of last update';


--
-- Name: category_notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.category_notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    meal_id uuid NOT NULL,
    category text NOT NULL,
    sent_at timestamp with time zone DEFAULT now(),
    is_read boolean DEFAULT false NOT NULL
);


ALTER TABLE public.category_notifications OWNER TO postgres;

--
-- Name: conversations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conversations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ngo_id uuid NOT NULL,
    restaurant_id uuid NOT NULL,
    last_message_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.conversations OWNER TO postgres;

--
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    conversation_id uuid NOT NULL,
    sender_id uuid NOT NULL,
    content text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- Name: profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    role text,
    email text,
    full_name text,
    phone_number text,
    avatar_url text,
    is_verified boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    approval_status text DEFAULT 'pending'::text NOT NULL,
    address_text text,
    default_location text,
    CONSTRAINT profiles_approval_status_check CHECK ((approval_status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text]))),
    CONSTRAINT profiles_role_check CHECK ((role = ANY (ARRAY['user'::text, 'restaurant'::text, 'ngo'::text, 'admin'::text])))
);


ALTER TABLE public.profiles OWNER TO postgres;

--
-- Name: COLUMN profiles.address_text; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profiles.address_text IS 'Primary address for all stakeholders (users, restaurants, NGOs) - displayed on home screen';


--
-- Name: COLUMN profiles.default_location; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.profiles.default_location IS 'User default delivery address for homepage display';


--
-- Name: restaurants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.restaurants (
    profile_id uuid NOT NULL,
    restaurant_name text DEFAULT 'Unnamed Restaurant'::text,
    address_text text,
    legal_docs_urls text[] DEFAULT ARRAY[]::text[],
    rating double precision DEFAULT 0,
    min_order_price numeric(12,2) DEFAULT 0,
    rush_hour_active boolean DEFAULT false,
    phone text,
    address text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    rating_count integer DEFAULT 0
);


ALTER TABLE public.restaurants OWNER TO postgres;

--
-- Name: COLUMN restaurants.rating; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.restaurants.rating IS 'Average rating (0-5 stars) calculated from all user ratings';


--
-- Name: COLUMN restaurants.rating_count; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.restaurants.rating_count IS 'Total number of ratings received';


--
-- Name: conversation_details; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.conversation_details AS
 SELECT c.id,
    c.ngo_id,
    c.restaurant_id,
    c.last_message_at,
    c.created_at,
    ngo.full_name AS ngo_name,
    ngo.avatar_url AS ngo_avatar,
    rest.full_name AS restaurant_name,
    r.restaurant_name AS restaurant_business_name,
    rest.avatar_url AS restaurant_avatar,
    ( SELECT messages.content
           FROM public.messages
          WHERE (messages.conversation_id = c.id)
          ORDER BY messages.created_at DESC
         LIMIT 1) AS last_message,
    ( SELECT count(*) AS count
           FROM public.messages
          WHERE ((messages.conversation_id = c.id) AND (messages.is_read = false) AND (messages.sender_id <> auth.uid()))) AS unread_count,
        CASE
            WHEN (c.ngo_id = auth.uid()) THEN c.restaurant_id
            WHEN (c.restaurant_id = auth.uid()) THEN c.ngo_id
            ELSE NULL::uuid
        END AS other_party_id,
        CASE
            WHEN (c.ngo_id = auth.uid()) THEN COALESCE(r.restaurant_name, rest.full_name, 'Restaurant'::text)
            WHEN (c.restaurant_id = auth.uid()) THEN COALESCE(ngo.full_name, 'NGO'::text)
            ELSE NULL::text
        END AS other_party_name,
        CASE
            WHEN (c.ngo_id = auth.uid()) THEN rest.avatar_url
            WHEN (c.restaurant_id = auth.uid()) THEN ngo.avatar_url
            ELSE NULL::text
        END AS other_party_avatar
   FROM (((public.conversations c
     LEFT JOIN public.profiles ngo ON ((c.ngo_id = ngo.id)))
     LEFT JOIN public.profiles rest ON ((c.restaurant_id = rest.id)))
     LEFT JOIN public.restaurants r ON ((c.restaurant_id = r.profile_id)))
  ORDER BY c.last_message_at DESC;


ALTER VIEW public.conversation_details OWNER TO postgres;

--
-- Name: email_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email_queue_id uuid,
    order_id uuid,
    recipient_email text NOT NULL,
    email_type text NOT NULL,
    status text NOT NULL,
    error_message text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT email_logs_status_check CHECK ((status = ANY (ARRAY['queued'::text, 'sent'::text, 'failed'::text])))
);


ALTER TABLE public.email_logs OWNER TO postgres;

--
-- Name: email_queue; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_queue (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid NOT NULL,
    recipient_email text NOT NULL,
    recipient_type text NOT NULL,
    email_type text NOT NULL,
    email_data jsonb NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    last_error text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sent_at timestamp with time zone,
    CONSTRAINT email_queue_attempts_check CHECK ((attempts <= 3)),
    CONSTRAINT email_queue_email_type_check CHECK ((email_type = ANY (ARRAY['invoice'::text, 'new_order'::text, 'ngo_pickup'::text, 'ngo_confirmation'::text]))),
    CONSTRAINT email_queue_recipient_type_check CHECK ((recipient_type = ANY (ARRAY['user'::text, 'restaurant'::text, 'ngo'::text]))),
    CONSTRAINT email_queue_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'sent'::text, 'failed'::text])))
);


ALTER TABLE public.email_queue OWNER TO postgres;

--
-- Name: favorite_restaurants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.favorite_restaurants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    restaurant_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.favorite_restaurants OWNER TO postgres;

--
-- Name: favorites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.favorites (
    user_id uuid NOT NULL,
    meal_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.favorites OWNER TO postgres;

--
-- Name: free_meal_notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.free_meal_notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    meal_id uuid NOT NULL,
    restaurant_id uuid NOT NULL,
    original_price numeric(12,2) NOT NULL,
    donated_at timestamp with time zone DEFAULT now() NOT NULL,
    notification_sent boolean DEFAULT false NOT NULL,
    claimed_by uuid,
    claimed_at timestamp with time zone
);


ALTER TABLE public.free_meal_notifications OWNER TO postgres;

--
-- Name: free_meal_user_notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.free_meal_user_notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    meal_id uuid NOT NULL,
    donation_id uuid NOT NULL,
    restaurant_id uuid NOT NULL,
    sent_at timestamp with time zone DEFAULT now() NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    claimed boolean DEFAULT false NOT NULL,
    claimed_at timestamp with time zone
);


ALTER TABLE public.free_meal_user_notifications OWNER TO postgres;

--
-- Name: TABLE free_meal_user_notifications; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.free_meal_user_notifications IS 'Special notifications for free meal donations - separate from category notifications';


--
-- Name: loyalty_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.loyalty_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    points integer NOT NULL,
    transaction_type text NOT NULL,
    source text NOT NULL,
    order_id uuid,
    reward_id uuid,
    description text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT loyalty_transactions_source_check CHECK ((source = ANY (ARRAY['order'::text, 'donation'::text, 'referral'::text, 'bonus'::text, 'reward_redemption'::text]))),
    CONSTRAINT loyalty_transactions_transaction_type_check CHECK ((transaction_type = ANY (ARRAY['earned'::text, 'redeemed'::text, 'expired'::text, 'bonus'::text])))
);


ALTER TABLE public.loyalty_transactions OWNER TO postgres;

--
-- Name: TABLE loyalty_transactions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.loyalty_transactions IS 'History of all points earned and redeemed';


--
-- Name: meal_reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.meal_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    meal_id uuid NOT NULL,
    restaurant_id uuid NOT NULL,
    issue_type text NOT NULL,
    details text,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    resolved_at timestamp with time zone,
    admin_notes text,
    CONSTRAINT meal_reports_issue_type_check CHECK ((issue_type = ANY (ARRAY['Wrong information'::text, 'Quality concerns'::text, 'Meal not available'::text, 'Incorrect pricing'::text, 'Location issue'::text, 'Other'::text]))),
    CONSTRAINT meal_reports_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'reviewing'::text, 'resolved'::text, 'dismissed'::text])))
);


ALTER TABLE public.meal_reports OWNER TO postgres;

--
-- Name: meal_reports_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.meal_reports_summary AS
 SELECT restaurant_id,
    count(*) AS total_reports,
    count(*) FILTER (WHERE (status = 'pending'::text)) AS pending_reports,
    count(*) FILTER (WHERE (status = 'resolved'::text)) AS resolved_reports,
    max(created_at) AS latest_report_at
   FROM public.meal_reports mr
  GROUP BY restaurant_id;


ALTER VIEW public.meal_reports_summary OWNER TO postgres;

--
-- Name: meals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.meals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    restaurant_id uuid,
    title text NOT NULL,
    description text,
    category text,
    image_url text,
    original_price numeric(12,2) NOT NULL,
    discounted_price numeric(12,2) NOT NULL,
    quantity_available integer DEFAULT 0 NOT NULL,
    expiry_date timestamp with time zone NOT NULL,
    pickup_deadline timestamp with time zone,
    embedding public.vector(1536),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    status text DEFAULT 'active'::text,
    location text DEFAULT 'Pickup at restaurant'::text,
    unit text DEFAULT 'portions'::text,
    fulfillment_method text DEFAULT 'pickup'::text,
    is_donation_available boolean DEFAULT true,
    ingredients text[] DEFAULT ARRAY[]::text[],
    allergens text[] DEFAULT ARRAY[]::text[],
    co2_savings numeric(12,2) DEFAULT 0,
    pickup_time timestamp with time zone,
    CONSTRAINT meals_category_check CHECK ((category = ANY (ARRAY['Meals'::text, 'Bakery'::text, 'Meat & Poultry'::text, 'Seafood'::text, 'Vegetables'::text, 'Desserts'::text, 'Groceries'::text]))),
    CONSTRAINT meals_fulfillment_method_check CHECK ((fulfillment_method = ANY (ARRAY['pickup'::text, 'delivery'::text]))),
    CONSTRAINT meals_status_check CHECK ((status = ANY (ARRAY['active'::text, 'sold'::text, 'expired'::text]))),
    CONSTRAINT meals_unit_check CHECK ((unit = ANY (ARRAY['portions'::text, 'kilograms'::text, 'items'::text, 'boxes'::text])))
);


ALTER TABLE public.meals OWNER TO postgres;

--
-- Name: rush_hours; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rush_hours (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    restaurant_id uuid,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    discount_percentage integer,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT rush_hours_discount_percentage_check CHECK (((discount_percentage >= 0) AND (discount_percentage <= 100)))
);


ALTER TABLE public.rush_hours OWNER TO postgres;

--
-- Name: meals_with_effective_discount; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.meals_with_effective_discount AS
 SELECT m.id,
    m.restaurant_id,
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
    m.ingredients,
    m.allergens,
    m.co2_savings,
    m.pickup_time,
    m.created_at,
    m.updated_at,
    COALESCE(rh.discount_percentage, (round((((m.original_price - m.discounted_price) / m.original_price) * (100)::numeric), 0))::integer) AS effective_discount_percentage,
    ((rh.id IS NOT NULL) AND rh.is_active AND ((now() >= rh.start_time) AND (now() <= rh.end_time))) AS rush_hour_active_now,
        CASE
            WHEN ((rh.id IS NOT NULL) AND rh.is_active AND ((now() >= rh.start_time) AND (now() <= rh.end_time))) THEN round((m.original_price * ((1)::numeric - ((rh.discount_percentage)::numeric / 100.0))), 2)
            ELSE m.discounted_price
        END AS effective_price,
    r.restaurant_name,
    r.rating AS restaurant_rating,
    r.address_text AS restaurant_address
   FROM ((public.meals m
     LEFT JOIN public.restaurants r ON ((m.restaurant_id = r.profile_id)))
     LEFT JOIN public.rush_hours rh ON (((m.restaurant_id = rh.restaurant_id) AND (rh.is_active = true) AND ((now() >= rh.start_time) AND (now() <= rh.end_time)))))
  WHERE (((m.status = 'active'::text) OR (m.status IS NULL)) AND (m.quantity_available > 0) AND (m.expiry_date > now()));


ALTER VIEW public.meals_with_effective_discount OWNER TO postgres;

--
-- Name: VIEW meals_with_effective_discount; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.meals_with_effective_discount IS 'Returns meals with computed effective discount and price based on rush hour status. 
Use this view instead of querying meals directly to ensure correct pricing.';


--
-- Name: ngos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ngos (
    profile_id uuid NOT NULL,
    organization_name text DEFAULT 'Unnamed Organization'::text,
    address_text text,
    legal_docs_urls text[] DEFAULT ARRAY[]::text[],
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.ngos OWNER TO postgres;

--
-- Name: order_issues; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_issues (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid NOT NULL,
    user_id uuid NOT NULL,
    restaurant_id uuid NOT NULL,
    issue_type text NOT NULL,
    description text NOT NULL,
    photo_url text,
    status text DEFAULT 'pending'::text NOT NULL,
    resolution_notes text,
    refund_amount numeric(10,2),
    resolved_at timestamp with time zone,
    resolved_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT order_issues_issue_type_check CHECK ((issue_type = ANY (ARRAY['food_quality'::text, 'wrong_order'::text, 'missing_items'::text, 'cold_food'::text, 'packaging_issue'::text, 'other'::text]))),
    CONSTRAINT order_issues_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'under_review'::text, 'resolved'::text, 'rejected'::text])))
);


ALTER TABLE public.order_issues OWNER TO postgres;

--
-- Name: TABLE order_issues; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.order_issues IS 'User-reported issues with completed orders';


--
-- Name: COLUMN order_issues.issue_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.order_issues.issue_type IS 'Type of issue: food_quality, wrong_order, missing_items, cold_food, packaging_issue, other';


--
-- Name: COLUMN order_issues.photo_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.order_issues.photo_url IS 'URL to uploaded photo evidence of the issue';


--
-- Name: COLUMN order_issues.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.order_issues.status IS 'Issue status: pending, under_review, resolved, rejected';


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid,
    meal_id uuid,
    meal_title text,
    quantity integer NOT NULL,
    unit_price numeric(12,2) NOT NULL,
    subtotal numeric(12,2) GENERATED ALWAYS AS (((quantity)::numeric * unit_price)) STORED
);


ALTER TABLE public.order_items OWNER TO postgres;

--
-- Name: TABLE order_items; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.order_items IS 'Stores individual items within an order. Each order can have multiple meal items.';


--
-- Name: COLUMN order_items.subtotal; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.order_items.subtotal IS 'Computed as quantity * unit_price. Used in order emails and reporting.';


--
-- Name: order_status_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_status_history (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    order_id uuid NOT NULL,
    status public.order_status NOT NULL,
    changed_by uuid,
    changed_at timestamp with time zone DEFAULT now(),
    notes text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.order_status_history OWNER TO postgres;

--
-- Name: TABLE order_status_history; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.order_status_history IS 'Tracks all status changes for orders';


--
-- Name: orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_code integer NOT NULL,
    user_id uuid,
    restaurant_id uuid,
    ngo_id uuid,
    delivery_type text,
    subtotal numeric(12,2),
    service_fee numeric(12,2),
    delivery_fee numeric(12,2),
    platform_commission numeric(12,2),
    total_amount numeric(12,2),
    otp_code text,
    delivery_address text,
    created_at timestamp with time zone DEFAULT now(),
    order_number text,
    payment_method text,
    payment_status text DEFAULT 'pending'::text,
    updated_at timestamp with time zone DEFAULT now(),
    qr_code text,
    pickup_code character varying(6),
    estimated_ready_time timestamp with time zone,
    actual_ready_time timestamp with time zone,
    picked_up_at timestamp with time zone,
    delivered_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    cancellation_reason text,
    special_instructions text,
    rating integer,
    review_text text,
    reviewed_at timestamp with time zone,
    status public.order_status DEFAULT 'pending'::public.order_status NOT NULL,
    CONSTRAINT orders_delivery_type_check CHECK ((delivery_type = ANY (ARRAY['pickup'::text, 'delivery'::text, 'donation'::text]))),
    CONSTRAINT orders_payment_method_check CHECK ((payment_method = ANY (ARRAY['card'::text, 'wallet'::text, 'cod'::text, 'cash'::text]))),
    CONSTRAINT orders_payment_status_check CHECK ((payment_status = ANY (ARRAY['pending'::text, 'paid'::text, 'failed'::text, 'refunded'::text]))),
    CONSTRAINT orders_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.orders OWNER TO postgres;

--
-- Name: COLUMN orders.order_number; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orders.order_number IS 'Unique human-readable order number (e.g., ORD20260205001)';


--
-- Name: COLUMN orders.payment_method; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orders.payment_method IS 'Payment method used: card, wallet, cod, cash';


--
-- Name: COLUMN orders.payment_status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orders.payment_status IS 'Payment status: pending, paid, failed, refunded';


--
-- Name: COLUMN orders.qr_code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orders.qr_code IS 'QR code data (JSON) for pickup verification';


--
-- Name: COLUMN orders.pickup_code; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orders.pickup_code IS '6-character alphanumeric code for pickup';


--
-- Name: COLUMN orders.estimated_ready_time; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orders.estimated_ready_time IS 'When the order is estimated to be ready';


--
-- Name: COLUMN orders.actual_ready_time; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orders.actual_ready_time IS 'When the order was actually ready';


--
-- Name: COLUMN orders.picked_up_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orders.picked_up_at IS 'When the order was picked up by customer';


--
-- Name: COLUMN orders.delivered_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orders.delivered_at IS 'When the order was delivered';


--
-- Name: COLUMN orders.rating; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orders.rating IS 'Customer rating (1-5 stars)';


--
-- Name: COLUMN orders.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orders.status IS 'Order status: pending, confirmed, preparing, ready_for_pickup, out_for_delivery, delivered, completed, cancelled';


--
-- Name: orders_order_code_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.orders_order_code_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.orders_order_code_seq OWNER TO postgres;

--
-- Name: orders_order_code_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.orders_order_code_seq OWNED BY public.orders.order_code;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid,
    transaction_id text,
    provider text,
    amount numeric(12,2),
    status text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT payments_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'success'::text, 'failed'::text, 'refunded'::text])))
);


ALTER TABLE public.payments OWNER TO postgres;

--
-- Name: restaurant_ratings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.restaurant_ratings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid NOT NULL,
    user_id uuid NOT NULL,
    restaurant_id uuid NOT NULL,
    rating integer NOT NULL,
    review_text text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT restaurant_ratings_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.restaurant_ratings OWNER TO postgres;

--
-- Name: TABLE restaurant_ratings; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.restaurant_ratings IS 'Individual restaurant ratings from users after order completion';


--
-- Name: COLUMN restaurant_ratings.rating; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.restaurant_ratings.rating IS 'Rating value from 1 to 5 stars';


--
-- Name: COLUMN restaurant_ratings.review_text; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.restaurant_ratings.review_text IS 'Optional text review from user';


--
-- Name: rewards_catalog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rewards_catalog (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reward_type text NOT NULL,
    title text NOT NULL,
    description text NOT NULL,
    points_cost integer NOT NULL,
    discount_percentage integer,
    discount_amount numeric(10,2),
    min_tier text,
    is_active boolean DEFAULT true NOT NULL,
    valid_days integer DEFAULT 30 NOT NULL,
    icon text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT rewards_catalog_min_tier_check CHECK ((min_tier = ANY (ARRAY['bronze'::text, 'silver'::text, 'gold'::text, 'platinum'::text]))),
    CONSTRAINT rewards_catalog_reward_type_check CHECK ((reward_type = ANY (ARRAY['discount'::text, 'free_delivery'::text, 'donation'::text, 'priority_support'::text, 'special_offer'::text])))
);


ALTER TABLE public.rewards_catalog OWNER TO postgres;

--
-- Name: TABLE rewards_catalog; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.rewards_catalog IS 'Available rewards that users can redeem';


--
-- Name: user_addresses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_addresses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    label text,
    address_text text NOT NULL,
    location_lat double precision,
    location_long double precision,
    is_default boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.user_addresses OWNER TO postgres;

--
-- Name: user_badges; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_badges (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    badge_type text NOT NULL,
    badge_name text NOT NULL,
    badge_description text NOT NULL,
    icon text NOT NULL,
    earned_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT user_badges_badge_type_check CHECK ((badge_type = ANY (ARRAY['food_rescuer'::text, 'ngo_supporter'::text, 'eco_warrior'::text, 'first_order'::text, 'loyal_customer'::text, 'top_donor'::text, 'community_hero'::text, 'early_adopter'::text])))
);


ALTER TABLE public.user_badges OWNER TO postgres;

--
-- Name: TABLE user_badges; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_badges IS 'Badges earned by users for achievements';


--
-- Name: user_category_preferences; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_category_preferences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    category text NOT NULL,
    notifications_enabled boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT user_category_preferences_category_check CHECK ((category = ANY (ARRAY['Meals'::text, 'Bakery'::text, 'Meat & Poultry'::text, 'Seafood'::text, 'Vegetables'::text, 'Desserts'::text, 'Groceries'::text])))
);


ALTER TABLE public.user_category_preferences OWNER TO postgres;

--
-- Name: user_loyalty; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_loyalty (
    user_id uuid NOT NULL,
    total_points integer DEFAULT 0 NOT NULL,
    available_points integer DEFAULT 0 NOT NULL,
    lifetime_points integer DEFAULT 0 NOT NULL,
    current_tier text DEFAULT 'bronze'::text NOT NULL,
    total_orders integer DEFAULT 0 NOT NULL,
    total_donations integer DEFAULT 0 NOT NULL,
    meals_rescued integer DEFAULT 0 NOT NULL,
    co2_saved numeric(10,2) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT user_loyalty_current_tier_check CHECK ((current_tier = ANY (ARRAY['bronze'::text, 'silver'::text, 'gold'::text, 'platinum'::text])))
);


ALTER TABLE public.user_loyalty OWNER TO postgres;

--
-- Name: TABLE user_loyalty; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_loyalty IS 'User loyalty profiles with points and tier information';


--
-- Name: user_notifications_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.user_notifications_summary AS
 SELECT user_id,
    category,
    count(*) AS unread_count,
    max(sent_at) AS latest_notification_at
   FROM public.category_notifications cn
  WHERE (is_read = false)
  GROUP BY user_id, category;


ALTER VIEW public.user_notifications_summary OWNER TO postgres;

--
-- Name: user_rewards; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_rewards (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    reward_id uuid NOT NULL,
    transaction_id uuid,
    status text DEFAULT 'active'::text NOT NULL,
    redeemed_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    used_at timestamp with time zone,
    order_id uuid,
    CONSTRAINT user_rewards_status_check CHECK ((status = ANY (ARRAY['active'::text, 'used'::text, 'expired'::text])))
);


ALTER TABLE public.user_rewards OWNER TO postgres;

--
-- Name: TABLE user_rewards; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_rewards IS 'Rewards redeemed by users';


--
-- Name: orders order_code; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders ALTER COLUMN order_code SET DEFAULT nextval('public.orders_order_code_seq'::regclass);


--
-- Name: backup_profiles_role backup_profiles_role_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backup_profiles_role
    ADD CONSTRAINT backup_profiles_role_pkey PRIMARY KEY (id);


--
-- Name: cart_items cart_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT cart_items_pkey PRIMARY KEY (id);


--
-- Name: cart_items cart_items_profile_id_meal_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT cart_items_profile_id_meal_id_key UNIQUE (profile_id, meal_id);


--
-- Name: cart_items cart_items_user_meal_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT cart_items_user_meal_unique UNIQUE (user_id, meal_id);


--
-- Name: category_notifications category_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.category_notifications
    ADD CONSTRAINT category_notifications_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_unique_pair; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_unique_pair UNIQUE (ngo_id, restaurant_id);


--
-- Name: email_logs email_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_logs
    ADD CONSTRAINT email_logs_pkey PRIMARY KEY (id);


--
-- Name: email_queue email_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_queue
    ADD CONSTRAINT email_queue_pkey PRIMARY KEY (id);


--
-- Name: favorite_restaurants favorite_restaurants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorite_restaurants
    ADD CONSTRAINT favorite_restaurants_pkey PRIMARY KEY (id);


--
-- Name: favorite_restaurants favorite_restaurants_user_id_restaurant_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorite_restaurants
    ADD CONSTRAINT favorite_restaurants_user_id_restaurant_id_key UNIQUE (user_id, restaurant_id);


--
-- Name: favorites favorites_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_pkey PRIMARY KEY (user_id, meal_id);


--
-- Name: free_meal_notifications free_meal_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.free_meal_notifications
    ADD CONSTRAINT free_meal_notifications_pkey PRIMARY KEY (id);


--
-- Name: free_meal_user_notifications free_meal_user_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.free_meal_user_notifications
    ADD CONSTRAINT free_meal_user_notifications_pkey PRIMARY KEY (id);


--
-- Name: loyalty_transactions loyalty_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loyalty_transactions
    ADD CONSTRAINT loyalty_transactions_pkey PRIMARY KEY (id);


--
-- Name: meal_reports meal_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meal_reports
    ADD CONSTRAINT meal_reports_pkey PRIMARY KEY (id);


--
-- Name: meals meals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meals
    ADD CONSTRAINT meals_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: ngos ngos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ngos
    ADD CONSTRAINT ngos_pkey PRIMARY KEY (profile_id);


--
-- Name: order_issues order_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_issues
    ADD CONSTRAINT order_issues_pkey PRIMARY KEY (id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: order_status_history order_status_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_status_history
    ADD CONSTRAINT order_status_history_pkey PRIMARY KEY (id);


--
-- Name: orders orders_order_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_order_number_key UNIQUE (order_number);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_email_key UNIQUE (email);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: restaurant_ratings restaurant_ratings_order_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.restaurant_ratings
    ADD CONSTRAINT restaurant_ratings_order_unique UNIQUE (order_id);


--
-- Name: restaurant_ratings restaurant_ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.restaurant_ratings
    ADD CONSTRAINT restaurant_ratings_pkey PRIMARY KEY (id);


--
-- Name: restaurant_ratings restaurant_ratings_user_restaurant_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.restaurant_ratings
    ADD CONSTRAINT restaurant_ratings_user_restaurant_unique UNIQUE (user_id, restaurant_id, order_id);


--
-- Name: restaurants restaurants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.restaurants
    ADD CONSTRAINT restaurants_pkey PRIMARY KEY (profile_id);


--
-- Name: rewards_catalog rewards_catalog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rewards_catalog
    ADD CONSTRAINT rewards_catalog_pkey PRIMARY KEY (id);


--
-- Name: rush_hours rush_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rush_hours
    ADD CONSTRAINT rush_hours_pkey PRIMARY KEY (id);


--
-- Name: user_addresses user_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_addresses
    ADD CONSTRAINT user_addresses_pkey PRIMARY KEY (id);


--
-- Name: user_badges user_badges_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_badges
    ADD CONSTRAINT user_badges_pkey PRIMARY KEY (id);


--
-- Name: user_badges user_badges_user_id_badge_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_badges
    ADD CONSTRAINT user_badges_user_id_badge_type_key UNIQUE (user_id, badge_type);


--
-- Name: user_category_preferences user_category_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_category_preferences
    ADD CONSTRAINT user_category_preferences_pkey PRIMARY KEY (id);


--
-- Name: user_category_preferences user_category_preferences_user_category_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_category_preferences
    ADD CONSTRAINT user_category_preferences_user_category_unique UNIQUE (user_id, category);


--
-- Name: user_loyalty user_loyalty_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_loyalty
    ADD CONSTRAINT user_loyalty_pkey PRIMARY KEY (user_id);


--
-- Name: user_rewards user_rewards_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_rewards
    ADD CONSTRAINT user_rewards_pkey PRIMARY KEY (id);


--
-- Name: idx_cart_items_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cart_items_created_at ON public.cart_items USING btree (created_at DESC);


--
-- Name: idx_cart_items_meal_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cart_items_meal_id ON public.cart_items USING btree (meal_id);


--
-- Name: idx_cart_items_profile_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cart_items_profile_id ON public.cart_items USING btree (profile_id);


--
-- Name: idx_cart_items_profile_meal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cart_items_profile_meal ON public.cart_items USING btree (profile_id, meal_id);


--
-- Name: idx_cart_items_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cart_items_user_id ON public.cart_items USING btree (user_id);


--
-- Name: idx_category_notifications_is_read; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_category_notifications_is_read ON public.category_notifications USING btree (is_read);


--
-- Name: idx_category_notifications_meal_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_category_notifications_meal_id ON public.category_notifications USING btree (meal_id);


--
-- Name: idx_category_notifications_sent_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_category_notifications_sent_at ON public.category_notifications USING btree (sent_at DESC);


--
-- Name: idx_category_notifications_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_category_notifications_user_id ON public.category_notifications USING btree (user_id);


--
-- Name: idx_conversations_last_message_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_conversations_last_message_at ON public.conversations USING btree (last_message_at DESC);


--
-- Name: idx_conversations_ngo_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_conversations_ngo_id ON public.conversations USING btree (ngo_id);


--
-- Name: idx_conversations_restaurant_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_conversations_restaurant_id ON public.conversations USING btree (restaurant_id);


--
-- Name: idx_email_logs_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_email_logs_order ON public.email_logs USING btree (order_id, created_at DESC);


--
-- Name: idx_email_queue_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_email_queue_order ON public.email_queue USING btree (order_id);


--
-- Name: idx_email_queue_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_email_queue_status ON public.email_queue USING btree (status, created_at);


--
-- Name: idx_favorite_restaurants_restaurant_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_favorite_restaurants_restaurant_id ON public.favorite_restaurants USING btree (restaurant_id);


--
-- Name: idx_favorite_restaurants_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_favorite_restaurants_user_id ON public.favorite_restaurants USING btree (user_id);


--
-- Name: idx_favorites_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_favorites_user_id ON public.favorites USING btree (user_id);


--
-- Name: idx_free_meal_notifications_claimed_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_free_meal_notifications_claimed_by ON public.free_meal_notifications USING btree (claimed_by);


--
-- Name: idx_free_meal_notifications_donated_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_free_meal_notifications_donated_at ON public.free_meal_notifications USING btree (donated_at DESC);


--
-- Name: idx_free_meal_notifications_meal_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_free_meal_notifications_meal_id ON public.free_meal_notifications USING btree (meal_id);


--
-- Name: idx_free_meal_notifications_restaurant_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_free_meal_notifications_restaurant_id ON public.free_meal_notifications USING btree (restaurant_id);


--
-- Name: idx_free_meal_user_notifications_claimed; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_free_meal_user_notifications_claimed ON public.free_meal_user_notifications USING btree (claimed);


--
-- Name: idx_free_meal_user_notifications_is_read; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_free_meal_user_notifications_is_read ON public.free_meal_user_notifications USING btree (is_read);


--
-- Name: idx_free_meal_user_notifications_meal_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_free_meal_user_notifications_meal_id ON public.free_meal_user_notifications USING btree (meal_id);


--
-- Name: idx_free_meal_user_notifications_sent_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_free_meal_user_notifications_sent_at ON public.free_meal_user_notifications USING btree (sent_at DESC);


--
-- Name: idx_free_meal_user_notifications_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_free_meal_user_notifications_user_id ON public.free_meal_user_notifications USING btree (user_id);


--
-- Name: idx_loyalty_transactions_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_loyalty_transactions_order ON public.loyalty_transactions USING btree (order_id);


--
-- Name: idx_loyalty_transactions_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_loyalty_transactions_user ON public.loyalty_transactions USING btree (user_id, created_at DESC);


--
-- Name: idx_meal_reports_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meal_reports_created_at ON public.meal_reports USING btree (created_at DESC);


--
-- Name: idx_meal_reports_meal_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meal_reports_meal_id ON public.meal_reports USING btree (meal_id);


--
-- Name: idx_meal_reports_restaurant_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meal_reports_restaurant_id ON public.meal_reports USING btree (restaurant_id);


--
-- Name: idx_meal_reports_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meal_reports_status ON public.meal_reports USING btree (status);


--
-- Name: idx_meal_reports_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meal_reports_user_id ON public.meal_reports USING btree (user_id);


--
-- Name: idx_meals_active_available; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meals_active_available ON public.meals USING btree (status, quantity_available, expiry_date) WHERE ((status = 'active'::text) AND (quantity_available > 0));


--
-- Name: INDEX idx_meals_active_available; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON INDEX public.idx_meals_active_available IS 'Partial index for active meals with available quantity. Optimizes home screen meal listing query.';


--
-- Name: idx_meals_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meals_category ON public.meals USING btree (category) WHERE (status = 'active'::text);


--
-- Name: INDEX idx_meals_category; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON INDEX public.idx_meals_category IS 'Index for filtering meals by category. Useful for category-specific meal listings.';


--
-- Name: idx_meals_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meals_created_at ON public.meals USING btree (created_at DESC);


--
-- Name: idx_meals_created_at_desc; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meals_created_at_desc ON public.meals USING btree (created_at DESC);


--
-- Name: INDEX idx_meals_created_at_desc; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON INDEX public.idx_meals_created_at_desc IS 'Index for ordering meals by creation date (newest first). Used in home screen pagination.';


--
-- Name: idx_meals_expiry_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meals_expiry_date ON public.meals USING btree (expiry_date);


--
-- Name: idx_meals_expiry_range; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meals_expiry_range ON public.meals USING btree (expiry_date) WHERE ((status = 'active'::text) AND (quantity_available > 0));


--
-- Name: INDEX idx_meals_expiry_range; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON INDEX public.idx_meals_expiry_range IS 'Index for finding meals by expiry date range. Useful for "expiring soon" features.';


--
-- Name: idx_meals_restaurant_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meals_restaurant_id ON public.meals USING btree (restaurant_id);


--
-- Name: idx_meals_restaurant_lookup; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meals_restaurant_lookup ON public.meals USING btree (restaurant_id, status) WHERE (status = 'active'::text);


--
-- Name: INDEX idx_meals_restaurant_lookup; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON INDEX public.idx_meals_restaurant_lookup IS 'Composite index for restaurant joins. Optimizes queries that filter by restaurant and status.';


--
-- Name: idx_meals_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meals_status ON public.meals USING btree (status);


--
-- Name: idx_messages_conversation_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_conversation_id ON public.messages USING btree (conversation_id);


--
-- Name: idx_messages_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_created_at ON public.messages USING btree (created_at DESC);


--
-- Name: idx_messages_is_read; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_is_read ON public.messages USING btree (is_read);


--
-- Name: idx_messages_sender_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_sender_id ON public.messages USING btree (sender_id);


--
-- Name: idx_order_issues_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_issues_order ON public.order_issues USING btree (order_id);


--
-- Name: idx_order_issues_restaurant; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_issues_restaurant ON public.order_issues USING btree (restaurant_id, status, created_at DESC);


--
-- Name: idx_order_issues_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_issues_status ON public.order_issues USING btree (status, created_at DESC);


--
-- Name: idx_order_issues_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_issues_user ON public.order_issues USING btree (user_id, created_at DESC);


--
-- Name: idx_order_items_meal_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_items_meal_id ON public.order_items USING btree (meal_id);


--
-- Name: idx_order_items_order_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_items_order_id ON public.order_items USING btree (order_id);


--
-- Name: idx_order_status_history_order_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_status_history_order_id ON public.order_status_history USING btree (order_id);


--
-- Name: idx_orders_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_created_at ON public.orders USING btree (created_at DESC) WHERE (status = ANY (ARRAY['delivered'::public.order_status, 'completed'::public.order_status]));


--
-- Name: idx_orders_ngo_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_ngo_id ON public.orders USING btree (ngo_id);


--
-- Name: idx_orders_order_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_order_number ON public.orders USING btree (order_number);


--
-- Name: idx_orders_payment_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_payment_status ON public.orders USING btree (payment_status);


--
-- Name: idx_orders_restaurant_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_restaurant_id ON public.orders USING btree (restaurant_id);


--
-- Name: idx_orders_restaurant_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_restaurant_status ON public.orders USING btree (restaurant_id, status, created_at DESC);


--
-- Name: idx_orders_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_status ON public.orders USING btree (status);


--
-- Name: idx_orders_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_user_id ON public.orders USING btree (user_id);


--
-- Name: idx_profiles_address; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profiles_address ON public.profiles USING btree (address_text);


--
-- Name: idx_profiles_approval_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profiles_approval_role ON public.profiles USING btree (approval_status, role) WHERE ((approval_status = 'approved'::text) AND (role = 'restaurant'::text));


--
-- Name: idx_profiles_approval_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profiles_approval_status ON public.profiles USING btree (approval_status);


--
-- Name: idx_profiles_default_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profiles_default_location ON public.profiles USING btree (id) WHERE (default_location IS NOT NULL);


--
-- Name: idx_profiles_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profiles_email ON public.profiles USING btree (email);


--
-- Name: idx_profiles_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profiles_id ON public.profiles USING btree (id);


--
-- Name: idx_profiles_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profiles_role ON public.profiles USING btree (role);


--
-- Name: idx_restaurant_ratings_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_restaurant_ratings_order ON public.restaurant_ratings USING btree (order_id);


--
-- Name: idx_restaurant_ratings_restaurant; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_restaurant_ratings_restaurant ON public.restaurant_ratings USING btree (restaurant_id);


--
-- Name: idx_restaurant_ratings_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_restaurant_ratings_user ON public.restaurant_ratings USING btree (user_id);


--
-- Name: idx_rewards_catalog_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_rewards_catalog_active ON public.rewards_catalog USING btree (is_active, points_cost);


--
-- Name: idx_rush_hours_active_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_rush_hours_active_time ON public.rush_hours USING btree (restaurant_id, is_active, start_time, end_time) WHERE (is_active = true);


--
-- Name: idx_rush_hours_one_active_per_restaurant; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_rush_hours_one_active_per_restaurant ON public.rush_hours USING btree (restaurant_id) WHERE (is_active = true);


--
-- Name: INDEX idx_rush_hours_one_active_per_restaurant; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON INDEX public.idx_rush_hours_one_active_per_restaurant IS 'Ensures only one active rush hour configuration per restaurant at any time';


--
-- Name: idx_rush_hours_restaurant_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_rush_hours_restaurant_id ON public.rush_hours USING btree (restaurant_id);


--
-- Name: idx_user_badges_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_badges_user ON public.user_badges USING btree (user_id, earned_at DESC);


--
-- Name: idx_user_category_preferences_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_category_preferences_category ON public.user_category_preferences USING btree (category);


--
-- Name: idx_user_category_preferences_notifications_enabled; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_category_preferences_notifications_enabled ON public.user_category_preferences USING btree (notifications_enabled);


--
-- Name: idx_user_category_preferences_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_category_preferences_user_id ON public.user_category_preferences USING btree (user_id);


--
-- Name: idx_user_loyalty_points; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_loyalty_points ON public.user_loyalty USING btree (available_points DESC);


--
-- Name: idx_user_loyalty_tier; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_loyalty_tier ON public.user_loyalty USING btree (current_tier);


--
-- Name: idx_user_rewards_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_rewards_status ON public.user_rewards USING btree (status, expires_at);


--
-- Name: idx_user_rewards_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_rewards_user ON public.user_rewards USING btree (user_id, status, expires_at);


--
-- Name: cart_items trg_cart_items_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_cart_items_updated_at BEFORE UPDATE ON public.cart_items FOR EACH ROW EXECUTE FUNCTION public.update_cart_items_updated_at();


--
-- Name: ngos trg_ngos_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_ngos_set_updated_at BEFORE UPDATE ON public.ngos FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: meals trg_notify_category_subscribers; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_notify_category_subscribers AFTER INSERT OR UPDATE ON public.meals FOR EACH ROW EXECUTE FUNCTION public.notify_category_subscribers();


--
-- Name: restaurants trg_restaurants_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_restaurants_set_updated_at BEFORE UPDATE ON public.restaurants FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: messages trg_update_conversation_last_message; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_conversation_last_message AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION public.update_conversation_last_message();


--
-- Name: orders trg_update_orders_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: profiles trg_update_profiles_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: rush_hours trg_update_rush_hour_flag; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_rush_hour_flag AFTER INSERT OR DELETE OR UPDATE ON public.rush_hours FOR EACH ROW EXECUTE FUNCTION public.update_restaurant_rush_hour_flag();


--
-- Name: user_addresses trg_update_user_addresses_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_user_addresses_updated_at BEFORE UPDATE ON public.user_addresses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: user_category_preferences trg_update_user_category_preferences_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_user_category_preferences_updated_at BEFORE UPDATE ON public.user_category_preferences FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: orders trigger_auto_generate_order_codes; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_auto_generate_order_codes BEFORE INSERT ON public.orders FOR EACH ROW EXECUTE FUNCTION public.auto_generate_order_codes();


--
-- Name: orders trigger_award_order_points; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_award_order_points AFTER UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.award_order_points();


--
-- Name: user_addresses trigger_handle_address_deletion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_handle_address_deletion BEFORE DELETE ON public.user_addresses FOR EACH ROW EXECUTE FUNCTION public.handle_address_deletion();


--
-- Name: profiles trigger_initialize_loyalty; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_initialize_loyalty AFTER INSERT ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.initialize_user_loyalty();


--
-- Name: orders trigger_log_order_status_change; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_log_order_status_change BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.log_order_status_change();


--
-- Name: order_issues trigger_notify_restaurant_issue; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_notify_restaurant_issue AFTER INSERT ON public.order_issues FOR EACH ROW EXECUTE FUNCTION public.notify_restaurant_of_issue();


--
-- Name: orders trigger_queue_order_emails; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_queue_order_emails AFTER INSERT ON public.orders FOR EACH ROW EXECUTE FUNCTION public.queue_order_emails();


--
-- Name: order_issues trigger_update_issue_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_update_issue_timestamp BEFORE UPDATE ON public.order_issues FOR EACH ROW EXECUTE FUNCTION public.update_order_issue_timestamp();


--
-- Name: user_addresses trigger_update_profile_default_location; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_update_profile_default_location AFTER INSERT OR UPDATE OF is_default, address_text ON public.user_addresses FOR EACH ROW EXECUTE FUNCTION public.update_profile_default_location();


--
-- Name: restaurant_ratings trigger_update_restaurant_rating_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_update_restaurant_rating_delete AFTER DELETE ON public.restaurant_ratings FOR EACH ROW EXECUTE FUNCTION public.update_restaurant_rating();


--
-- Name: restaurant_ratings trigger_update_restaurant_rating_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_update_restaurant_rating_insert AFTER INSERT ON public.restaurant_ratings FOR EACH ROW EXECUTE FUNCTION public.update_restaurant_rating();


--
-- Name: restaurant_ratings trigger_update_restaurant_rating_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_update_restaurant_rating_update AFTER UPDATE ON public.restaurant_ratings FOR EACH ROW EXECUTE FUNCTION public.update_restaurant_rating();


--
-- Name: cart_items cart_items_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT cart_items_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES public.meals(id) ON DELETE CASCADE;


--
-- Name: cart_items cart_items_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT cart_items_user_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: cart_items cart_items_user_id_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT cart_items_user_id_fkey1 FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: category_notifications category_notifications_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.category_notifications
    ADD CONSTRAINT category_notifications_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES public.meals(id) ON DELETE CASCADE;


--
-- Name: category_notifications category_notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.category_notifications
    ADD CONSTRAINT category_notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: conversations conversations_ngo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_ngo_id_fkey FOREIGN KEY (ngo_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: conversations conversations_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: email_logs email_logs_email_queue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_logs
    ADD CONSTRAINT email_logs_email_queue_id_fkey FOREIGN KEY (email_queue_id) REFERENCES public.email_queue(id) ON DELETE SET NULL;


--
-- Name: email_logs email_logs_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_logs
    ADD CONSTRAINT email_logs_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: email_queue email_queue_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_queue
    ADD CONSTRAINT email_queue_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: favorite_restaurants favorite_restaurants_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorite_restaurants
    ADD CONSTRAINT favorite_restaurants_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(profile_id) ON DELETE CASCADE;


--
-- Name: CONSTRAINT favorite_restaurants_restaurant_id_fkey ON favorite_restaurants; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT favorite_restaurants_restaurant_id_fkey ON public.favorite_restaurants IS 'When a restaurant is deleted, automatically remove it from all favorites';


--
-- Name: favorite_restaurants favorite_restaurants_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorite_restaurants
    ADD CONSTRAINT favorite_restaurants_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: favorites favorites_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES public.meals(id) ON DELETE CASCADE;


--
-- Name: CONSTRAINT favorites_meal_id_fkey ON favorites; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT favorites_meal_id_fkey ON public.favorites IS 'When a meal is deleted, automatically remove it from all favorites';


--
-- Name: favorites favorites_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: free_meal_notifications free_meal_notifications_claimed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.free_meal_notifications
    ADD CONSTRAINT free_meal_notifications_claimed_by_fkey FOREIGN KEY (claimed_by) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: free_meal_notifications free_meal_notifications_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.free_meal_notifications
    ADD CONSTRAINT free_meal_notifications_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES public.meals(id) ON DELETE CASCADE;


--
-- Name: free_meal_notifications free_meal_notifications_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.free_meal_notifications
    ADD CONSTRAINT free_meal_notifications_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(profile_id) ON DELETE CASCADE;


--
-- Name: free_meal_user_notifications free_meal_user_notifications_donation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.free_meal_user_notifications
    ADD CONSTRAINT free_meal_user_notifications_donation_id_fkey FOREIGN KEY (donation_id) REFERENCES public.free_meal_notifications(id) ON DELETE CASCADE;


--
-- Name: free_meal_user_notifications free_meal_user_notifications_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.free_meal_user_notifications
    ADD CONSTRAINT free_meal_user_notifications_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES public.meals(id) ON DELETE CASCADE;


--
-- Name: free_meal_user_notifications free_meal_user_notifications_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.free_meal_user_notifications
    ADD CONSTRAINT free_meal_user_notifications_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(profile_id) ON DELETE CASCADE;


--
-- Name: free_meal_user_notifications free_meal_user_notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.free_meal_user_notifications
    ADD CONSTRAINT free_meal_user_notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: loyalty_transactions loyalty_transactions_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loyalty_transactions
    ADD CONSTRAINT loyalty_transactions_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE SET NULL;


--
-- Name: loyalty_transactions loyalty_transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.loyalty_transactions
    ADD CONSTRAINT loyalty_transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: meal_reports meal_reports_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meal_reports
    ADD CONSTRAINT meal_reports_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES public.meals(id) ON DELETE CASCADE;


--
-- Name: meal_reports meal_reports_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meal_reports
    ADD CONSTRAINT meal_reports_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: meal_reports meal_reports_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meal_reports
    ADD CONSTRAINT meal_reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: meals meals_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meals
    ADD CONSTRAINT meals_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(profile_id) ON DELETE CASCADE;


--
-- Name: messages messages_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE;


--
-- Name: messages messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: ngos ngos_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ngos
    ADD CONSTRAINT ngos_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: order_issues order_issues_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_issues
    ADD CONSTRAINT order_issues_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: order_issues order_issues_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_issues
    ADD CONSTRAINT order_issues_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.profiles(id);


--
-- Name: order_issues order_issues_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_issues
    ADD CONSTRAINT order_issues_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(profile_id) ON DELETE CASCADE;


--
-- Name: order_issues order_issues_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_issues
    ADD CONSTRAINT order_issues_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: order_items order_items_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES public.meals(id) ON DELETE RESTRICT;


--
-- Name: CONSTRAINT order_items_meal_id_fkey ON order_items; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT order_items_meal_id_fkey ON public.order_items IS 'Prevents deleting meals that are in orders. Protects order history and email generation.';


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: CONSTRAINT order_items_order_id_fkey ON order_items; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT order_items_order_id_fkey ON public.order_items IS 'When an order is deleted, automatically delete all its items';


--
-- Name: order_status_history order_status_history_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_status_history
    ADD CONSTRAINT order_status_history_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.profiles(id);


--
-- Name: order_status_history order_status_history_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_status_history
    ADD CONSTRAINT order_status_history_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: orders orders_ngo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_ngo_id_fkey FOREIGN KEY (ngo_id) REFERENCES public.ngos(profile_id);


--
-- Name: orders orders_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(profile_id);


--
-- Name: orders orders_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id);


--
-- Name: payments payments_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: restaurant_ratings restaurant_ratings_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.restaurant_ratings
    ADD CONSTRAINT restaurant_ratings_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: restaurant_ratings restaurant_ratings_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.restaurant_ratings
    ADD CONSTRAINT restaurant_ratings_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(profile_id) ON DELETE CASCADE;


--
-- Name: restaurant_ratings restaurant_ratings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.restaurant_ratings
    ADD CONSTRAINT restaurant_ratings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: restaurants restaurants_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.restaurants
    ADD CONSTRAINT restaurants_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: rush_hours rush_hours_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rush_hours
    ADD CONSTRAINT rush_hours_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(profile_id) ON DELETE CASCADE;


--
-- Name: user_addresses user_addresses_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_addresses
    ADD CONSTRAINT user_addresses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: user_badges user_badges_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_badges
    ADD CONSTRAINT user_badges_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: user_category_preferences user_category_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_category_preferences
    ADD CONSTRAINT user_category_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_loyalty user_loyalty_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_loyalty
    ADD CONSTRAINT user_loyalty_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: user_rewards user_rewards_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_rewards
    ADD CONSTRAINT user_rewards_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE SET NULL;


--
-- Name: user_rewards user_rewards_reward_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_rewards
    ADD CONSTRAINT user_rewards_reward_id_fkey FOREIGN KEY (reward_id) REFERENCES public.rewards_catalog(id) ON DELETE CASCADE;


--
-- Name: user_rewards user_rewards_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_rewards
    ADD CONSTRAINT user_rewards_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.loyalty_transactions(id) ON DELETE SET NULL;


--
-- Name: user_rewards user_rewards_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_rewards
    ADD CONSTRAINT user_rewards_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: order_issues Admins can manage all issues; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage all issues" ON public.order_issues TO service_role USING (true) WITH CHECK (true);


--
-- Name: order_items Admins can view all order items; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can view all order items" ON public.order_items FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'admin'::text)))));


--
-- Name: POLICY "Admins can view all order items" ON order_items; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON POLICY "Admins can view all order items" ON public.order_items IS 'Allows admin users to view all order items for management purposes';


--
-- Name: order_status_history Admins can view all order status history; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can view all order status history" ON public.order_status_history FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'admin'::text)))));


--
-- Name: POLICY "Admins can view all order status history" ON order_status_history; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON POLICY "Admins can view all order status history" ON public.order_status_history IS 'Allows admin users to view all order status history for management purposes';


--
-- Name: orders Admins can view all orders; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can view all orders" ON public.orders FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'admin'::text)))));


--
-- Name: POLICY "Admins can view all orders" ON orders; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON POLICY "Admins can view all orders" ON public.orders IS 'Allows admin users to view all orders in the system for management purposes';


--
-- Name: meals Anonymous can view active meals; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anonymous can view active meals" ON public.meals FOR SELECT TO anon USING ((((status = 'active'::text) OR (status IS NULL)) AND (quantity_available > 0) AND (expiry_date > now())));


--
-- Name: rewards_catalog Anyone can view active rewards; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anyone can view active rewards" ON public.rewards_catalog FOR SELECT TO authenticated USING ((is_active = true));


--
-- Name: restaurant_ratings Anyone can view restaurant ratings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anyone can view restaurant ratings" ON public.restaurant_ratings FOR SELECT USING (true);


--
-- Name: cart_items Authenticated users can delete own cart items; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authenticated users can delete own cart items" ON public.cart_items FOR DELETE TO authenticated USING ((auth.uid() = profile_id));


--
-- Name: cart_items Authenticated users can insert own cart items; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authenticated users can insert own cart items" ON public.cart_items FOR INSERT TO authenticated WITH CHECK ((auth.uid() = profile_id));


--
-- Name: cart_items Authenticated users can update own cart items; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authenticated users can update own cart items" ON public.cart_items FOR UPDATE TO authenticated USING ((auth.uid() = profile_id)) WITH CHECK ((auth.uid() = profile_id));


--
-- Name: cart_items Authenticated users can view own cart items; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authenticated users can view own cart items" ON public.cart_items FOR SELECT TO authenticated USING ((auth.uid() = profile_id));


--
-- Name: conversations NGOs can create conversations; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "NGOs can create conversations" ON public.conversations FOR INSERT TO authenticated WITH CHECK ((ngo_id = auth.uid()));


--
-- Name: orders NGOs can view their orders; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "NGOs can view their orders" ON public.orders FOR SELECT TO authenticated USING ((ngo_id = auth.uid()));


--
-- Name: POLICY "NGOs can view their orders" ON orders; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON POLICY "NGOs can view their orders" ON public.orders IS 'Allows NGOs to view orders assigned to them';


--
-- Name: rush_hours Public can view active rush hours; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view active rush hours" ON public.rush_hours FOR SELECT TO authenticated, anon USING ((is_active = true));


--
-- Name: meals Public can view available meals; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view available meals" ON public.meals FOR SELECT TO authenticated, anon USING (((quantity_available > 0) AND (expiry_date > now())));


--
-- Name: restaurants Public can view restaurants; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view restaurants" ON public.restaurants FOR SELECT TO authenticated, anon USING (true);


--
-- Name: rush_hours Public can view rush hours; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view rush hours" ON public.rush_hours FOR SELECT USING (true);


--
-- Name: restaurants Restaurant owners can insert own details; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurant owners can insert own details" ON public.restaurants FOR INSERT WITH CHECK ((auth.uid() = profile_id));


--
-- Name: rush_hours Restaurant owners can manage rush hours; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurant owners can manage rush hours" ON public.rush_hours USING ((auth.uid() = restaurant_id));


--
-- Name: restaurants Restaurant owners can update own details; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurant owners can update own details" ON public.restaurants FOR UPDATE USING ((auth.uid() = profile_id));


--
-- Name: restaurants Restaurant owners can update own record; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurant owners can update own record" ON public.restaurants FOR UPDATE TO authenticated USING (((auth.uid() = profile_id) OR public.is_admin())) WITH CHECK (((auth.uid() = profile_id) OR public.is_admin()));


--
-- Name: restaurants Restaurant owners can view own record; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurant owners can view own record" ON public.restaurants FOR SELECT TO authenticated USING (((auth.uid() = profile_id) OR public.is_admin()));


--
-- Name: conversations Restaurants can create conversations; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can create conversations" ON public.conversations FOR INSERT TO authenticated WITH CHECK ((restaurant_id = auth.uid()));


--
-- Name: meals Restaurants can delete their own meals; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can delete their own meals" ON public.meals FOR DELETE TO authenticated USING ((restaurant_id = auth.uid()));


--
-- Name: rush_hours Restaurants can delete their own rush hours; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can delete their own rush hours" ON public.rush_hours FOR DELETE TO authenticated USING ((restaurant_id = auth.uid()));


--
-- Name: free_meal_notifications Restaurants can insert their own donations; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can insert their own donations" ON public.free_meal_notifications FOR INSERT TO authenticated WITH CHECK ((restaurant_id = auth.uid()));


--
-- Name: meals Restaurants can insert their own meals; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can insert their own meals" ON public.meals FOR INSERT TO authenticated WITH CHECK ((restaurant_id = auth.uid()));


--
-- Name: rush_hours Restaurants can insert their own rush hours; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can insert their own rush hours" ON public.rush_hours FOR INSERT TO authenticated WITH CHECK ((restaurant_id = auth.uid()));


--
-- Name: order_issues Restaurants can update their issues; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can update their issues" ON public.order_issues FOR UPDATE TO authenticated USING ((restaurant_id = auth.uid())) WITH CHECK ((restaurant_id = auth.uid()));


--
-- Name: orders Restaurants can update their orders; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can update their orders" ON public.orders FOR UPDATE TO authenticated USING ((restaurant_id = auth.uid())) WITH CHECK ((restaurant_id = auth.uid()));


--
-- Name: meals Restaurants can update their own meals; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can update their own meals" ON public.meals FOR UPDATE TO authenticated USING ((restaurant_id = auth.uid())) WITH CHECK ((restaurant_id = auth.uid()));


--
-- Name: restaurants Restaurants can update their own profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can update their own profile" ON public.restaurants FOR UPDATE TO authenticated USING ((profile_id = auth.uid())) WITH CHECK ((profile_id = auth.uid()));


--
-- Name: rush_hours Restaurants can update their own rush hours; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can update their own rush hours" ON public.rush_hours FOR UPDATE TO authenticated USING ((restaurant_id = auth.uid())) WITH CHECK ((restaurant_id = auth.uid()));


--
-- Name: meal_reports Restaurants can view reports about their meals; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can view reports about their meals" ON public.meal_reports FOR SELECT TO authenticated USING ((restaurant_id = auth.uid()));


--
-- Name: order_issues Restaurants can view their issues; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can view their issues" ON public.order_issues FOR SELECT TO authenticated USING ((restaurant_id = auth.uid()));


--
-- Name: orders Restaurants can view their orders; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can view their orders" ON public.orders FOR SELECT TO authenticated USING ((restaurant_id = auth.uid()));


--
-- Name: POLICY "Restaurants can view their orders" ON orders; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON POLICY "Restaurants can view their orders" ON public.orders IS 'Allows restaurants to view orders assigned to them';


--
-- Name: free_meal_notifications Restaurants can view their own donations; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can view their own donations" ON public.free_meal_notifications FOR SELECT TO authenticated USING ((restaurant_id = auth.uid()));


--
-- Name: meals Restaurants can view their own meals; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can view their own meals" ON public.meals FOR SELECT TO authenticated USING ((restaurant_id = auth.uid()));


--
-- Name: restaurants Restaurants can view their own profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can view their own profile" ON public.restaurants FOR SELECT TO authenticated USING ((profile_id = auth.uid()));


--
-- Name: rush_hours Restaurants can view their own rush hours; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can view their own rush hours" ON public.rush_hours FOR SELECT TO authenticated USING ((restaurant_id = auth.uid()));


--
-- Name: restaurants Restaurants: public browse approved; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants: public browse approved" ON public.restaurants FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = restaurants.profile_id) AND (p.approval_status = 'approved'::text)))));


--
-- Name: restaurants Restaurants: select own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants: select own" ON public.restaurants FOR SELECT USING ((auth.uid() = profile_id));


--
-- Name: restaurants Restaurants: update own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants: update own" ON public.restaurants FOR UPDATE USING ((auth.uid() = profile_id)) WITH CHECK ((auth.uid() = profile_id));


--
-- Name: ngos Service role can insert ngos; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Service role can insert ngos" ON public.ngos FOR INSERT TO service_role WITH CHECK (true);


--
-- Name: restaurants Service role can insert restaurants; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Service role can insert restaurants" ON public.restaurants FOR INSERT TO service_role WITH CHECK (true);


--
-- Name: email_logs Service role full access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Service role full access" ON public.email_logs TO service_role USING (true) WITH CHECK (true);


--
-- Name: email_queue Service role full access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Service role full access" ON public.email_queue TO service_role USING (true) WITH CHECK (true);


--
-- Name: ngos System can insert ngos; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "System can insert ngos" ON public.ngos FOR INSERT WITH CHECK (true);


--
-- Name: restaurants System can insert restaurants; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "System can insert restaurants" ON public.restaurants FOR INSERT WITH CHECK (true);


--
-- Name: user_badges System can manage badges; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "System can manage badges" ON public.user_badges TO service_role USING (true) WITH CHECK (true);


--
-- Name: user_loyalty System can manage loyalty profiles; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "System can manage loyalty profiles" ON public.user_loyalty TO service_role USING (true) WITH CHECK (true);


--
-- Name: rewards_catalog System can manage rewards catalog; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "System can manage rewards catalog" ON public.rewards_catalog TO service_role USING (true) WITH CHECK (true);


--
-- Name: loyalty_transactions System can manage transactions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "System can manage transactions" ON public.loyalty_transactions TO service_role USING (true) WITH CHECK (true);


--
-- Name: user_rewards System can manage user rewards; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "System can manage user rewards" ON public.user_rewards TO service_role USING (true) WITH CHECK (true);


--
-- Name: free_meal_notifications Users can claim free meals; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can claim free meals" ON public.free_meal_notifications FOR UPDATE TO authenticated USING (((claimed_by IS NULL) OR (claimed_by = auth.uid()))) WITH CHECK ((claimed_by = auth.uid()));


--
-- Name: order_issues Users can create issues for own orders; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can create issues for own orders" ON public.order_issues FOR INSERT TO authenticated WITH CHECK (((auth.uid() = user_id) AND (EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = order_issues.order_id) AND (o.user_id = auth.uid()) AND (o.status = ANY (ARRAY['completed'::public.order_status, 'delivered'::public.order_status])))))));


--
-- Name: orders Users can create orders; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can create orders" ON public.orders FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: favorites Users can delete favorites; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete favorites" ON public.favorites FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: user_addresses Users can delete own addresses; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete own addresses" ON public.user_addresses FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: favorite_restaurants Users can delete own favorite restaurants; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete own favorite restaurants" ON public.favorite_restaurants FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: user_addresses Users can delete their own addresses; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete their own addresses" ON public.user_addresses FOR DELETE TO authenticated USING ((user_id = auth.uid()));


--
-- Name: cart_items Users can delete their own cart items; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete their own cart items" ON public.cart_items FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: user_category_preferences Users can delete their own category preferences; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete their own category preferences" ON public.user_category_preferences FOR DELETE TO authenticated USING ((user_id = auth.uid()));


--
-- Name: restaurant_ratings Users can delete their own ratings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete their own ratings" ON public.restaurant_ratings FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: favorites Users can insert favorites; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert favorites" ON public.favorites FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_addresses Users can insert own addresses; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert own addresses" ON public.user_addresses FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: favorite_restaurants Users can insert own favorite restaurants; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert own favorite restaurants" ON public.favorite_restaurants FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_addresses Users can insert their own addresses; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert their own addresses" ON public.user_addresses FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));


--
-- Name: cart_items Users can insert their own cart items; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert their own cart items" ON public.cart_items FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_category_preferences Users can insert their own category preferences; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert their own category preferences" ON public.user_category_preferences FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));


--
-- Name: orders Users can insert their own orders; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert their own orders" ON public.orders FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));


--
-- Name: meal_reports Users can insert their own reports; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert their own reports" ON public.meal_reports FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));


--
-- Name: restaurant_ratings Users can rate their completed orders; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can rate their completed orders" ON public.restaurant_ratings FOR INSERT WITH CHECK (((auth.uid() = user_id) AND (EXISTS ( SELECT 1
   FROM public.orders
  WHERE ((orders.id = restaurant_ratings.order_id) AND (orders.user_id = auth.uid()) AND (orders.status = ANY (ARRAY['delivered'::public.order_status, 'completed'::public.order_status])))))));


--
-- Name: favorites Users can read favorites; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can read favorites" ON public.favorites FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: messages Users can send messages in their conversations; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can send messages in their conversations" ON public.messages FOR INSERT TO authenticated WITH CHECK (((sender_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.conversations
  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.ngo_id = auth.uid()) OR (conversations.restaurant_id = auth.uid())))))));


--
-- Name: favorites Users can update favorites; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update favorites" ON public.favorites FOR UPDATE USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_addresses Users can update own addresses; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update own addresses" ON public.user_addresses FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: restaurants Users can update own restaurant; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update own restaurant" ON public.restaurants FOR UPDATE USING ((auth.uid() = profile_id));


--
-- Name: user_addresses Users can update their own addresses; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own addresses" ON public.user_addresses FOR UPDATE TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: cart_items Users can update their own cart items; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own cart items" ON public.cart_items FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: user_category_preferences Users can update their own category preferences; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own category preferences" ON public.user_category_preferences FOR UPDATE TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: free_meal_user_notifications Users can update their own free meal notifications; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own free meal notifications" ON public.free_meal_user_notifications FOR UPDATE TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: messages Users can update their own messages; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own messages" ON public.messages FOR UPDATE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.conversations
  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.ngo_id = auth.uid()) OR (conversations.restaurant_id = auth.uid())))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.conversations
  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.ngo_id = auth.uid()) OR (conversations.restaurant_id = auth.uid()))))));


--
-- Name: category_notifications Users can update their own notifications; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own notifications" ON public.category_notifications FOR UPDATE TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: orders Users can update their own orders; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own orders" ON public.orders FOR UPDATE TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: restaurant_ratings Users can update their own ratings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own ratings" ON public.restaurant_ratings FOR UPDATE USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: meals Users can view active meals; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view active meals" ON public.meals FOR SELECT TO authenticated USING ((((status = 'active'::text) OR (status IS NULL)) AND (quantity_available > 0) AND (expiry_date > now())));


--
-- Name: free_meal_notifications Users can view free meal notifications; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view free meal notifications" ON public.free_meal_notifications FOR SELECT TO authenticated USING (true);


--
-- Name: messages Users can view messages in their conversations; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view messages in their conversations" ON public.messages FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.conversations
  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.ngo_id = auth.uid()) OR (conversations.restaurant_id = auth.uid()))))));


--
-- Name: user_addresses Users can view own addresses; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own addresses" ON public.user_addresses FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: user_badges Users can view own badges; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own badges" ON public.user_badges FOR SELECT TO authenticated USING ((auth.uid() = user_id));


--
-- Name: favorite_restaurants Users can view own favorite restaurants; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own favorite restaurants" ON public.favorite_restaurants FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: order_issues Users can view own issues; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own issues" ON public.order_issues FOR SELECT TO authenticated USING ((auth.uid() = user_id));


--
-- Name: user_loyalty Users can view own loyalty profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own loyalty profile" ON public.user_loyalty FOR SELECT TO authenticated USING ((auth.uid() = user_id));


--
-- Name: payments Users can view own payments; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own payments" ON public.payments FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.orders
  WHERE ((orders.id = payments.order_id) AND (orders.user_id = auth.uid())))));


--
-- Name: restaurants Users can view own restaurant; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own restaurant" ON public.restaurants FOR SELECT USING ((auth.uid() = profile_id));


--
-- Name: user_rewards Users can view own rewards; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own rewards" ON public.user_rewards FOR SELECT TO authenticated USING ((auth.uid() = user_id));


--
-- Name: loyalty_transactions Users can view own transactions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own transactions" ON public.loyalty_transactions FOR SELECT TO authenticated USING ((auth.uid() = user_id));


--
-- Name: orders Users can view their orders; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their orders" ON public.orders FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: POLICY "Users can view their orders" ON orders; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON POLICY "Users can view their orders" ON public.orders IS 'Allows users to view their own orders';


--
-- Name: user_addresses Users can view their own addresses; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their own addresses" ON public.user_addresses FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: cart_items Users can view their own cart items; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their own cart items" ON public.cart_items FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: user_category_preferences Users can view their own category preferences; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their own category preferences" ON public.user_category_preferences FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: conversations Users can view their own conversations; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their own conversations" ON public.conversations FOR SELECT TO authenticated USING (((ngo_id = auth.uid()) OR (restaurant_id = auth.uid())));


--
-- Name: free_meal_user_notifications Users can view their own free meal notifications; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their own free meal notifications" ON public.free_meal_user_notifications FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: category_notifications Users can view their own notifications; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their own notifications" ON public.category_notifications FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: meal_reports Users can view their own reports; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their own reports" ON public.meal_reports FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: email_logs Users view own logs; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users view own logs" ON public.email_logs FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.orders o
  WHERE ((o.id = email_logs.order_id) AND (o.user_id = auth.uid())))));


--
-- Name: cart_items; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

--
-- Name: category_notifications; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.category_notifications ENABLE ROW LEVEL SECURITY;

--
-- Name: conversations; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

--
-- Name: email_logs; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.email_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: email_queue; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.email_queue ENABLE ROW LEVEL SECURITY;

--
-- Name: favorite_restaurants; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.favorite_restaurants ENABLE ROW LEVEL SECURITY;

--
-- Name: favorites; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

--
-- Name: free_meal_notifications; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.free_meal_notifications ENABLE ROW LEVEL SECURITY;

--
-- Name: free_meal_user_notifications; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.free_meal_user_notifications ENABLE ROW LEVEL SECURITY;

--
-- Name: loyalty_transactions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.loyalty_transactions ENABLE ROW LEVEL SECURITY;

--
-- Name: meal_reports; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.meal_reports ENABLE ROW LEVEL SECURITY;

--
-- Name: meals; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.meals ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: ngos ngos_select_owner; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY ngos_select_owner ON public.ngos FOR SELECT TO authenticated USING (((profile_id = auth.uid()) OR public.is_admin()));


--
-- Name: ngos ngos_select_public_approved; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY ngos_select_public_approved ON public.ngos FOR SELECT TO authenticated, anon USING ((EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = ngos.profile_id) AND (p.approval_status = 'approved'::text)))));


--
-- Name: ngos ngos_update_owner; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY ngos_update_owner ON public.ngos FOR UPDATE TO authenticated USING (((profile_id = auth.uid()) OR public.is_admin())) WITH CHECK (((profile_id = auth.uid()) OR public.is_admin()));


--
-- Name: order_issues; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.order_issues ENABLE ROW LEVEL SECURITY;

--
-- Name: order_items; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

--
-- Name: order_items order_items_insert_users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY order_items_insert_users ON public.order_items FOR INSERT TO authenticated WITH CHECK ((order_id IN ( SELECT orders.id
   FROM public.orders
  WHERE (orders.user_id = auth.uid()))));


--
-- Name: order_items order_items_select_ngos; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY order_items_select_ngos ON public.order_items FOR SELECT TO authenticated USING ((order_id IN ( SELECT orders.id
   FROM public.orders
  WHERE (orders.ngo_id = auth.uid()))));


--
-- Name: POLICY order_items_select_ngos ON order_items; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON POLICY order_items_select_ngos ON public.order_items IS 'NGOs can view their order items - uses IN subquery to prevent recursion';


--
-- Name: order_items order_items_select_restaurants; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY order_items_select_restaurants ON public.order_items FOR SELECT TO authenticated USING ((order_id IN ( SELECT orders.id
   FROM public.orders
  WHERE (orders.restaurant_id = auth.uid()))));


--
-- Name: POLICY order_items_select_restaurants ON order_items; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON POLICY order_items_select_restaurants ON public.order_items IS 'Restaurants can view their order items - uses IN subquery to prevent recursion';


--
-- Name: order_items order_items_select_users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY order_items_select_users ON public.order_items FOR SELECT TO authenticated USING ((order_id IN ( SELECT orders.id
   FROM public.orders
  WHERE (orders.user_id = auth.uid()))));


--
-- Name: POLICY order_items_select_users ON order_items; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON POLICY order_items_select_users ON public.order_items IS 'Users can view their order items - uses IN subquery to prevent recursion when querying orders with nested order_items';


--
-- Name: order_status_history; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;

--
-- Name: order_status_history order_status_history_insert_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY order_status_history_insert_all ON public.order_status_history FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: order_status_history order_status_history_insert_restaurants; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY order_status_history_insert_restaurants ON public.order_status_history FOR INSERT TO authenticated WITH CHECK ((order_id IN ( SELECT orders.id
   FROM public.orders
  WHERE (orders.restaurant_id = auth.uid()))));


--
-- Name: order_status_history order_status_history_select_restaurants; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY order_status_history_select_restaurants ON public.order_status_history FOR SELECT TO authenticated USING ((order_id IN ( SELECT orders.id
   FROM public.orders
  WHERE (orders.restaurant_id = auth.uid()))));


--
-- Name: POLICY order_status_history_select_restaurants ON order_status_history; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON POLICY order_status_history_select_restaurants ON public.order_status_history IS 'Restaurants can view order history - uses IN subquery to prevent recursion';


--
-- Name: order_status_history order_status_history_select_users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY order_status_history_select_users ON public.order_status_history FOR SELECT TO authenticated USING ((order_id IN ( SELECT orders.id
   FROM public.orders
  WHERE (orders.user_id = auth.uid()))));


--
-- Name: POLICY order_status_history_select_users ON order_status_history; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON POLICY order_status_history_select_users ON public.order_status_history IS 'Users can view order history - uses IN subquery to prevent recursion';


--
-- Name: orders; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

--
-- Name: payments; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles profiles_insert_service; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_insert_service ON public.profiles FOR INSERT TO service_role WITH CHECK (true);


--
-- Name: profiles profiles_insert_users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_insert_users ON public.profiles FOR INSERT TO authenticated WITH CHECK ((id = auth.uid()));


--
-- Name: profiles profiles_select_approved; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_select_approved ON public.profiles FOR SELECT TO authenticated, anon USING ((approval_status = 'approved'::text));


--
-- Name: POLICY profiles_select_approved ON profiles; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON POLICY profiles_select_approved ON public.profiles IS 'Public can view approved profiles - direct check, no function calls';


--
-- Name: profiles profiles_select_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_select_own ON public.profiles FOR SELECT TO authenticated USING ((id = auth.uid()));


--
-- Name: POLICY profiles_select_own ON profiles; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON POLICY profiles_select_own ON public.profiles IS 'Users can view their own profile - direct check, no function calls, prevents recursion';


--
-- Name: profiles profiles_update_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_update_own ON public.profiles FOR UPDATE TO authenticated USING ((id = auth.uid())) WITH CHECK ((id = auth.uid()));


--
-- Name: POLICY profiles_update_own ON profiles; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON POLICY profiles_update_own ON public.profiles IS 'Users can update their own profile - direct check, no is_admin() call';


--
-- Name: restaurant_ratings; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.restaurant_ratings ENABLE ROW LEVEL SECURITY;

--
-- Name: rewards_catalog; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.rewards_catalog ENABLE ROW LEVEL SECURITY;

--
-- Name: rush_hours; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.rush_hours ENABLE ROW LEVEL SECURITY;

--
-- Name: user_addresses; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_addresses ENABLE ROW LEVEL SECURITY;

--
-- Name: user_badges; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;

--
-- Name: user_category_preferences; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_category_preferences ENABLE ROW LEVEL SECURITY;

--
-- Name: user_loyalty; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_loyalty ENABLE ROW LEVEL SECURITY;

--
-- Name: user_rewards; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_rewards ENABLE ROW LEVEL SECURITY;

--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;


--
-- Name: FUNCTION append_ngo_legal_doc(p_url text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.append_ngo_legal_doc(p_url text) TO anon;
GRANT ALL ON FUNCTION public.append_ngo_legal_doc(p_url text) TO authenticated;
GRANT ALL ON FUNCTION public.append_ngo_legal_doc(p_url text) TO service_role;


--
-- Name: FUNCTION append_restaurant_legal_doc(p_url text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.append_restaurant_legal_doc(p_url text) TO anon;
GRANT ALL ON FUNCTION public.append_restaurant_legal_doc(p_url text) TO authenticated;
GRANT ALL ON FUNCTION public.append_restaurant_legal_doc(p_url text) TO service_role;


--
-- Name: FUNCTION auto_generate_order_codes(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.auto_generate_order_codes() TO anon;
GRANT ALL ON FUNCTION public.auto_generate_order_codes() TO authenticated;
GRANT ALL ON FUNCTION public.auto_generate_order_codes() TO service_role;


--
-- Name: FUNCTION award_order_points(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.award_order_points() TO anon;
GRANT ALL ON FUNCTION public.award_order_points() TO authenticated;
GRANT ALL ON FUNCTION public.award_order_points() TO service_role;


--
-- Name: FUNCTION calculate_effective_price(p_meal_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.calculate_effective_price(p_meal_id uuid) TO anon;
GRANT ALL ON FUNCTION public.calculate_effective_price(p_meal_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.calculate_effective_price(p_meal_id uuid) TO service_role;


--
-- Name: FUNCTION can_rate_order(p_order_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.can_rate_order(p_order_id uuid) TO anon;
GRANT ALL ON FUNCTION public.can_rate_order(p_order_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.can_rate_order(p_order_id uuid) TO service_role;


--
-- Name: FUNCTION check_and_award_badges(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.check_and_award_badges(p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.check_and_award_badges(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.check_and_award_badges(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION complete_pickup(p_order_id uuid, p_pickup_code text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.complete_pickup(p_order_id uuid, p_pickup_code text) TO anon;
GRANT ALL ON FUNCTION public.complete_pickup(p_order_id uuid, p_pickup_code text) TO authenticated;
GRANT ALL ON FUNCTION public.complete_pickup(p_order_id uuid, p_pickup_code text) TO service_role;


--
-- Name: FUNCTION complete_restaurant_setup(p_user_id uuid, p_full_name text, p_email text, p_org_name text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.complete_restaurant_setup(p_user_id uuid, p_full_name text, p_email text, p_org_name text) TO anon;
GRANT ALL ON FUNCTION public.complete_restaurant_setup(p_user_id uuid, p_full_name text, p_email text, p_org_name text) TO authenticated;
GRANT ALL ON FUNCTION public.complete_restaurant_setup(p_user_id uuid, p_full_name text, p_email text, p_org_name text) TO service_role;


--
-- Name: FUNCTION create_meal_notifications(p_meal_id uuid, p_category text, p_restaurant_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.create_meal_notifications(p_meal_id uuid, p_category text, p_restaurant_id uuid) TO anon;
GRANT ALL ON FUNCTION public.create_meal_notifications(p_meal_id uuid, p_category text, p_restaurant_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.create_meal_notifications(p_meal_id uuid, p_category text, p_restaurant_id uuid) TO service_role;


--
-- Name: FUNCTION decrement_meal_quantity(meal_id uuid, qty integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.decrement_meal_quantity(meal_id uuid, qty integer) TO anon;
GRANT ALL ON FUNCTION public.decrement_meal_quantity(meal_id uuid, qty integer) TO authenticated;
GRANT ALL ON FUNCTION public.decrement_meal_quantity(meal_id uuid, qty integer) TO service_role;


--
-- Name: FUNCTION donate_meal(p_meal_id uuid, p_restaurant_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.donate_meal(p_meal_id uuid, p_restaurant_id uuid) TO anon;
GRANT ALL ON FUNCTION public.donate_meal(p_meal_id uuid, p_restaurant_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.donate_meal(p_meal_id uuid, p_restaurant_id uuid) TO service_role;


--
-- Name: FUNCTION ensure_restaurant_details_on_profile(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.ensure_restaurant_details_on_profile() TO anon;
GRANT ALL ON FUNCTION public.ensure_restaurant_details_on_profile() TO authenticated;
GRANT ALL ON FUNCTION public.ensure_restaurant_details_on_profile() TO service_role;


--
-- Name: FUNCTION generate_order_number(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.generate_order_number() TO anon;
GRANT ALL ON FUNCTION public.generate_order_number() TO authenticated;
GRANT ALL ON FUNCTION public.generate_order_number() TO service_role;


--
-- Name: FUNCTION generate_pickup_code(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.generate_pickup_code() TO anon;
GRANT ALL ON FUNCTION public.generate_pickup_code() TO authenticated;
GRANT ALL ON FUNCTION public.generate_pickup_code() TO service_role;


--
-- Name: FUNCTION generate_qr_code_data(order_uuid uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.generate_qr_code_data(order_uuid uuid) TO anon;
GRANT ALL ON FUNCTION public.generate_qr_code_data(order_uuid uuid) TO authenticated;
GRANT ALL ON FUNCTION public.generate_qr_code_data(order_uuid uuid) TO service_role;


--
-- Name: FUNCTION get_approved_ngos(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_approved_ngos() TO anon;
GRANT ALL ON FUNCTION public.get_approved_ngos() TO authenticated;
GRANT ALL ON FUNCTION public.get_approved_ngos() TO service_role;


--
-- Name: FUNCTION get_free_meal_notifications(p_user_id uuid, p_limit integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_free_meal_notifications(p_user_id uuid, p_limit integer) TO anon;
GRANT ALL ON FUNCTION public.get_free_meal_notifications(p_user_id uuid, p_limit integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_free_meal_notifications(p_user_id uuid, p_limit integer) TO service_role;


--
-- Name: FUNCTION get_meals_with_effective_discount(p_restaurant_id uuid, p_category text, p_limit integer, p_offset integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_meals_with_effective_discount(p_restaurant_id uuid, p_category text, p_limit integer, p_offset integer) TO anon;
GRANT ALL ON FUNCTION public.get_meals_with_effective_discount(p_restaurant_id uuid, p_category text, p_limit integer, p_offset integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_meals_with_effective_discount(p_restaurant_id uuid, p_category text, p_limit integer, p_offset integer) TO service_role;


--
-- Name: FUNCTION get_my_restaurant_rank(period_filter text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_my_restaurant_rank(period_filter text) TO anon;
GRANT ALL ON FUNCTION public.get_my_restaurant_rank(period_filter text) TO authenticated;
GRANT ALL ON FUNCTION public.get_my_restaurant_rank(period_filter text) TO service_role;


--
-- Name: FUNCTION get_my_rush_hour(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_my_rush_hour() TO anon;
GRANT ALL ON FUNCTION public.get_my_rush_hour() TO authenticated;
GRANT ALL ON FUNCTION public.get_my_rush_hour() TO service_role;


--
-- Name: FUNCTION get_pending_emails(p_limit integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_pending_emails(p_limit integer) TO anon;
GRANT ALL ON FUNCTION public.get_pending_emails(p_limit integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_pending_emails(p_limit integer) TO service_role;


--
-- Name: FUNCTION get_restaurant_leaderboard(period_filter text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_restaurant_leaderboard(period_filter text) TO anon;
GRANT ALL ON FUNCTION public.get_restaurant_leaderboard(period_filter text) TO authenticated;
GRANT ALL ON FUNCTION public.get_restaurant_leaderboard(period_filter text) TO service_role;


--
-- Name: FUNCTION get_restaurant_ratings(p_restaurant_id uuid, p_limit integer, p_offset integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_restaurant_ratings(p_restaurant_id uuid, p_limit integer, p_offset integer) TO anon;
GRANT ALL ON FUNCTION public.get_restaurant_ratings(p_restaurant_id uuid, p_limit integer, p_offset integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_restaurant_ratings(p_restaurant_id uuid, p_limit integer, p_offset integer) TO service_role;


--
-- Name: FUNCTION handle_address_deletion(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.handle_address_deletion() TO anon;
GRANT ALL ON FUNCTION public.handle_address_deletion() TO authenticated;
GRANT ALL ON FUNCTION public.handle_address_deletion() TO service_role;


--
-- Name: FUNCTION handle_new_user(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.handle_new_user() TO anon;
GRANT ALL ON FUNCTION public.handle_new_user() TO authenticated;
GRANT ALL ON FUNCTION public.handle_new_user() TO service_role;


--
-- Name: FUNCTION increment_meal_quantity(meal_id uuid, qty integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.increment_meal_quantity(meal_id uuid, qty integer) TO anon;
GRANT ALL ON FUNCTION public.increment_meal_quantity(meal_id uuid, qty integer) TO authenticated;
GRANT ALL ON FUNCTION public.increment_meal_quantity(meal_id uuid, qty integer) TO service_role;


--
-- Name: FUNCTION initialize_user_loyalty(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.initialize_user_loyalty() TO anon;
GRANT ALL ON FUNCTION public.initialize_user_loyalty() TO authenticated;
GRANT ALL ON FUNCTION public.initialize_user_loyalty() TO service_role;


--
-- Name: FUNCTION is_admin(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_admin() TO anon;
GRANT ALL ON FUNCTION public.is_admin() TO authenticated;
GRANT ALL ON FUNCTION public.is_admin() TO service_role;


--
-- Name: FUNCTION log_order_status_change(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.log_order_status_change() TO anon;
GRANT ALL ON FUNCTION public.log_order_status_change() TO authenticated;
GRANT ALL ON FUNCTION public.log_order_status_change() TO service_role;


--
-- Name: FUNCTION notify_category_subscribers(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.notify_category_subscribers() TO anon;
GRANT ALL ON FUNCTION public.notify_category_subscribers() TO authenticated;
GRANT ALL ON FUNCTION public.notify_category_subscribers() TO service_role;


--
-- Name: FUNCTION notify_restaurant_of_issue(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.notify_restaurant_of_issue() TO anon;
GRANT ALL ON FUNCTION public.notify_restaurant_of_issue() TO authenticated;
GRANT ALL ON FUNCTION public.notify_restaurant_of_issue() TO service_role;


--
-- Name: FUNCTION prevent_role_update(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.prevent_role_update() TO anon;
GRANT ALL ON FUNCTION public.prevent_role_update() TO authenticated;
GRANT ALL ON FUNCTION public.prevent_role_update() TO service_role;


--
-- Name: FUNCTION process_email_queue_item(p_email_id uuid, p_success boolean, p_error_message text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.process_email_queue_item(p_email_id uuid, p_success boolean, p_error_message text) TO anon;
GRANT ALL ON FUNCTION public.process_email_queue_item(p_email_id uuid, p_success boolean, p_error_message text) TO authenticated;
GRANT ALL ON FUNCTION public.process_email_queue_item(p_email_id uuid, p_success boolean, p_error_message text) TO service_role;


--
-- Name: FUNCTION provision_auth_user(p_role text, p_full_name text, p_phone_number text, p_organization_name text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.provision_auth_user(p_role text, p_full_name text, p_phone_number text, p_organization_name text) TO anon;
GRANT ALL ON FUNCTION public.provision_auth_user(p_role text, p_full_name text, p_phone_number text, p_organization_name text) TO authenticated;
GRANT ALL ON FUNCTION public.provision_auth_user(p_role text, p_full_name text, p_phone_number text, p_organization_name text) TO service_role;


--
-- Name: FUNCTION queue_order_emails(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.queue_order_emails() TO anon;
GRANT ALL ON FUNCTION public.queue_order_emails() TO authenticated;
GRANT ALL ON FUNCTION public.queue_order_emails() TO service_role;


--
-- Name: FUNCTION redeem_reward(p_user_id uuid, p_reward_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.redeem_reward(p_user_id uuid, p_reward_id uuid) TO anon;
GRANT ALL ON FUNCTION public.redeem_reward(p_user_id uuid, p_reward_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.redeem_reward(p_user_id uuid, p_reward_id uuid) TO service_role;


--
-- Name: FUNCTION safe_delete_meal(p_meal_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.safe_delete_meal(p_meal_id uuid) TO anon;
GRANT ALL ON FUNCTION public.safe_delete_meal(p_meal_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.safe_delete_meal(p_meal_id uuid) TO service_role;


--
-- Name: FUNCTION set_rush_hour_settings(p_is_active boolean, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_discount_percentage integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.set_rush_hour_settings(p_is_active boolean, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_discount_percentage integer) TO anon;
GRANT ALL ON FUNCTION public.set_rush_hour_settings(p_is_active boolean, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_discount_percentage integer) TO authenticated;
GRANT ALL ON FUNCTION public.set_rush_hour_settings(p_is_active boolean, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_discount_percentage integer) TO service_role;


--
-- Name: FUNCTION set_updated_at(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.set_updated_at() TO anon;
GRANT ALL ON FUNCTION public.set_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.set_updated_at() TO service_role;


--
-- Name: FUNCTION submit_restaurant_rating(p_order_id uuid, p_rating integer, p_review_text text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.submit_restaurant_rating(p_order_id uuid, p_rating integer, p_review_text text) TO anon;
GRANT ALL ON FUNCTION public.submit_restaurant_rating(p_order_id uuid, p_rating integer, p_review_text text) TO authenticated;
GRANT ALL ON FUNCTION public.submit_restaurant_rating(p_order_id uuid, p_rating integer, p_review_text text) TO service_role;


--
-- Name: FUNCTION sync_profile_emails(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.sync_profile_emails() TO anon;
GRANT ALL ON FUNCTION public.sync_profile_emails() TO authenticated;
GRANT ALL ON FUNCTION public.sync_profile_emails() TO service_role;


--
-- Name: FUNCTION sync_user_verification(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.sync_user_verification() TO anon;
GRANT ALL ON FUNCTION public.sync_user_verification() TO authenticated;
GRANT ALL ON FUNCTION public.sync_user_verification() TO service_role;


--
-- Name: FUNCTION update_cart_items_updated_at(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_cart_items_updated_at() TO anon;
GRANT ALL ON FUNCTION public.update_cart_items_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.update_cart_items_updated_at() TO service_role;


--
-- Name: FUNCTION update_conversation_last_message(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_conversation_last_message() TO anon;
GRANT ALL ON FUNCTION public.update_conversation_last_message() TO authenticated;
GRANT ALL ON FUNCTION public.update_conversation_last_message() TO service_role;


--
-- Name: FUNCTION update_order_issue_timestamp(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_order_issue_timestamp() TO anon;
GRANT ALL ON FUNCTION public.update_order_issue_timestamp() TO authenticated;
GRANT ALL ON FUNCTION public.update_order_issue_timestamp() TO service_role;


--
-- Name: FUNCTION update_profile_default_location(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_profile_default_location() TO anon;
GRANT ALL ON FUNCTION public.update_profile_default_location() TO authenticated;
GRANT ALL ON FUNCTION public.update_profile_default_location() TO service_role;


--
-- Name: FUNCTION update_restaurant_rating(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_restaurant_rating() TO anon;
GRANT ALL ON FUNCTION public.update_restaurant_rating() TO authenticated;
GRANT ALL ON FUNCTION public.update_restaurant_rating() TO service_role;


--
-- Name: FUNCTION update_restaurant_rush_hour_flag(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_restaurant_rush_hour_flag() TO anon;
GRANT ALL ON FUNCTION public.update_restaurant_rush_hour_flag() TO authenticated;
GRANT ALL ON FUNCTION public.update_restaurant_rush_hour_flag() TO service_role;


--
-- Name: FUNCTION update_updated_at_column(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_updated_at_column() TO anon;
GRANT ALL ON FUNCTION public.update_updated_at_column() TO authenticated;
GRANT ALL ON FUNCTION public.update_updated_at_column() TO service_role;


--
-- Name: FUNCTION update_user_tier(p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_user_tier(p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.update_user_tier(p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.update_user_tier(p_user_id uuid) TO service_role;


--
-- Name: FUNCTION verify_pickup_code(p_order_id uuid, p_pickup_code text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.verify_pickup_code(p_order_id uuid, p_pickup_code text) TO anon;
GRANT ALL ON FUNCTION public.verify_pickup_code(p_order_id uuid, p_pickup_code text) TO authenticated;
GRANT ALL ON FUNCTION public.verify_pickup_code(p_order_id uuid, p_pickup_code text) TO service_role;


--
-- Name: TABLE backup_profiles_role; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.backup_profiles_role TO anon;
GRANT ALL ON TABLE public.backup_profiles_role TO authenticated;
GRANT ALL ON TABLE public.backup_profiles_role TO service_role;


--
-- Name: TABLE cart_items; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.cart_items TO anon;
GRANT ALL ON TABLE public.cart_items TO authenticated;
GRANT ALL ON TABLE public.cart_items TO service_role;


--
-- Name: TABLE category_notifications; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.category_notifications TO anon;
GRANT ALL ON TABLE public.category_notifications TO authenticated;
GRANT ALL ON TABLE public.category_notifications TO service_role;


--
-- Name: TABLE conversations; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.conversations TO anon;
GRANT ALL ON TABLE public.conversations TO authenticated;
GRANT ALL ON TABLE public.conversations TO service_role;


--
-- Name: TABLE messages; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.messages TO anon;
GRANT ALL ON TABLE public.messages TO authenticated;
GRANT ALL ON TABLE public.messages TO service_role;


--
-- Name: TABLE profiles; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profiles TO anon;
GRANT ALL ON TABLE public.profiles TO authenticated;
GRANT ALL ON TABLE public.profiles TO service_role;


--
-- Name: TABLE restaurants; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.restaurants TO anon;
GRANT ALL ON TABLE public.restaurants TO authenticated;
GRANT ALL ON TABLE public.restaurants TO service_role;


--
-- Name: TABLE conversation_details; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.conversation_details TO anon;
GRANT ALL ON TABLE public.conversation_details TO authenticated;
GRANT ALL ON TABLE public.conversation_details TO service_role;


--
-- Name: TABLE email_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.email_logs TO anon;
GRANT ALL ON TABLE public.email_logs TO authenticated;
GRANT ALL ON TABLE public.email_logs TO service_role;


--
-- Name: TABLE email_queue; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.email_queue TO anon;
GRANT ALL ON TABLE public.email_queue TO authenticated;
GRANT ALL ON TABLE public.email_queue TO service_role;


--
-- Name: TABLE favorite_restaurants; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.favorite_restaurants TO anon;
GRANT ALL ON TABLE public.favorite_restaurants TO authenticated;
GRANT ALL ON TABLE public.favorite_restaurants TO service_role;


--
-- Name: TABLE favorites; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.favorites TO anon;
GRANT ALL ON TABLE public.favorites TO authenticated;
GRANT ALL ON TABLE public.favorites TO service_role;


--
-- Name: TABLE free_meal_notifications; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.free_meal_notifications TO anon;
GRANT ALL ON TABLE public.free_meal_notifications TO authenticated;
GRANT ALL ON TABLE public.free_meal_notifications TO service_role;


--
-- Name: TABLE free_meal_user_notifications; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.free_meal_user_notifications TO anon;
GRANT ALL ON TABLE public.free_meal_user_notifications TO authenticated;
GRANT ALL ON TABLE public.free_meal_user_notifications TO service_role;


--
-- Name: TABLE loyalty_transactions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.loyalty_transactions TO anon;
GRANT ALL ON TABLE public.loyalty_transactions TO authenticated;
GRANT ALL ON TABLE public.loyalty_transactions TO service_role;


--
-- Name: TABLE meal_reports; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.meal_reports TO anon;
GRANT ALL ON TABLE public.meal_reports TO authenticated;
GRANT ALL ON TABLE public.meal_reports TO service_role;


--
-- Name: TABLE meal_reports_summary; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.meal_reports_summary TO anon;
GRANT ALL ON TABLE public.meal_reports_summary TO authenticated;
GRANT ALL ON TABLE public.meal_reports_summary TO service_role;


--
-- Name: TABLE meals; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.meals TO anon;
GRANT ALL ON TABLE public.meals TO authenticated;
GRANT ALL ON TABLE public.meals TO service_role;


--
-- Name: TABLE rush_hours; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.rush_hours TO anon;
GRANT ALL ON TABLE public.rush_hours TO authenticated;
GRANT ALL ON TABLE public.rush_hours TO service_role;


--
-- Name: TABLE meals_with_effective_discount; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.meals_with_effective_discount TO anon;
GRANT ALL ON TABLE public.meals_with_effective_discount TO authenticated;
GRANT ALL ON TABLE public.meals_with_effective_discount TO service_role;


--
-- Name: TABLE ngos; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.ngos TO anon;
GRANT ALL ON TABLE public.ngos TO authenticated;
GRANT ALL ON TABLE public.ngos TO service_role;


--
-- Name: TABLE order_issues; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.order_issues TO anon;
GRANT ALL ON TABLE public.order_issues TO authenticated;
GRANT ALL ON TABLE public.order_issues TO service_role;


--
-- Name: TABLE order_items; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.order_items TO anon;
GRANT ALL ON TABLE public.order_items TO authenticated;
GRANT ALL ON TABLE public.order_items TO service_role;


--
-- Name: TABLE order_status_history; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.order_status_history TO anon;
GRANT ALL ON TABLE public.order_status_history TO authenticated;
GRANT ALL ON TABLE public.order_status_history TO service_role;


--
-- Name: TABLE orders; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.orders TO anon;
GRANT ALL ON TABLE public.orders TO authenticated;
GRANT ALL ON TABLE public.orders TO service_role;


--
-- Name: SEQUENCE orders_order_code_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.orders_order_code_seq TO anon;
GRANT ALL ON SEQUENCE public.orders_order_code_seq TO authenticated;
GRANT ALL ON SEQUENCE public.orders_order_code_seq TO service_role;


--
-- Name: TABLE payments; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.payments TO anon;
GRANT ALL ON TABLE public.payments TO authenticated;
GRANT ALL ON TABLE public.payments TO service_role;


--
-- Name: TABLE restaurant_ratings; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.restaurant_ratings TO anon;
GRANT ALL ON TABLE public.restaurant_ratings TO authenticated;
GRANT ALL ON TABLE public.restaurant_ratings TO service_role;


--
-- Name: TABLE rewards_catalog; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.rewards_catalog TO anon;
GRANT ALL ON TABLE public.rewards_catalog TO authenticated;
GRANT ALL ON TABLE public.rewards_catalog TO service_role;


--
-- Name: TABLE user_addresses; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_addresses TO anon;
GRANT ALL ON TABLE public.user_addresses TO authenticated;
GRANT ALL ON TABLE public.user_addresses TO service_role;


--
-- Name: TABLE user_badges; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_badges TO anon;
GRANT ALL ON TABLE public.user_badges TO authenticated;
GRANT ALL ON TABLE public.user_badges TO service_role;


--
-- Name: TABLE user_category_preferences; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_category_preferences TO anon;
GRANT ALL ON TABLE public.user_category_preferences TO authenticated;
GRANT ALL ON TABLE public.user_category_preferences TO service_role;


--
-- Name: TABLE user_loyalty; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_loyalty TO anon;
GRANT ALL ON TABLE public.user_loyalty TO authenticated;
GRANT ALL ON TABLE public.user_loyalty TO service_role;


--
-- Name: TABLE user_notifications_summary; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_notifications_summary TO anon;
GRANT ALL ON TABLE public.user_notifications_summary TO authenticated;
GRANT ALL ON TABLE public.user_notifications_summary TO service_role;


--
-- Name: TABLE user_rewards; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_rewards TO anon;
GRANT ALL ON TABLE public.user_rewards TO authenticated;
GRANT ALL ON TABLE public.user_rewards TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- PostgreSQL database dump complete
--

\unrestrict ntn6h8dTTI7vnJDI6o1WJMqijqg9Zfr7gxicuaCcy2JxK4Z6znsHyZzXHFD7Fqn

