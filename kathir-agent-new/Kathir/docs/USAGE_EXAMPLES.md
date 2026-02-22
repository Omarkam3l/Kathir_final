# Boss AI Agent - Usage Examples

## ✅ Current Status: All Outputs in JSON

The agent now returns **structured JSON** for all responses with complete data from tool calls.

## 📋 JSON Response Structure

Every agent response follows this format:

```json
{
  "message": "User-friendly message for display",
  "data": {
    // Complete results from tool calls
    // Structure varies by action type
  },
  "action": "search" | "cart" | "build" | "info" | null
}
```

## 🎯 Example Queries and Responses

### 1. Search for Meals

**Query:** "show me chicken dishes under 80 EGP"

**JSON Response:**
```json
{
  "message": "Found 2 chicken dishes under 80 EGP",
  "data": {
    "meals": [
      {
        "id": "meal-uuid-1",
        "title": "Grilled Chicken Platter",
        "price": 75,
        "restaurant_name": "Taste of Egypt",
        "category": "Meat & Poultry",
        "description": "Tender grilled chicken with rice and vegetables",
        "allergens": []
      },
      {
        "id": "meal-uuid-2",
        "title": "Chicken Souvlaki Skewers",
        "price": 65,
        "restaurant_name": "Mediterranean Grill House",
        "category": "Meat & Poultry",
        "description": "Greek-style chicken skewers with pita",
        "allergens": ["gluten"]
      }
    ],
    "count": 2
  },
  "action": "search"
}
```

**UI Display:**
- Shows meal cards with title, price, restaurant, category
- Displays allergen badges if present
- Shows total count of results

---

### 2. View Cart

**Query:** "what's in my cart?"

**JSON Response:**
```json
{
  "message": "Your cart has 11 items totaling 1197.0 EGP",
  "data": {
    "items": [
      {
        "title": "Hummus & Falafel Combo",
        "quantity": 4,
        "unit_price": 32,
        "subtotal": 128,
        "restaurant_name": "Mediterranean Grill House",
        "category": "Meals"
      },
      {
        "title": "Ful Medames Breakfast",
        "quantity": 7,
        "unit_price": 22,
        "subtotal": 154,
        "restaurant_name": "Taste of Egypt",
        "category": "Meals"
      }
      // ... more items
    ],
    "total": 1197,
    "count": 11
  },
  "action": "cart"
}
```

**UI Display:**
- Shows cart summary with all items
- Displays quantity × price = subtotal for each item
- Shows total price and item count
- Updates cart stats in header

---

### 3. Build Cart with Budget

**Query:** "build a cart with 300 EGP budget"

**JSON Response:**
```json
{
  "message": "Built cart for 300 EGP budget",
  "data": {
    "items": [
      {
        "title": "Ful Medames Breakfast",
        "quantity": 1,
        "unit_price": 22,
        "subtotal": 22
      },
      {
        "title": "Vegetable Moussaka",
        "quantity": 1,
        "unit_price": 35,
        "subtotal": 35
      },
      {
        "title": "Umm Ali (Egyptian Bread Pudding)",
        "quantity": 1,
        "unit_price": 40,
        "subtotal": 40
      }
      // ... more items
    ],
    "total": 279,
    "remaining_budget": 21,
    "restaurant_name": "Taste of Egypt"
  },
  "action": "build"
}
```

**UI Display:**
- Shows build cart summary
- Displays budget, total spent, and remaining
- Lists all items with quantities and prices
- Shows restaurant name

---

### 4. Dietary Restrictions

**Query:** "find me gluten-free desserts"

**JSON Response:**
```json
{
  "message": "No gluten-free desserts found. Here are some other gluten-free options.",
  "data": {
    "meals": [
      {
        "id": "meal-uuid-3",
        "title": "Hummus & Falafel Combo",
        "price": 32,
        "restaurant_name": "Mediterranean Grill House",
        "category": "Meals",
        "allergens": []
      }
      // ... more meals
    ],
    "count": 8
  },
  "action": "search"
}
```

**UI Display:**
- Shows alternative meals that match dietary restrictions
- Displays allergen information clearly
- Suggests related options

