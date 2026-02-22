"""
tools/favorites.py
──────────────────
LangChain tool: search_favorites

Searches inside a user's saved/favourite meals.
  • No query  → direct DB filter on the favorites set
  • With query → semantic embedding search, intersected with favorites
"""

from typing import Any, Dict, List, Optional

from langchain.tools import tool

from src.utils.db_client import sb
from src.utils.embeddings import encode_query
from src.utils.time_utils import now_iso


@tool("search_favorites")
def search_favorites(
    user_id: str,
    query: str = "",
    limit: int = 8,
    category: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    min_similarity: float = 0.55,
) -> Dict[str, Any]:
    """
    Search inside the user's favourite meals.

    - If query is given: semantic search (embeddings) intersected with favorites.
    - Otherwise: direct filter on the favorites set.
    - Supports category and price filters.

    Args:
        user_id       : Required — the authenticated user's UUID.
        query         : Optional semantic search string.
        limit         : Max results to return (1–50).
        category      : Exact category filter (e.g. "Desserts").
        min_price     : Lower price bound in EGP.
        max_price     : Upper price bound in EGP.
        min_similarity: Cosine similarity threshold for semantic search (default 0.55).
        
    Note: Restaurant IDs are not exposed for security. Results include restaurant_name.
    """
    if not user_id:
        return {"ok": False, "error": "user_id is required"}

    limit = max(1, min(int(limit), 50))

    # ── 1. Fetch the user's favorite meal IDs ─────────────────────────────────
    fav_rows = (
        sb.table("favorites")
          .select("meal_id")
          .eq("user_id", user_id)
          .limit(5000)
          .execute()
          .data or []
    )
    fav_ids = [r["meal_id"] for r in fav_rows if r.get("meal_id")]

    if not fav_ids:
        return {"ok": True, "count": 0, "results": [], "message": "No favorite meals yet."}

    # ── 2. Base query with common filters ─────────────────────────────────────
    base_q = (
        sb.table("meals")
          .select("id, title, description, category, discounted_price, restaurant_id, restaurants(restaurant_name)")
          .in_("id", fav_ids)
          .eq("status", "active")
          .gt("quantity_available", 0)
          .gt("expiry_date", now_iso())
    )

    if category:
        base_q = base_q.eq("category", category)
    if min_price is not None:
        base_q = base_q.gte("discounted_price", float(min_price))
    if max_price is not None:
        base_q = base_q.lte("discounted_price", float(max_price))

    def _clean(row: Dict[str, Any], score: Optional[float] = None) -> Dict[str, Any]:
        desc = (row.get("description") or "").strip()
        # Get restaurant name from nested object or fallback
        restaurant_name = "Unknown Restaurant"
        if isinstance(row.get("restaurants"), dict):
            restaurant_name = row["restaurants"].get("restaurant_name", "Unknown Restaurant")
        elif row.get("restaurant_name"):
            restaurant_name = row["restaurant_name"]
            
        return {
            "meal_id": row["id"],
            "title": row["title"],
            "description": desc[:140] if desc else "",
            "category": row.get("category"),
            "price": float(row["discounted_price"]),
            "restaurant_name": restaurant_name,
            "score": score,
        }

    qtext = (query or "").strip()

    # ── 3A. No query → simple filtered list ──────────────────────────────────
    if not qtext:
        rows = base_q.order("discounted_price").limit(limit).execute().data or []
        results = [_clean(r) for r in rows]
        return {
            "ok": True,
            "count": len(results),
            "results": results,
            "message": f"Found {len(results)} favorite meals.",
        }

    # ── 3B. Semantic search → intersect with favorites ────────────────────────
    query_emb = encode_query(qtext)
    vec_rows = (
        sb.rpc("match_meals", {
            "query_embedding": query_emb,
            "match_threshold": float(min_similarity),
            "match_count": limit * 10,
        })
        .execute()
        .data or []
    )

    fav_set = set(fav_ids)
    intersect_ids = [r["id"] for r in vec_rows if r.get("id") in fav_set]

    if not intersect_ids:
        return {
            "ok": True,
            "count": 0,
            "results": [],
            "message": f"No favorites matched '{qtext}'.",
        }

    score_map = {
        r["id"]: float(r.get("similarity", r.get("score", 0)))
        for r in vec_rows
        if "id" in r
    }

    rows = base_q.in_("id", intersect_ids).limit(limit * 3).execute().data or []
    results = [_clean(r, score_map.get(r["id"])) for r in rows]

    # Sort: highest relevance first, then price ascending
    results.sort(key=lambda x: (x["score"] is None, -(x["score"] or 0.0), x["price"]))
    results = results[:limit]

    return {
        "ok": True,
        "count": len(results),
        "results": results,
        "message": f"Found {len(results)} favorites matching '{qtext}'.",
    }
