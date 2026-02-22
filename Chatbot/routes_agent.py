"""
routes_agent.py
───────────────
FastAPI routes for the Boss AI agent.
"""

import uuid
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from boss_agent import create_agent

router = APIRouter()

# Global agent instance (singleton)
_agent = None
_sessions = {}  # Store session threads


def get_agent():
    """Get or create the global agent instance"""
    global _agent
    if _agent is None:
        _agent = create_agent()
    return _agent


class ChatRequest(BaseModel):
    """Request model for chat endpoint"""
    message: str = Field(..., description="User message to the agent")
    session_id: Optional[str] = Field(None, description="Session ID for conversation continuity")
    user_id: Optional[str] = Field("11111111-1111-1111-1111-111111111111", description="User ID for personalization")


class ChatResponse(BaseModel):
    """Response model for chat endpoint"""
    ok: bool
    response: str
    session_id: str
    message_count: Optional[int] = None


@router.post("/chat", response_model=ChatResponse)
async def chat_with_agent(request: ChatRequest):
    """
    Chat with the Boss AI agent.
    
    The agent returns structured JSON responses with:
    - message: User-friendly text
    - data: Structured data (meals, cart, etc.)
    - action: Type of response (search, cart, build, etc.)
    
    Example requests:
    - "Show me chicken dishes under 80 EGP"
    - "I need gluten-free desserts"
    - "Build a cart with 500 EGP budget"
    - "What's in my cart?"
    """
    try:
        agent = get_agent()
        
        # Get or create session
        session_id = request.session_id or str(uuid.uuid4())
        
        # Create config for this session
        config = {"configurable": {"thread_id": session_id}}
        
        # Add context (time, location, user_id)
        now = datetime.now().strftime("%Y-%m-%d %H:%M")
        contextual_message = f"[context: current time={now}, location=Cairo EG, user_id={request.user_id}]\n{request.message}"
        
        # Invoke agent
        result = agent.invoke(
            {"messages": [{"role": "user", "content": contextual_message}]},
            config,
        )
        
        # Extract response
        response_content = result["messages"][-1].content
        message_count = len(result["messages"])
        
        # Try to parse JSON response
        import json
        import re
        
        # Extract JSON from response (in case there's extra text)
        json_match = re.search(r'\{.*\}', response_content, re.DOTALL)
        if json_match:
            try:
                parsed_json = json.loads(json_match.group())
                # Return structured response
                response_content = json.dumps(parsed_json, ensure_ascii=False)
            except json.JSONDecodeError:
                # If JSON parsing fails, wrap in standard format
                response_content = json.dumps({
                    "message": response_content,
                    "data": None,
                    "action": None
                }, ensure_ascii=False)
        else:
            # No JSON found, wrap response
            response_content = json.dumps({
                "message": response_content,
                "data": None,
                "action": None
            }, ensure_ascii=False)
        
        # Store session
        if session_id not in _sessions:
            _sessions[session_id] = {"created_at": datetime.now(), "message_count": 0}
        _sessions[session_id]["message_count"] = message_count
        
        return ChatResponse(
            ok=True,
            response=response_content,
            session_id=session_id,
            message_count=message_count
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Agent error: {str(e)}")


@router.get("/sessions")
async def list_sessions():
    """List all active chat sessions"""
    return {
        "ok": True,
        "sessions": {
            sid: {
                "created_at": info["created_at"].isoformat(),
                "message_count": info["message_count"]
            }
            for sid, info in _sessions.items()
        },
        "count": len(_sessions)
    }


@router.delete("/sessions/{session_id}")
async def delete_session(session_id: str):
    """Delete a chat session"""
    if session_id in _sessions:
        del _sessions[session_id]
        return {"ok": True, "message": f"Session {session_id} deleted"}
    else:
        raise HTTPException(status_code=404, detail="Session not found")


@router.get("/agent/info")
async def agent_info():
    """Get information about the agent"""
    return {
        "ok": True,
        "name": "Boss Food Ordering Agent",
        "description": "AI-powered food ordering assistant for Cairo",
        "capabilities": [
            "Search meals by name, category, or description",
            "Filter by price range",
            "Exclude allergens",
            "Manage shopping cart",
            "Build budget-optimized carts",
            "Search user favorites"
        ],
        "tools": [
            "search_meals",
            "search_favorites",
            "build_cart",
            "add_to_cart",
            "get_cart"
        ],
        "model": "google/gemini-2.0-flash-001",
        "active_sessions": len(_sessions)
    }
