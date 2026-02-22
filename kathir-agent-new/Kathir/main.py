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
from fastapi.middleware.cors import CORSMiddleware

# Load environment variables from .env file
load_dotenv()

from src.api.routes_cart import router as cart_router
from src.api.routes_favorites import router as favorites_router
from src.api.routes_health import router as health_router
from src.api.routes_meals import router as meals_router
from src.api.routes_agent import router as agent_router

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

@app.get("/")
async def root():
    """API root endpoint"""
    return {
        "message": "Boss Food Ordering API",
        "version": "1.0.0",
        "docs": "/docs",
        "redoc": "/redoc",
        "health": "/health",
        "endpoints": {
            "agent_chat": "/agent/chat",
            "agent_info": "/agent/info",
            "meals_search": "/meals/search",
            "favorites_search": "/favorites/search",
            "cart_get": "/cart/",
            "cart_add": "/cart/add",
            "cart_build": "/cart/build"
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
