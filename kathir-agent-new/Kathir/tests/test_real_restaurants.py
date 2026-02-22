"""Test with real restaurant names"""
from dotenv import load_dotenv
load_dotenv()

import meals

print("Testing restaurant name search with actual names:\n")

# Test with actual restaurant names
test_cases = [
    ("Malfoof Restaurant", "full name"),
    ("Malfoof", "partial name"),
    ("malfoof", "lowercase"),
    ("test1", "test1 restaurant"),
    ("Mohamed", "Mohamed restaurant"),
]

for name, description in test_cases:
    print(f"Testing '{name}' ({description}):")
    try:
        # Search without query to just test restaurant filter
        result = meals.search_meals.func(restaurant_name=name, limit=3)
        if result['ok']:
            print(f"  ✓ Found {result['count']} meals")
            if result['count'] > 0:
                print(f"    First: {result['results'][0]['title']}")
        else:
            print(f"  ✗ Error: {result.get('error')}")
    except Exception as e:
        print(f"  ✗ Exception: {e}")
    print()
