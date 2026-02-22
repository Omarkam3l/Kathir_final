# Boss Food Ordering - Chat UI Guide

## 🚀 Quick Start

1. **Start the server:**
   ```bash
   python -m uvicorn main:app --reload
   ```

2. **Open the Chat UI:**
   - Visit: http://localhost:8000/
   - Or directly: http://localhost:8000/static/index.html

3. **Start chatting!**

## 🎯 Features

### 1. Meal Search
Ask natural language questions like:
- "Show me chicken dishes"
- "I want seafood under 100 EGP"
- "Find me gluten-free desserts"
- "What bakery items do you have?"

### 2. Price Filtering
- "Show meals under 50 EGP"
- "I need something between 30 and 80 EGP"
- "What's available above 100 EGP?"

### 3. Allergen Filtering
- "I need gluten-free meals"
- "Show me dairy-free options"
- "I'm allergic to shellfish"
- "No eggs please"

### 4. Cart Management
- "Show my cart"
- "View my cart"
- "What's in my cart?"

### 5. Build Cart with Budget
- "Build a cart with 500 EGP budget"
- "Create a cart for 300 EGP"
- "I have 1000 EGP to spend"

### 6. Favorites
- "Show my favorites"
- "What are my favorite meals?"

## 🎨 UI Components

### Sidebar
- **Quick Actions**: Pre-defined queries for common tasks
- **Stats**: Real-time cart statistics
- **Tips**: Helpful hints for using the chatbot

### Chat Area
- **Message History**: All your conversations
- **Meal Cards**: Beautiful display of search results
- **Cart Summary**: Detailed cart information
- **Loading Indicators**: Visual feedback while processing

### Input Area
- **Text Input**: Type your questions naturally
- **Quick Hints**: Click badges for common queries
- **Send Button**: Submit your message

## 💡 Example Conversations

### Example 1: Finding Meals
```
You: Show me chicken dishes
Bot: Found 2 meals:
     - Grilled Chicken Platter (75 EGP)
     - Chicken Souvlaki Skewers (65 EGP)
```

### Example 2: Budget Shopping
```
You: I want seafood under 100 EGP
Bot: Found 1 meal:
     - Grilled Salmon with Vegetables (98 EGP)
```

### Example 3: Dietary Restrictions
```
You: Show me gluten-free desserts
Bot: Found 0 meals matching your criteria.
     Try adjusting your search!
```

### Example 4: Building a Cart
```
You: Build a cart with 500 EGP budget
Bot: ✨ Cart Built Successfully!
     Budget: 500 EGP
     Total: 481 EGP
     Remaining: 19 EGP
```

## 🔧 Technical Details

### API Integration
The UI connects to these endpoints:
- `GET /health` - Server status
- `GET /meals/search` - Search meals
- `GET /cart/` - Get cart
- `POST /cart/build` - Build cart with budget
- `GET /favorites/search` - Get favorites

### Natural Language Processing
The chatbot parses your messages to extract:
- **Keywords**: chicken, seafood, dessert, etc.
- **Price ranges**: under 50, between 30-80, above 100
- **Categories**: Meals, Desserts, Bakery, etc.
- **Allergens**: gluten, dairy, eggs, shellfish, etc.
- **Intents**: search, cart, favorites, build

### Real-time Updates
- Cart statistics update automatically
- Server status indicator shows connection state
- Message counter tracks conversation length

## 🎨 Customization

### Colors
Edit `static/style.css` to change the color scheme:
```css
:root {
    --primary-color: #2563eb;  /* Main blue */
    --secondary-color: #10b981; /* Green */
    --danger-color: #ef4444;    /* Red */
}
```

### Quick Actions
Edit `static/index.html` to add more quick action buttons:
```html
<button class="action-btn" onclick="sendQuickMessage('Your query here')">
    🔥 Your Label
</button>
```

## 📱 Responsive Design

The UI is fully responsive and works on:
- 💻 Desktop (1400px+)
- 📱 Tablet (768px - 1024px)
- 📱 Mobile (< 768px)

## 🐛 Troubleshooting

### UI Not Loading
1. Check server is running: `curl http://localhost:8000/health`
2. Clear browser cache
3. Check browser console for errors (F12)

### "Offline" Status
1. Verify server is running
2. Check API_BASE_URL in `static/app.js`
3. Ensure no firewall blocking localhost:8000

### No Search Results
1. Check database has data
2. Try broader search terms
3. Remove filters and try again

### Cart Not Updating
1. Refresh the page
2. Check browser console for errors
3. Verify cart API endpoint is working

## 🚀 Advanced Usage

### Custom User ID
Edit `static/app.js` to change the default user:
```javascript
const userId = 'your-user-id-here';
```

### API Base URL
Change the API endpoint in `static/app.js`:
```javascript
const API_BASE_URL = 'http://your-server:8000';
```

### Add New Intents
Extend the `processMessage` function in `static/app.js`:
```javascript
if (lowerMessage.includes('your-keyword')) {
    await handleYourCustomFunction(message, loadingId);
}
```

## 📊 Performance

- Initial load: < 1 second
- Message processing: 1-3 seconds
- Search results: 1-2 seconds
- Cart operations: < 1 second

## 🔒 Security Notes

- All API calls use CORS
- No authentication implemented (add as needed)
- User ID is hardcoded (implement proper auth)
- Input is sanitized to prevent XSS

## 📝 Future Enhancements

Potential improvements:
- [ ] User authentication
- [ ] Voice input
- [ ] Image upload for visual search
- [ ] Order history
- [ ] Payment integration
- [ ] Restaurant ratings
- [ ] Delivery tracking
- [ ] Multi-language support

## 🎉 Enjoy!

Your Boss Food Ordering chatbot UI is ready to use. Start exploring and ordering delicious food! 🍕🍔🍰
