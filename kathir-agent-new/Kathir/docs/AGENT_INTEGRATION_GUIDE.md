# 🤖 Boss AI Agent Integration Guide

## Overview

The Boss Food Ordering system now includes a **LangGraph-powered AI agent** that orchestrates all tools intelligently using natural language understanding.

## Architecture

```
User Message
     ↓
  Chat UI (JavaScript)
     ↓
  /agent/chat endpoint
     ↓
  Boss Agent (LangGraph)
     ↓
  ┌─────────────────────┐
  │  Tool Selection     │
  │  - search_meals     │
  │  - search_favorites │
  │  - build_cart       │
  │  - add_to_cart      │
  │  - get_cart         │
  └─────────────────────┘
     ↓
  Response to User
```

## Key Components

### 1. Boss Agent (`boss_agent.py`)
- **Framework**: LangGraph ReAct agent
- **Model**: Google Gemini 2.0 Flash (via OpenRouter)
- **Memory**: MemorySaver for conversation continuity
- **Tools**: 5 specialized tools for food ordering

### 2. Agent API (`routes_agent.py`)
- **POST /agent/chat**: Main chat endpoint
- **GET /agent/info**: Agent capabilities
- **GET /agent/sessions**: List active sessions
- **DELETE /agent/sessions/{id}**: Clear session

### 3. UI Integration (`static/app.js`)
- **USE_AGENT flag**: Toggle between agent and direct API
- **Session management**: Maintains conversation context
- **Automatic tool calling**: Agent decides which tools to use

## How It Works

### 1. User Sends Message
```javascript
User: "Show me chicken dishes under 80 EGP"
```

### 2. UI Sends to Agent
```javascript
POST /agent/chat
{
  "message": "Show me chicken dishes under 80 EGP",
  "session_id": "abc123...",
  "user_id": "11111111-1111-1111-1111-111111111111"
}
```

### 3. Agent Processes
```python
# Agent receives message with context
[context: current time=2026-02-19 16:44, location=Cairo EG, user_id=...]
Show me chicken dishes under 80 EGP

# Agent decides to use search_meals tool
agent.invoke({
    "tool": "search_meals",
    "params": {
        "query": "chicken",
        "max_price": 80,
        "limit": 10
    }
})
```

### 4. Agent Responds
```json
{
  "ok": true,
  "response": "We have these chicken dishes under 80 EGP:\n* Grilled Chicken Platter - 75 EGP\n* Chicken Souvlaki Skewers - 65 EGP",
  "session_id": "abc123...",
  "message_count": 4
}
```

## Available Tools

### 1. search_meals
**Purpose**: Search for meals with filters
**Parameters**:
- query: Search text
- max_price, min_price: Price range
- category: Meal category
- exclude_allergens: List of allergens to avoid
- limit: Max results

**Example**:
```
User: "Show me gluten-free desserts under 50 EGP"
Agent: Uses search_meals(query="dessert", category="Desserts", max_price=50, exclude_allergens=["gluten"])
```

### 2. search_favorites
**Purpose**: Search user's favorite meals
**Parameters**:
- user_id: User identifier
- query: Optional search text
- limit: Max results

**Example**:
```
User: "Show my favorite pizza"
Agent: Uses search_favorites(user_id="...", query="pizza")
```

### 3. build_cart
**Purpose**: Build optimized cart within budget
**Parameters**:
- budget: Total budget in EGP
- user_id: For favorites weighting
- restaurant_id or restaurant_name: Restaurant filter
- target_meal_count: Desired number of meals
- max_qty_per_meal: Max quantity per item

**Example**:
```
User: "Build a cart with 500 EGP budget"
Agent: Uses build_cart(budget=500, restaurant_id="...", target_meal_count=5)
```

### 4. add_to_cart
**Purpose**: Add meal to cart
**Parameters**:
- meal_id: Meal identifier
- quantity: Number of portions
- user_id: User identifier

**Example**:
```
User: "Add 2 portions of chicken platter to my cart"
Agent: Uses add_to_cart(meal_id="...", quantity=2)
```

### 5. get_cart
**Purpose**: View current cart
**Parameters**:
- user_id: User identifier
- include_expired: Include stale items
- restaurant_id: Filter by restaurant

**Example**:
```
User: "What's in my cart?"
Agent: Uses get_cart(user_id="...")
```

## Agent Capabilities

### Natural Language Understanding
The agent can understand various phrasings:
- "Show me chicken" = "I want chicken dishes" = "Find chicken meals"
- "Under 50 EGP" = "Below 50" = "Max 50 EGP"
- "Gluten-free" = "No gluten" = "Without gluten"

### Context Awareness
The agent maintains context across conversation:
```
User: "Show me chicken dishes"
Agent: [Shows chicken dishes]

User: "Which one is cheapest?"
Agent: [Remembers previous results, identifies cheapest]

User: "Add it to my cart"
Agent: [Adds the cheapest chicken dish]
```

### Multi-step Reasoning
The agent can chain multiple tools:
```
User: "Build me a cart with my favorite meals for 500 EGP"
Agent:
  1. Uses search_favorites() to get favorites
  2. Uses build_cart() with preferred_meals from favorites
  3. Returns optimized cart
```

### Error Handling
The agent gracefully handles errors:
```
User: "Show me pizza"
Agent: [No results] "I couldn't find any pizza. Would you like to try a different search?"
```

## Configuration

