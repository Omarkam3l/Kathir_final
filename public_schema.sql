--
-- PostgreSQL database dump
--

\restrict 4d8CzWtjKJ5MPkGvmFmHyEZoOUfNxspYvq7rDEdvEtNZXi7YnyisP2joMti0off

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
    RAISE EXCEPTION 'NGO record not found for user %', v_profile_id;
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

COMMENT ON FUNCTION public.append_ngo_legal_doc(p_url text) IS 'Atomically appends a legal document URL to ngos.legal_docs_urls array. Only the authenticated user can update their own record.';


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
    RAISE EXCEPTION 'Restaurant record not found for user %', v_profile_id;
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

COMMENT ON FUNCTION public.append_restaurant_legal_doc(p_url text) IS 'Atomically appends a legal document URL to restaurants.legal_docs_urls array. Only the authenticated user can update their own record.';


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
    AND eq.attempts < 3  -- Max 3 attempts
  ORDER BY eq.created_at ASC
  LIMIT p_limit;
END;
$$;


ALTER FUNCTION public.get_pending_emails(p_limit integer) OWNER TO postgres;

--
-- Name: FUNCTION get_pending_emails(p_limit integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.get_pending_emails(p_limit integer) IS 'Returns pending emails to be processed by Edge Function.';


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
  user_role text;
  user_full_name text;
  user_phone text;
  org_name text;
  final_org_name text;
  profile_created boolean := false;
BEGIN
  -- Extract metadata from auth.users
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'user');
  user_full_name := COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'full_name'), ''), 'User');
  user_phone := NEW.raw_user_meta_data->>'phone_number';
  org_name := NEW.raw_user_meta_data->>'organization_name';

  -- Log trigger execution
  RAISE NOTICE 'handle_new_user triggered for user % with role %', NEW.id, user_role;

  -- Determine final organization name (never NULL or empty)
  IF user_role IN ('restaurant', 'ngo') THEN
    final_org_name := COALESCE(
      NULLIF(TRIM(org_name), ''),
      NULLIF(TRIM(user_full_name), ''),
      CASE 
        WHEN user_role = 'restaurant' THEN 'Restaurant ' || SUBSTRING(NEW.id::text, 1, 8)
        ELSE 'Organization ' || SUBSTRING(NEW.id::text, 1, 8)
      END
    );
  END IF;

  -- CRITICAL: Create profile record (must succeed)
  BEGIN
    INSERT INTO public.profiles (
      id, 
      email, 
      role, 
      full_name, 
      phone_number, 
      is_verified,
      approval_status,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      user_role,
      user_full_name,
      user_phone,
      CASE 
        WHEN user_role = 'user' THEN true 
        ELSE false 
      END,
      CASE 
        WHEN user_role IN ('restaurant', 'ngo') THEN 'pending'
        WHEN user_role = 'admin' THEN 'approved'
        ELSE 'approved'
      END,
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      role = EXCLUDED.role,
      full_name = EXCLUDED.full_name,
      phone_number = EXCLUDED.phone_number,
      updated_at = NOW();
    
    profile_created := true;
    RAISE NOTICE 'Profile created successfully for user %', NEW.id;
    
  EXCEPTION WHEN OTHERS THEN
    -- Profile creation is CRITICAL - must not fail
    RAISE WARNING 'CRITICAL: Failed to create profile for user %: % (SQLSTATE: %)', 
      NEW.id, SQLERRM, SQLSTATE;
    -- Re-raise to fail the signup
    RAISE;
  END;

  -- NON-CRITICAL: Create restaurant record (wrapped in exception)
  IF user_role = 'restaurant' AND profile_created THEN
    BEGIN
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
        final_org_name,
        ARRAY[]::text[],
        0,
        0,
        false
      )
      ON CONFLICT (profile_id) DO UPDATE SET
        restaurant_name = COALESCE(EXCLUDED.restaurant_name, public.restaurants.restaurant_name),
        updated_at = NOW();
      
      RAISE NOTICE 'Restaurant record created for user %', NEW.id;
      
    EXCEPTION WHEN OTHERS THEN
      -- Log warning but don't fail signup
      RAISE WARNING 'Failed to create restaurant record for user %: % (SQLSTATE: %)', 
        NEW.id, SQLERRM, SQLSTATE;
      -- Don't re-raise - allow signup to continue
    END;
  END IF;

  -- NON-CRITICAL: Create NGO record (wrapped in exception)
  IF user_role = 'ngo' AND profile_created THEN
    BEGIN
      INSERT INTO public.ngos (
        profile_id,
        organization_name,
        legal_docs_urls,
        created_at,
        updated_at
      )
      VALUES (
        NEW.id,
        final_org_name,
        ARRAY[]::text[],
        NOW(),
        NOW()
      )
      ON CONFLICT (profile_id) DO UPDATE SET
        organization_name = COALESCE(EXCLUDED.organization_name, public.ngos.organization_name),
        updated_at = NOW();
      
      RAISE NOTICE 'NGO record created for user %', NEW.id;
      
    EXCEPTION WHEN OTHERS THEN
      -- Log warning but don't fail signup
      RAISE WARNING 'Failed to create NGO record for user %: % (SQLSTATE: %)', 
        NEW.id, SQLERRM, SQLSTATE;
      -- Don't re-raise - allow signup to continue
    END;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

