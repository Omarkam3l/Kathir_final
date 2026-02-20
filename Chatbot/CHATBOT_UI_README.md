# 🍽️ Boss Food Ordering - Chatbot UI

A beautiful, interactive web interface for the Boss Food Ordering API with natural language processing capabilities.

## 🎯 What You Can Do

### 1. Search for Meals
- **Natural Language**: "Show me chicken dishes"
- **With Filters**: "I want seafood under 100 EGP"
- **By Category**: "Show me desserts"
- **Dietary Needs**: "I need gluten-free meals"

### 2. Manage Your Cart
- **View Cart**: "Show my cart"
- **Build Cart**: "Build a cart with 500 EGP budget"
- **Auto-optimization**: Automatically selects best meals within budget

### 3. Browse Favorites
- **View Favorites**: "Show my favorites"
- **Search Favorites**: "Find pizza in my favorites"

### 4. Filter by Allergens
- **Exclude Allergens**: "No gluten", "dairy-free", "shellfish-free"
- **Multiple Filters**: Combine price, category, and allergen filters

## 🚀 Quick Start

### Method 1: Double-click Launcher
```
Double-click: start_ui.bat
```

### Method 2: Command Line
```bash
python -m uvicorn main:app --reload
```

Then open your browser to: **http://localhost:8000/**

## 📸 Features

### Beautiful UI
- 🎨 Modern gradient design
- 📱 Fully responsive (desktop, tablet, mobile)
- 🌙 Clean, professional interface
- ⚡ Real-time updates

### Smart Chatbot
- 🤖 Natural language understanding
- 🔍 Semantic search with relevance scoring
- 💡 Context-aware responses
- 📊 Rich meal cards with details

### Quick Actions
- 🍗 Pre-defined queries for common tasks
- 💰 Budget-based cart building
- 🛒 One-click cart viewing
- ⭐ Favorites management

### Real-time Stats
- 📈 Message counter
- 🛒 Live cart item count
- 💵 Current cart total
- 🟢 Server status indicator

## 💬 Example Conversations

### Finding Meals
```
You: Show me chicken dishes
Bot: Found 2 meals:
     ┌─────────────────────────────────────┐
     │ Grilled Chicken Platter             │
     │ Meat & Poultry                      │
     │ 75.0 EGP                            │
     │ Marinated grilled chicken breast... │
     │ ⚠️ sesame                           │
     │ Relevance: 60%                      │
     └─────────────────────────────────────┘
```

### Budget Shopping
```
You: Build a cart with 500 EGP budget
Bot: ✨ Cart Built Successfully!
     Budget: 500 EGP
     Total: 481.0 EGP
     Remaining: 19 EGP
     
     5 items selected:
     - Ful Medames Breakfast: 2x @ 22 EGP
     - Hummus & Falafel Combo: 3x @ 32 EGP
     - ...
```

### Dietary Restrictions
```
You: I need gluten-free desserts
Bot: Found 0 meals matching your criteria.
     Try adjusting your search!
```

## 🎨 UI Components

### Header
- App title and subtitle
- Real-time server status indicator
- Connection state (Online/Offline)

### Sidebar (Desktop)
- **Quick Actions**: 6 pre-defined queries
- **Stats Dashboard**: Message count, cart items, cart total
- **Tips Section**: Helpful usage hints

### Chat Area
- **Message History**: Scrollable conversation
- **Meal Cards**: Beautiful result display
- **Cart Summaries**: Detailed cart information
- **Loading Indicators**: Visual feedback

### Input Area
- **Text Input**: Auto-resizing textarea
- **Send Button**: One-click message sending
- **Quick Hints**: Category, Budget, Allergies badges
- **Keyboard Shortcuts**: Enter to send, Shift+Enter for new line

## 🔧 Technical Stack

### Frontend
- **HTML5**: Semantic markup
- **CSS3**: Modern styling with gradients, animations
- **Vanilla JavaScript**: No frameworks, pure JS
- **Responsive Design**: Mobile-first approach

### Backend Integration
- **FastAPI**: Python web framework
- **CORS Enabled**: Cross-origin requests
- **Static Files**: Served via FastAPI
- **RESTful API**: Clean endpoint structure

### Features
- **Natural Language Processing**: Intent detection
- **Parameter Extraction**: Price, category, allergens
- **Real-time Updates**: WebSocket-ready architecture
- **Error Handling**: Graceful degradation

## 📁 File Structure

