# Boss AI Agent - Quick Start Guide

## 🚀 Start the Application

```bash
# Start the API server
uvicorn main:app --reload

# Or use the batch file to start both server and UI
start_ui.bat
```

The server will be available at: `http://localhost:8000`

## 🌐 Access the UI

Open your browser and go to:
```
http://localhost:8000/static/index.html
```

Or just:
```
http://localhost:8000
```

## 🤖 Using the AI Agent

The UI is configured to use the AI agent by default (`USE_AGENT = true` in `app.js`).

### Example Queries

**Search for meals:**
- "show me chicken dishes under 80 EGP"
- "find me gluten-free desserts"
- "what seafood do you have?"
- "show me cheap vegetarian meals"

**View cart:**
- "what's in my cart?"
- "show me my cart"

**Build a cart:**
- "build a cart with 500 EGP budget"
- "create a cart for 300 EGP"

**Favorites:**
- "show me my favorite meals"

## 📊 JSON Response Format

The agent returns structured JSON:

```json
{
  "message": "User-friendly message",
  "data": {
    // Complete tool results
  },
  "action": "search" | "cart" | "build" | null
}
```

## 🧪 Testing

### Test Scripts

```bash
# Simple test (recommended)
python test_simple.py

# Full demo with all features
python demo_agent.py

# Comprehensive API tests
python test_api.py
```

### API Endpoints

```bash
# Health check
curl http://localhost:8000/health

# Search meals
curl "http://localhost:8000/meals/search?query=chicken&max_price=80"

# Agent chat
curl -X POST http://localhost:8000/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "show me chicken dishes"}'
```

## ⚙️ Configuration

### Environment Variables

Edit `.env` file:
```env
OPENROUTER_API_KEY=your_key_here
HF_TOKEN=your_token_here
SUPABASE_URL=your_url_here
SUPABASE_KEY=your_key_here
```

### Agent Settings

Edit `boss_agent.py`:
```python
# Change model
model = "google/gemini-2.0-flash-001"  # Fast, good for most tasks

# Adjust token limit
max_tokens = 2048  # Lower = cheaper, faster
```

### UI Settings

Edit `static/app.js`:
```javascript
// Toggle between AI agent and direct API calls
const USE_AGENT = true;  // true = AI agent, false = direct API

// Change API URL
const API_BASE_URL = 'http://localhost:8000';
```

## 📝 Important Notes

### First Search Query
The first search query will take 30-60 seconds because it loads the embedding model (BAAI/bge-m3). Subsequent searches are fast.

### Restaurant IDs
Restaurant IDs are never exposed in API responses for security. Only restaurant names are shown.

### Session Management
The agent maintains conversation context using session IDs. Each new conversation gets a unique session.

### API Credits
The agent uses OpenRouter API which requires credits. Monitor your usage at: https://openrouter.ai/settings/credits

## 🔧 Troubleshooting

### Server won't start
```bash
# Install dependencies
pip install -r requirements.txt

# Check if port 8000 is available
netstat -ano | findstr :8000
```

### Agent returns errors
- Check your OpenRouter API key in `.env`
- Verify you have API credits
- Check server logs for detailed errors

### Embedding model loading is slow
This is normal for the first search query. The model is cached after the first load.

### UI not connecting
- Make sure the server is running
- Check the browser console for errors
- Verify `API_BASE_URL` in `app.js` is correct

## 📚 Documentation

- `API_TESTING_GUIDE.md` - Complete API documentation
- `AGENT_INTEGRATION_GUIDE.md` - Agent setup and usage
- `JSON_RESPONSE_UPDATE.md` - JSON response format details
- `SECURITY_UPDATE.md` - Security features
- `UI_GUIDE.md` - UI features and usage

## 🎯 Quick Examples

### Python
```python
import requests

response = requests.post(
    "http://localhost:8000/agent/chat",
    json={"message": "show me chicken dishes"}
)
print(response.json())
```

### JavaScript
```javascript
fetch('http://localhost:8000/agent/chat', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({message: 'show me chicken dishes'})
})
.then(r => r.json())
.then(data => console.log(data));
```

### cURL
```bash
curl -X POST http://localhost:8000/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "show me chicken dishes"}'
```

## ✅ Verification

Run this to verify everything is working:
```bash
python demo_agent.py
```

You should see:
- ✅ Cart retrieval working
- ✅ Meal search working (with model loading)
- ✅ Dietary restrictions working
- ✅ Cart building working
- ✅ Category search working

All responses should be valid JSON with complete data!