--
-- Name: FUNCTION handle_new_user(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.handle_new_user() IS 'Trigger function to auto-create profile and role-specific records on user signup. Profile creation is critical and will fail signup if it fails. Role table creation is non-critical and will only log warnings. Fixed to properly handle NGO table columns.';


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
BEGIN
  IF p_success THEN
    UPDATE email_queue
    SET 
      status = 'sent',
      sent_at = NOW(),
      updated_at = NOW()
    WHERE id = p_email_id;
  ELSE
    UPDATE email_queue
    SET 
      status = 'failed',
      attempts = attempts + 1,
      last_attempt_at = NOW(),
      error_message = p_error_message,
      updated_at = NOW()
    WHERE id = p_email_id;
  END IF;
END;
$$;


ALTER FUNCTION public.process_email_queue_item(p_email_id uuid, p_success boolean, p_error_message text) OWNER TO postgres;

--
-- Name: FUNCTION process_email_queue_item(p_email_id uuid, p_success boolean, p_error_message text); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.process_email_queue_item(p_email_id uuid, p_success boolean, p_error_message text) IS 'Marks an email as sent or failed. Called by Edge Function after sending.';


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
  -- If you want stricter logic, set it based on your app rules.
  v_is_verified := true;

  -- Approval status logic
  v_approval_status :=
    CASE
      WHEN v_role IN ('restaurant', 'ngo') THEN 'pending'
      WHEN v_role = 'admin' THEN 'approved'
      ELSE 'approved'
    END;

  -- 1) Upsert profile (CRITICAL)
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
      -- Do not fail provisioning if restaurant insert fails
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
      -- Do not fail provisioning if ngo insert fails
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
  v_buyer_type text;
BEGIN
  -- Get order details with all related data
  SELECT jsonb_build_object(
    'order_id', NEW.id,
    'order_number', NEW.id::text,
    'total_amount', NEW.total_amount,
    'delivery_type', NEW.delivery_type,
    'delivery_address', NEW.delivery_address,
    'created_at', NEW.created_at,
    'items', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'meal_title', m.title,
          'quantity', oi.quantity,
          'unit_price', oi.unit_price,
          'subtotal', oi.subtotal
        )
      )
      FROM order_items oi
      JOIN meals m ON oi.meal_id = m.id
      WHERE oi.order_id = NEW.id
    )
  ) INTO v_order_data;

  -- Get user/buyer details
  SELECT 
    p.email,
    p.full_name,
    p.role
  INTO 
    v_user_email,
    v_user_name,
    v_buyer_type
  FROM profiles p
  WHERE p.id = NEW.user_id;

  -- Get restaurant details
  SELECT 
    p.email,
    r.restaurant_name
  INTO 
    v_restaurant_email,
    v_restaurant_name
  FROM restaurants r
  JOIN profiles p ON r.profile_id = p.id
  WHERE r.profile_id = NEW.restaurant_id;

  -- Get NGO details if donation
  IF NEW.ngo_id IS NOT NULL THEN
    SELECT 
      p.email,
      p.full_name
    INTO 
      v_ngo_email,
      v_ngo_name
    FROM profiles p
    WHERE p.id = NEW.ngo_id;
  END IF;

  -- Add buyer and restaurant info to order data
  v_order_data := v_order_data || jsonb_build_object(
    'buyer_email', v_user_email,
    'buyer_name', v_user_name,
    'buyer_type', v_buyer_type,
    'restaurant_email', v_restaurant_email,
    'restaurant_name', v_restaurant_name,
    'ngo_email', v_ngo_email,
    'ngo_name', v_ngo_name
  );

  -- SCENARIO 1 & 2: User purchases (delivery/pickup or donate to NGO)
  IF v_buyer_type = 'user' THEN
    
    -- Email 1: Invoice to user
    INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
    VALUES (
      NEW.id,
      v_user_email,
      'user',
      'invoice',
      v_order_data
    );

    -- Email 2: New order notification to restaurant
    INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
    VALUES (
      NEW.id,
      v_restaurant_email,
      'restaurant',
      'new_order',
      v_order_data
    );

    -- Email 3: If donation, notify NGO
    IF NEW.ngo_id IS NOT NULL AND v_ngo_email IS NOT NULL THEN
      INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
      VALUES (
        NEW.id,
        v_ngo_email,
        'ngo',
        'ngo_pickup',
        v_order_data
      );
    END IF;

  -- SCENARIO 3: NGO purchases
  ELSIF v_buyer_type = 'ngo' THEN
    
    -- Email 1: New order notification to restaurant
    INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
    VALUES (
      NEW.id,
      v_restaurant_email,
      'restaurant',
      'new_order',
      v_order_data
    );

    -- Email 2: Confirmation to NGO
    INSERT INTO email_queue (order_id, recipient_email, recipient_type, email_type, email_data)
    VALUES (
      NEW.id,
      v_user_email,
      'ngo',
      'ngo_confirmation',
      v_order_data
    );

  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.queue_order_emails() OWNER TO postgres;

