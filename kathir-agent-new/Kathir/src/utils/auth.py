"""
auth.py
───────
Authentication utilities for FastAPI routes.

Provides dependency injection for getting the current authenticated user.
"""

from typing import Optional
from fastapi import Header, HTTPException
from src.utils.db_client import sb


async def get_current_user(authorization: Optional[str] = Header(None)) -> str:
    """
    FastAPI dependency to get the current authenticated user.
    
    Extracts the JWT token from the Authorization header and validates it.
    
    Args:
        authorization: Authorization header (format: "Bearer <token>")
        
    Returns:
        User UUID string
        
    Raises:
        HTTPException: If authentication fails
    """
    # For development/testing without auth
    if not authorization:
        # Return a default user ID for development
        # In production, you should raise an error here
        return "11111111-1111-1111-1111-111111111111"
    
    try:
        # Extract token from "Bearer <token>"
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Invalid authorization header format")
        
        token = authorization.replace("Bearer ", "")
        
        # Validate token and get user
        user = sb.auth.get_user(token)
        
        if not user or not user.user:
            raise HTTPException(status_code=401, detail="Invalid or expired token")
        
        return user.user.id
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Authentication failed: {str(e)}")


def get_current_user_sync() -> str:
    """
    Synchronous version for use in non-async contexts (tools, etc.)
    
    Returns:
        User UUID string
    """
    try:
        user = sb.auth.get_user()
        if user and user.user:
            return user.user.id
        else:
            # Fallback for development/testing
            return "11111111-1111-1111-1111-111111111111"
    except Exception:
        # Fallback for development/testing
        return "11111111-1111-1111-1111-111111111111"
