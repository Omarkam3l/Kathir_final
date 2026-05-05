-- Migration: Auto-deactivate expired rush hours
-- This ensures rush hours are automatically deactivated when their end_time passes

-- Function to auto-deactivate expired rush hours
CREATE OR REPLACE FUNCTION auto_deactivate_expired_rush_hours()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- Deactivate any rush hours where end_time has passed
  UPDATE rush_hours
  SET is_active = false
  WHERE is_active = true
    AND end_time < NOW();
END;
$$;

COMMENT ON FUNCTION auto_deactivate_expired_rush_hours() IS 
'Automatically deactivates rush hours that have passed their end_time. 
Should be called periodically (e.g., via cron job or edge function).';

-- Grant execute permission
GRANT EXECUTE ON FUNCTION auto_deactivate_expired_rush_hours() TO authenticated;
GRANT EXECUTE ON FUNCTION auto_deactivate_expired_rush_hours() TO service_role;

-- Optional: Create a view to check active rush hours status
CREATE OR REPLACE VIEW active_rush_hours_status AS
SELECT 
  rh.id,
  rh.restaurant_id,
  r.restaurant_name,
  rh.start_time,
  rh.end_time,
  rh.discount_percentage,
  rh.is_active,
  CASE 
    WHEN rh.is_active AND NOW() BETWEEN rh.start_time AND rh.end_time THEN 'active'
    WHEN rh.is_active AND NOW() > rh.end_time THEN 'expired'
    ELSE 'inactive'
  END AS status,
  CASE 
    WHEN rh.is_active AND NOW() < rh.end_time THEN 
      EXTRACT(EPOCH FROM (rh.end_time - NOW())) / 60
    ELSE 0
  END AS minutes_remaining
FROM rush_hours rh
LEFT JOIN restaurants r ON rh.restaurant_id = r.profile_id
WHERE rh.is_active = true
ORDER BY rh.end_time DESC;

COMMENT ON VIEW active_rush_hours_status IS 
'Shows all active rush hours with their current status and remaining time';

-- Grant access to view
GRANT SELECT ON active_rush_hours_status TO authenticated;
GRANT SELECT ON active_rush_hours_status TO service_role;
