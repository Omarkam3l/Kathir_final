"""
Interactive API Tester for Boss Food Ordering API
Run with: python interactive_test.py
"""

import requests
import json

BASE_URL = "http://localhost:8000"

def print_json(data):
    """Pretty print JSON"""
    print(json.dumps(data, indent=2))

def test_meal_search():
    """Interactive meal search"""
    print("\n" + "="*60)
    print("MEAL SEARCH TEST")
    print("="*60)
    
    queries = [
        {"query": "chicken", "limit": 3},
        {"query": "seafood", "category": "Seafood", "limit": 3},
        {"query": "dessert", "max_price": 50, "limit": 3},
        {"category": "Bakery", "sort": "price_asc", "limit": 5},
    ]
    
    for params in queries:
        print(f"\nSearching with: {params}")
        response = requests.get(f"{BASE_URL}/meals/search", params=params)
        data = response.json()
        
        if data.get("ok") and data.get("count", 0) > 0:
            print(f"Found {data['count']} meals:")
            for meal in data["results"]:
                print(f"  - {meal['title']} ({meal['category']}) - {meal['price']} EGP")
                if meal.get('score'):
                    print(f"    Relevance: {meal['score']:.2f}")
        else:
            print("  No results found")

def test_cart_operations():
    """Test cart operations"""
    print("\n" + "="*60)
    print("CART OPERATIONS TEST")
    print("="*60)
    
    # Get current cart
    print("\n1. Getting current cart...")
    response = requests.get(f"{BASE_URL}/cart/")
    cart = response.json()
    
    if cart.get("ok"):
        print(f"Cart has {cart['count']} items, total: {cart['total']} EGP")
        if cart['count'] > 0:
            print("\nItems in cart:")
            for item in cart['items'][:3]:  # Show first 3
                print(f"  - {item['title']}: {item['quantity']}x @ {item['unit_price']} EGP")

def test_build_cart():
    """Test cart building with different budgets"""
    print("\n" + "="*60)
    print("BUILD CART TEST")
    print("="*60)
    
    # First, get a restaurant ID from meals
    print("\n1. Finding available restaurants...")
    response = requests.get(f"{BASE_URL}/meals/search", params={"limit": 1})
    meals = response.json()
    
    if meals.get("results"):
        restaurant_id = meals["results"][0]["restaurant_id"]
        restaurant_name = meals["results"][0].get("restaurant_name", "Unknown")
        print(f"Using restaurant: {restaurant_name} ({restaurant_id})")
        
        # Test different budgets
        budgets = [200, 500, 1000]
        
        for budget in budgets:
            print(f"\n2. Building cart with {budget} EGP budget...")
            response = requests.post(
                f"{BASE_URL}/cart/build",
                json={
                    "budget": budget,
                    "restaurant_id": restaurant_id,
                    "target_meal_count": 5,
                    "max_qty_per_meal": 3
                }
            )
            result = response.json()
            
            if result.get("ok"):
                print(f"   ✓ Built cart: {result.get('count', 0)} items")
                print(f"   Total: {result.get('total', 0)} EGP")
                print(f"   Remaining: {result.get('remaining_budget', 0)} EGP")
                
                if result.get('items'):
                    print("   Items:")
                    for item in result['items'][:3]:
                        print(f"     - {item['title']}: {item['quantity']}x @ {item['unit_price']} EGP")
            else:
                print(f"   ✗ Error: {result.get('error', 'Unknown error')}")

def test_categories():
    """Test searching by different categories"""
    print("\n" + "="*60)
    print("CATEGORY SEARCH TEST")
    print("="*60)
    
    categories = ["Meals", "Desserts", "Meat & Poultry", "Seafood", "Bakery", "Vegetables"]
    
    for category in categories:
        response = requests.get(
            f"{BASE_URL}/meals/search",
            params={"category": category, "limit": 2, "sort": "price_asc"}
        )
        data = response.json()
        
        if data.get("ok") and data.get("count", 0) > 0:
            print(f"\n{category}: {data['count']} items")
            for meal in data["results"]:
                allergens = ", ".join(meal.get("allergens", [])) or "None"
                print(f"  - {meal['title']}: {meal['price']} EGP (Allergens: {allergens})")

def test_allergen_filtering():
    """Test allergen filtering"""
    print("\n" + "="*60)
    print("ALLERGEN FILTERING TEST")
    print("="*60)
    
    allergens_to_exclude = ["gluten", "dairy", "eggs"]
    
    for allergen in allergens_to_exclude:
        print(f"\nSearching for meals without {allergen}...")
        response = requests.get(
            f"{BASE_URL}/meals/search",
            params={
                "query": "meal",
                "exclude_allergens": [allergen],
                "limit": 3
            }
        )
        data = response.json()
        
        if data.get("ok") and data.get("count", 0) > 0:
            print(f"Found {data['count']} {allergen}-free meals:")
            for meal in data["results"]:
                allergens = ", ".join(meal.get("allergens", [])) or "None"
                print(f"  - {meal['title']} (Allergens: {allergens})")

def main():
    """Run all interactive tests"""
    print("\n" + "="*60)
    print("BOSS FOOD ORDERING API - INTERACTIVE TEST")
    print("="*60)
    
    try:
        # Check if server is running
        response = requests.get(f"{BASE_URL}/health", timeout=2)
        if response.status_code != 200:
            print("❌ Server is not responding correctly!")
            return
        print("✓ Server is running")
        
        # Run tests
        test_meal_search()
        test_categories()
        test_allergen_filtering()
        test_cart_operations()
        test_build_cart()
        
        print("\n" + "="*60)
        print("✓ ALL TESTS COMPLETED")
        print("="*60)
        print(f"\nAPI Documentation: {BASE_URL}/docs")
        print(f"OpenAPI Schema: {BASE_URL}/openapi.json")
        print()
        
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to server. Is it running?")
        print(f"   Start with: python -m uvicorn main:app --reload")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
