from typing import Any, Dict


def format_meal_row(row: Dict[str, Any], score_map: Dict[str, float] = {}) -> Dict[str, Any]:
    """
    Normalize a raw meals DB row into the standard agent-facing shape.
    
    Returns all meal data except: embedding, created_at, updated_at, restaurant_id
    Note: restaurant_id is excluded for security - only restaurant_name is exposed.
    score_map: optional {meal_id: similarity_score} from a vector search call.
    """
    # Extract restaurant name from nested object or use fallback
    restaurant_name = "Unknown Restaurant"
    if isinstance(row.get("restaurants"), dict):
        restaurant_name = row["restaurants"].get("restaurant_name", "Unknown Restaurant")
    elif row.get("restaurant_name"):
        restaurant_name = row["restaurant_name"]
    
    return {
        "id": row["id"],
        "title": row["title"],
        "description": row.get("description") or "",
        "category": row.get("category"),
        "image_url": row.get("image_url"),
        "price": float(row["discounted_price"]),
        "restaurant_name": restaurant_name,
        "allergens": row.get("allergens") or [],
        "status": row.get("status"),
        "expiry_date": row.get("expiry_date"),
        "quantity_available": row.get("quantity_available"),
        "score": score_map.get(row["id"]),
    }