### Enable/Disable Agent
In `static/app.js`:
```javascript
const USE_AGENT = true;  // Use AI agent
const USE_AGENT = false; // Use direct API calls
```

### Change Model
In `boss_agent.py`:
```python
def create_agent(model: str = "google/gemini-2.0-flash-001"):
    # Options:
    # - "google/gemini-2.0-flash-001" (fast, reliable)
    # - "qwen/qwen3-235b-a22b-thinking-2507" (stronger reasoning)
    # - "anthropic/claude-3.5-sonnet" (best quality)
```

### Adjust Temperature
In `boss_agent.py`:
```python
llm = ChatOpenAI(
    temperature=0.0,  # 0.0 = deterministic, 1.0 = creative
)
```

## Testing

### Test Agent via API
```bash
python test_agent.py
```

### Test Agent via UI
1. Open http://localhost:8000/
2. Ensure `USE_AGENT = true` in `app.js`
3. Start chatting!

### Test Agent via CLI
```bash
python -m boss_agent
```

## Performance

### First Request
- **Time**: 5-10 seconds
- **Reason**: Model initialization, tool loading
- **Optimization**: Keep agent instance warm

### Subsequent Requests
- **Time**: 1-3 seconds
- **Reason**: Tool execution, LLM inference
- **Optimization**: Cache common queries

### Memory Usage
- **Agent**: ~500MB (model + tools)
- **Session**: ~1KB per conversation
- **Optimization**: Limit session history

## Advantages of Agent vs Direct API

### Agent (LangGraph)
✅ Natural language understanding
✅ Context-aware conversations
✅ Multi-step reasoning
✅ Automatic tool selection
✅ Error recovery
✅ Conversational flow

### Direct API
✅ Faster response time
✅ Predictable behavior
✅ Lower resource usage
✅ Simpler debugging
✅ No LLM costs

## Best Practices

### 1. Session Management
```javascript
// Store session ID for conversation continuity
let sessionId = null;

// Include in every request
{
  "message": "...",
  "session_id": sessionId
}
```

### 2. Error Handling
```javascript
try {
  const response = await fetch('/agent/chat', {...});
  if (!response.ok) {
    // Handle HTTP errors
  }
  const data = await response.json();
  if (!data.ok) {
    // Handle agent errors
  }
} catch (error) {
  // Handle network errors
}
```

### 3. Timeout Handling
```javascript
// Set reasonable timeout for agent requests
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 30000);

fetch('/agent/chat', {
  signal: controller.signal,
  ...
});
```

### 4. User Feedback
```javascript
// Show loading indicator
addLoadingMessage();

// Show progress for long operations
"Searching meals... 🔍"
"Building cart... 🛒"
"Optimizing selection... ⚡"
```

## Troubleshooting

### Agent Not Responding
1. Check server logs for errors
2. Verify OpenRouter API key is set
3. Check model availability
4. Increase timeout

### Wrong Tool Selection
1. Improve prompt clarity
2. Add examples to system prompt
3. Adjust model temperature
3. Use stronger model

### Slow Performance
1. Use faster model (Gemini Flash)
2. Reduce tool complexity
3. Cache common queries
4. Limit conversation history

### Memory Issues
1. Clear old sessions periodically
2. Limit message history
3. Use smaller model
4. Implement session cleanup

## Advanced Features

### Custom System Prompt
Edit `prompts.py`:
```python
BASE_SYSTEM_PROMPT = """
You are Boss, a food ordering assistant for Cairo.
[Add custom instructions here]
"""
```

### Add New Tools
1. Create tool function with `@tool` decorator
2. Add to `AGENT_TOOLS` list in `boss_agent.py`
3. Document in system prompt

### Multi-turn Conversations
The agent automatically maintains context:
```python
# Session stored in MemorySaver
config = {"configurable": {"thread_id": session_id}}
agent.invoke({"messages": [...]}, config)
```

### Streaming Responses
For real-time updates:
```python
# Use agent.stream() instead of agent.invoke()
for chunk in agent.stream({"messages": [...]}, config):
    yield chunk
```

## Security Considerations

### API Key Protection
- ✅ Store in environment variables
- ✅ Never expose in client code
- ✅ Rotate regularly
- ✅ Use separate keys for dev/prod

### Input Validation
- ✅ Sanitize user input
- ✅ Limit message length
- ✅ Rate limiting
- ✅ Session timeout

### Session Security
- ✅ Use UUIDs for session IDs
- ✅ Implement session expiry
- ✅ Clear sensitive data
- ✅ Validate user_id

## Monitoring

### Track Metrics
- Request count
- Response time
- Error rate
- Tool usage
- Session duration

### Logging
```python
import logging

logging.info(f"Agent request: {message}")
logging.info(f"Tool called: {tool_name}")
logging.info(f"Response time: {elapsed}ms")
```

## Future Enhancements

- [ ] Streaming responses
- [ ] Voice input/output
- [ ] Image understanding
- [ ] Multi-language support
- [ ] Personalized recommendations
- [ ] Order history analysis
- [ ] Proactive suggestions

## Conclusion

The Boss AI Agent provides an intelligent, conversational interface to your food ordering system. It combines the power of LangGraph, modern LLMs, and specialized tools to deliver a seamless user experience.

**Key Benefits:**
- 🤖 Natural language understanding
- 🧠 Context-aware conversations
- ⚡ Automatic tool orchestration
- 🎯 Intelligent decision making
- 💬 Human-like interactions

Start using the agent today and experience the future of food ordering! 🍕🤖
