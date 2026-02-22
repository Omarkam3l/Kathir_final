"""Test restaurant name search"""
from dotenv import load_dotenv
load_dotenv()

from db_client import sb
import meals

print("="*60)
print("TESTING RESTAURANT SEARCH")
print("="*60)

# Get all restaurants
print("\n1. Available Restaurants:")
restaurants = sb.table('restaurants').select('profile_id, restaurant_name').execute().data
for r in restaurants:
    print(f"   - {r['restaurant_name']} (ID: {r['profile_id']})")

# Test search by name
print("\n2. Testing search by restaurant name:")
test_names = [
    "Taste of Egypt",
    "taste",
    "egypt",
    "Mediterranean",
    "Grill"
]

for name in test_names:
    print(f"\n   Searching for: '{name}'")
    result = meals.search_meals.func(query="chicken", restaurant_name=name, limit=3)
    if result['ok']:
        print(f"   ✓ Found {result['count']} meals")
        if result['count'] > 0:
            print(f"     First meal: {result['results'][0]['title']}")
    else:
        print(f"   ✗ Error: {result.get('error', 'Unknown error')}")

# Test search by ID
print("\n3. Testing search by restaurant ID:")
if restaurants:
    test_id = restaurants[0]['profile_id']
    test_name = restaurants[0]['restaurant_name']
    print(f"   Using ID: {test_id} ({test_name})")
    result = meals.search_meals.func(query="chicken", restaurant_id=test_id, limit=3)
    if result['ok']:
        print(f"   ✓ Found {result['count']} meals")
    else:
        print(f"   ✗ Error: {result.get('error', 'Unknown error')}")

print("\n" + "="*60)
