-- =====================================================
-- COMPREHENSIVE TRIGGER DIAGNOSTIC
-- =====================================================
-- Run these queries ONE BY ONE to find the exact issue
-- =====================================================

-- =====================================================
-- STEP 1: Verify your subscription exists
-- =====================================================
SELECT 
  id,
  user_id,
  category,
  notifications_enabled,
  created_at
FROM user_category_preferences
WHERE category = 'Bakery'
ORDER BY created_at DESC;

-- Expected: Should show your subscription with notifications_enabled = true
-- If empty: Subscription didn't save (but your log shows it did)

-- =====================================================
-- STEP 2: Check the most recent meal added
-- =====================================================
SELECT 
  id,
  title,
  category,
  status,
  quantity_available,
  expiry_date,
  restaurant_id,
  created_at
FROM meals
ORDER BY created_at DESC
LIMIT 1;

-- Expected: Should show the meal you just added
-- Check: category = 'Bakery', status = 'active', quantity_available > 0, expiry_date in future

-- =====================================================
-- STEP 3: Check if trigger exists and is enabled
-- =====================================================
SELECT 
  tgname as trigger_name,
  tgenabled as enabled,
  tgtype as trigger_type,
  proname as function_name
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgname = 'trg_notify_category_subscribers';

-- Expected: Should show trigger with enabled = 'O' (origin enabled)
-- If empty: Trigger doesn't exist

-- =====================================================
-- STEP 4: Check if function exists
-- =====================================================
SELECT 
  proname as function_name,
  prosrc as function_body
FROM pg_proc
WHERE proname = 'notify_category_subscribers';

-- Expected: Should show the function
-- If empty: Function doesn't exist

-- =====================================================
-- STEP 5: Test the trigger logic MANUALLY
-- =====================================================
-- This simulates what the trigger should do
-- Replace 'YOUR_USER_ID' with the user_id from STEP 1
-- Replace 'YOUR_RESTAURANT_ID' with the restaurant_id from STEP 2
-- Replace 'MEAL_ID' with the id from STEP 2

DO $$
DECLARE
  v_user_id uuid := 'cab48b70-f54d-4988-a6d2-38f4a258ab9d'; -- YOUR USER ID
  v_restaurant_id uuid := 'REPLACE_WITH_RESTAURANT_ID'; -- RESTAURANT ID
  v_meal_id uuid := 'REPLACE_WITH_MEAL_ID'; -- MEAL ID
  v_category text := 'Bakery';
  v_count int;
BEGIN
  -- Check if user is subscribed
  SELECT COUNT(*) INTO v_count
  FROM user_category_preferences
  WHERE category = v_category
    AND notifications_enabled = true
    AND user_id = v_user_id;
  
  RAISE NOTICE 'Found % subscribed users for category %', v_count, v_category;
  
  -- Check if user is not the restaurant owner
  IF v_user_id != v_restaurant_id THEN
    RAISE NOTICE 'User is NOT the restaurant owner - should create notification';
  ELSE
    RAISE NOTICE 'User IS the restaurant owner - will NOT create notification';
  END IF;
  
  -- Try to insert notification
  BEGIN
    INSERT INTO category_notifications (user_id, meal_id, category)
    VALUES (v_user_id, v_meal_id, v_category);
    
    RAISE NOTICE 'Successfully inserted notification!';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Failed to insert notification: %', SQLERRM;
  END;
END $$;

-- =====================================================
-- STEP 6: Check if notification was created
-- =====================================================
SELECT COUNT(*) as notification_count
FROM category_notifications;

-- Expected: Should be > 0 if manual insert worked

-- =====================================================
-- STEP 7: Check RLS policies on category_notifications
-- =====================================================
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'category_notifications';

-- Expected: Should show policies including the "System can insert" policy

-- =====================================================
-- STEP 8: Check table owner and permissions
-- =====================================================
SELECT 
  grantee,
  privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'category_notifications'
  AND grantee = 'authenticated';

-- Expected: Should show INSERT permission for authenticated role

-- =====================================================
-- FINAL TEST: Manually trigger the function
-- =====================================================
-- This will tell us if the trigger function itself works
-- Replace the IDs with actual values from STEP 2

DO $$
DECLARE
  v_new_meal RECORD;
  v_result RECORD;
BEGIN
  -- Get the most recent meal
  SELECT * INTO v_new_meal
  FROM meals
  ORDER BY created_at DESC
  LIMIT 1;
  
  RAISE NOTICE 'Testing trigger with meal: % (category: %, status: %)', 
    v_new_meal.title, v_new_meal.category, v_new_meal.status;
  
  -- Manually call the trigger function
  -- This simulates what happens when a meal is inserted
  PERFORM notify_category_subscribers();
  
  RAISE NOTICE 'Trigger function executed';
  
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error executing trigger: %', SQLERRM;
END $$;

-- =====================================================
-- SUMMARY
-- =====================================================
-- After running all steps, you should know:
-- 1. If subscription exists ✓
-- 2. If meal was created correctly ✓
-- 3. If trigger exists and is enabled
-- 4. If function exists
-- 5. If manual insert works (RLS issue if it fails)
-- 6. If trigger function can be called
-- =====================================================
