import os
from supabase import create_client, Client

SUPABASE_URL: str = os.environ["SUPABASE_URL"]
SUPABASE_SERVICE_ROLE_KEY: str = os.environ["SUPABASE_SERVICE_ROLE_KEY"]

# Single shared client — import `sb` everywhere instead of re-creating it.
sb: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
