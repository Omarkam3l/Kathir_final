# NGO Chat Feature - Complete Implementation

## Overview
Complete real-time chat/messaging system for NGO dashboard allowing NGOs to communicate with restaurants about meal donations.

## Features Implemented

### 1. Database Schema
**File**: `supabase/migrations/20260203_chat_system.sql`

**Tables Created**:
- `conversations` - Stores chat conversations between NGOs and restaurants
- `messages` - Stores individual messages within conversations

**Key Features**:
- Unique constraint on NGO-Restaurant pairs (one conversation per pair)
- Automatic `last_message_at` update via trigger
- Indexes for performance optimization
- Row Level Security (RLS) policies for data protection
- View `conversation_details` for easy querying with unread counts

### 2. Domain Layer

**Entities**:
- `lib/features/ngo_dashboard/domain/entities/conversation.dart`
  - Conversation metadata with restaurant info
  - Unread message count
  - Last message preview

- `lib/features/ngo_dashboard/domain/entities/message.dart`
  - Message content and metadata
  - Helper method `isMine()` for UI rendering

**Models**:
- `lib/features/ngo_dashboard/data/models/conversation_model.dart`
- `lib/features/ngo_dashboard/data/models/message_model.dart`

### 3. ViewModels

**NgoChatListViewModel**:
- `lib/features/ngo_dashboard/presentation/viewmodels/ngo_chat_list_viewmodel.dart`
- Loads all conversations for current NGO
- Calculates total unread count
- Creates new conversations with restaurants

**NgoChatViewModel**:
- `lib/features/ngo_dashboard/presentation/viewmodels/ngo_chat_viewmodel.dart`
- Loads messages for specific conversation
- Real-time message updates via Supabase Realtime
- Sends new messages
- Marks messages as read automatically
- Handles subscription cleanup

### 4. Screens

**Chat List Screen**:
- `lib/features/ngo_dashboard/presentation/screens/ngo_chat_list_screen.dart`
- Shows all conversations sorted by last message time
- Displays unread count badges
- Pull-to-refresh functionality
- Empty state for no conversations
- Integrated with bottom navigation

**Chat Screen**:
- `lib/features/ngo_dashboard/presentation/screens/ngo_chat_screen.dart`
- Real-time message display
- Message bubbles (different styles for sent/received)
- Date dividers for better organization
- Auto-scroll to bottom on new messages
- Message input with send button
- Loading and error states
- Time formatting (12-hour format)

### 5. UI/UX Features

**Chat List**:
- Restaurant avatar (with fallback icon)
- Restaurant name
- Last message preview
- Relative time (using timeago package)
- Unread count badge (green)
- Bold text for unread conversations
- Dark mode support

**Chat Screen**:
- Restaurant info in app bar
- Message bubbles with rounded corners
- Different colors for sent (green) vs received (white/dark)
- Timestamp on each message
- Date dividers between days
- Empty state with icon
- Disabled input while sending
- Loading indicator on send button

### 6. Real-time Features

**Supabase Realtime Integration**:
- Automatic message updates without refresh
- New messages appear instantly
- Auto-mark as read for received messages
- Subscription cleanup on dispose

### 7. Routes Added

```dart
// Chat list
GET /ngo/chats

// Individual chat
GET /ngo/chat/:id
```

**Route Configuration**:
- Integrated with Provider for state management
- Passes conversation ID and restaurant name
- Handles navigation from meal detail screen

### 8. Integration Points

**From Meal Detail Screen**:
- "Chat" button next to restaurant info
- Creates conversation if doesn't exist
- Navigates directly to chat screen

**Bottom Navigation**:
- Chat icon with badge for unread count
- Navigates to chat list screen

## Database Schema Details

### Conversations Table
```sql
- id (uuid, primary key)
- ngo_id (uuid, foreign key to profiles)
- restaurant_id (uuid, foreign key to profiles)
- last_message_at (timestamp)
- created_at (timestamp)
- UNIQUE constraint on (ngo_id, restaurant_id)
```

