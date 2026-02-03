-- Migration: NGO Dashboard Enhancements
-- Date: February 3, 2026
-- Description: Additional indexes and functions for NGO operations

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Index for NGO orders lookup
CREATE INDEX IF NOT EXISTS idx_orders_ngo_id_status 
ON public.orders (ngo_id, status);

-- Index for donation-available meals
CREATE INDEX IF NOT EXISTS idx_meals_donation_available 
ON public.meals (is_donation_available, status, expiry_date) 
WHERE is_donation_available = true AND status = 'active';

-- Index for meal expiry lookups
CREATE INDEX IF NOT EXISTS idx_meals_expiry_active 
ON public.meals (expiry_date) 
WHERE status = 'active';

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to get NGO statistics
CREATE OR REPLACE FUNCTION get_ngo_stats(ngo_user_id uuid)
RETURNS TABLE (
  meals_claimed bigint,
  carbon_saved numeric,
  active_orders bigint,
  total_value_saved numeric
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT o.id) FILTER (WHERE o.status = 'completed') as meals_claimed,
    (COUNT(DISTINCT o.id) FILTER (WHERE o.status = 'completed') * 2.5)::numeric as carbon_saved,
    COUNT(DISTINCT o.id) FILTER (WHERE o.status IN ('pending', 'paid', 'processing')) as active_orders,
    COALESCE(SUM(o.total_amount) FILTER (WHERE o.status = 'completed'), 0) as total_value_saved
  FROM orders o
  WHERE o.ngo_id = ngo_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get expiring meals for NGOs
CREATE OR REPLACE FUNCTION get_expiring_meals(hours_threshold integer DEFAULT 2)
RETURNS TABLE (
  id uuid,
  title text,
  restaurant_name text,
  quantity_available integer,
  expiry_date timestamp with time zone,
  minutes_until_expiry integer
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.id,
    m.title,
    r.restaurant_name,
    m.quantity_available,
    m.expiry_date,
    EXTRACT(EPOCH FROM (m.expiry_date - NOW())) / 60 as minutes_until_expiry
  FROM meals m
  INNER JOIN restaurants r ON m.restaurant_id = r.profile_id
  WHERE m.is_donation_available = true
    AND m.status = 'active'
    AND m.quantity_available > 0
    AND m.expiry_date > NOW()
    AND m.expiry_date <= NOW() + (hours_threshold || ' hours')::interval
  ORDER BY m.expiry_date ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate NGO impact
CREATE OR REPLACE FUNCTION calculate_ngo_impact(ngo_user_id uuid)
RETURNS TABLE (
  total_meals bigint,
  co2_saved_kg numeric,
  water_saved_liters numeric,
  money_saved numeric,
  people_helped bigint,
  this_month_meals bigint
) AS $$
DECLARE
  total_completed bigint;
BEGIN
  -- Get total completed orders
  SELECT COUNT(*) INTO total_completed
  FROM orders
  WHERE ngo_id = ngo_user_id AND status = 'completed';

  RETURN QUERY
  SELECT 
    total_completed as total_meals,
    (total_completed * 2.5)::numeric as co2_saved_kg,
    (total_completed * 50)::numeric as water_saved_liters,
    COALESCE(SUM(o.total_amount), 0) as money_saved,
    (total_completed * 3)::bigint as people_helped,
    COUNT(*) FILTER (
      WHERE o.created_at >= date_trunc('month', CURRENT_DATE)
    ) as this_month_meals
  FROM orders o
  WHERE o.ngo_id = ngo_user_id AND o.status = 'completed';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- VIEWS
-- =====================================================

-- View for NGO dashboard meals
CREATE OR REPLACE VIEW ngo_available_meals AS
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
  m.is_donation_available,
  m.created_at,
  r.profile_id as restaurant_id,
  r.restaurant_name,
  r.rating as restaurant_rating,
  r.address_text as restaurant_address,
  EXTRACT(EPOCH FROM (m.expiry_date - NOW())) / 60 as minutes_until_expiry,
  CASE 
    WHEN m.expiry_date <= NOW() + interval '1 hour' THEN 'urgent'
    WHEN m.expiry_date <= NOW() + interval '2 hours' THEN 'expiring_soon'
    ELSE 'available'
  END as urgency_level
FROM meals m
INNER JOIN restaurants r ON m.restaurant_id = r.profile_id
WHERE m.is_donation_available = true
  AND m.status = 'active'
  AND m.quantity_available > 0
  AND m.expiry_date > NOW()
ORDER BY m.expiry_date ASC;

-- Grant access to views
GRANT SELECT ON ngo_available_meals TO authenticated;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger to update meal status when quantity reaches zero
CREATE OR REPLACE FUNCTION update_meal_status_on_quantity()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.quantity_available = 0 AND OLD.quantity_available > 0 THEN
    NEW.status = 'sold';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_meal_status_on_quantity
BEFORE UPDATE ON meals
FOR EACH ROW
WHEN (NEW.quantity_available IS DISTINCT FROM OLD.quantity_available)
EXECUTE FUNCTION update_meal_status_on_quantity();

-- Trigger to auto-expire meals
CREATE OR REPLACE FUNCTION auto_expire_meals()
RETURNS void AS $$
BEGIN
  UPDATE meals
  SET status = 'expired'
  WHERE status = 'active'
    AND expiry_date < NOW()
    AND quantity_available > 0;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- NOTIFICATIONS
-- =====================================================

-- Function to notify NGOs of new donations
CREATE OR REPLACE FUNCTION notify_ngos_new_donation()
RETURNS TRIGGER AS $$
BEGIN
  -- This would integrate with a notification system
  -- For now, we just log it
  RAISE NOTICE 'New donation available: % from restaurant %', NEW.title, NEW.restaurant_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_notify_ngos_new_donation
AFTER INSERT ON meals
FOR EACH ROW
WHEN (NEW.is_donation_available = true AND NEW.status = 'active')
EXECUTE FUNCTION notify_ngos_new_donation();

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON FUNCTION get_ngo_stats IS 'Returns comprehensive statistics for an NGO including meals claimed, carbon saved, and active orders';
COMMENT ON FUNCTION get_expiring_meals IS 'Returns meals that are expiring within the specified hours threshold';
COMMENT ON FUNCTION calculate_ngo_impact IS 'Calculates the environmental and social impact of an NGO';
COMMENT ON VIEW ngo_available_meals IS 'Optimized view for NGO dashboard showing available donation meals with urgency levels';

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant execute permissions on functions to authenticated users
GRANT EXECUTE ON FUNCTION get_ngo_stats TO authenticated;
GRANT EXECUTE ON FUNCTION get_expiring_meals TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_ngo_impact TO authenticated;

-- =====================================================
-- END OF MIGRATION
-- =====================================================
