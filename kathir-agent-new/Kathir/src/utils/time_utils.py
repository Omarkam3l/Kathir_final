from datetime import datetime, timezone


def now_iso() -> str:
    """Return the current UTC time as an ISO 8601 string (used in Supabase queries)."""
    return datetime.now(timezone.utc).isoformat()


def now_fmt(fmt: str = "%Y-%m-%d %H:%M") -> str:
    """Return the current local time formatted as a human-readable string."""
    return datetime.now().strftime(fmt)
