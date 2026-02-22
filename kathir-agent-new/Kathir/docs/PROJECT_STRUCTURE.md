# Project Structure

## Overview

The Boss Food Ordering API has been reorganized into a clean, modular structure following Python best practices.

## Directory Structure

```
Boss-Food-Ordering-API/
├── src/                        # Source code
│   ├── api/                    # FastAPI routes
│   │   ├── __init__.py
│   │   ├── routes_agent.py     # AI agent chat endpoint
│   │   ├── routes_cart.py      # Cart management endpoints
│   │   ├── routes_favorites.py # Favorites endpoints
│   │   ├── routes_health.py    # Health check endpoint
│   │   └── routes_meals.py     # Meal search endpoints
│   │
│   ├── tools/                  # LangChain tools
│   │   ├── __init__.py
│   │   ├── budget.py           # Budget-based cart builder
│   │   ├── cart.py             # Cart operations (add, get)
│   │   ├── favorites.py        # Favorites search
│   │   └── meals.py            # Meal search with embeddings
│   │
│   ├── utils/                  # Utility modules
│   │   ├── __init__.py
│   │   ├── auth.py             # Authentication helpers
│   │   ├── db_client.py        # Supabase database client
│   │   ├── embeddings.py       # Vector embeddings
│   │   ├── filters.py          # Allergen filtering
│   │   ├── formatters.py       # Response formatting
│   │   ├── nutrition.py        # Nutrition utilities
│   │   └── time_utils.py       # Time/date utilities
│   │
│   ├── __init__.py
│   ├── boss_agent.py           # LangGraph ReAct agent
│   └── prompts.py              # Agent system prompts
│
├── static/                     # Web UI assets
│   ├── index.html              # Chat interface
│   ├── style.css               # Styles
│   └── app.js                  # Frontend logic
│
├── docs/                       # Documentation
│   ├── QUICK_START.md
│   ├── API_TESTING_GUIDE.md
│   ├── AGENT_INTEGRATION_GUIDE.md
│   ├── AUTHENTICATION_UPDATE.md
│   ├── SECURITY_UPDATE.md
│   ├── MEAL_FIELDS_UPDATE.md
│   ├── RESTAURANT_ID_REMOVAL.md
│   ├── UI_GUIDE.md
│   └── ... (other docs)
│
├── tests/                      # Test files
│   ├── test_api.py
│   ├── test_agent.py
│   ├── demo_agent.py
│   └── ... (other tests)
│
├── .kiro/                      # Kiro IDE configuration
│   └── hooks/
│
├── main.py                     # FastAPI application entry point
├── requirements.txt            # Python dependencies
├── .env                        # Environment variables (not in git)
├── .env.example                # Environment template
├── .gitignore                  # Git ignore rules
├── README.md                   # Project documentation
└── start_ui.bat                # Windows launcher script
```

## Module Organization

### src/api/ - API Routes

FastAPI route handlers organized by resource:

- **routes_agent.py**: AI agent chat endpoint with session management
- **routes_cart.py**: Cart CRUD operations and budget builder
- **routes_favorites.py**: User favorites search
- **routes_health.py**: Health check and status
- **routes_meals.py**: Meal search with filters

All routes use dependency injection for authentication.

### src/tools/ - LangChain Tools

LangChain tool implementations for the AI agent:

- **meals.py**: Semantic meal search with vector embeddings
- **cart.py**: Add to cart and get cart operations
- **budget.py**: Budget-optimized cart builder
- **favorites.py**: Search within user favorites

Each tool is decorated with `@tool()` for LangChain integration.

### src/utils/ - Utilities

Shared utility modules:

- **auth.py**: Authentication helpers (JWT validation, user extraction)
- **db_client.py**: Supabase client singleton
- **embeddings.py**: Vector embedding generation
- **filters.py**: Allergen filtering logic
- **formatters.py**: Response formatting and sanitization
- **nutrition.py**: Nutrition-related utilities
- **time_utils.py**: Time/date helpers

### src/ - Core Agent

- **boss_agent.py**: LangGraph ReAct agent configuration
- **prompts.py**: System prompts and instructions for the agent

## Import Structure

All imports use absolute paths from the `src` package:

```python
# API routes
from src.api.routes_agent import router as agent_router

# Tools
from src.tools.meals import search_meals
from src.tools.cart import add_to_cart, get_cart

# Utils
from src.utils.db_client import sb
from src.utils.auth import get_current_user
```

## Configuration Files

### .env
Environment variables (not in version control):
- API keys (OpenRouter, Hugging Face)
- Database credentials (Supabase)

### .env.example
Template for environment variables

### requirements.txt
Python package dependencies

### .gitignore
Excludes:
- `.env`
- `__pycache__/`
- `*.pyc`
- Virtual environments

## Static Assets

### static/
Web UI files served by FastAPI:
- **index.html**: Chat interface
- **style.css**: Modern gradient design
- **app.js**: Frontend logic with JSON response handling

## Documentation

### docs/
Comprehensive documentation:
- Setup guides
- API documentation
- Security updates
- Feature explanations
- Migration guides

## Tests

### tests/
Test files for:
- API endpoints
- Agent functionality
- Tool operations
- Integration tests

## Entry Points

### main.py
FastAPI application with:
- Route registration
- CORS middleware
- Static file serving
- API documentation

### start_ui.bat
Windows batch script to:
1. Start uvicorn server
2. Open browser to UI

## Benefits of This Structure

### 1. Modularity
- Clear separation of concerns
- Easy to find and modify code
- Reusable components

### 2. Scalability
- Easy to add new routes
- Simple to add new tools
- Organized utilities

### 3. Maintainability
- Logical file organization
- Clear import paths
- Documented structure

### 4. Testability
- Isolated modules
- Easy to mock dependencies
- Clear test organization

### 5. Professional
- Follows Python best practices
- Standard project layout
- Clean repository

## Migration Notes

### Old Structure
```
├── routes_agent.py
├── routes_cart.py
├── meals.py
├── cart.py
├── db_client.py
└── ... (all in root)
```

### New Structure
```
├── src/
│   ├── api/routes_agent.py
│   ├── tools/meals.py
│   └── utils/db_client.py
└── main.py
```

### Import Changes
```python
# Old
from meals import search_meals

# New
from src.tools.meals import search_meals
```

All imports have been automatically updated.

## Development Workflow

1. **Add new API endpoint**: Create in `src/api/`
2. **Add new tool**: Create in `src/tools/`
3. **Add utility**: Create in `src/utils/`
4. **Update agent**: Modify `src/boss_agent.py` or `src/prompts.py`
5. **Add tests**: Create in `tests/`
6. **Document**: Add to `docs/`

## Summary

The project is now organized into a clean, professional structure that:
- ✅ Separates concerns (API, tools, utils)
- ✅ Uses absolute imports
- ✅ Follows Python conventions
- ✅ Is easy to navigate
- ✅ Is ready for production
