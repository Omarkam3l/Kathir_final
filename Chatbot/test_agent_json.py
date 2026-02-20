"""
Test script for agent JSON responses
"""
import requests
import json

API_BASE = "http://localhost:8000"

def test_agent_chat(message):
    """Test agent chat endpoint"""
    print(f"\n{'='*60}")
    print(f"Testing: {message}")
    print('='*60)
    
    try:
        response = requests.post(
            f"{API_BASE}/agent/chat",
            json={
                "message": message,
                "user_id": "11111111-1111-1111-1111-111111111111"
            },
            timeout=30
        )
        
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"\nResponse OK: {data.get('ok')}")
            print(f"Session ID: {data.get('session_id')}")
            
            # Parse the agent response
            agent_response = data.get('response', '')
            print(f"\nRaw Response:\n{agent_response}")
            
            # Try to parse as JSON
            try:
                parsed = json.loads(agent_response)
                print(f"\n✓ Valid JSON!")
                print(f"Message: {parsed.get('message')}")
                print(f"Action: {parsed.get('action')}")
                print(f"Data: {json.dumps(parsed.get('data'), indent=2)}")
            except json.JSONDecodeError as e:
                print(f"\n✗ Invalid JSON: {e}")
        else:
            print(f"\nError Response:\n{response.text}")
            
    except Exception as e:
        print(f"\n✗ Request failed: {e}")

if __name__ == "__main__":
    # Test various queries
    test_agent_chat("show me chicken dishes under 80 EGP")
    test_agent_chat("what's in my cart?")
    test_agent_chat("build a cart with 500 EGP budget")
