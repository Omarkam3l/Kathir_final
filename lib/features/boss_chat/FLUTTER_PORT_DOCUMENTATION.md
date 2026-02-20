# Boss AI Chat - Flutter Port Documentation

## Overview

This document provides complete documentation for the Flutter port of the Boss AI Chat feature from HTML/CSS/JavaScript to Flutter/Dart.

## Component Mapping Table

| HTML/CSS Component | Flutter Widget | File Location |
|-------------------|----------------|---------------|
| **Header** | | |
| `.header` container | `Container` with decoration | `boss_chat_screen.dart` → `_buildHeader()` |
| `.header-content h1` | `Text` with style | `boss_chat_screen.dart` → `_buildHeader()` |
| `.subtitle` | `Text` with secondary color | `boss_chat_screen.dart` → `_buildHeader()` |
| `.status-indicator` | `Container` with `Row` | `boss_chat_screen.dart` → `_buildHeader()` |
| `.status-dot` | `Container` with `BoxDecoration` (circle) | `boss_chat_screen.dart` → `_buildHeader()` |
| **Sidebar** | | |
| `.sidebar` container | `Container` with `SingleChildScrollView` | `boss_chat_screen.dart` → `_buildSidebar()` |
| `.sidebar-section` | `Column` with children | Multiple widget files |
| **Quick Actions** | | |
| `.action-btn` buttons | `Material` + `InkWell` | `widgets/quick_actions_widget.dart` |
| Quick actions section | `QuickActionsWidget` | `widgets/quick_actions_widget.dart` |
| **Stats** | | |
| `.stat-item` rows | `Container` with `Row` | `widgets/stats_widget.dart` |
| `.stat-label` | `Text` with secondary color | `widgets/stats_widget.dart` |
| `.stat-value` | `Text` with primary color | `widgets/stats_widget.dart` |
| Stats section | `StatsWidget` | `widgets/stats_widget.dart` |
| **Tips** | | |
| `.tips-list` | `Column` with tip items | `widgets/tips_widget.dart` |
| `.tips-list li` | `Row` with emoji + text | `widgets/tips_widget.dart` |
| Tips section | `TipsWidget` | `widgets/tips_widget.dart` |
| **Chat Container** | | |
| `.chat-container` | `Container` with `Column` | `boss_chat_screen.dart` → `_buildChatArea()` |
| `.chat-messages` | `ListView.builder` | `boss_chat_screen.dart` → `_buildChatArea()` |
| **Messages** | | |
| `.message` div | `MessageBubble` widget | `widgets/message_bubble.dart` |
| `.message-avatar` | `Container` with gradient | `widgets/message_bubble.dart` → `_buildAvatar()` |
| `.message-content` | `Flexible` widget | `widgets/message_bubble.dart` |
| `.message-text` | `Container` with text | `widgets/message_bubble.dart` → `_buildTextContent()` |
| `.user-message` | `MessageBubble` with `isUser=true` | `widgets/message_bubble.dart` |
| `.bot-message` | `MessageBubble` with `isUser=false` | `widgets/message_bubble.dart` |
| **Meal Cards** | | |
| `.meal-card` | `Container` with decoration | `widgets/meal_card_widget.dart` |
| `.meal-header` | `Row` with title and price | `widgets/meal_card_widget.dart` |
| `.meal-title` | `Text` with bold style | `widgets/meal_card_widget.dart` |
| `.meal-price` | `Container` with green background | `widgets/meal_card_widget.dart` |
| `.meal-category` | `Container` with badge style | `widgets/meal_card_widget.dart` |
| `.meal-description` | `Text` with ellipsis | `widgets/meal_card_widget.dart` |
| `.meal-allergens` | `Wrap` with allergen badges | `widgets/meal_card_widget.dart` |
| `.allergen-badge` | `Container` with orange background | `widgets/meal_card_widget.dart` |
| `.meal-score` | `Text` with secondary color | `widgets/meal_card_widget.dart` |
| **Cart Summary** | | |
| `.cart-summary` | `Container` with gradient | `widgets/cart_summary_widget.dart` |
| `.cart-item` | `Container` with semi-transparent bg | `widgets/cart_summary_widget.dart` → `_buildCartItem()` |
| `.cart-total` | `Container` with border-top | `widgets/cart_summary_widget.dart` |
| Cart summary component | `CartSummaryWidget` | `widgets/cart_summary_widget.dart` |
| **Build Cart Summary** | | |
| Build cart display | `BuildCartSummaryWidget` | `widgets/build_cart_summary_widget.dart` |
| **Loading Indicator** | | |
| `.loading` div | `Container` with `Row` | `widgets/loading_indicator_widget.dart` |
| `.loading-dot` | `AnimatedBuilder` with scale | `widgets/loading_indicator_widget.dart` |
| Loading animation | `LoadingIndicatorWidget` | `widgets/loading_indicator_widget.dart` |
| **Input Area** | | |
| `.chat-input-container` | `Container` with `Column` | `boss_chat_screen.dart` → `_buildInputArea()` |
| `.input-wrapper` | `Row` with children | `boss_chat_screen.dart` → `_buildInputArea()` |
| `#messageInput` textarea | `TextField` with `maxLines: null` | `boss_chat_screen.dart` → `_buildInputArea()` |
| `#sendButton` | `Material` + `InkWell` | `boss_chat_screen.dart` → `_buildInputArea()` |
| `.input-hints` | `Wrap` with hint badges | `boss_chat_screen.dart` → `_buildInputArea()` |
| `.hint-badge` | `Material` + `InkWell` | `boss_chat_screen.dart` → `_buildHintBadge()` |

