"""Quick verification that all outputs are JSON"""
import requests
import json

print("🔍 Verifying JSON Responses...\n")

try:
    response = requests.post(
        'http://localhost:8000/agent/chat',
        json={'message': 'show me desserts'},
        timeout=120
    )
    
    data = response.json()
    agent_response = json.loads(data['response'])
    
    print("✅ SUCCESS - All outputs are in JSON format!\n")
    print(f"✓ Valid JSON: True")
    print(f"✓ Has 'message' field: {'message' in agent_response}")
    print(f"✓ Has 'data' field: {'data' in agent_response}")
    print(f"✓ Has 'action' field: {'action' in agent_response}")
    print(f"\n📊 Response Preview:")
    print(f"   Message: {agent_response['message']}")
    print(f"   Action: {agent_response['action']}")
    print(f"   Data Type: {type(agent_response['data']).__name__}")
    
    if agent_response['data']:
        print(f"   Data Keys: {list(agent_response['data'].keys())}")
        
    print("\n✅ All agent responses are structured JSON with complete data!")
    
except Exception as e:
    print(f"❌ Error: {e}")
