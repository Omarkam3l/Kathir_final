-- Fix NGO signup issue: ensure NGO records are created properly
-- Issue: NGOs table missing updated_at column, and trigger has wrong column reference

-- Step 1: Add missing columns to NGOs table if they don't exist
ALTER TABLE public.ngos 
ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Step 2: Create or replace the handle_new_user function with fixed NGO creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
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

-- Step 3: Backfill missing NGO records for existing NGO profiles
-- This will create NGO records for any NGO profiles that don't have them
INSERT INTO public.ngos (profile_id, organization_name, legal_docs_urls, created_at, updated_at)
SELECT 
  p.id,
  COALESCE(p.full_name, 'Organization ' || SUBSTRING(p.id::text, 1, 8)),
  ARRAY[]::text[],
  p.created_at,
  NOW()
FROM public.profiles p
WHERE p.role = 'ngo'
  AND NOT EXISTS (
    SELECT 1 FROM public.ngos n WHERE n.profile_id = p.id
  )
ON CONFLICT (profile_id) DO NOTHING;

-- Step 4: Add comment
COMMENT ON FUNCTION public.handle_new_user() IS 
  'Trigger function to auto-create profile and role-specific records on user signup. Profile creation is critical and will fail signup if it fails. Role table creation is non-critical and will only log warnings. Fixed to properly handle NGO table columns.';

-- Step 5: Verify the fix worked
DO $$
DECLARE
  missing_count integer;
BEGIN
  SELECT COUNT(*) INTO missing_count
  FROM public.profiles p
  WHERE p.role = 'ngo'
    AND NOT EXISTS (SELECT 1 FROM public.ngos n WHERE n.profile_id = p.id);
  
  IF missing_count > 0 THEN
    RAISE WARNING 'Still have % NGO profiles without NGO records', missing_count;
  ELSE
    RAISE NOTICE 'All NGO profiles now have corresponding NGO records';
  END IF;
END $$;
