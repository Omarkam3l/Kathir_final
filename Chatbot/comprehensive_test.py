"""
Comprehensive Test Suite for Boss Food Ordering API
Tests all functionalities with detailed output
Run with: python comprehensive_test.py
"""

import requests
import json
from typing import Dict, Any, List
from datetime import datetime

BASE_URL = "http://localhost:8000"

class Colors:
    """ANSI color codes for terminal output"""
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def print_header(title: str):
    """Print a formatted header"""
    print(f"\n{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.CYAN}{title.center(70)}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.RESET}\n")

def print_test(name: str, passed: bool, details: str = ""):
    """Print test result"""
    status = f"{Colors.GREEN}✓ PASS{Colors.RESET}" if passed else f"{Colors.RED}✗ FAIL{Colors.RESET}"
    print(f"{status} | {name}")
    if details:
        print(f"       {Colors.YELLOW}{details}{Colors.RESET}")

def print_data(label: str, data: Any):
    """Print formatted data"""
    print(f"{Colors.BLUE}{label}:{Colors.RESET}")
    if isinstance(data, (dict, list)):
        print(json.dumps(data, indent=2))
    else:
        print(data)
    print()

# ============================================================================
# TEST 1: HEALTH & READINESS
# ============================================================================

def test_health_endpoints():
    """Test health and readiness endpoints"""
    print_header("TEST 1: HEALTH & READINESS CHECKS")
    
    # Test 1.1: Health check
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        data = response.json()
        passed = response.status_code == 200 and data.get("status") == "ok"
        print_test("Health Check", passed, f"Status: {data.get('status')}")
    except Exception as e:
        print_test("Health Check", False, str(e))
    
    # Test 1.2: Readiness check
    try:
        response = requests.get(f"{BASE_URL}/ready", timeout=5)
        data = response.json()
        passed = response.status_code == 200 and data.get("status") == "ready"
        print_test("Readiness Check", passed, f"DB: {data.get('db')}")
    except Exception as e:
        print_test("Readiness Check", False, str(e))
    
    # Test 1.3: Root endpoint
    try:
        response = requests.get(f"{BASE_URL}/", timeout=5)
        data = response.json()
        passed = response.status_code == 200 and "message" in data
        print_test("Root Endpoint", passed, data.get("message", ""))
    except Exception as e:
        print_test("Root Endpoint", False, str(e))

# ============================================================================
# TEST 2: MEAL SEARCH - BASIC
# ============================================================================

def test_meal_search_basic():
    """Test basic meal search functionality"""
    print_header("TEST 2: MEAL SEARCH - BASIC QUERIES")
    
    test_queries = [
        ("chicken", "Search for 'chicken'"),
        ("seafood", "Search for 'seafood'"),
        ("dessert", "Search for 'dessert'"),
        ("", "Empty query (should return results)"),
    ]
    
    for query, description in test_queries:
        try:
            response = requests.get(
                f"{BASE_URL}/meals/search",
                params={"query": query, "limit": 3}
            )
            data = response.json()
            passed = response.status_code == 200 and data.get("ok")
            count = data.get("count", 0)
            print_test(description, passed, f"Found {count} meals")
            
            if count > 0 and data.get("results"):
                for meal in data["results"][:2]:
                    print(f"       - {meal['title']} ({meal['price']} EGP)")
        except Exception as e:
            print_test(description, False, str(e))

# ============================================================================
# TEST 3: MEAL SEARCH - FILTERS
# ============================================================================

def test_meal_search_filters():
    """Test meal search with various filters"""
    print_header("TEST 3: MEAL SEARCH - FILTERS")
    
    # Test 3.1: Category filter
    categories = ["Meals", "Desserts", "Meat & Poultry", "Seafood", "Bakery", "Vegetables"]
    print(f"{Colors.BOLD}Testing Category Filters:{Colors.RESET}")
    for category in categories:
        try:
            response = requests.get(
                f"{BASE_URL}/meals/search",
                params={"category": category, "limit": 2}
            )
            data = response.json()
            passed = response.status_code == 200 and data.get("ok")
            count = data.get("count", 0)
            print_test(f"Category: {category}", passed, f"{count} items")
        except Exception as e:
            print_test(f"Category: {category}", False, str(e))
    
    # Test 3.2: Price filters
    print(f"\n{Colors.BOLD}Testing Price Filters:{Colors.RESET}")
    price_tests = [
        ({"max_price": 50}, "Max price 50 EGP"),
        ({"min_price": 100}, "Min price 100 EGP"),
        ({"min_price": 30, "max_price": 80}, "Price range 30-80 EGP"),
    ]
    
    for params, description in price_tests:
        try:
            params["limit"] = 3
            response = requests.get(f"{BASE_URL}/meals/search", params=params)
            data = response.json()
            passed = response.status_code == 200 and data.get("ok")
            count = data.get("count", 0)
            print_test(description, passed, f"{count} meals")
            
            if count > 0 and data.get("results"):
                prices = [m['price'] for m in data["results"]]
                print(f"       Prices: {prices}")
        except Exception as e:
            print_test(description, False, str(e))
    
    # Test 3.3: Sorting
    print(f"\n{Colors.BOLD}Testing Sorting:{Colors.RESET}")
    try:
        response = requests.get(
            f"{BASE_URL}/meals/search",
            params={"category": "Bakery", "sort": "price_asc", "limit": 5}
        )
        data = response.json()
        passed = response.status_code == 200 and data.get("ok")
        
        if passed and data.get("results"):
            prices = [m['price'] for m in data["results"]]
            is_sorted = prices == sorted(prices)
            print_test("Sort by price ascending", is_sorted, f"Prices: {prices}")
        else:
            print_test("Sort by price ascending", passed)
    except Exception as e:
        print_test("Sort by price ascending", False, str(e))