## JavaScript Behaviors → Dart Implementation

| JS Behavior | Dart Implementation | File Location |
|-------------|---------------------|---------------|
| `checkServerStatus()` | `checkServerStatus()` | `controllers/boss_chat_controller.dart` |
| `sendMessage()` | `sendMessage(String text)` | `controllers/boss_chat_controller.dart` |
| `sendQuickMessage()` | `_sendQuickMessage()` | `boss_chat_screen.dart` |
| `addMessage()` | Automatic via `ChatMessage` model | `models/chat_message.dart` |
| `addLoadingMessage()` | Automatic via `MessageType.loading` | `controllers/boss_chat_controller.dart` |
| `removeLoadingMessage()` | `_messages.removeWhere()` | `controllers/boss_chat_controller.dart` |
| `handleAgentChat()` | `sendMessage()` with API call | `controllers/boss_chat_controller.dart` |
| `displayMealResults()` | `MessageType.mealResults` | `widgets/message_bubble.dart` |
| `displayCart()` | `MessageType.cart` | `widgets/cart_summary_widget.dart` |
| `displayBuildCartResult()` | `MessageType.buildCart` | `widgets/build_cart_summary_widget.dart` |
| `updateCartStats()` | `updateCartStats()` | `controllers/boss_chat_controller.dart` |
| Auto-scroll on new message | `_scrollToBottom()` with `ScrollController` | `boss_chat_screen.dart` |
| Session management | `_sessionId` state variable | `controllers/boss_chat_controller.dart` |
| Message count tracking | `_messageCount` state variable | `controllers/boss_chat_controller.dart` |

## API Calls Mapping

| JS API Call | Dart Method | File Location |
|-------------|-------------|---------------|
| `fetch('/health')` | `checkHealth()` | `services/boss_chat_api_service.dart` |
| `fetch('/agent/chat', POST)` | `sendAgentChat()` | `services/boss_chat_api_service.dart` |
| `fetch('/cart/')` | `getCart()` | `services/boss_chat_api_service.dart` |
| `fetch('/meals/search')` | `searchMeals()` | `services/boss_chat_api_service.dart` |
| `fetch('/cart/build', POST)` | `buildCart()` | `services/boss_chat_api_service.dart` |
| `fetch('/favorites/search')` | `searchFavorites()` | `services/boss_chat_api_service.dart` |

## File Structure

