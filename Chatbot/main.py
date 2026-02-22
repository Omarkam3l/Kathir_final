"""
main.py
───────
FastAPI application entry point.

Run locally:
    uvicorn main:app --reload

Run the CLI chat loop instead:
    python -m agents.boss_agent
"""

import os
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.responses import Response
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware

# Load environment variables from .env file
load_dotenv()

from routes_cart import router as cart_router
from routes_favorites import router as favorites_router
from routes_health import router as health_router
from routes_meals import router as meals_router
from routes_agent import router as agent_router

app = FastAPI(
    title="Boss Food Ordering API",
    description="Cairo food-ordering assistant — meal search, favorites, and cart management.",
    version="1.0.0",
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/")
async def root():
    """Redirect to chat UI"""
    from fastapi.responses import RedirectResponse
    return RedirectResponse(url="/static/index.html")

@app.get("/api")
async def api_info():
    """API information endpoint"""
    return {
        "message": "Welcome to Boss Food Ordering API",
        "version": "1.0.0",
        "docs": "/docs",
        "redoc": "/redoc",
        "openapi": "/openapi.json",
        "chat_ui": "/static/index.html",
        "endpoints": {
            "health": "/health",
            "meals": "/meals/search",
            "favorites": "/favorites/search",
            "cart": "/cart/",
            "build_cart": "/cart/build"
        }
    }

@app.get("/favicon.ico")
async def favicon():
    """Return empty favicon to prevent 404 errors"""
    return Response(content=b"", media_type="image/x-icon")

app.include_router(health_router, tags=["Health"])
app.include_router(agent_router, prefix="/agent", tags=["Agent"])
app.include_router(meals_router, prefix="/meals", tags=["Meals"])
app.include_router(favorites_router, prefix="/favorites", tags=["Favorites"])
app.include_router(cart_router, prefix="/cart", tags=["Cart"])
