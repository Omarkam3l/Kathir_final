from typing import Any, Dict, List, Optional


def apply_allergen_filters(
    rows: List[Dict[str, Any]],
    exclude_allergens: Optional[List[str]],
    require_allergens: Optional[List[str]],
) -> List[Dict[str, Any]]:
    """
    Post-filter a list of meal rows by allergen constraints.

    exclude_allergens: meals must NOT contain any of these allergens.
                       e.g. ["gluten"] → gluten-free results only.
    require_allergens: meals must contain ALL of these allergens (rare use-case).

    The `allergens` column is expected to be a list of lowercase strings on each row.
    """
    if not exclude_allergens and not require_allergens:
        return rows

    out = []
    for row in rows:
        allergens = [a.lower() for a in (row.get("allergens") or [])]

        if exclude_allergens:
            if any(a.lower() in allergens for a in exclude_allergens):
                continue  # contains a banned allergen — skip

        if require_allergens:
            if not all(a.lower() in allergens for a in require_allergens):
                continue  # missing a required allergen — skip

        out.append(row)

    return out
