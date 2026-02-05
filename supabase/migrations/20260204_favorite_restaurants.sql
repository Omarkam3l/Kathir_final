-- Create favorite_restaurants table to track restaurant favorites separately from meal favorites
CREATE TABLE IF NOT EXISTS favorite_restaurants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  restaurant_id UUID NOT NULL REFERENCES restaurants(profile_id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, restaurant_id)
);

-- Add RLS policies
ALTER TABLE favorite_restaurants ENABLE ROW LEVEL SECURITY;

-- Users can view their own favorite restaurants
CREATE POLICY "Users can view own favorite restaurants"
  ON favorite_restaurants
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own favorite restaurants
CREATE POLICY "Users can insert own favorite restaurants"
  ON favorite_restaurants
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own favorite restaurants
CREATE POLICY "Users can delete own favorite restaurants"
  ON favorite_restaurants
  FOR DELETE
  USING (auth.uid() = user_id);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_favorite_restaurants_user_id ON favorite_restaurants(user_id);
CREATE INDEX IF NOT EXISTS idx_favorite_restaurants_restaurant_id ON favorite_restaurants(restaurant_id);
