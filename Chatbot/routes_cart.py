"""
api/routes_cart.py
──────────────────
FastAPI router — cart management endpoints.

Mount this router in your main app:
    from api.routes_cart import router as cart_router
    app.include_router(cart_router, prefix="/cart", tags=["Cart"])
"""

from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Body, Query
from pydantic import BaseModel, Field

from budget import build_cart
from cart import add_to_cart, get_cart

router = APIRouter()


# ── Request bodies ────────────────────────────────────────────────────────────

class AddToCartRequest(BaseModel):
    meal_id: str = Field(..., description="UUID of the meal to add")
    quantity: int = Field(default=1, ge=1, description="Portions to add")


class BuildCartRequest(BaseModel):
    budget: float = Field(..., gt=0, description="Total budget in EGP")
    user_id: Optional[str] = Field(default=None, description="User UUID (for favorites weighting)")
    restaurant_id: Optional[str] = Field(default=None)
    restaurant_name: Optional[str] = Field(default=None)
    target_meal_count: int = Field(default=5, ge=1)
    max_qty_per_meal: int = Field(default=5, ge=1)
    preferred_meals: Optional[List[str]] = Field(default=None, description="Extra meal IDs to prioritize")


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/", response_model=Dict[str, Any])
def get_cart_endpoint(
    include_expired: bool = Query(default=False, description="Include stale/expired items"),
    restaurant_id: Optional[str] = Query(default=None, description="Filter by restaurant UUID"),
) -> Dict[str, Any]:
    """
    Retrieve the current user's cart with itemised details and a grand total.
    Stale items (expired / out of stock) are always returned separately.
    """
    return get_cart.invoke({
        "include_expired": include_expired,
        "restaurant_id": restaurant_id,
    })


@router.post("/add", response_model=Dict[str, Any])
def add_to_cart_endpoint(body: AddToCartRequest = Body(...)) -> Dict[str, Any]:
    """
    Add or increment a meal in the cart.
    Validates stock, expiry, and active status before writing.
    """
    return add_to_cart.invoke({
        "meal_id": body.meal_id,
        "quantity": body.quantity,
    })


@router.post("/build", response_model=Dict[str, Any])
def build_cart_endpoint(body: BuildCartRequest = Body(...)) -> Dict[str, Any]:
    """
    Generate a suggested cart that fits within the given budget.
    Favorites (from DB or preferred_meals) are weighted 3× during selection.
    """
    return build_cart.invoke({
        "budget": body.budget,
        "user_id": body.user_id,
        "restaurant_id": body.restaurant_id,
        "restaurant_name": body.restaurant_name,
        "target_meal_count": body.target_meal_count,
        "max_qty_per_meal": body.max_qty_per_meal,
        "preferred_meals": body.preferred_meals,
    })
