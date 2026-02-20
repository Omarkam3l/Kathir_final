"""
Test the Boss AI Agent
Run with: python test_agent.py
"""

import requests
import json

BASE_URL = "http://localhost:8000"

def print_response(title, response_text):
    """Pretty print response"""
    print(f"\n{'='*70}")
    print(f"{title}")
    print(f"{'='*70}")
    print(response_text)
    print()

def test_agent():
    """Test the agent with various queries"""
    
    print("\n" + "="*70)
    print("TESTING BOSS AI AGENT")
    print("="*70)
    
    # Test queries
    queries = [
        "Show me chicken dishes",
        "I want seafood under 100 EGP",
        "I need gluten-free desserts",
        "Build a cart with 500 EGP budget",
        "What's in my cart?",
        "Show me my favorite meals",
    ]
    
    session_id = None
    
    for i, query in enumerate(queries, 1):
        print(f"\n[Query {i}] You: {query}")
        
        try:
            response = requests.post(
                f"{BASE_URL}/agent/chat",
                json={
                    "message": query,
                    "session_id": session_id
                }
            )
            
            data = response.json()
            
            if data.get("ok"):
                session_id = data["session_id"]
                print(f"Boss: {data['response']}")
                print(f"(Session: {session_id[:8]}..., Messages: {data.get('message_count', 'N/A')})")
            else:
                print(f"Error: {data}")
                
        except Exception as e:
            print(f"Error: {e}")
        
        print("-" * 70)
    
    # Test agent info
    print("\n" + "="*70)
    print("AGENT INFORMATION")
    print("="*70)
    
    try:
        response = requests.get(f"{BASE_URL}/agent/info")
        data = response.json()
        print(json.dumps(data, indent=2))
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_agent()
