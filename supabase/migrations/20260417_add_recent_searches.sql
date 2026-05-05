-- Add recent_searches table for home page search history
-- Stores the last 5 search queries per authenticated user.

-- Step 1: Create table
CREATE TABLE IF NOT EXISTS public.recent_searches (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  query       text        NOT NULL,
  searched_at timestamptz NOT NULL DEFAULT now()
);

-- Step 2: Unique constraint – one row per (user, query)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'recent_searches_user_id_query_key'
  ) THEN
    ALTER TABLE public.recent_searches
      ADD CONSTRAINT recent_searches_user_id_query_key
      UNIQUE (user_id, query);
  END IF;
END $$;

-- Step 3: Index for efficient ordered retrieval
CREATE INDEX IF NOT EXISTS idx_recent_searches_user_searched_at
  ON public.recent_searches (user_id, searched_at DESC);

-- Step 4: Enable Row Level Security
ALTER TABLE public.recent_searches ENABLE ROW LEVEL SECURITY;

-- Step 5: RLS policy – users can only access their own rows
DROP POLICY IF EXISTS "Users manage own recent searches" ON public.recent_searches;

CREATE POLICY "Users manage own recent searches"
  ON public.recent_searches
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Step 6: Comments
COMMENT ON TABLE public.recent_searches IS
  'Stores the last 5 search queries per authenticated user for the home page search bar.';

COMMENT ON COLUMN public.recent_searches.user_id IS
  'References profiles(id). Cascades on delete.';

COMMENT ON COLUMN public.recent_searches.query IS
  'Trimmed, lowercase search query string.';

COMMENT ON COLUMN public.recent_searches.searched_at IS
  'UTC timestamp of the last time this query was submitted.';