# ============================================================================
# TEST 4: ALLERGEN FILTERING
# ============================================================================

def test_allergen_filtering():
    """Test allergen filtering"""
    print_header("TEST 4: ALLERGEN FILTERING")
    
    allergens = ["gluten", "dairy", "eggs", "shellfish", "tree nuts"]
    
    for allergen in allergens:
        try:
            response = requests.get(
                f"{BASE_URL}/meals/search",
                params={
                    "query": "meal",
                    "exclude_allergens": [allergen],
                    "limit": 3
                }
            )
            data = response.json()
            passed = response.status_code == 200 and data.get("ok")
            count = data.get("count", 0)
            
            # Verify no results contain the excluded allergen
            valid = True
            if data.get("results"):
                for meal in data["results"]:
                    if allergen in meal.get("allergens", []):
                        valid = False
                        break
            
            status = passed and valid
            print_test(f"Exclude {allergen}", status, f"{count} {allergen}-free meals")
            
            if count > 0 and data.get("results"):
                meal = data["results"][0]
                allergen_list = ", ".join(meal.get("allergens", [])) or "None"
                print(f"       Example: {meal['title']} (Allergens: {allergen_list})")
        except Exception as e:
            print_test(f"Exclude {allergen}", False, str(e))

# ============================================================================
# TEST 5: SEMANTIC SEARCH
# ============================================================================

def test_semantic_search():
    """Test semantic search capabilities"""
    print_header("TEST 5: SEMANTIC SEARCH & RELEVANCE")
    
    queries = [
        "grilled chicken with vegetables",
        "chocolate dessert",
        "fresh seafood platter",
        "healthy breakfast options",
    ]
    
    for query in queries:
        try:
            response = requests.get(
                f"{BASE_URL}/meals/search",
                params={"query": query, "limit": 3, "min_similarity": 0.5}
            )
            data = response.json()
            passed = response.status_code == 200 and data.get("ok")
            count = data.get("count", 0)
            
            print_test(f"Query: '{query}'", passed, f"{count} relevant results")
            
            if count > 0 and data.get("results"):
                for meal in data["results"]:
                    score = meal.get("score", 0)
                    print(f"       - {meal['title']} (Relevance: {score:.3f})")
        except Exception as e:
            print_test(f"Query: '{query}'", False, str(e))

# ============================================================================
# TEST 6: CART OPERATIONS
# ============================================================================