--
-- Name: FUNCTION queue_order_emails(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.queue_order_emails() IS 'Automatically queues emails when an order is created. 
Handles user purchases, donations, and NGO purchases.';


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
-- Name: sync_user_verification(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sync_user_verification() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF (OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL) THEN
    UPDATE public.profiles
    SET is_verified = true,
        updated_at = now()
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.sync_user_verification() OWNER TO postgres;

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
    user_id uuid,
    meal_id uuid,
    quantity integer DEFAULT 1,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.cart_items OWNER TO postgres;

--
-- Name: TABLE cart_items; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.cart_items IS 'Cart items table - cleaned up invalid price references on 2026-02-05';


--
-- Name: COLUMN cart_items.user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.cart_items.user_id IS 'User who owns this cart item';


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
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.restaurants OWNER TO postgres;

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
    last_attempt_at timestamp with time zone,
    sent_at timestamp with time zone,
    error_message text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT email_queue_email_type_check CHECK ((email_type = ANY (ARRAY['invoice'::text, 'new_order'::text, 'ngo_pickup'::text, 'ngo_confirmation'::text]))),
    CONSTRAINT email_queue_recipient_type_check CHECK ((recipient_type = ANY (ARRAY['user'::text, 'restaurant'::text, 'ngo'::text]))),
    CONSTRAINT email_queue_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'sent'::text, 'failed'::text])))
);


ALTER TABLE public.email_queue OWNER TO postgres;

--
-- Name: TABLE email_queue; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.email_queue IS 'Queue for order-related emails. Processed by Edge Function.';


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
-- Name: order_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid,
    meal_id uuid,
    meal_title text,
    quantity integer NOT NULL,
    unit_price numeric(12,2) NOT NULL
);


ALTER TABLE public.order_items OWNER TO postgres;

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
-- Name: cart_items cart_items_user_id_meal_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT cart_items_user_id_meal_id_key UNIQUE (user_id, meal_id);


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
-- Name: restaurants restaurants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.restaurants
    ADD CONSTRAINT restaurants_pkey PRIMARY KEY (profile_id);


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
-- Name: idx_cart_items_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cart_items_created_at ON public.cart_items USING btree (created_at DESC);


--
-- Name: idx_cart_items_meal_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cart_items_meal_id ON public.cart_items USING btree (meal_id);


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
-- Name: idx_email_queue_order_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_email_queue_order_id ON public.email_queue USING btree (order_id);


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
-- Name: idx_meals_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meals_created_at ON public.meals USING btree (created_at DESC);


--
-- Name: idx_meals_expiry_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meals_expiry_date ON public.meals USING btree (expiry_date);


--
-- Name: idx_meals_restaurant_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meals_restaurant_id ON public.meals USING btree (restaurant_id);


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
-- Name: idx_profiles_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profiles_role ON public.profiles USING btree (role);


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
-- Name: user_addresses trigger_handle_address_deletion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_handle_address_deletion BEFORE DELETE ON public.user_addresses FOR EACH ROW EXECUTE FUNCTION public.handle_address_deletion();