```
lib/features/boss_chat/
├── boss_chat_screen.dart              # Main screen
├── routes.dart                         # Route configuration
├── controllers/
│   └── boss_chat_controller.dart      # State management (Provider)
├── models/
│   ├── agent_response.dart            # API response models
│   └── chat_message.dart              # UI message model
├── services/
│   └── boss_chat_api_service.dart     # HTTP API client
└── widgets/
    ├── message_bubble.dart            # Message bubble component
    ├── loading_indicator_widget.dart  # Loading animation
    ├── meal_card_widget.dart          # Meal card display
    ├── cart_summary_widget.dart       # Cart summary display
    ├── build_cart_summary_widget.dart # Build cart result display
    ├── quick_actions_widget.dart      # Quick action buttons
    ├── stats_widget.dart              # Stats display
    └── tips_widget.dart               # Tips display
```

## Dependencies Added

No new dependencies were added. The implementation uses existing dependencies:
- `provider: ^6.0.5` - State management
- `http: ^1.1.0` - HTTP client
- `uuid: ^4.3.3` - UUID generation

## Color Scheme (CSS → Flutter)

| CSS Variable | Flutter Color | Usage |
|--------------|---------------|-------|
| `--primary-color: #2563eb` | `Color(0xFF2563eb)` | Primary buttons, text |
| `--primary-dark: #1e40af` | `Color(0xFF1e40af)` | Button hover |
| `--secondary-color: #10b981` | `Color(0xFF10b981)` | Success, price badges |
| `--danger-color: #ef4444` | `Color(0xFFef4444)` | Error states |
| `--warning-color: #f59e0b` | `Color(0xFFf59e0b)` | Allergen badges |
| `--bg-color: #f8fafc` | `Color(0xFFf8fafc)` | Background |
| `--surface-color: #ffffff` | `Colors.white` | Cards, surfaces |
| `--text-primary: #1e293b` | `Color(0xFF1e293b)` | Primary text |
| `--text-secondary: #64748b` | `Color(0xFF64748b)` | Secondary text |
| `--border-color: #e2e8f0` | `Color(0xFFe2e8f0)` | Borders |
| Gradient: `#667eea → #764ba2` | `LinearGradient([Color(0xFF667eea), Color(0xFF764ba2)])` | Background, bot avatar |
| Gradient: `#f093fb → #f5576c` | `LinearGradient([Color(0xFFf093fb), Color(0xFFf5576c)])` | User avatar |

## Animations

| CSS Animation | Flutter Implementation |
|---------------|------------------------|
| `@keyframes slideIn` | Implicit animation via `ListView` item insertion |
| `@keyframes pulse` | Not implemented (status dot is static) |
| `@keyframes bounce` | `AnimationController` with `AnimatedBuilder` in `LoadingIndicatorWidget` |
| Hover effects | `InkWell` ripple effect |
| Transform scale | `Transform.scale` in loading dots |

## Responsive Behavior

| Breakpoint | Implementation |
|------------|----------------|
| Desktop (>1024px) | `LayoutBuilder` shows sidebar + chat area |
| Mobile (≤1024px) | `LayoutBuilder` shows chat area only |
| Tablet | Same as desktop if width > 1024px |

## Configuration

### Backend URL

Update the base URL in `lib/features/boss_chat/services/boss_chat_api_service.dart`:

```dart
static const String baseUrl = 'http://localhost:8000';
```

Change to your production URL:

```dart
static const String baseUrl = 'https://your-api.com';
```

### User ID

Currently hardcoded in the controller. To use authenticated user:

```dart
// In boss_chat_controller.dart
final userId = context.read<AuthProvider>().user?.id ?? 'default-user-id';
```

## Integration Steps

### 1. Add Route to App Router

Already completed in `lib/features/_shared/router/app_router.dart`:

```dart
import '../../boss_chat/routes.dart';

// In routes list:
...bossChatRoutes(),
```

### 2. Add Entry Point in Home Screen

Already completed in `lib/features/user_home/presentation/screens/home_dashboard_screen.dart`:

```dart
Widget _buildBossAIChatButton(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/boss-chat'),
        // ... gradient container with icon and text
      ),
    ),
  );
}
```

### 3. Navigate to Boss Chat

From anywhere in the app:

```dart
context.push('/boss-chat');
```

Or using GoRouter:

```dart
GoRouter.of(context).push('/boss-chat');
```

## Testing

### Manual Testing Checklist

