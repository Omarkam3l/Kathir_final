"""
tools/cart.py
─────────────
LangChain tools: add_to_cart, get_cart

add_to_cart — validates and upserts a single meal into the user's cart.
get_cart    — returns a full, annotated view of the user's current cart.

NOTE: USER_ID is currently hardcoded for dev/notebook parity.
      Replace with a real auth-context lookup in production.
"""

from datetime import datetime, timezone
from typing import Any, Dict, Optional

from langchain_core.tools import tool

from db_client import sb
from time_utils import now_iso

# TODO: replace with real auth context (e.g. token → user_id resolution)
_DEV_USER_ID = "11111111-1111-1111-1111-111111111111"


# ─────────────────────────────────────────────────────────────────────────────
# add_to_cart
# ─────────────────────────────────────────────────────────────────────────────

@tool("add_to_cart")
def add_to_cart(meal_id: str, quantity: int = 1) -> Dict[str, Any]:
    """
    Add or increment a meal in the cart.

    Validates meal existence, active status, expiry date, and available stock
    before writing. If the meal is already in the cart, the quantity is
    incremented (not replaced).

    Args:
        meal_id  : UUID of the meal to add.
        quantity : Number of portions to add (must be >= 1).

    Returns:
        A dict with success status, action taken ("added" / "updated"),
        and cart details for the affected item.
    """
    USER_ID = _DEV_USER_ID

    # ── Input validation ──────────────────────────────────────────────────────
    if not meal_id or not meal_id.strip():
        return {"success": False, "error": "meal_id is required"}
    if quantity < 1:
        return {"success": False, "error": "quantity must be >= 1"}

    # ── Fetch & validate meal ─────────────────────────────────────────────────
    meal = (
        sb.table("meals")
          .select("id, title, discounted_price, quantity_available, status, expiry_date")
          .eq("id", meal_id)
          .single()
          .execute()
          .data
    )

    if not meal:
        return {"success": False, "error": f"Meal {meal_id} not found"}

    if meal["status"] != "active":
        return {"success": False, "error": f"Meal is not available (status: {meal['status']})"}

    if meal.get("expiry_date"):
        expiry = datetime.fromisoformat(meal["expiry_date"])
        if expiry < datetime.now(timezone.utc):
            return {"success": False, "error": "Meal has expired"}

    available = int(meal["quantity_available"])
    if available <= 0:
        return {"success": False, "error": "Meal is out of stock"}

    price = float(meal["discounted_price"])

    # ── Fetch existing cart row ───────────────────────────────────────────────
    existing = (
        sb.table("cart_items")
          .select("id, quantity")
          .eq("profile_id", USER_ID)
          .eq("meal_id", meal_id)
          .limit(1)
          .execute()
          .data or []
    )

    current_qty = int(existing[0]["quantity"]) if existing else 0
    new_qty = current_qty + quantity

    # ── Stock ceiling check ───────────────────────────────────────────────────
    if new_qty > available:
        return {
            "success": False,
            "error": (
                f"Not enough stock — only {available} available, "
                f"cart already has {current_qty}"
            ),
        }

    # ── Upsert cart row ───────────────────────────────────────────────────────
    ts = now_iso()
    if existing:
        write_res = (
            sb.table("cart_items")
              .update({"quantity": new_qty, "updated_at": ts})
              .eq("id", existing[0]["id"])
              .execute()
        )
        action = "updated"
    else:
        write_res = (
            sb.table("cart_items")
              .insert({
                  "profile_id": USER_ID,
                  "user_id": USER_ID,
                  "meal_id": meal_id,
                  "quantity": new_qty,
                  "created_at": ts,
                  "updated_at": ts,
              })
              .execute()
        )
        action = "added"

    if not write_res.data:
        return {"success": False, "error": "DB write failed — no data returned"}

    return {
        "success": True,
        "action": action,
        "meal_id": meal_id,
        "title": meal["title"],
        "unit_price": price,
        "added_quantity": quantity,
        "new_quantity": new_qty,
        "total_price": round(price * new_qty, 2),
        "message": f"{action.capitalize()} '{meal['title']}' ×{quantity} — cart qty: {new_qty}",
    }


# ─────────────────────────────────────────────────────────────────────────────
# get_cart
# ─────────────────────────────────────────────────────────────────────────────

