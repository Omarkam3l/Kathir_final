"""Check meals in database"""
from dotenv import load_dotenv
load_dotenv()

from db_client import sb
from time_utils import now_iso

print("Checking meals in database:\n")

# Get sample meals
meals = sb.table('meals').select('id, title, restaurant_id, status, quantity_available, expiry_date').limit(10).execute().data

print(f"Total meals fetched: {len(meals)}\n")

for m in meals:
    print(f"Title: {m['title']}")
    print(f"  Restaurant ID: {m['restaurant_id']}")
    print(f"  Status: {m['status']}")
    print(f"  Quantity: {m['quantity_available']}")
    print(f"  Expiry: {m['expiry_date']}")
    print()

# Check active meals with quantity
print("\nActive meals with quantity > 0:")
active = sb.table('meals').select('id, title, restaurant_id').eq('status', 'active').gt('quantity_available', 0).limit(5).execute().data
print(f"Found: {len(active)} meals")
for m in active:
    print(f"  - {m['title']} (Restaurant: {m['restaurant_id']})")

# Check if expiry date is the issue
print(f"\nCurrent time: {now_iso()}")
print("\nActive meals with quantity > 0 and not expired:")
active_not_expired = sb.table('meals').select('id, title, restaurant_id, expiry_date').eq('status', 'active').gt('quantity_available', 0).gt('expiry_date', now_iso()).limit(5).execute().data
print(f"Found: {len(active_not_expired)} meals")
for m in active_not_expired:
    print(f"  - {m['title']} (Expiry: {m['expiry_date']})")
