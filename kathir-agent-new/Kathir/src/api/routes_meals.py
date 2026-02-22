"""
api/routes_meals.py
───────────────────
FastAPI router — meal search endpoints.

Mount this router in your main app:
    from api.routes_meals import router as meals_router
    app.include_router(meals_router, prefix="/meals", tags=["Meals"])
"""

from typing import Any, Dict, List, Literal, Optional

from fastapi import APIRouter, Query

from src.tools.meals import search_meals

router = APIRouter()


@router.get("/search", response_model=Dict[str, Any])
def search_meals_endpoint(
    query: str = Query(default="", description="Semantic search string"),
    restaurant_name: Optional[str] = Query(default=None, description="Restaurant name (partial match)"),
    max_price: Optional[float] = Query(default=None),
    min_price: Optional[float] = Query(default=None),
    category: Optional[str] = Query(default=None),
    exclude_allergens: Optional[List[str]] = Query(default=None),
    require_allergens: Optional[List[str]] = Query(default=None),
    limit: int = Query(default=8, ge=1, le=50),
    min_similarity: float = Query(default=0.55, ge=0.0, le=1.0),
    sort: Literal["relevance", "price_asc"] = Query(default="relevance"),
) -> Dict[str, Any]:
    """
    Search for meals using semantic similarity and/or structured filters.

    - **query**: Free-text description (e.g. "grilled chicken", "chocolate cake")
    - **restaurant_name**: Filter by restaurant name (partial match, case-insensitive)
    - **category**: Exact match — "Desserts", "Bakery", "Meat & Poultry", "Seafood", "Meals"
    - **exclude_allergens**: e.g. `["gluten"]` for gluten-free results
    - **sort**: `relevance` (default) or `price_asc`
    
    Note: Restaurant IDs are not exposed for security reasons. Use restaurant_name instead.
    """
    return search_meals.invoke({
        "query": query,
        "restaurant_name": restaurant_name,
        "max_price": max_price,
        "min_price": min_price,
        "category": category,
        "exclude_allergens": exclude_allergens,
        "require_allergens": require_allergens,
        "limit": limit,
        "min_similarity": min_similarity,
        "sort": sort,
    })
