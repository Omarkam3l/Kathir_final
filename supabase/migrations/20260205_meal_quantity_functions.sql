-- =====================================================
-- MEAL QUANTITY MANAGEMENT FUNCTIONS
-- =====================================================
-- Functions to safely increment/decrement meal quantities
-- Used when creating/cancelling orders
-- =====================================================

-- =====================================================
-- FUNCTION: Decrement Meal Quantity
-- =====================================================

CREATE OR REPLACE FUNCTION public.decrement_meal_quantity(
  meal_id uuid,
  qty integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $
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
$;

-- =====================================================
-- FUNCTION: Increment Meal Quantity
-- =====================================================

CREATE OR REPLACE FUNCTION public.increment_meal_quantity(
  meal_id uuid,
  qty integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $
BEGIN
  -- Update meal quantity
  UPDATE meals
  SET quantity_available = quantity_available + qty,
      status = 'active',  -- Reactivate if was sold
      updated_at = now()
  WHERE id = meal_id;
END;
$;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON FUNCTION decrement_meal_quantity IS 'Safely decrements meal quantity when order is created';
COMMENT ON FUNCTION increment_meal_quantity IS 'Safely increments meal quantity when order is cancelled';

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION decrement_meal_quantity(uuid, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_meal_quantity(uuid, integer) TO authenticated;