--
-- Name: orders trigger_log_order_status_change; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_log_order_status_change BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.log_order_status_change();


--
-- Name: orders trigger_queue_order_emails; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_queue_order_emails AFTER INSERT ON public.orders FOR EACH ROW EXECUTE FUNCTION public.queue_order_emails();


--
-- Name: user_addresses trigger_update_profile_default_location; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_update_profile_default_location AFTER INSERT OR UPDATE OF is_default, address_text ON public.user_addresses FOR EACH ROW EXECUTE FUNCTION public.update_profile_default_location();


--
-- Name: cart_items cart_items_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT cart_items_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES public.meals(id) ON DELETE CASCADE;


--
-- Name: cart_items cart_items_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cart_items
    ADD CONSTRAINT cart_items_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


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
-- Name: favorite_restaurants favorite_restaurants_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.favorite_restaurants
    ADD CONSTRAINT favorite_restaurants_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


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
-- Name: order_items order_items_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_meal_id_fkey FOREIGN KEY (meal_id) REFERENCES public.meals(id) ON DELETE SET NULL;


--
-- Name: CONSTRAINT order_items_meal_id_fkey ON order_items; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT order_items_meal_id_fkey ON public.order_items IS 'Foreign key to meals table for order item details';


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


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
-- Name: user_category_preferences user_category_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_category_preferences
    ADD CONSTRAINT user_category_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: order_status_history Allow status history inserts; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Allow status history inserts" ON public.order_status_history FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: meals Anonymous can view active meals; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anonymous can view active meals" ON public.meals FOR SELECT TO anon USING ((((status = 'active'::text) OR (status IS NULL)) AND (quantity_available > 0) AND (expiry_date > now())));


--
-- Name: ngos NGO owners can insert own details; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "NGO owners can insert own details" ON public.ngos FOR INSERT WITH CHECK ((auth.uid() = profile_id));


--
-- Name: ngos NGO owners can update own details; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "NGO owners can update own details" ON public.ngos FOR UPDATE USING ((auth.uid() = profile_id));


--
-- Name: ngos NGO owners can update own record; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "NGO owners can update own record" ON public.ngos FOR UPDATE TO authenticated USING (((auth.uid() = profile_id) OR public.is_admin())) WITH CHECK (((auth.uid() = profile_id) OR public.is_admin()));


--
-- Name: ngos NGO owners can view own record; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "NGO owners can view own record" ON public.ngos FOR SELECT TO authenticated USING (((auth.uid() = profile_id) OR public.is_admin()));


--
-- Name: conversations NGOs can create conversations; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "NGOs can create conversations" ON public.conversations FOR INSERT TO authenticated WITH CHECK ((ngo_id = auth.uid()));


--
-- Name: ngos NGOs can update their own profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "NGOs can update their own profile" ON public.ngos FOR UPDATE TO authenticated USING ((profile_id = auth.uid())) WITH CHECK ((profile_id = auth.uid()));


--
-- Name: orders NGOs can view their orders; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "NGOs can view their orders" ON public.orders FOR SELECT TO authenticated USING ((ngo_id = auth.uid()));


--
-- Name: ngos NGOs can view their own profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "NGOs can view their own profile" ON public.ngos FOR SELECT TO authenticated USING ((profile_id = auth.uid()));


--
-- Name: ngos NGOs: public browse approved; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "NGOs: public browse approved" ON public.ngos FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = ngos.profile_id) AND (p.approval_status = 'approved'::text)))));


--
-- Name: ngos NGOs: select own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "NGOs: select own" ON public.ngos FOR SELECT USING ((auth.uid() = profile_id));


--
-- Name: ngos NGOs: update own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "NGOs: update own" ON public.ngos FOR UPDATE USING ((auth.uid() = profile_id)) WITH CHECK ((auth.uid() = profile_id));


--
-- Name: profiles Profiles: select own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Profiles: select own" ON public.profiles FOR SELECT USING ((auth.uid() = id));


--
-- Name: profiles Profiles: update own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Profiles: update own" ON public.profiles FOR UPDATE USING ((auth.uid() = id)) WITH CHECK ((auth.uid() = id));


--
-- Name: ngos Public can view NGOs; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view NGOs" ON public.ngos FOR SELECT TO authenticated, anon USING (true);


--
-- Name: rush_hours Public can view active rush hours; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view active rush hours" ON public.rush_hours FOR SELECT TO authenticated, anon USING ((is_active = true));


