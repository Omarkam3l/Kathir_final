# Boss Food Ordering API

AI-powered food ordering assistant for Cairo with semantic search, cart management, and budget optimization.

## 🚀 Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your API keys

# Run the server
uvicorn main:app --reload

# Or use the batch file (Windows)
start_ui.bat
```

Access the application:
- **Web UI**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

## 📁 Project Structure

```
├── src/
│   ├── api/                    # FastAPI routes
│   │   ├── routes_agent.py     # AI agent chat endpoint
│   │   ├── routes_cart.py      # Cart management
│   │   ├── routes_favorites.py # User favorites
│   │   ├── routes_health.py    # Health check
│   │   └── routes_meals.py     # Meal search
│   ├── tools/                  # LangChain tools
│   │   ├── budget.py           # Budget-based cart builder
│   │   ├── cart.py             # Cart operations
│   │   ├── favorites.py        # Favorites search
│   │   └── meals.py            # Meal search with embeddings
│   ├── utils/                  # Utilities
│   │   ├── auth.py             # Authentication
│   │   ├── db_client.py        # Supabase client
│   │   ├── embeddings.py       # Vector embeddings
│   │   ├── filters.py          # Allergen filtering
│   │   ├── formatters.py       # Response formatting
│   │   ├── nutrition.py        # Nutrition utilities
│   │   └── time_utils.py       # Time utilities
│   ├── boss_agent.py           # LangGraph agent
│   └── prompts.py              # Agent system prompts
├── static/                     # Web UI
│   ├── index.html
│   ├── style.css
│   └── app.js
├── docs/                       # Documentation
├── tests/                      # Test files
├── main.py                     # FastAPI app entry point
├── requirements.txt            # Python dependencies
└── .env.example                # Environment template
```

## 🔑 Features

### 1. AI Agent Chat
- Natural language food ordering
- Context-aware conversations
- Structured JSON responses
- Session management

### 2. Semantic Meal Search
- Vector-based similarity search
- Category filtering
- Price range filtering
- Allergen exclusion/inclusion
- Restaurant filtering by name

### 3. Cart Management
- Add/update items
- View cart with details
- Stock validation
- Expiry checking

### 4. Budget Optimization
- Build carts within budget
- Favorite meal prioritization
- Variety optimization
- Stock-aware selection

### 5. User Favorites
- Save favorite meals
- Search within favorites
- Semantic search support

## 🔐 Security Features

- ✅ No restaurant IDs exposed (name-based filtering only)
- ✅ Dynamic user authentication via JWT
- ✅ No static user IDs
- ✅ Allergen information included
- ✅ CORS configured

## 📡 API Endpoints

### Agent
- `POST /agent/chat` - Chat with AI agent

### Meals
- `GET /meals/search` - Search meals with filters

### Cart
- `GET /cart/` - Get current cart
- `POST /cart/add` - Add item to cart
- `POST /cart/build` - Build budget-optimized cart

### Favorites
- `GET /favorites/search` - Search user favorites

### Health
- `GET /health` - Health check

## 🤖 AI Agent

The Boss AI agent uses:
- **Model**: Google Gemini 2.0 Flash (via OpenRouter)
- **Framework**: LangGraph with ReAct pattern
- **Tools**: 5 specialized tools for food ordering
- **Memory**: Conversation context with MemorySaver

### Agent Capabilities
- Semantic meal search
- Budget-based cart building
- Cart management
- Favorites search
- Natural language understanding

### Response Format
```json
{
  "message": "User-friendly text",
  "data": {
    // Structured data (meals, cart, etc.)
  },
  "action": "search" | "cart" | "build" | null
}
```

## 🔧 Configuration

### Environment Variables

Create `.env` file:
```env
# OpenRouter API (for AI agent)
OPENROUTER_API_KEY=your_key_here

# Hugging Face (for embeddings)
HF_TOKEN=your_token_here

# Supabase (database)
SUPABASE_URL=your_url_here
SUPABASE_KEY=your_key_here
```

### Database Schema

Required Supabase tables:
- `meals` - Meal catalog with embeddings
- `restaurants` - Restaurant information
- `cart_items` - User shopping carts
- `favorites` - User favorite meals

Required RPC function:
- `match_meals` - Vector similarity search

## 🧪 Testing

```bash
# Run all tests
python -m pytest tests/

# Run specific test
python tests/test_api.py
```

## 📚 Documentation

See `docs/` folder for detailed documentation:
- `QUICK_START.md` - Getting started guide
- `API_TESTING_GUIDE.md` - API usage examples
- `AGENT_INTEGRATION_GUIDE.md` - Agent setup
- `AUTHENTICATION_UPDATE.md` - Auth implementation
- `SECURITY_UPDATE.md` - Security features
- `MEAL_FIELDS_UPDATE.md` - Meal data structure
- `RESTAURANT_ID_REMOVAL.md` - Security improvements

## 🎨 Web UI

Modern, responsive chat interface with:
- Real-time agent responses
- Meal cards with details
- Cart summary display
- Quick action buttons
- Session management

## 🛠️ Development

### Run Development Server
```bash
uvicorn main:app --reload
```

### Run Agent CLI
```bash
python -m src.boss_agent
```

### Code Structure
- **API Routes**: FastAPI endpoints in `src/api/`
- **Tools**: LangChain tools in `src/tools/`
- **Utils**: Helper functions in `src/utils/`
- **Agent**: LangGraph agent in `src/boss_agent.py`

## 📦 Dependencies

Key packages:
- `fastapi` - Web framework
- `langchain` - LLM framework
- `langgraph` - Agent framework
- `supabase` - Database client
- `sentence-transformers` - Embeddings
- `uvicorn` - ASGI server

See `requirements.txt` for full list.

## 🚢 Deployment

### Production Checklist
- [ ] Set production environment variables
- [ ] Enable strict authentication
- [ ] Configure CORS for your domain
- [ ] Set up database indexes
- [ ] Configure rate limiting
- [ ] Enable HTTPS
- [ ] Set up monitoring

### Environment
- Python 3.10+
- Supabase database
- OpenRouter API access
- Hugging Face API access

## 📝 License

[Your License Here]

## 🤝 Contributing

[Your Contributing Guidelines Here]

## 📧 Contact

[Your Contact Information Here]

---

Built with ❤️ using FastAPI, LangChain, and Supabase