- [ ] Server connection status updates correctly
- [ ] Welcome message displays on screen load
- [ ] User can type and send messages
- [ ] Loading indicator appears while waiting for response
- [ ] Bot responses display correctly
- [ ] Meal cards render with all information
- [ ] Cart summary displays correctly
- [ ] Build cart summary shows budget and items
- [ ] Quick action buttons work
- [ ] Hint badges work
- [ ] Stats update after cart operations
- [ ] Auto-scroll works on new messages
- [ ] Sidebar shows/hides based on screen width
- [ ] Back button closes the screen
- [ ] Session ID persists across messages
- [ ] Message count increments correctly

### API Testing

Test with your backend running:

```bash
# Start backend
cd Chatbot
uvicorn main:app --reload

# Test endpoints
curl http://localhost:8000/health
curl -X POST http://localhost:8000/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "show me chicken dishes"}'
```

## RTL Support

The implementation supports RTL text automatically through Flutter's `Directionality` widget. To enable RTL:

```dart
// In MaterialApp
MaterialApp(
  locale: const Locale('ar', 'EG'), // Arabic
  // ...
)
```

All text will automatically flip direction. The layout uses `Row` and `Flexible` which respect text direction.

## Performance Considerations

1. **Message List**: Uses `ListView.builder` for efficient rendering
2. **Auto-scroll**: Debounced with `addPostFrameCallback`
3. **State Management**: Provider with `ChangeNotifier` for reactive updates
4. **HTTP Client**: Reuses single `http.Client` instance
5. **Animations**: Uses `AnimationController` for smooth loading dots

## Known Limitations

1. **No message persistence**: Messages are lost on screen close
2. **No offline support**: Requires active internet connection
3. **No image support**: Text-only messages
4. **No voice input**: Text input only
5. **No file attachments**: Not implemented
6. **No message editing**: Cannot edit sent messages
7. **No message deletion**: Cannot delete messages

## Future Enhancements

1. Add message persistence (local database)
2. Add offline queue for messages
3. Add image support in messages
4. Add voice input capability
5. Add file attachment support
6. Add message reactions
7. Add typing indicators
8. Add read receipts
9. Add message search
10. Add conversation history

## Troubleshooting

### Issue: "Connection failed"

**Solution**: Check backend URL in `boss_chat_api_service.dart` and ensure backend is running.

### Issue: "No response from agent"

**Solution**: Check backend logs for errors. Verify OpenRouter API key is set in backend `.env` file.

### Issue: "Sidebar not showing"

**Solution**: Sidebar only shows on screens wider than 1024px. Test on tablet/desktop or use responsive mode in Flutter DevTools.

### Issue: "Messages not scrolling"

**Solution**: Ensure `ScrollController` is attached to `ListView`. Check `_scrollToBottom()` is called after state updates.

### Issue: "Stats not updating"

**Solution**: Verify `updateCartStats()` is called after cart operations. Check `/cart/` endpoint is working.

## Build Instructions

### Development Build

```bash
# Get dependencies
flutter pub get

# Run on device/emulator
flutter run

# Run with hot reload
flutter run --hot
```

### Production Build

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Environment Configuration

Create `.env` file in project root (if not exists):

```env
# Backend API URL
API_BASE_URL=https://your-production-api.com
```

Update `boss_chat_api_service.dart` to read from environment:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

static final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
```

## Maintenance

### Updating API Endpoints

Modify `services/boss_chat_api_service.dart`:

```dart
Future<Map<String, dynamic>> newEndpoint() async {
  final response = await _client.get(
    Uri.parse('$baseUrl/new-endpoint'),
  );
  return json.decode(response.body);
}
```

### Adding New Message Types

1. Add to `MessageType` enum in `models/chat_message.dart`
2. Create widget in `widgets/` folder
3. Add case in `message_bubble.dart` → `_buildMessageContent()`
4. Handle in controller's response parsing

### Updating Styles

All colors and styles are inline. To centralize:

1. Create `lib/features/boss_chat/theme/boss_chat_theme.dart`
2. Define color constants
3. Replace inline colors with constants

## Support

For issues or questions:
1. Check this documentation
2. Review the original HTML/CSS/JS files
3. Check backend API documentation
4. Review Flutter/Dart documentation

## License

Same as parent project.

---

**Last Updated**: February 20, 2026
**Flutter Version**: 3.5.3+
**Dart Version**: 3.5.3+