--
-- Name: ngos Public can view approved ngos; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view approved ngos" ON public.ngos FOR SELECT TO authenticated, anon USING ((EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = ngos.profile_id) AND (p.approval_status = 'approved'::text)))));


--
-- Name: profiles Public can view approved profiles; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view approved profiles" ON public.profiles FOR SELECT TO authenticated, anon USING ((approval_status = 'approved'::text));


--
-- Name: restaurants Public can view approved restaurants; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view approved restaurants" ON public.restaurants FOR SELECT TO authenticated, anon USING ((EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = restaurants.profile_id) AND (p.approval_status = 'approved'::text)))));


--
-- Name: meals Public can view available meals; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view available meals" ON public.meals FOR SELECT TO authenticated, anon USING (((quantity_available > 0) AND (expiry_date > now())));


--
-- Name: ngos Public can view ngos; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view ngos" ON public.ngos FOR SELECT USING (true);


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
-- Name: order_status_history Restaurants can insert status history for their orders; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can insert status history for their orders" ON public.order_status_history FOR INSERT TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM public.orders
  WHERE ((orders.id = order_status_history.order_id) AND (orders.restaurant_id = auth.uid())))));


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
-- Name: order_items Restaurants can view assigned order items; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can view assigned order items" ON public.order_items FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.orders
  WHERE ((orders.id = order_items.order_id) AND (orders.restaurant_id = auth.uid())))));


--
-- Name: orders Restaurants can view assigned orders; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can view assigned orders" ON public.orders FOR SELECT USING ((auth.uid() = restaurant_id));


--
-- Name: order_items Restaurants can view order items; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can view order items" ON public.order_items FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.orders
  WHERE ((orders.id = order_items.order_id) AND (orders.restaurant_id = auth.uid())))));


--
-- Name: meal_reports Restaurants can view reports about their meals; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can view reports about their meals" ON public.meal_reports FOR SELECT TO authenticated USING ((restaurant_id = auth.uid()));


--
-- Name: order_status_history Restaurants can view their order history; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can view their order history" ON public.order_status_history FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.orders
  WHERE ((orders.id = order_status_history.order_id) AND (orders.restaurant_id = auth.uid())))));


--
-- Name: orders Restaurants can view their orders; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Restaurants can view their orders" ON public.orders FOR SELECT TO authenticated USING ((restaurant_id = auth.uid()));


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
-- Name: profiles Service role can insert profiles; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Service role can insert profiles" ON public.profiles FOR INSERT TO service_role WITH CHECK (true);


--
-- Name: restaurants Service role can insert restaurants; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Service role can insert restaurants" ON public.restaurants FOR INSERT TO service_role WITH CHECK (true);


--
-- Name: email_queue Service role can manage email queue; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Service role can manage email queue" ON public.email_queue TO service_role USING (true) WITH CHECK (true);


--
-- Name: ngos System can insert ngos; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "System can insert ngos" ON public.ngos FOR INSERT WITH CHECK (true);


--
-- Name: restaurants System can insert restaurants; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "System can insert restaurants" ON public.restaurants FOR INSERT WITH CHECK (true);


--
-- Name: free_meal_notifications Users can claim free meals; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can claim free meals" ON public.free_meal_notifications FOR UPDATE TO authenticated USING (((claimed_by IS NULL) OR (claimed_by = auth.uid()))) WITH CHECK ((claimed_by = auth.uid()));


--
-- Name: orders Users can create orders; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can create orders" ON public.orders FOR INSERT WITH CHECK ((auth.uid() = user_id));


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
-- Name: user_addresses Users can insert own addresses; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert own addresses" ON public.user_addresses FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: favorite_restaurants Users can insert own favorite restaurants; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert own favorite restaurants" ON public.favorite_restaurants FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: profiles Users can insert own profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK ((auth.uid() = id));


--
-- Name: order_items Users can insert their order items; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert their order items" ON public.order_items FOR INSERT TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM public.orders
  WHERE ((orders.id = order_items.order_id) AND (orders.user_id = auth.uid())))));


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
-- Name: favorites Users can manage favorites; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can manage favorites" ON public.favorites USING ((auth.uid() = user_id));


--
-- Name: cart_items Users can manage own cart; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can manage own cart" ON public.cart_items USING ((auth.uid() = user_id));


--
-- Name: messages Users can send messages in their conversations; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can send messages in their conversations" ON public.messages FOR INSERT TO authenticated WITH CHECK (((sender_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.conversations
  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.ngo_id = auth.uid()) OR (conversations.restaurant_id = auth.uid())))))));


