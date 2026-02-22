"""
routes_agent.py
───────────────
FastAPI routes for the Boss AI agent.
"""

import uuid
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from src.boss_agent import create_agent
from src.utils.auth import get_current_user

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


class ChatResponse(BaseModel):
    """Response model for chat endpoint"""
    ok: bool
    response: str
    session_id: str
    message_count: Optional[int] = None


@router.post("/chat", response_model=ChatResponse)
async def chat_with_agent(
    request: ChatRequest,
    user_id: str = Depends(get_current_user)
):
    """
    Chat with the Boss AI agent.
    
    The agent returns structured JSON responses with:
    - message: User-friendly text
    - data: Structured data (meals, cart, etc.)
    - action: Type of response (search, cart, build, etc.)
    
    User is automatically determined from authentication.
    
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
        contextual_message = f"[context: current time={now}, location=Cairo EG, user_id={user_id}]\n{request.message}"
        
        # Invoke agent
        result = agent.invoke(
            {"messages": [{"role": "user", "content": contextual_message}]},
            config,
        )
        
        # Extract response
        response_content = result["messages"][-1].content
        message_count = len(result["messages"])
        
        # Try to extract tool results from message history
        import json
        import re
        
        tool_results = None
        tool_action = None
        
        # Look through messages for tool calls and results
        for msg in result["messages"]:
            # Check if this is a tool message (has tool_calls)
            if hasattr(msg, 'tool_calls') and msg.tool_calls:
                for tool_call in msg.tool_calls:
                    tool_action = tool_call.get('name', '').replace('_', '')
            
            # Check if this is a tool result message
            if hasattr(msg, 'type') and msg.type == 'tool':
                try:
                    # Tool result is in the content
                    if isinstance(msg.content, str):
                        tool_results = json.loads(msg.content)
                    elif isinstance(msg.content, dict):
                        tool_results = msg.content
                except:
                    pass
        
        # Try to parse JSON from agent's response
        json_match = re.search(r'\{.*\}', response_content, re.DOTALL)
        if json_match:
            try:
                parsed_json = json.loads(json_match.group())
                
                # If agent didn't include data but we have tool results, add them
                if (parsed_json.get('data') is None or parsed_json.get('data') == {}) and tool_results:
                    parsed_json['data'] = tool_results
                
                # If no action specified but we detected one, add it
                if not parsed_json.get('action') and tool_action:
                    parsed_json['action'] = tool_action
                
                response_content = json.dumps(parsed_json, ensure_ascii=False)
            except json.JSONDecodeError:
                # If JSON parsing fails, create response with tool results
                response_content = json.dumps({
                    "message": response_content,
                    "data": tool_results,
                    "action": tool_action
                }, ensure_ascii=False)
        else:
            # No JSON found, wrap response with tool results
            response_content = json.dumps({
                "message": response_content,
                "data": tool_results,
                "action": tool_action
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
