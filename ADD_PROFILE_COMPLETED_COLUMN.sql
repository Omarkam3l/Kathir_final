-- Add is_profile_completed column to profiles table
-- This tracks whether the user has completed the profile setup during onboarding

-- Add the column if it doesn't exist with default FALSE
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS is_profile_completed BOOLEAN DEFAULT FALSE;

-- If the column already exists, change its default to FALSE
ALTER TABLE profiles 
ALTER COLUMN is_profile_completed SET DEFAULT FALSE;

-- Add comment to explain the column
COMMENT ON COLUMN profiles.is_profile_completed IS 'Indicates whether the user has completed the profile setup step during onboarding. New users start with FALSE.';

-- IMPORTANT: For existing users, set to TRUE for backward compatibility
-- This ensures existing users don't have to go through profile setup again
UPDATE profiles 
SET is_profile_completed = TRUE 
WHERE created_at < NOW() - INTERVAL '1 minute';

-- Alternative: If you want ALL existing users to skip profile setup, uncomment this:
-- UPDATE profiles SET is_profile_completed = TRUE WHERE is_profile_completed IS NULL OR is_profile_completed = FALSE;

-- New users created after this migration will have is_profile_completed = FALSE by default
-- and will be required to complete the profile setup during onboarding
