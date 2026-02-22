"""
api/routes_cart.py
──────────────────
FastAPI router — cart management endpoints.

Mount this router in your main app:
    from api.routes_cart import router as cart_router
    app.include_router(cart_router, prefix="/cart", tags=["Cart"])
"""

from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Body, Depends, Query
from pydantic import BaseModel, Field

from src.tools.budget import build_cart
from src.tools.cart import add_to_cart, get_cart
from src.utils.auth import get_current_user

router = APIRouter()


# ── Request bodies ────────────────────────────────────────────────────────────

class AddToCartRequest(BaseModel):
    meal_id: str = Field(..., description="UUID of the meal to add")
    quantity: int = Field(default=1, ge=1, description="Portions to add")


class BuildCartRequest(BaseModel):
    budget: float = Field(..., gt=0, description="Total budget in EGP")
    restaurant_name: str = Field(..., description="Restaurant name (partial match allowed)")
    target_meal_count: int = Field(default=5, ge=1)
    max_qty_per_meal: int = Field(default=5, ge=1)
    preferred_meals: Optional[List[str]] = Field(default=None, description="Extra meal IDs to prioritize")


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/", response_model=Dict[str, Any])
def get_cart_endpoint(
    include_expired: bool = Query(default=False, description="Include stale/expired items"),
) -> Dict[str, Any]:
    """
    Retrieve the current user's cart with itemised details and a grand total.
    Stale items (expired / out of stock) are always returned separately.
    
    Note: Restaurant filtering removed for security. Use restaurant_name in search instead.
    """
    return get_cart.invoke({
        "include_expired": include_expired,
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
async def build_cart_endpoint(
    body: BuildCartRequest = Body(...),
    user_id: str = Depends(get_current_user)
) -> Dict[str, Any]:
    """
    Generate a suggested cart that fits within the given budget.
    Favorites (from DB or preferred_meals) are weighted 3× during selection.
    
    Note: Restaurant must be specified by name, not ID, for security.
    User is automatically determined from authentication.
    """
    return build_cart.invoke({
        "budget": body.budget,
        "restaurant_name": body.restaurant_name,
        "user_id": user_id,
        "target_meal_count": body.target_meal_count,
        "max_qty_per_meal": body.max_qty_per_meal,
        "preferred_meals": body.preferred_meals,
    })