---

### 5. Category Search

**Query:** "show me seafood dishes"

**JSON Response:**
```json
{
  "message": "Found 3 seafood dishes",
  "data": {
    "meals": [
      {
        "id": "meal-uuid-4",
        "title": "Seafood Medley",
        "price": 110,
        "restaurant_name": "Mediterranean Grill House",
        "category": "Seafood",
        "description": "Mixed seafood platter",
        "allergens": ["shellfish", "fish"]
      },
      {
        "id": "meal-uuid-5",
        "title": "Grilled Sea Bass",
        "price": 155,
        "restaurant_name": "Taste of Egypt",
        "category": "Seafood",
        "allergens": ["fish"]
      }
      // ... more meals
    ],
    "count": 3
  },
  "action": "search"
}
```

**UI Display:**
- Shows meals filtered by category
- Displays allergen warnings for seafood
- Shows price and restaurant information

---

## 🎨 UI Rendering Logic

The UI (`static/app.js`) parses the JSON and renders based on `action` type:

```javascript
if (action === 'search' && data.meals) {
    // Display meal cards
    displayMealResults({ok: true, count: data.count, results: data.meals});
}
else if (action === 'cart' && data.items) {
    // Display cart summary
    displayCart({ok: true, count: data.count, total: data.total, items: data.items});
}
else if (action === 'build' && data.items) {
    // Display build cart result
    displayBuildCartResult({ok: true, total: data.total, remaining_budget: data.remaining_budget, items: data.items});
}
else {
    // Display plain message
    addBotMessage(message);
}
```

## 🔍 Data Fields Reference

### Search Response (`action: "search"`)
```typescript
{
  message: string,
  data: {
    meals: Array<{
      id: string,
      title: string,
      price: number,
      restaurant_name: string,
      category: string,
      description?: string,
      allergens?: string[],
      score?: number  // Relevance score 0-1
    }>,
    count: number
  },
  action: "search"
}
```

### Cart Response (`action: "cart"`)
```typescript
{
  message: string,
  data: {
    items: Array<{
      title: string,
      quantity: number,
      unit_price: number,
      subtotal: number,
      restaurant_name?: string,
      category?: string
    }>,
    total: number,
    count: number
  },
  action: "cart"
}
```

### Build Cart Response (`action: "build"`)
```typescript
{
  message: string,
  data: {
    items: Array<{
      title: string,
      quantity: number,
      unit_price: number,
      subtotal: number
    }>,
    total: number,
    remaining_budget: number,
    restaurant_name: string
  },
  action: "build"
}
```

### Info/Error Response (`action: null`)
```typescript
{
  message: string,
  data: null,
  action: null
}
```

## 🧪 Testing the JSON Responses

### In Browser Console
```javascript
// Send a test message
fetch('http://localhost:8000/agent/chat', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({message: 'show me chicken dishes'})
})
.then(r => r.json())
.then(data => {
    const response = JSON.parse(data.response);
    console.log('Message:', response.message);
    console.log('Data:', response.data);
    console.log('Action:', response.action);
});
```

### Using Python
```python
import requests
import json

response = requests.post(
    'http://localhost:8000/agent/chat',
    json={'message': 'show me chicken dishes'}
)

data = response.json()
agent_response = json.loads(data['response'])

print(f"Message: {agent_response['message']}")
print(f"Action: {agent_response['action']}")
print(f"Data: {json.dumps(agent_response['data'], indent=2)}")
```

## ✅ Verification Checklist

- [x] All agent responses are valid JSON
- [x] JSON includes `message`, `data`, and `action` fields
- [x] `data` field contains complete tool results
- [x] `action` field indicates response type
- [x] UI correctly parses and displays JSON responses
- [x] Meal cards show all relevant information
- [x] Cart displays show totals and items
- [x] Build cart shows budget breakdown
- [x] Error messages are user-friendly

## 🎉 Success!

Your Boss AI agent now returns **100% JSON responses** with complete data from all tool calls. The UI can parse these responses and display them appropriately based on the action type.

Try it out in the UI at: http://localhost:8000/static/index.html