def test_cart_operations():
    """Test cart operations"""
    print_header("TEST 6: CART OPERATIONS")
    
    # Test 6.1: Get current cart
    print(f"{Colors.BOLD}6.1 Get Current Cart:{Colors.RESET}")
    try:
        response = requests.get(f"{BASE_URL}/cart/")
        data = response.json()
        passed = response.status_code == 200 and data.get("ok")
        
        if passed:
            count = data.get("count", 0)
            total = data.get("total", 0)
            quantity = data.get("total_quantity", 0)
            print_test("Get cart", True, f"{count} items, {quantity} portions, {total} EGP")
            
            if count > 0 and data.get("items"):
                print(f"\n       {Colors.BOLD}Cart Items:{Colors.RESET}")
                for item in data["items"][:5]:
                    print(f"       - {item['title']}: {item['quantity']}x @ {item['unit_price']} EGP = {item['subtotal']} EGP")
                    print(f"         Stock: {item['available_stock']}, Restaurant: {item.get('restaurant_name', 'N/A')}")
        else:
            print_test("Get cart", False)
    except Exception as e:
        print_test("Get cart", False, str(e))
    
    # Test 6.2: Get cart with filters
    print(f"\n{Colors.BOLD}6.2 Get Cart with Filters:{Colors.RESET}")
    try:
        response = requests.get(
            f"{BASE_URL}/cart/",
            params={"include_expired": False}
        )
        data = response.json()
        passed = response.status_code == 200 and data.get("ok")
        stale_count = data.get("stale_count", 0)
        print_test("Get cart (exclude expired)", passed, f"Stale items: {stale_count}")
    except Exception as e:
        print_test("Get cart (exclude expired)", False, str(e))
    
    # Test 6.3: Add to cart (will need a valid meal ID)
    print(f"\n{Colors.BOLD}6.3 Add to Cart:{Colors.RESET}")
    try:
        # First get a meal ID
        search_response = requests.get(
            f"{BASE_URL}/meals/search",
            params={"limit": 1}
        )
        search_data = search_response.json()
        
        if search_data.get("results"):
            meal_id = search_data["results"][0]["id"]
            meal_title = search_data["results"][0]["title"]
            
            # Try to add to cart
            response = requests.post(
                f"{BASE_URL}/cart/add",
                json={"meal_id": meal_id, "quantity": 1}
            )
            
            if response.status_code == 200:
                data = response.json()
                passed = data.get("ok", False)
                print_test(f"Add '{meal_title}' to cart", passed, data.get("message", ""))
            else:
                print_test(f"Add '{meal_title}' to cart", False, f"Status: {response.status_code}")
        else:
            print_test("Add to cart", False, "No meals found to add")
    except Exception as e:
        print_test("Add to cart", False, str(e))

# ============================================================================
# TEST 7: BUILD CART
# ============================================================================

def test_build_cart():
    """Test cart building functionality"""
    print_header("TEST 7: BUILD CART WITH BUDGET")
    
    # First get a restaurant ID
    try:
        search_response = requests.get(
            f"{BASE_URL}/meals/search",
            params={"limit": 1}
        )
        search_data = search_response.json()
        
        if not search_data.get("results"):
            print_test("Build cart", False, "No meals found to build cart")
            return
        
        restaurant_id = search_data["results"][0]["restaurant_id"]
        
        # Test different budgets
        budgets = [
            (200, 3, "Small budget"),
            (500, 5, "Medium budget"),
            (1000, 7, "Large budget"),
        ]
        
        for budget, target_meals, description in budgets:
            try:
                response = requests.post(
                    f"{BASE_URL}/cart/build",
                    json={
                        "budget": budget,
                        "restaurant_id": restaurant_id,
                        "target_meal_count": target_meals,
                        "max_qty_per_meal": 3
                    }
                )
                data = response.json()
                passed = response.status_code == 200
                
                if data.get("ok"):
                    count = data.get("count", 0)
                    total = data.get("total", 0)
                    remaining = data.get("remaining_budget", 0)
                    print_test(
                        f"{description} ({budget} EGP)",
                        True,
                        f"{count} items, Total: {total} EGP, Remaining: {remaining} EGP"
                    )
                    
                    if data.get("items"):
                        print(f"       {Colors.BOLD}Selected items:{Colors.RESET}")
                        for item in data["items"][:3]:
                            print(f"       - {item['title']}: {item['quantity']}x @ {item['unit_price']} EGP")
                else:
                    print_test(f"{description} ({budget} EGP)", False, data.get("error", "Unknown error"))
            except Exception as e:
                print_test(f"{description} ({budget} EGP)", False, str(e))
    except Exception as e:
        print_test("Build cart", False, str(e))

# ============================================================================
# TEST 8: FAVORITES
# ============================================================================

def test_favorites():
    """Test favorites functionality"""
    print_header("TEST 8: FAVORITES SEARCH")
    
    # Note: This requires a valid user_id with favorites
    test_user_id = "11111111-1111-1111-1111-111111111111"
    
    # Test 8.1: Search all favorites
    try:
        response = requests.get(
            f"{BASE_URL}/favorites/search",
            params={"user_id": test_user_id, "limit": 10}
        )
        data = response.json()
        passed = response.status_code == 200 and data.get("ok")
        count = data.get("count", 0)
        
        print_test("Get all favorites", passed, f"{count} favorites found")
        
        if count > 0 and data.get("results"):
            print(f"\n       {Colors.BOLD}Favorite meals:{Colors.RESET}")
            for meal in data["results"][:5]:
                print(f"       - {meal['title']} ({meal['category']}) - {meal['price']} EGP")
    except Exception as e:
        print_test("Get all favorites", False, str(e))
    
    # Test 8.2: Search favorites with query
    try:
        response = requests.get(
            f"{BASE_URL}/favorites/search",
            params={
                "user_id": test_user_id,
                "query": "chicken",
                "limit": 5
            }
        )
        data = response.json()
        passed = response.status_code == 200 and data.get("ok")
        count = data.get("count", 0)
        
        print_test("Search favorites with query", passed, f"{count} matching favorites")
    except Exception as e:
        print_test("Search favorites with query", False, str(e))

