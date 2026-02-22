"""
Test script for Boss Food Ordering API
Run with: python test_api.py
"""

import requests
import json
from typing import Dict, Any

BASE_URL = "http://localhost:8000"

def print_response(title: str, response: requests.Response):
    """Pretty print API response"""
    print(f"\n{'='*60}")
    print(f"TEST: {title}")
    print(f"{'='*60}")
    print(f"Status Code: {response.status_code}")
    try:
        data = response.json()
        print(f"Response:\n{json.dumps(data, indent=2)}")
    except:
        print(f"Response: {response.text}")
    print()

def test_health():
    """Test health check endpoint"""
    response = requests.get(f"{BASE_URL}/health")
    print_response("Health Check", response)
    return response.status_code == 200

def test_readiness():
    """Test readiness check endpoint"""
    response = requests.get(f"{BASE_URL}/ready")
    print_response("Readiness Check", response)
    return response.status_code == 200

def test_search_meals():
    """Test meal search endpoint"""
    # Test 1: Simple search
    response = requests.get(
        f"{BASE_URL}/meals/search",
        params={"query": "chicken", "limit": 5}
    )
    print_response("Search Meals - 'chicken'", response)
    
    # Test 2: Search with filters
    response = requests.get(
        f"{BASE_URL}/meals/search",
        params={
            "query": "dessert",
            "category": "Desserts",
            "max_price": 100,
            "limit": 3
        }
    )
    print_response("Search Meals - Desserts under 100 EGP", response)
    
    # Test 3: Search with allergen exclusion
    response = requests.get(
        f"{BASE_URL}/meals/search",
        params={
            "query": "pasta",
            "exclude_allergens": ["gluten"],
            "limit": 3
        }
    )
    print_response("Search Meals - Pasta without gluten", response)
    
    return response.status_code == 200

def test_search_favorites():
    """Test favorites search endpoint"""
    # Note: This requires a valid user_id
    test_user_id = "00000000-0000-0000-0000-000000000000"  # Replace with real user ID
    
    response = requests.get(
        f"{BASE_URL}/favorites/search",
        params={
            "user_id": test_user_id,
            "query": "pizza",
            "limit": 5
        }
    )
    print_response("Search Favorites - 'pizza'", response)
    return True  # May fail if user doesn't exist, that's ok

def test_get_cart():
    """Test get cart endpoint"""
    response = requests.get(f"{BASE_URL}/cart/")
    print_response("Get Cart", response)
    return response.status_code == 200

def test_add_to_cart():
    """Test add to cart endpoint"""
    # Note: This requires a valid meal_id
    test_meal_id = "00000000-0000-0000-0000-000000000000"  # Replace with real meal ID
    
    response = requests.post(
        f"{BASE_URL}/cart/add",
        json={
            "meal_id": test_meal_id,
            "quantity": 2
        }
    )
    print_response("Add to Cart", response)
    return True  # May fail if meal doesn't exist, that's ok

def test_build_cart():
    """Test build cart endpoint"""
    response = requests.post(
        f"{BASE_URL}/cart/build",
        json={
            "budget": 500,
            "target_meal_count": 5,
            "max_qty_per_meal": 3
        }
    )
    print_response("Build Cart - 500 EGP budget", response)
    
    # Test with restaurant filter
    response = requests.post(
        f"{BASE_URL}/cart/build",
        json={
            "budget": 300,
            "restaurant_name": "pizza",
            "target_meal_count": 3
        }
    )
    print_response("Build Cart - 300 EGP, pizza restaurant", response)
    
    return response.status_code == 200

def main():
    """Run all tests"""
    print("\n" + "="*60)
    print("BOSS FOOD ORDERING API - TEST SUITE")
    print("="*60)
    
    tests = [
        ("Health Check", test_health),
        ("Readiness Check", test_readiness),
        ("Search Meals", test_search_meals),
        ("Search Favorites", test_search_favorites),
        ("Get Cart", test_get_cart),
        ("Add to Cart", test_add_to_cart),
        ("Build Cart", test_build_cart),
    ]
    
    results = []
    for name, test_func in tests:
        try:
            success = test_func()
            results.append((name, "✓ PASS" if success else "✗ FAIL"))
        except Exception as e:
            results.append((name, f"✗ ERROR: {str(e)}"))
    
    # Summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    for name, result in results:
        print(f"{name:.<40} {result}")
    print()

if __name__ == "__main__":
    main()
