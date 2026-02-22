"""
tools/meals.py
──────────────
LangChain tool: search_meals

All-in-one meal search supporting:
  • Semantic (embedding-based) search
  • Restaurant filter (by ID, list of IDs, or partial name)
  • Price range filter
  • Category filter
  • Allergen include/exclude filter
  • Sort by relevance or price ascending
"""

from typing import Any, Dict, List, Literal, Optional

from langchain.tools import tool

from db_client import sb
from embeddings import encode_query
from filters import apply_allergen_filters
from formatters import format_meal_row
from time_utils import now_iso

SortMode = Literal["relevance", "price_asc"]


@tool("search_meals")
def search_meals(
    query: str = "",
    restaurant_id: Optional[str] = None,
    restaurant_ids: Optional[List[str]] = None,
    restaurant_name: Optional[str] = None,
    max_price: Optional[float] = None,
    min_price: Optional[float] = None,
    category: Optional[str] = None,
    exclude_allergens: Optional[List[str]] = None,
    require_allergens: Optional[List[str]] = None,
    limit: int = 8,
    min_similarity: float = 0.55,
    sort: SortMode = "relevance",
) -> Dict[str, Any]:
    """
    All-in-one meal search.

    Dietary / allergen filtering:
      exclude_allergens: list of allergens the result must NOT contain.
                         Use for: gluten-free → ["gluten"]
                                  dairy-free  → ["dairy", "milk"]
                                  nut-free    → ["nuts", "peanuts"]
                                  vegan       → ["meat", "dairy", "eggs", "honey"]
      require_allergens: list of allergens the result MUST contain (rare).

    Other filters:
      query           : semantic search string
      restaurant_name : partial name match
      max_price       : upper price bound in EGP
      min_price       : lower price bound in EGP
      category        : exact category string (e.g. "Desserts", "Bakery", "Meat & Poultry")
      min_similarity  : cosine threshold 0–1, default 0.55 (lower to 0.4 for dietary queries)
      sort            : "relevance" (default) or "price_asc"
    """
    # ── 1. Resolve restaurant IDs ─────────────────────────────────────────────
    rids = list(restaurant_ids or [])
    if restaurant_id:
        rids = [restaurant_id] + rids
    if restaurant_name and not rids:
        rest = (
            sb.table("restaurants")
              .select("profile_id")
              .ilike("restaurant_name", f"%{restaurant_name}%")
              .limit(3)
              .execute()
              .data
        )
        if rest:
            rids = [r["profile_id"] for r in rest]
        else:
            return {
                "ok": False,
                "error": f"No restaurant matching '{restaurant_name}'",
                "results": [],
            }

    # ── 2. Base DB query ──────────────────────────────────────────────────────
    base_q = (
        sb.table("meals")
          .select("id, title, description, category, discounted_price, allergens, restaurants(restaurant_name)")
          .eq("status", "active")
          .gt("quantity_available", 0)
          .gt("expiry_date", now_iso())
    )

    if rids:
        base_q = base_q.in_("restaurant_id", rids)
    if max_price is not None:
        base_q = base_q.lte("discounted_price", float(max_price))
    if min_price is not None:
        base_q = base_q.gte("discounted_price", float(min_price))
    if category:
        base_q = base_q.eq("category", category)

    # ── 3. No query → filtered browse ────────────────────────────────────────
    if not (query or "").strip():
        rows = base_q.order("discounted_price").limit(limit * 4).execute().data or []
        rows = apply_allergen_filters(rows, exclude_allergens, require_allergens)
        results = [format_meal_row(r) for r in rows[:limit]]
        return {
            "ok": True,
            "query": "",
            "restaurant_name": restaurant_name,
            "max_price": max_price,
            "exclude_allergens": exclude_allergens,
            "results": results,
            "count": len(results),
            "sort": sort,
        }

    # ── 4. Semantic search ────────────────────────────────────────────────────
    fetch_count = limit * 5
    query_emb = encode_query(query)

    vec_res = sb.rpc("match_meals", {
        "query_embedding": query_emb,
        "match_threshold": float(min_similarity),
        "match_count": fetch_count,
    }).execute()

    matched_ids = [r["id"] for r in (vec_res.data or [])]

    if matched_ids:
        rows = base_q.in_("id", matched_ids).limit(fetch_count).execute().data or []
        score_map = {
            r["id"]: float(r.get("similarity", 0))
            for r in (vec_res.data or [])
        }
    else:
        # Text fallback when no vector matches found
        term = f"%{query}%"
        rows = (
            base_q.or_(f"title.ilike.{term},description.ilike.{term},category.ilike.{term}")
                  .limit(limit * 2)
                  .execute()
                  .data or []
        )
        score_map = {}

    # ── 5. Allergen filter → sort → slice ─────────────────────────────────────
    rows = apply_allergen_filters(rows, exclude_allergens, require_allergens)
    results = [format_meal_row(r, score_map) for r in rows]

    if sort == "price_asc":
        results.sort(key=lambda x: x["price"])
    else:
        results.sort(key=lambda x: (x["score"] is None, -(x["score"] or 0.0)))

    results = results[:limit]

    return {
        "ok": True,
        "query": query,
        "restaurant_name": restaurant_name,
        "max_price": max_price,
        "min_price": min_price,
        "category": category,
        "exclude_allergens": exclude_allergens,
        "require_allergens": require_allergens,
        "count": len(results),
        "results": results,
        "sort": sort,
    }
