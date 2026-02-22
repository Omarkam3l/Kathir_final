"""Test that meal search returns all fields except excluded ones"""
from dotenv import load_dotenv
load_dotenv()

import meals

print("Testing meal search output fields:\n")

# Test search (will return empty since no meals in DB, but we can check the structure)
result = meals.search_meals.func(query="", limit=5)

print(f"Search result keys: {result.keys()}")
print(f"OK: {result['ok']}")
print(f"Count: {result['count']}")

if result['count'] > 0:
    print("\nFirst meal fields:")
    first_meal = result['results'][0]
    for key, value in first_meal.items():
        print(f"  {key}: {type(value).__name__}")
    
    print("\n✅ Expected fields present:")
    expected_fields = [
        'id', 'title', 'description', 'category', 'price',
        'restaurant_name', 'allergens', 'status', 
        'expiry_date', 'quantity_available', 'score'
    ]
    for field in expected_fields:
        status = "✓" if field in first_meal else "✗"
        print(f"  {status} {field}")
    
    print("\n❌ Excluded fields (should NOT be present):")
    excluded_fields = ['embedding', 'created_at', 'updated_at', 'restaurant_id']
    for field in excluded_fields:
        status = "✓ (correctly excluded)" if field not in first_meal else "✗ (ERROR: should be excluded)"
        print(f"  {status} {field}")
else:
    print("\nNo meals in database to test with.")
    print("Expected output format:")
    print("""
    {
        "id": "meal-uuid",
        "title": "Meal Name",
        "description": "Full description (not truncated)",
        "category": "Category",
        "price": 75.0,
        "restaurant_name": "Restaurant Name",
        "allergens": ["allergen1", "allergen2"],
        "status": "active",
        "expiry_date": "2026-02-28T00:00:00",
        "quantity_available": 10,
        "score": 0.85  // or null if not from semantic search
    }
    
    Excluded fields (NOT in output):
    - embedding
    - created_at
    - updated_at
    - restaurant_id
    """)
