"""
tools/nutrition.py
──────────────────
LangChain tool: rank_by_calories

Takes a list of meals (already fetched by search_meals), calls an external
nutrition API for each one, and returns them filtered + sorted by calorie band.

Supported providers (switch via NUTRITION_PROVIDER env var or module constant):
  • nutritionix  — free tier: 500 calls/day
  • edamam       — free tier: 10,000 calls/month
"""

import os
import time
from typing import Any, Dict, List, Literal, Optional

import requests
from langchain_core.tools import tool

# ── Provider config ───────────────────────────────────────────────────────────
NUTRITIONIX_APP_ID = os.environ.get("NUTRITIONIX_APP_ID", "")
NUTRITIONIX_APP_KEY = os.environ.get("NUTRITIONIX_APP_KEY", "")
EDAMAM_APP_ID = os.environ.get("EDAMAM_APP_ID", "")
EDAMAM_APP_KEY = os.environ.get("EDAMAM_APP_KEY", "")

# Change this to "edamam" to switch the active provider
NUTRITION_PROVIDER: Literal["nutritionix", "edamam"] = os.environ.get(
    "NUTRITION_PROVIDER", "nutritionix"
)  # type: ignore[assignment]

CalorieLevel = Literal["low", "medium", "high", "any"]

# Calorie band boundaries (kcal)
_BANDS: Dict[str, tuple[int, int]] = {
    "low":    (0,   400),
    "medium": (400, 700),
    "high":   (700, 9999),
}


# ── Per-provider calorie lookups ──────────────────────────────────────────────

def _query_nutritionix(query: str) -> Optional[int]:
    """
    Natural-language calorie lookup via Nutritionix /v2/natural/nutrients.
    Returns total kcal for the query, or None on failure.
    """
    if not NUTRITIONIX_APP_ID or not NUTRITIONIX_APP_KEY:
        raise EnvironmentError("NUTRITIONIX_APP_ID / NUTRITIONIX_APP_KEY are not set.")

    try:
        resp = requests.post(
            "https://trackapi.nutritionix.com/v2/natural/nutrients",
            json={"query": query},
            headers={
                "x-app-id": NUTRITIONIX_APP_ID,
                "x-app-key": NUTRITIONIX_APP_KEY,
                "Content-Type": "application/json",
            },
            timeout=8,
        )
        resp.raise_for_status()
        foods = resp.json().get("foods", [])
        if not foods:
            return None
        return int(round(sum(f.get("nf_calories", 0) for f in foods)))
    except Exception:
        return None


def _query_edamam(query: str) -> Optional[int]:
    """
    Calorie lookup via Edamam Food Database /api/food-database/v2/parser.
    Returns kcal for the best match, or None on failure.
    """
    if not EDAMAM_APP_ID or not EDAMAM_APP_KEY:
        raise EnvironmentError("EDAMAM_APP_ID / EDAMAM_APP_KEY are not set.")

    try:
        resp = requests.get(
            "https://api.edamam.com/api/food-database/v2/parser",
            params={
                "app_id": EDAMAM_APP_ID,
                "app_key": EDAMAM_APP_KEY,
                "ingr": query,
                "nutrition-type": "logging",
            },
            timeout=8,
        )
        resp.raise_for_status()
        hints = resp.json().get("hints", [])
        if not hints:
            return None
        kcal = hints[0].get("food", {}).get("nutrients", {}).get("ENERC_KCAL")
        return int(round(kcal)) if kcal is not None else None
    except Exception:
        return None


# ── Internal helpers ──────────────────────────────────────────────────────────

def _get_calories(query: str) -> Optional[int]:
    """Route to the configured provider."""
    if NUTRITION_PROVIDER == "nutritionix":
        return _query_nutritionix(query)
    return _query_edamam(query)


def _calorie_level(kcal: int) -> CalorieLevel:
    for level, (lo, hi) in _BANDS.items():
        if lo <= kcal < hi:
            return level  # type: ignore[return-value]
    return "high"


def _build_query(meal: Dict[str, Any]) -> str:
    """
    Construct the best query string for the nutrition API.
    Combines title with the first sentence of the description for richer context.
    """
    title = meal.get("title") or ""
    desc = (meal.get("description") or "").split(".")[0].strip()
    return f"{title}. {desc}" if desc else title


# ── Main tool ─────────────────────────────────────────────────────────────────

@tool("rank_by_calories")
def rank_by_calories(
    meals: List[Dict[str, Any]],
    target: CalorieLevel = "low",
    limit: int = 5,
) -> Dict[str, Any]:
    """
    Enrich a meals list with real calorie data, then filter and sort by
    calorie band.

    Always call search_meals first to get the meals list, then pass its
    'results' list to this tool.

    Args:
        meals  : The 'results' list from a previous search_meals call.
        target : "low" (< 400 kcal), "medium" (400–700 kcal),
                 "high" (> 700 kcal), or "any" (no filter, just sort).
        limit  : Max results to return (default 5).

    Returns:
        Dict with results (filtered + sorted), count, not_found list,
        dominant_level, and an optional suggestion string.
    """
    if not meals:
        return {
            "ok": False,
            "error": "No meals provided — call search_meals first.",
            "results": [],
        }

    enriched: List[Dict[str, Any]] = []
    not_found: List[Dict[str, Any]] = []

    for meal in meals:
        query = _build_query(meal)
        kcal = _get_calories(query)

        if kcal is None:
            not_found.append({**meal, "estimated_calories": None, "calorie_level": "unknown"})
        else:
            enriched.append({
                **meal,
                "estimated_calories": kcal,
                "calorie_level": _calorie_level(kcal),
            })

        time.sleep(0.15)  # stay within API rate limits

    # Filter by target band
    if target == "any":
        filtered = enriched
    else:
        lo, hi = _BANDS[target]
        filtered = [m for m in enriched if lo <= (m["estimated_calories"] or 0) < hi]

    # Sort low → high calories
    filtered.sort(key=lambda m: m["estimated_calories"] or 0)

    # Determine dominant calorie level across all resolved meals
    level_counts: Dict[str, int] = {}
    for m in enriched:
        lvl = m["calorie_level"]
        level_counts[lvl] = level_counts.get(lvl, 0) + 1

    dominant_level = max(level_counts, key=lambda k: level_counts[k]) if level_counts else "unknown"
    all_same_level = len(level_counts) == 1

    # Build a helpful suggestion when results are thin
    suggestion = ""
    if not filtered and target != "any":
        suggestion = (
            f"No {target}-calorie meals found in this batch. "
            f"All resolved meals are {dominant_level}-calorie. "
            f"Shall I run a new search targeting {target}-calorie options?"
        )
    elif all_same_level and target != "any" and dominant_level != target:
        suggestion = (
            f"Every meal in this batch is {dominant_level}-calorie. "
            f"Want me to search for {target}-calorie meals specifically?"
        )

    return {
        "ok": True,
        "provider": NUTRITION_PROVIDER,
        "target": target,
        "results": filtered[:limit],
        "count": len(filtered),
        "not_found": not_found,
        "all_same_level": all_same_level,
        "dominant_level": dominant_level,
        "suggestion": suggestion,
    }