```
├── static/
│   ├── index.html      # Main UI structure
│   ├── style.css       # Styling and animations
│   └── app.js          # JavaScript logic
├── main.py             # FastAPI server with static files
├── start_ui.bat        # Windows launcher
├── UI_GUIDE.md         # Detailed UI documentation
└── CHATBOT_UI_README.md # This file
```

## 🎯 Supported Queries

### Search Patterns
- "Show me [food]"
- "I want [food]"
- "Find [food]"
- "Search for [food]"

### Price Filters
- "under [amount] EGP"
- "below [amount]"
- "max [amount]"
- "between [min] and [max]"
- "above [amount]"
- "over [amount]"

### Categories
- Meals
- Desserts
- Meat & Poultry
- Seafood
- Bakery
- Vegetables

### Allergens
- gluten / gluten-free
- dairy / dairy-free
- eggs / egg-free
- shellfish
- fish
- tree nuts
- peanuts
- soy
- sesame

### Cart Operations
- "show my cart"
- "view cart"
- "what's in my cart"
- "build cart with [amount] EGP"
- "create cart for [amount]"

### Favorites
- "show my favorites"
- "my favorite meals"
- "favorite [food]"

## 🎨 Customization

### Change Colors
Edit `static/style.css`:
```css
:root {
    --primary-color: #2563eb;    /* Main blue */
    --secondary-color: #10b981;  /* Success green */
    --danger-color: #ef4444;     /* Error red */
}
```

### Add Quick Actions
Edit `static/index.html`:
```html
<button class="action-btn" onclick="sendQuickMessage('Your query')">
    🔥 Your Label
</button>
```

### Modify API Endpoint
Edit `static/app.js`:
```javascript
const API_BASE_URL = 'http://your-server:8000';
```

## 📱 Responsive Breakpoints

- **Desktop**: 1400px+ (Full sidebar + chat)
- **Tablet**: 768px - 1024px (Hidden sidebar)
- **Mobile**: < 768px (Optimized layout)

## 🐛 Troubleshooting

### UI Not Loading
1. Check server: `curl http://localhost:8000/health`
2. Clear browser cache (Ctrl+Shift+Delete)
3. Check console (F12) for errors

### "Offline" Status
1. Verify server is running
2. Check firewall settings
3. Try different browser

### No Search Results
1. Check database has data
2. Use broader search terms
3. Remove filters

### Slow Performance
1. First request loads embedding model (slow)
2. Subsequent requests are faster
3. Consider caching strategies

## 🚀 Performance

- **Initial Load**: < 1 second
- **First Search**: 2-3 seconds (model loading)
- **Subsequent Searches**: < 1 second
- **Cart Operations**: < 500ms

## 🔒 Security

- ✅ Input sanitization (XSS prevention)
- ✅ CORS enabled
- ⚠️ No authentication (add as needed)
- ⚠️ Hardcoded user ID (implement proper auth)

## 📊 Browser Support

- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+

## 🎉 What's Next?

### Planned Features
- [ ] User authentication
- [ ] Voice input
- [ ] Image search
- [ ] Order history
- [ ] Payment integration
- [ ] Restaurant ratings
- [ ] Delivery tracking
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Meal recommendations

## 📝 Testing the UI

### Manual Testing
1. Open http://localhost:8000/
2. Try each quick action button
3. Type custom queries
4. Check cart operations
5. Verify responsive design (resize browser)

### Automated Testing
```bash
python comprehensive_test.py
```

## 💡 Tips for Best Experience

1. **Be Specific**: "chicken under 80 EGP" vs "food"
2. **Use Natural Language**: Talk like you would to a person
3. **Combine Filters**: "gluten-free desserts under 50 EGP"
4. **Check Cart Often**: View cart to see current items
5. **Use Quick Actions**: Fastest way to common queries

## 🎓 Learning Resources

- **API Docs**: http://localhost:8000/docs
- **UI Guide**: See `UI_GUIDE.md`
- **Testing Guide**: See `API_TESTING_GUIDE.md`
- **Comprehensive Tests**: Run `comprehensive_test.py`

## 📞 Support

If you encounter issues:
1. Check server logs in terminal
2. Open browser console (F12)
3. Review error messages
4. Check `UI_GUIDE.md` for solutions

## 🎊 Enjoy Your Chatbot!

Your Boss Food Ordering chatbot UI is ready to use. Start exploring delicious food options with natural language! 🍕🍔🍰

---

**Made with ❤️ for Cairo food lovers**
