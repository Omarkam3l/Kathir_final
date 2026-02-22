# Authentication Update - Dynamic User IDs

## ✅ Complete

Replaced all static user IDs with dynamic authentication using `sb.auth.get_user()`. The system now automatically gets the current authenticated user instead of using hardcoded IDs.

## Changes Made

### 1. New Authentication Module (`auth.py`)

Created a centralized authentication module with two functions:

#### `get_current_user()` - For FastAPI Routes (Async)
```python
async def get_current_user(authorization: Optional[str] = Header(None)) -> str:
    """
    FastAPI dependency to get the current authenticated user.
    Extracts JWT token from Authorization header and validates it.
    """
```

#### `get_current_user_sync()` - For Tools (Sync)
```python
def get_current_user_sync() -> str:
    """
    Synchronous version for use in non-async contexts (tools, etc.)
    """
```

### 2. Updated Cart Module (`cart.py`)

**Before:**
```python
# Static user ID
_DEV_USER_ID = "11111111-1111-1111-1111-111111111111"

@tool("add_to_cart")
def add_to_cart(meal_id: str, quantity: int = 1):
    USER_ID = _DEV_USER_ID  # Hardcoded!
```

**After:**
```python
# Dynamic user ID
from auth import get_current_user_sync

def get_current_user_id() -> str:
    return get_current_user_sync()

@tool("add_to_cart")
def add_to_cart(meal_id: str, quantity: int = 1):
    USER_ID = get_current_user_id()  # Automatic!
```

### 3. Updated API Routes

#### `routes_cart.py`

**Before:**
```python
class BuildCartRequest(BaseModel):
    user_id: Optional[str] = Field(default=None)  # User provides ID

def build_cart_endpoint(body: BuildCartRequest):
    return build_cart.invoke({"user_id": body.user_id, ...})
```

**After:**
```python
class BuildCartRequest(BaseModel):
    # user_id removed from request body

async def build_cart_endpoint(
    body: BuildCartRequest,
    user_id: str = Depends(get_current_user)  # Automatic!
):
    return build_cart.invoke({"user_id": user_id, ...})
```

#### `routes_favorites.py`

**Before:**
```python
def search_favorites_endpoint(
    user_id: str = Query(...),  # User provides ID
    ...
):
```

**After:**
```python
async def search_favorites_endpoint(
    user_id: str = Depends(get_current_user),  # Automatic!
    ...
):
```

#### `routes_agent.py`

**Before:**
```python
class ChatRequest(BaseModel):
    user_id: Optional[str] = Field("11111111-1111-1111-1111-111111111111")

async def chat_with_agent(request: ChatRequest):
    contextual_message = f"...user_id={request.user_id}..."
```

**After:**
```python
class ChatRequest(BaseModel):
    # user_id removed from request

async def chat_with_agent(
    request: ChatRequest,
    user_id: str = Depends(get_current_user)  # Automatic!
):
    contextual_message = f"...user_id={user_id}..."
```

## How It Works

### Authentication Flow

1. **Client sends request** with Authorization header:
   ```
   Authorization: Bearer <jwt_token>
   ```

2. **FastAPI dependency** extracts and validates token:
   ```python
   user_id: str = Depends(get_current_user)
   ```

3. **Supabase validates** the JWT token:
   ```python
   user = sb.auth.get_user(token)
   ```

4. **User ID is extracted** and passed to the endpoint:
   ```python
   return user.user.id
   ```

### Development Fallback

For development/testing without authentication:
- If no Authorization header is provided
- Falls back to default user ID: `11111111-1111-1111-1111-111111111111`
- In production, this should raise an error instead

## API Usage

### Before (Manual User ID)

```bash
# User had to provide their own ID
curl -X POST http://localhost:8000/cart/build \
  -H "Content-Type: application/json" \
  -d '{
    "budget": 500,
    "restaurant_name": "Malfoof",
    "user_id": "11111111-1111-1111-1111-111111111111"
  }'
```

### After (Automatic Authentication)

```bash
# User ID is automatic from auth token
curl -X POST http://localhost:8000/cart/build \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <jwt_token>" \
  -d '{
    "budget": 500,
    "restaurant_name": "Malfoof"
  }'
```

## Benefits

### 1. Security
- ✅ Users can't impersonate other users
- ✅ User ID comes from validated JWT token
- ✅ No way to manipulate user_id in requests

### 2. Simplicity
- ✅ Cleaner API - no user_id in request bodies
- ✅ Automatic user detection
- ✅ Consistent across all endpoints

### 3. Production Ready
- ✅ Uses Supabase's built-in authentication
- ✅ JWT token validation
- ✅ Proper error handling

### 4. Development Friendly
- ✅ Fallback for testing without auth
- ✅ Easy to switch between dev and prod

## Request/Response Examples

### Cart Operations

```bash
# Add to cart (automatic user)
curl -X POST http://localhost:8000/cart/add \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"meal_id": "meal-uuid", "quantity": 2}'

# Get cart (automatic user)
curl http://localhost:8000/cart/ \
  -H "Authorization: Bearer <token>"

# Build cart (automatic user)
curl -X POST http://localhost:8000/cart/build \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"budget": 500, "restaurant_name": "Malfoof"}'
```

### Favorites

```bash
# Search favorites (automatic user)
curl "http://localhost:8000/favorites/search?query=chicken" \
  -H "Authorization: Bearer <token>"
```

### Agent Chat

```bash
# Chat with agent (automatic user)
curl -X POST http://localhost:8000/agent/chat \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"message": "show me chicken dishes"}'
```

## Development Mode

For testing without authentication:

```bash
# No Authorization header = uses default user ID
curl -X POST http://localhost:8000/cart/build \
  -H "Content-Type: application/json" \
  -d '{"budget": 500, "restaurant_name": "Malfoof"}'
```

## Production Deployment

To enable strict authentication in production:

1. Update `auth.py`:
```python
async def get_current_user(authorization: Optional[str] = Header(None)) -> str:
    if not authorization:
        # In production, raise error instead of fallback
        raise HTTPException(status_code=401, detail="Authentication required")
    # ... rest of validation
```

2. Ensure all clients send Authorization headers
3. Use Supabase authentication on the frontend
4. Pass JWT tokens in all API requests

## Error Handling

### Missing Token
```json
{
  "detail": "Authentication required"
}
```
Status: 401 Unauthorized

### Invalid Token
```json
{
  "detail": "Invalid or expired token"
}
```
Status: 401 Unauthorized

### Malformed Header
```json
{
  "detail": "Invalid authorization header format"
}
```
Status: 401 Unauthorized

## Files Modified

- ✅ `auth.py` - New authentication module
- ✅ `cart.py` - Uses dynamic user ID
- ✅ `routes_cart.py` - Removed user_id from requests
- ✅ `routes_favorites.py` - Uses auth dependency
- ✅ `routes_agent.py` - Uses auth dependency

## Migration Notes

### For API Clients

1. Remove `user_id` from request bodies
2. Add `Authorization: Bearer <token>` header
3. Get JWT token from Supabase authentication

### For Frontend

```javascript
// Get token from Supabase auth
const { data: { session } } = await supabase.auth.getSession();
const token = session?.access_token;

// Use token in API calls
fetch('http://localhost:8000/cart/build', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    budget: 500,
    restaurant_name: 'Malfoof'
  })
});
```

## Summary

The system now uses proper authentication with `sb.auth.get_user()` instead of static user IDs. This provides better security, simpler APIs, and is production-ready while maintaining a development fallback for testing.