--
-- Name: user_addresses Users can update own addresses; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update own addresses" ON public.user_addresses FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: ngos Users can update own ngo; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update own ngo" ON public.ngos FOR UPDATE USING ((auth.uid() = profile_id));


--
-- Name: profiles Users can update own profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE TO authenticated USING (((auth.uid() = id) OR public.is_admin())) WITH CHECK ((public.is_admin() OR ((auth.uid() = id) AND (approval_status = ( SELECT p.approval_status
   FROM public.profiles p
  WHERE (p.id = auth.uid()))))));


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
-- Name: profiles Users can update their own profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE TO authenticated USING ((id = auth.uid())) WITH CHECK ((id = auth.uid()));


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
-- Name: favorite_restaurants Users can view own favorite restaurants; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own favorite restaurants" ON public.favorite_restaurants FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: ngos Users can view own ngo; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own ngo" ON public.ngos FOR SELECT USING ((auth.uid() = profile_id));


--
-- Name: order_items Users can view own order items; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own order items" ON public.order_items FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.orders
  WHERE ((orders.id = order_items.order_id) AND (orders.user_id = auth.uid())))));


--
-- Name: orders Users can view own orders; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own orders" ON public.orders FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: payments Users can view own payments; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own payments" ON public.payments FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.orders
  WHERE ((orders.id = payments.order_id) AND (orders.user_id = auth.uid())))));


--
-- Name: profiles Users can view own profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT TO authenticated USING (((auth.uid() = id) OR public.is_admin()));


--
-- Name: restaurants Users can view own restaurant; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view own restaurant" ON public.restaurants FOR SELECT USING ((auth.uid() = profile_id));


--
-- Name: order_status_history Users can view their order history; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their order history" ON public.order_status_history FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.orders
  WHERE ((orders.id = order_status_history.order_id) AND (orders.user_id = auth.uid())))));


--
-- Name: order_items Users can view their order items; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their order items" ON public.order_items FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.orders
  WHERE ((orders.id = order_items.order_id) AND (orders.user_id = auth.uid())))));


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
-- Name: orders Users can view their own orders; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their own orders" ON public.orders FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: profiles Users can view their own profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their own profile" ON public.profiles FOR SELECT TO authenticated USING ((id = auth.uid()));


--
-- Name: meal_reports Users can view their own reports; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can view their own reports" ON public.meal_reports FOR SELECT TO authenticated USING ((user_id = auth.uid()));


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
-- Name: ngos; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.ngos ENABLE ROW LEVEL SECURITY;

--
-- Name: order_items; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

--
-- Name: order_status_history; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;

--
-- Name: orders; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

--
-- Name: payments; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: restaurants; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;

--
-- Name: rush_hours; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.rush_hours ENABLE ROW LEVEL SECURITY;

--
-- Name: user_addresses; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_addresses ENABLE ROW LEVEL SECURITY;

--
-- Name: user_category_preferences; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.user_category_preferences ENABLE ROW LEVEL SECURITY;

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
-- Name: FUNCTION calculate_effective_price(p_meal_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.calculate_effective_price(p_meal_id uuid) TO anon;
GRANT ALL ON FUNCTION public.calculate_effective_price(p_meal_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.calculate_effective_price(p_meal_id uuid) TO service_role;


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
-- Name: FUNCTION update_profile_default_location(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_profile_default_location() TO anon;
GRANT ALL ON FUNCTION public.update_profile_default_location() TO authenticated;
GRANT ALL ON FUNCTION public.update_profile_default_location() TO service_role;


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
-- Name: TABLE user_addresses; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_addresses TO anon;
GRANT ALL ON TABLE public.user_addresses TO authenticated;
GRANT ALL ON TABLE public.user_addresses TO service_role;


--
-- Name: TABLE user_category_preferences; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_category_preferences TO anon;
GRANT ALL ON TABLE public.user_category_preferences TO authenticated;
GRANT ALL ON TABLE public.user_category_preferences TO service_role;


--
-- Name: TABLE user_notifications_summary; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.user_notifications_summary TO anon;
GRANT ALL ON TABLE public.user_notifications_summary TO authenticated;
GRANT ALL ON TABLE public.user_notifications_summary TO service_role;


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

\unrestrict 4d8CzWtjKJ5MPkGvmFmHyEZoOUfNxspYvq7rDEdvEtNZXi7YnyisP2joMti0off