@tool("get_cart")
def get_cart(
    include_expired: bool = False,
    restaurant_id: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Fetch the current user's cart with full meal details and a cost summary.

    Each item shows: title, unit price, quantity, subtotal.
    Stale items (expired / inactive / out of stock) are flagged separately.

    Args:
        include_expired : If True, include stale items in totals (default False).
        restaurant_id   : Optional UUID — show only items from this restaurant.

    Returns:
        Dict with ok, items, stale_items, total, count, and a summary message.
    """
    USER_ID = _DEV_USER_ID

    # ── 1. Fetch raw cart rows ────────────────────────────────────────────────
    cart_rows = (
        sb.table("cart_items")
          .select("id, meal_id, quantity, created_at, updated_at")
          .eq("profile_id", USER_ID)
          .execute()
          .data or []
    )

    if not cart_rows:
        return {
            "ok": True,
            "count": 0,
            "total": 0.0,
            "items": [],
            "stale_items": [],
            "message": "Your cart is empty. 🛒",
        }

    # ── 2. Batch-fetch meal details ───────────────────────────────────────────
    meal_ids = [r["meal_id"] for r in cart_rows if r.get("meal_id")]
    meal_q = (
        sb.table("meals")
          .select(
              "id, title, description, category, discounted_price, "
              "restaurant_id, status, expiry_date, quantity_available"
          )
          .in_("id", meal_ids)
    )
    if restaurant_id:
        meal_q = meal_q.eq("restaurant_id", restaurant_id)

    meal_map: Dict[str, Dict] = {
        m["id"]: m for m in (meal_q.execute().data or [])
    }

    # ── 3. Batch-fetch restaurant names ──────────────────────────────────────
    rest_ids = list({
        m["restaurant_id"] for m in meal_map.values() if m.get("restaurant_id")
    })
    rest_map: Dict[str, str] = {}
    if rest_ids:
        rest_rows = (
            sb.table("restaurants")
              .select("profile_id, restaurant_name")
              .in_("profile_id", rest_ids)
              .execute()
              .data or []
        )
        rest_map = {r["profile_id"]: r["restaurant_name"] for r in rest_rows}

    # ── 4. Build line items ───────────────────────────────────────────────────
    now_utc = datetime.now(timezone.utc)
    items: list[Dict[str, Any]] = []
    stale_items: list[Dict[str, Any]] = []

    for row in cart_rows:
        meal_id = row["meal_id"]
        qty = int(row["quantity"])
        meal = meal_map.get(meal_id)

        if meal is None:
            continue  # filtered out by restaurant_id or deleted from DB

        price = float(meal["discounted_price"])
        available = int(meal["quantity_available"])

        # Staleness checks
        is_inactive = meal.get("status") != "active"
        is_expired = False
        if meal.get("expiry_date"):
            expiry = datetime.fromisoformat(meal["expiry_date"])
            is_expired = expiry < now_utc
        is_out_of_stock = available <= 0
        qty_exceeds_stock = qty > available and not is_out_of_stock
        is_stale = is_inactive or is_expired or is_out_of_stock

        line: Dict[str, Any] = {
            "cart_item_id": row["id"],
            "meal_id": meal_id,
            "title": meal["title"],
            "category": meal.get("category"),
            "restaurant_name": rest_map.get(meal.get("restaurant_id", ""), "Unknown"),
            "unit_price": price,
            "quantity": qty,
            "subtotal": round(price * qty, 2),
            "available_stock": available,
            "added_at": row.get("created_at"),
        }

        if qty_exceeds_stock and not is_stale:
            line["warning"] = f"Only {available} in stock — you have {qty} in cart"

        if is_stale:
            reason = (
                "expired" if is_expired
                else "out of stock" if is_out_of_stock
                else f"status: {meal.get('status')}"
            )
            line["stale_reason"] = reason
            stale_items.append(line)
            if include_expired:
                items.append(line)
        else:
            items.append(line)

    # ── 5. Summary ────────────────────────────────────────────────────────────
    active_items = [i for i in items if "stale_reason" not in i]
    grand_total = round(
        sum(i["subtotal"] for i in (items if include_expired else active_items)), 2
    )
    total_qty = sum(i["quantity"] for i in active_items)

    if not active_items and not stale_items:
        message = "Your cart is empty after filtering. 🛒"
    elif not active_items and stale_items:
        message = (
            f"⚠️ Your cart has {len(stale_items)} item(s) that are no longer "
            f"available (expired/out of stock). Your cart is effectively empty."
        )
    else:
        stale_note = (
            f" ⚠️ ({len(stale_items)} stale item(s) hidden)"
            if stale_items and not include_expired
            else ""
        )
        message = (
            f"🛒 You have {len(active_items)} item(s) "
            f"({total_qty} portions) totalling {grand_total} EGP.{stale_note}"
        )

    return {
        "ok": True,
        "user_id": USER_ID,
        "count": len(active_items),
        "total_quantity": total_qty,
        "total": grand_total,
        "items": active_items,
        "stale_items": stale_items,
        "stale_count": len(stale_items),
        "message": message,
    }
