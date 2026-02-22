"""
Demo script showing the Boss AI agent with JSON responses
"""
import requests
import json
import time

API_BASE = "http://localhost:8000"

def print_section(title):
    """Print a section header"""
    print(f"\n{'='*70}")
    print(f"  {title}")
    print('='*70)

def chat(message, session_id=None):
    """Send a message to the agent and display the response"""
    print(f"\n👤 You: {message}")
    print("🤖 Boss: ", end="", flush=True)
    
    try:
        response = requests.post(
            f"{API_BASE}/agent/chat",
            json={
                "message": message,
                "session_id": session_id,
                "user_id": "11111111-1111-1111-1111-111111111111"
            },
            timeout=120
        )
        
        if response.status_code == 200:
            data = response.json()
            agent_response = json.loads(data['response'])
            
            # Print message
            print(agent_response['message'])
            
            # Print data summary
            if agent_response['data']:
                print(f"\n   📊 Data Type: {agent_response['action']}")
                
                if 'meals' in agent_response['data']:
                    meals = agent_response['data']['meals']
                    print(f"   🍽️  Found {len(meals)} meals:")
                    for meal in meals[:3]:  # Show first 3
                        print(f"      • {meal['title']} - {meal['price']} EGP")
                    if len(meals) > 3:
                        print(f"      ... and {len(meals) - 3} more")
                        
                elif 'items' in agent_response['data']:
                    items = agent_response['data']['items']
                    total = agent_response['data'].get('total', 0)
                    print(f"   🛒 {len(items)} items, Total: {total} EGP")
                    for item in items[:3]:  # Show first 3
                        print(f"      • {item['title']} x{item['quantity']} = {item['subtotal']} EGP")
                    if len(items) > 3:
                        print(f"      ... and {len(items) - 3} more")
                        
                    if 'remaining_budget' in agent_response['data']:
                        print(f"   💰 Remaining: {agent_response['data']['remaining_budget']} EGP")
            
            return data['session_id']
        else:
            print(f"❌ Error: {response.status_code}")
            print(response.text)
            return None
            
    except Exception as e:
        print(f"❌ Failed: {e}")
        return None

def main():
    """Run the demo"""
    print("\n" + "="*70)
    print("  🤖 BOSS AI AGENT - JSON RESPONSE DEMO")
    print("="*70)
    print("\n  This demo shows the agent returning structured JSON responses")
    print("  with complete data from tool calls.")
    print("\n  Note: First search query will load the embedding model (~30-60s)")
    
    # Test 1: View cart
    print_section("TEST 1: View Cart")
    session = chat("what's in my cart?")
    time.sleep(1)
    
    # Test 2: Search meals
    print_section("TEST 2: Search Meals")
    print("\n⏳ Loading embedding model (this may take 30-60 seconds)...")
    session = chat("show me chicken dishes under 80 EGP", session)
    time.sleep(1)
    
    # Test 3: Search with allergens
    print_section("TEST 3: Search with Dietary Restrictions")
    session = chat("find me gluten-free desserts", session)
    time.sleep(1)
    
    # Test 4: Build cart
    print_section("TEST 4: Build Cart with Budget")
    session = chat("build a cart with 300 EGP budget", session)
    time.sleep(1)
    
    # Test 5: Search by category
    print_section("TEST 5: Search by Category")
    session = chat("show me seafood dishes", session)
    
    print("\n" + "="*70)
    print("  ✅ DEMO COMPLETE")
    print("="*70)
    print("\n  All responses returned structured JSON with:")
    print("    • message: User-friendly text")
    print("    • data: Complete tool results")
    print("    • action: Response type (search/cart/build)")
    print("\n  The UI can now parse this JSON and display it appropriately!")
    print()

if __name__ == "__main__":
    main()