### Messages Table
```sql
- id (uuid, primary key)
- conversation_id (uuid, foreign key to conversations)
- sender_id (uuid, foreign key to profiles)
- content (text)
- is_read (boolean, default false)
- created_at (timestamp)
```

### Indexes
- `idx_conversations_ngo_id`
- `idx_conversations_restaurant_id`
- `idx_conversations_last_message_at`
- `idx_messages_conversation_id`
- `idx_messages_sender_id`
- `idx_messages_created_at`
- `idx_messages_is_read`

## Security (RLS Policies)

### Conversations
- Users can view conversations they're part of
- NGOs can create conversations
- Restaurants can create conversations

### Messages
- Users can view messages in their conversations
- Users can send messages in their conversations
- Users can update messages in their conversations

## Usage Flow

### Starting a Chat
1. NGO views meal detail screen
2. Clicks "Chat" button next to restaurant name
3. System checks if conversation exists
4. Creates new conversation if needed
5. Navigates to chat screen

### Viewing Chats
1. NGO taps "Chats" in bottom navigation
2. Sees list of all conversations
3. Unread count badge shows total unread messages
4. Taps conversation to open chat screen

### Sending Messages
1. Type message in input field
2. Tap send button
3. Message appears immediately (optimistic UI)
4. Real-time sync with database
5. Other party receives message instantly

### Receiving Messages
1. New messages appear automatically via Realtime
2. Unread badge updates in chat list
3. Messages marked as read when viewing conversation
4. Scroll to bottom shows new messages

## Dependencies Required

Add to `pubspec.yaml`:
```yaml
dependencies:
  timeago: ^3.6.1  # For relative time formatting
```

## Color Scheme

- **Primary Green**: `AppColors.primaryGreen` - Used for sent messages, badges, buttons
- **Dark Background**: `#0D1F14` - Main background in dark mode
- **Dark Surface**: `#1A2E22` - Cards and surfaces in dark mode
- **Light Background**: `#F5F5F5` - Main background in light mode
- **Light Surface**: `#FFFFFF` - Cards and surfaces in light mode

## File Structure

```
lib/features/ngo_dashboard/
├── data/
│   └── models/
│       ├── conversation_model.dart
│       └── message_model.dart
├── domain/
│   └── entities/
│       ├── conversation.dart
│       └── message.dart
└── presentation/
    ├── screens/
    │   ├── ngo_chat_list_screen.dart
    │   └── ngo_chat_screen.dart
    └── viewmodels/
        ├── ngo_chat_list_viewmodel.dart
        └── ngo_chat_viewmodel.dart
```

## Testing Checklist

- [x] Database migration runs successfully
- [x] Conversations table created with constraints
- [x] Messages table created with indexes
- [x] RLS policies applied correctly
- [x] Chat list loads conversations
- [x] Chat screen loads messages
- [x] Real-time updates work
- [x] Send message functionality
- [x] Mark as read functionality
- [x] Unread count displays correctly
- [x] Navigation from meal detail works
- [x] Bottom navigation integration
- [x] Dark mode support
- [x] Empty states display
- [x] Error handling works
- [x] Loading states display

## Future Enhancements

Potential improvements for future versions:

1. **Image/File Sharing**: Allow sending images of meals
2. **Message Reactions**: Add emoji reactions to messages
3. **Typing Indicators**: Show when other party is typing
4. **Push Notifications**: Notify users of new messages
5. **Message Search**: Search within conversations
6. **Message Deletion**: Allow deleting sent messages
7. **Read Receipts**: Show when messages are read
8. **Group Chats**: Support multiple participants
9. **Voice Messages**: Record and send audio
10. **Message Templates**: Quick replies for common questions

## Summary

The chat feature is fully functional and production-ready with:
- ✅ Complete database schema with RLS
- ✅ Real-time message updates
- ✅ Professional UI with dark mode
- ✅ Unread message tracking
- ✅ Integration with existing NGO dashboard
- ✅ Clean architecture (entities, models, viewmodels)
- ✅ Error handling and loading states
- ✅ Optimized with indexes and efficient queries

NGOs can now communicate directly with restaurants about meal donations, coordinate pickup times, ask questions, and build relationships.
