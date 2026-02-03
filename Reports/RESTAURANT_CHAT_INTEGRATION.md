# Restaurant Chat Integration

## Overview
Added complete chat functionality for restaurants to communicate with NGOs about meal donations.

## Changes Made

### 1. Database Updates
**File**: `supabase/migrations/20260203_chat_system.sql`

Updated `conversation_details` view to work for both NGOs and restaurants:
- Added `other_party_id` - ID of the other person in conversation
- Added `other_party_name` - Name to display (restaurant name for NGOs, NGO name for restaurants)
- Added `other_party_avatar` - Avatar of the other party
- View now works bidirectionally based on `auth.uid()`

### 2. Restaurant Chat Screens

**RestaurantChatListScreen**:
- `lib/features/restaurant_dashboard/presentation/screens/restaurant_chat_list_screen.dart`
- Shows all conversations with NGOs
- Displays unread count badges
- Pull-to-refresh functionality
- Integrated with restaurant bottom navigation

**RestaurantChatScreen**:
- `lib/features/restaurant_dashboard/presentation/screens/restaurant_chat_screen.dart`
- Real-time messaging with NGOs
- Same UI/UX as NGO chat screen
- Message bubbles, date dividers, timestamps
- Auto-scroll and mark as read

### 3. Navigation Updates

**Bottom Navigation**:
- Added "Chats" tab to `RestaurantBottomNav`
- Updated profile index from 3 to 4
- Chat icon with badge for unread messages

**Routes Added**:
```dart
/restaurant/chats - Chat list screen
/restaurant/chat/:id - Individual chat screen
```

### 4. Shared Components

Both NGO and Restaurant chat features use the same:
- `NgoChatListViewModel` - Works for both roles
- `NgoChatViewModel` - Works for both roles
- Conversation and Message entities/models
- Real-time Supabase subscriptions

## How It Works

### For NGOs (Initiating Chat):
1. NGO views meal detail screen
2. Clicks "Chat" button next to restaurant name
3. System creates conversation if doesn't exist
4. Opens chat screen with restaurant

### For Restaurants (Receiving Chat):
1. NGO starts conversation
2. Restaurant sees new conversation in "Chats" tab
3. Unread badge appears on bottom navigation
4. Restaurant can view and respond to messages

### Real-time Updates:
- Both parties see messages instantly
- Unread counts update automatically
- No page refresh needed
- Messages marked as read when viewing

## Navigation Flow

### Restaurant Starting Point:
1. Restaurant bottom nav → Chats tab (index 3)
2. See list of conversations with NGOs
3. Tap conversation to open chat
4. Send/receive messages in real-time

### NGO Starting Point:
1. View meal detail → Click "Chat" button
2. OR: NGO bottom nav → Chats tab
3. See list of conversations with restaurants
4. Tap conversation to open chat
5. Send/receive messages in real-time

## Database Schema

### Conversations Table
- Stores one conversation per NGO-Restaurant pair
- `ngo_id` and `restaurant_id` with unique constraint
- `last_message_at` for sorting

### Messages Table
- Stores all messages in conversations
- `sender_id` identifies who sent the message
- `is_read` tracks read status
- Real-time updates via Supabase Realtime

### View: conversation_details
- Dynamically shows correct party name based on current user
- Calculates unread count per conversation
- Includes last message preview
- Works for both NGOs and restaurants

## UI Features

### Chat List:
- Avatar with fallback icon (restaurant icon for NGOs, NGO icon for restaurants)
- Party name
- Last message preview
- Relative time (e.g., "5m", "2h", "3d")
- Unread count badge (green)
- Bold text for unread conversations

### Chat Screen:
- Party info in app bar
- Message bubbles (green for sent, white/dark for received)
- Date dividers between days
- Timestamps on each message
- Empty state with helpful text
- Loading indicator while sending
- Auto-scroll to bottom on new messages

## Testing Checklist

- [x] Restaurant can see conversations from NGOs
- [x] Restaurant can send messages
- [x] Restaurant can receive messages in real-time
- [x] Unread count displays correctly
- [x] Bottom navigation shows chat tab
- [x] Profile index updated to 4
- [x] Routes work correctly
- [x] Dark mode support
- [x] Empty states display
- [x] Error handling works

## Summary

The chat system is now fully bidirectional:
- ✅ NGOs can initiate chats with restaurants
- ✅ Restaurants can view and respond to chats
- ✅ Real-time messaging works both ways
- ✅ Unread tracking for both parties
- ✅ Professional UI matching app design
- ✅ Integrated with bottom navigation
- ✅ Shared codebase (viewmodels work for both roles)

Both NGOs and restaurants can now communicate seamlessly about meal donations, coordinate pickup times, ask questions, and build relationships.
