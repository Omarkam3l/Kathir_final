"""
api/routes_favorites.py
───────────────────────
FastAPI router — user favorites endpoints.

Mount this router in your main app:
    from api.routes_favorites import router as favorites_router
    app.include_router(favorites_router, prefix="/favorites", tags=["Favorites"])
"""

from typing import Any, Dict, Optional

from fastapi import APIRouter, Depends, Query

from src.tools.favorites import search_favorites
from src.utils.auth import get_current_user

router = APIRouter()


@router.get("/search", response_model=Dict[str, Any])
async def search_favorites_endpoint(
    user_id: str = Depends(get_current_user),
    query: str = Query(default="", description="Optional semantic search string"),
    limit: int = Query(default=8, ge=1, le=50),
    category: Optional[str] = Query(default=None),
    min_price: Optional[float] = Query(default=None),
    max_price: Optional[float] = Query(default=None),
    min_similarity: float = Query(default=0.55, ge=0.0, le=1.0),
) -> Dict[str, Any]:
    """
    Search within the authenticated user's saved favorite meals.

    - With **query**: performs semantic search intersected with the user's favorites.
    - Without **query**: returns all favorites matching the given filters.
    
    Note: Restaurant IDs are not exposed for security. Results include restaurant_name.
    User is automatically determined from authentication.
    """
    return search_favorites.invoke({
        "user_id": user_id,
        "query": query,
        "limit": limit,
        "category": category,
        "min_price": min_price,
        "max_price": max_price,
        "min_similarity": min_similarity,
    })
