"""
api/routes_health.py
────────────────────
FastAPI router — health and readiness endpoints.

Mount this router in your main app:
    from api.routes_health import router as health_router
    app.include_router(health_router, tags=["Health"])
"""

from datetime import datetime, timezone

from fastapi import APIRouter

from src.utils.db_client import sb

router = APIRouter()


@router.get("/health")
def health_check():
    """Lightweight liveness probe — always returns 200 if the app is running."""
    return {"status": "ok", "timestamp": datetime.now(timezone.utc).isoformat()}


@router.get("/ready")
def readiness_check():
    """
    Readiness probe — verifies connectivity to Supabase.
    Returns 200 if the DB is reachable, 503 otherwise.
    """
    try:
        # Cheap query: fetch a single row to confirm the connection is alive
        sb.table("meals").select("id").limit(1).execute()
        db_status = "connected"
    except Exception as exc:
        return {
            "status": "not_ready",
            "db": "unreachable",
            "error": str(exc),
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }

    return {
        "status": "ready",
        "db": db_status,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