# ============================================================================
# TEST 9: EDGE CASES
# ============================================================================

def test_edge_cases():
    """Test edge cases and error handling"""
    print_header("TEST 9: EDGE CASES & ERROR HANDLING")
    
    # Test 9.1: Invalid parameters
    try:
        response = requests.get(
            f"{BASE_URL}/meals/search",
            params={"limit": 1000}  # Exceeds max
        )
        # Should either cap at max or return error
        passed = response.status_code in [200, 422]
        print_test("Limit exceeds maximum", passed, f"Status: {response.status_code}")
    except Exception as e:
        print_test("Limit exceeds maximum", False, str(e))
    
    # Test 9.2: Invalid category
    try:
        response = requests.get(
            f"{BASE_URL}/meals/search",
            params={"category": "InvalidCategory"}
        )
        data = response.json()
        passed = response.status_code == 200
        count = data.get("count", 0)
        print_test("Invalid category", passed, f"Returned {count} results (expected 0)")
    except Exception as e:
        print_test("Invalid category", False, str(e))
    
    # Test 9.3: Build cart without restaurant
    try:
        response = requests.post(
            f"{BASE_URL}/cart/build",
            json={"budget": 500}
        )
        data = response.json()
        # Should return error about missing restaurant
        passed = not data.get("ok") and "restaurant" in data.get("error", "").lower()
        print_test("Build cart without restaurant", passed, data.get("error", ""))
    except Exception as e:
        print_test("Build cart without restaurant", False, str(e))
    
    # Test 9.4: Add invalid meal to cart
    try:
        response = requests.post(
            f"{BASE_URL}/cart/add",
            json={"meal_id": "00000000-0000-0000-0000-000000000000", "quantity": 1}
        )
        # Should handle gracefully
        passed = response.status_code in [200, 404, 500]
        print_test("Add invalid meal to cart", passed, f"Status: {response.status_code}")
    except Exception as e:
        print_test("Add invalid meal to cart", False, str(e))

# ============================================================================
# TEST 10: PERFORMANCE
# ============================================================================

def test_performance():
    """Test API performance"""
    print_header("TEST 10: PERFORMANCE TESTS")
    
    import time
    
    endpoints = [
        ("/health", "GET", None),
        ("/meals/search?query=chicken&limit=10", "GET", None),
        ("/cart/", "GET", None),
    ]
    
    for endpoint, method, body in endpoints:
        try:
            start = time.time()
            
            if method == "GET":
                response = requests.get(f"{BASE_URL}{endpoint}")
            else:
                response = requests.post(f"{BASE_URL}{endpoint}", json=body)
            
            elapsed = (time.time() - start) * 1000  # Convert to ms
            
            passed = response.status_code == 200 and elapsed < 2000  # Under 2 seconds
            print_test(
                f"{method} {endpoint}",
                passed,
                f"{elapsed:.0f}ms"
            )
        except Exception as e:
            print_test(f"{method} {endpoint}", False, str(e))

# ============================================================================
# MAIN TEST RUNNER
# ============================================================================

def main():
    """Run all tests"""
    print(f"\n{Colors.BOLD}{Colors.BLUE}")
    print("╔" + "═" * 68 + "╗")
    print("║" + "BOSS FOOD ORDERING API - COMPREHENSIVE TEST SUITE".center(68) + "║")
    print("║" + f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}".center(68) + "║")
    print("╚" + "═" * 68 + "╝")
    print(Colors.RESET)
    
    try:
        # Check if server is running
        response = requests.get(f"{BASE_URL}/health", timeout=2)
        if response.status_code != 200:
            print(f"{Colors.RED}❌ Server is not responding correctly!{Colors.RESET}")
            return
    except requests.exceptions.ConnectionError:
        print(f"{Colors.RED}❌ Cannot connect to server at {BASE_URL}{Colors.RESET}")
        print(f"{Colors.YELLOW}   Start with: python -m uvicorn main:app --reload{Colors.RESET}")
        return
    
    # Run all test suites
    test_health_endpoints()
    test_meal_search_basic()
    test_meal_search_filters()
    test_allergen_filtering()
    test_semantic_search()
    test_cart_operations()
    test_build_cart()
    test_favorites()
    test_edge_cases()
    test_performance()
    
    # Summary
    print_header("TEST SUMMARY")
    print(f"{Colors.GREEN}✓ All test suites completed{Colors.RESET}")
    print(f"\n{Colors.BOLD}API Documentation:{Colors.RESET} {BASE_URL}/docs")
    print(f"{Colors.BOLD}OpenAPI Schema:{Colors.RESET} {BASE_URL}/openapi.json\n")

if __name__ == "__main__":
    main()
