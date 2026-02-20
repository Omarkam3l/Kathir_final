"""
tools/budget.py
───────────────
LangChain tool: build_cart

Builds a randomized suggested cart that fits within a given budget.
  • Requires a restaurant (by ID or partial name)
  • Fetches the user's favorites from DB and gives them 3× selection weight
  • Phase 1 — variety: pick ≥1 of each unique meal until unique_target is reached
  • Phase 2 — fill: top up remaining budget aggressively
  • Never exceeds budget; never exceeds per-meal stock
"""

import random
from typing import Any, Dict, List, Optional

from langchain.tools import tool

from db_client import sb
from time_utils import now_iso


@tool("build_cart")
def build_cart(
    budget: float,
    user_id: Optional[str] = None,
    restaurant_id: Optional[str] = None,
    restaurant_name: Optional[str] = None,
    target_meal_count: int = 5,
    max_qty_per_meal: int = 5,
    preferred_meals: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Build a suggested cart that fits within the given budget.

    Favorites (from DB or preferred_meals) are weighted 3× more likely to be
    selected. The result is randomized each call for variety.

    Args:
        budget            : Total budget in EGP (must be > 0).
        user_id           : Optional — if given, favorites are fetched from DB.
        restaurant_id     : UUID of the restaurant to shop from.
        restaurant_name   : Partial name match (used when restaurant_id is absent).
        target_meal_count : Target number of unique meals (default 5; actual may be 1.5×).
        max_qty_per_meal  : Cap on quantity per individual meal (default 5).
        preferred_meals   : Additional meal IDs to treat as favorites.

    Returns:
        Dict with ok, budget, total, remainder, cart_items, breakdown, and a message.
    """
    if budget <= 0:
        return {"ok": False, "error": "Budget must be > 0"}

    # ── Resolve restaurant ────────────────────────────────────────────────────
    rids: List[str] = []
    rest_name: Optional[str] = None

    if restaurant_id:
        rids = [restaurant_id]
    elif restaurant_name:
        data = (
            sb.table("restaurants")
              .select("profile_id, restaurant_name")
              .ilike("restaurant_name", f"%{restaurant_name}%")
              .limit(1)
              .execute()
              .data or []
        )
        if not data:
            return {"ok": False, "error": f"No restaurant matching '{restaurant_name}'"}
        rids = [data[0]["profile_id"]]
        rest_name = data[0]["restaurant_name"]

    if not rids:
        return {"ok": False, "error": "A restaurant is required (provide restaurant_id or restaurant_name)"}

    # ── Fetch available meals ─────────────────────────────────────────────────
    raw_meals = (
        sb.table("meals")
          .select("id, title, discounted_price, quantity_available")
          .eq("status", "active")
          .gt("quantity_available", 0)
          .gt("expiry_date", now_iso())
          .in_("restaurant_id", rids)
          .order("discounted_price")
          .execute()
          .data or []
    )

    if not raw_meals:
        return {"ok": False, "error": "No available meals at this restaurant"}

    # Sanitize: drop zero-price entries
    cleaned_meals = [
        {
            "id": m["id"],
            "title": m["title"],
            "price": float(m["discounted_price"]),
            "available": int(m["quantity_available"]),
        }
        for m in raw_meals
        if float(m["discounted_price"]) > 0
    ]

    if not cleaned_meals:
        return {"ok": False, "error": "No valid priced meals at this restaurant"}

    # ── Fetch user favorites ──────────────────────────────────────────────────
    preferred_set: set[str] = set(preferred_meals or [])
    if user_id:
        fav_rows = (
            sb.table("favorites")
              .select("meal_id")
              .eq("user_id", user_id)
              .execute()
              .data or []
        )
        preferred_set.update(f["meal_id"] for f in fav_rows)

    # ── Weighted random ordering (favorites appear 3×) ────────────────────────
    fav_meals = [m for m in cleaned_meals if m["id"] in preferred_set]
    non_fav_meals = [m for m in cleaned_meals if m["id"] not in preferred_set]

    random.shuffle(fav_meals)
    random.shuffle(non_fav_meals)

    # Favorites listed 3× so they're encountered more often during filling
    randomized = (fav_meals * 3) + non_fav_meals

    # ── Build cart ────────────────────────────────────────────────────────────
    picked: Dict[str, Dict[str, Any]] = {}  # meal_id → accumulated item
    total = 0.0

    def try_add(meal: Dict[str, Any], qty: int) -> int:
        nonlocal total
        if qty <= 0:
            return 0
        mid = meal["id"]
        price = meal["price"]
        cap = min(max_qty_per_meal, meal["available"])
        current = picked.get(mid, {}).get("quantity", 0)
        remaining_cap = cap - current
        if remaining_cap <= 0:
            return 0
        max_by_budget = int((budget - total) // price)
        add = min(qty, remaining_cap, max_by_budget)
        if add <= 0:
            return 0
        if mid not in picked:
            picked[mid] = {"meal_id": mid, "title": meal["title"], "price": price, "quantity": 0}
        picked[mid]["quantity"] += add
        total += price * add
        return add

    # Phase 1 — variety (1.5× unique target)
    unique_target = max(2, int(target_meal_count * 1.5))
    for meal in randomized:
        if len(picked) >= unique_target:
            break
        try_add(meal, 1)

    # Phase 2 — fill remaining budget
    for meal in randomized:
        if total >= budget:
            break
        try_add(meal, 15)

    # ── Format output ─────────────────────────────────────────────────────────
    cart_items = sorted(
        picked.values(),
        key=lambda x: (0 if x["meal_id"] in preferred_set else 1, x["price"]),
    )

    breakdown = [
        {
            "meal_id": item["meal_id"],
            "title": item["title"],
            "unit_price": item["price"],
            "quantity": item["quantity"],
            "subtotal": round(item["price"] * item["quantity"], 2),
        }
        for item in cart_items
    ]

    total_rounded = round(total, 2)
    remainder = round(budget - total, 2)
    total_qty = sum(i["quantity"] for i in cart_items)

    return {
        "ok": True,
        "restaurant_name": rest_name,
        "budget": float(budget),
        "total": total_rounded,
        "remaining_budget": remainder,
        "count": len(cart_items),
        "total_quantity": total_qty,
        "items": breakdown,
        "message": (
            f"Suggested cart for {budget} EGP: {total_qty} items "
            f"({len(cart_items)} unique), total {total_rounded} EGP. Add this?"
        ),
    }
