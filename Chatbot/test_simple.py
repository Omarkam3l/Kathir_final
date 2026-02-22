"""
Simple test for agent - one query at a time
"""
import requests
import json

API_BASE = "http://localhost:8000"

def test_query(message):
    """Test a single query"""
    print(f"\n{'='*60}")
    print(f"Query: {message}")
    print('='*60)
    
    try:
        response = requests.post(
            f"{API_BASE}/agent/chat",
            json={"message": message},
            timeout=120  # 2 minutes for first query (model loading)
        )
        
        if response.status_code == 200:
            data = response.json()
            agent_response = json.loads(data['response'])
            
            print(f"✓ Message: {agent_response['message']}")
            print(f"✓ Action: {agent_response['action']}")
            
            if agent_response['data']:
                print(f"✓ Data keys: {list(agent_response['data'].keys())}")
                
                # Show sample data
                if 'meals' in agent_response['data']:
                    meals = agent_response['data']['meals']
                    print(f"  - Found {len(meals)} meals")
                    if meals:
                        print(f"  - First meal: {meals[0]['title']} - {meals[0]['price']} EGP")
                        
                elif 'items' in agent_response['data']:
                    items = agent_response['data']['items']
                    print(f"  - Found {len(items)} items")
                    print(f"  - Total: {agent_response['data'].get('total')} EGP")
            else:
                print("✗ No data returned")
                
        else:
            print(f"✗ Error: {response.status_code}")
            print(response.text)
            
    except Exception as e:
        print(f"✗ Failed: {e}")

if __name__ == "__main__":
    # Test cart first (no model loading needed)
    test_query("what's in my cart?")
    
    # Then test search (will load model)
    print("\n\nNow testing search (this will load the embedding model, please wait...)...")
    test_query("show me chicken dishes under 80 EGP")
    
    # Then test build
    test_query("build a cart with 300 EGP budget")
