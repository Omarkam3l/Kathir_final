# Boss AI Chat - Flutter Implementation

## Quick Start

### 1. Navigate to Boss Chat

From the user home screen, tap the "Boss AI Chat" button (gradient card with robot emoji).

### 2. Start Chatting

Type your message and press send or use quick action buttons:
- 🍗 Chicken Dishes
- 🦐 Affordable Seafood
- 🍰 Desserts
- 🌾 Gluten-Free
- 💰 Budget Cart (500 EGP)
- 🛒 View Cart

### 3. View Results

The AI will respond with:
- Meal cards with prices, categories, and allergens
- Cart summaries with totals
- Budget-optimized cart suggestions

## Features

✅ Natural language understanding
✅ Semantic meal search
✅ Dietary restriction filtering
✅ Budget-optimized cart building
✅ Real-time cart statistics
✅ Session-based conversations
✅ Responsive design (mobile + tablet/desktop)
✅ RTL support
✅ Smooth animations

## Configuration

### Backend URL

Edit `services/boss_chat_api_service.dart`:

```dart
static const String baseUrl = 'http://localhost:8000';
```

### User ID

The user ID is automatically retrieved from the authenticated user. Users must be logged in to use Boss AI Chat. If not logged in, the screen shows: "Please log in to use Boss AI Chat"

```dart
// Automatically handled in boss_chat_screen.dart
final userId = context.read<AuthProvider>().user?.id ?? '';
```

## File Structure

```
lib/features/boss_chat/
├── boss_chat_screen.dart              # Main screen
├── routes.dart                         # Routes
├── controllers/
│   └── boss_chat_controller.dart      # State management
├── models/
│   ├── agent_response.dart            # API models
│   └── chat_message.dart              # UI models
├── services/
│   └── boss_chat_api_service.dart     # API client
└── widgets/
    ├── message_bubble.dart            # Message display
    ├── loading_indicator_widget.dart  # Loading animation
    ├── meal_card_widget.dart          # Meal cards
    ├── cart_summary_widget.dart       # Cart display
    ├── build_cart_summary_widget.dart # Build cart display
    ├── quick_actions_widget.dart      # Quick actions
    ├── stats_widget.dart              # Statistics
    └── tips_widget.dart               # Usage tips
```

## API Endpoints

- `GET /health` - Server health check
- `POST /agent/chat` - Send message to AI agent
- `GET /cart/` - Get current cart
- `GET /meals/search` - Search meals
- `POST /cart/build` - Build budget cart
- `GET /favorites/search` - Search favorites

## Example Queries

- "Show me chicken dishes under 80 EGP"
- "I need gluten-free desserts"
- "Build a cart with 500 EGP budget"
- "What's in my cart?"
- "Show me seafood"

## Documentation

See `FLUTTER_PORT_DOCUMENTATION.md` for:
- Complete component mapping table
- Detailed implementation notes
- API documentation
- Testing guide
- Troubleshooting

## Dependencies

Uses existing project dependencies:
- `provider` - State management
- `http` - HTTP client
- `uuid` - UUID generation
- `go_router` - Navigation

No additional dependencies required.

## Integration

Already integrated in:
- ✅ `lib/features/_shared/router/app_router.dart` - Routes added
- ✅ `lib/features/user_home/presentation/screens/home_dashboard_screen.dart` - Entry button added

## Testing

### Manual Test

1. Run backend: `cd Chatbot && uvicorn main:app --reload`
2. Run Flutter app: `flutter run`
3. Navigate to Boss AI Chat from home screen
4. Send test message: "Show me chicken dishes"
5. Verify response displays correctly

### API Test

```bash
curl -X POST http://localhost:8000/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "show me chicken dishes"}'
```

## Support

For detailed documentation, see `FLUTTER_PORT_DOCUMENTATION.md`.

For backend documentation, see `Chatbot/CHATBOT_COMPREHENSIVE_REPORT.md`.
