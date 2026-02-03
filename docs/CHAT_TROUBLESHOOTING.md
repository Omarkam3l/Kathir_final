# Chat Feature Troubleshooting Guide

## Issue: Restaurant Not Receiving Messages

### Problem
NGO sends message but restaurant doesn't see it in their chat list.

### Solutions Applied

#### 1. Fixed Viewmodel Query (CODE FIX - DONE)
**File**: `lib/features/ngo_dashboard/presentation/viewmodels/ngo_chat_list_viewmodel.dart`

**Problem**: The viewmodel was only querying conversations where `ngo_id = current_user`, which doesn't work for restaurants.

**Fix**: Now checks user role and queries appropriately:
- NGOs: Filter by `ngo_id`
- Restaurants: Filter by `restaurant_id`

#### 2. Fixed Conversation Model (CODE FIX - DONE)
**File**: `lib/features/ngo_dashboard/data/models/conversation_model.dart`

**Problem**: Always used `restaurant_name` field which doesn't exist for restaurant users.

**Fix**: Now uses `other_party_name` from the updated database view, which shows:
- For NGOs: Restaurant name
- For Restaurants: NGO name

#### 3. Enable Supabase Realtime (MANUAL STEP REQUIRED)

You need to enable Realtime in Supabase for the chat tables:

**Steps:**
1. Go to Supabase Dashboard
2. Navigate to **Database** → **Replication**
3. Find these tables and enable replication:
   - `conversations`
   - `messages`
4. Click the toggle to enable for each table

**OR via SQL:**
```sql
-- Enable realtime for conversations table
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;

-- Enable realtime for messages table
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
```

#### 4. Verify Database View (MANUAL CHECK)

Make sure the `conversation_details` view has the updated fields:

**Check in Supabase SQL Editor:**
```sql
SELECT * FROM conversation_details LIMIT 1;
```

**Should have these columns:**
- `id`
- `ngo_id`
- `restaurant_id`
- `last_message_at`
- `created_at`
- `ngo_name`
- `ngo_avatar`
- `restaurant_name`
- `restaurant_business_name`
- `restaurant_avatar`
- `last_message`
- `unread_count`
- **`other_party_id`** ← NEW
- **`other_party_name`** ← NEW
- **`other_party_avatar`** ← NEW

If these fields are missing, run the update migration:
```bash
# In Supabase SQL Editor, run:
supabase/migrations/20260203_chat_system_update.sql
```

## Testing Steps

### Test 1: NGO Sends Message
1. Login as NGO
2. Go to meal detail → Click "Chat" button
3. Send a message
4. ✅ Message should appear in NGO's chat screen

### Test 2: Restaurant Receives Message
1. Login as Restaurant (same restaurant from the meal)
2. Go to "Chats" tab in bottom navigation
3. ✅ Should see conversation with NGO
4. ✅ Should see unread badge
5. Tap conversation to open
6. ✅ Should see NGO's message

### Test 3: Restaurant Replies
1. In restaurant chat screen, type and send reply
2. ✅ Message should appear in restaurant's chat
3. Switch to NGO account
4. ✅ NGO should see restaurant's reply in real-time

### Test 4: Real-time Updates
1. Open chat on both NGO and Restaurant (different devices/browsers)
2. Send message from NGO
3. ✅ Should appear instantly on restaurant's screen
4. Send reply from restaurant
5. ✅ Should appear instantly on NGO's screen

## Common Issues

### Issue: "No conversations yet" on Restaurant
**Cause**: View not updated or query filter wrong
**Fix**: 
- Run the update migration
- Restart the app
- Check that code changes were applied

### Issue: Messages not appearing in real-time
**Cause**: Realtime not enabled in Supabase
**Fix**: Enable replication for `conversations` and `messages` tables

### Issue: "Error loading conversations"
**Cause**: Database view missing or RLS policies blocking
**Fix**: 
- Check Supabase logs
- Verify RLS policies allow both NGOs and restaurants to read conversations
- Ensure view exists: `SELECT * FROM conversation_details;`

### Issue: Conversation shows but no messages
**Cause**: RLS policy on messages table
**Fix**: Verify messages RLS policy allows both parties to read:
```sql
-- Check existing policies
SELECT * FROM pg_policies WHERE tablename = 'messages';
```

## Verification Checklist

- [ ] Code changes applied (viewmodel and model updated)
- [ ] Database view updated with `other_party_*` fields
- [ ] Realtime enabled for `conversations` table
- [ ] Realtime enabled for `messages` table
- [ ] RLS policies allow both NGOs and restaurants to read/write
- [ ] App restarted after changes
- [ ] Tested NGO → Restaurant messaging
- [ ] Tested Restaurant → NGO messaging
- [ ] Tested real-time updates

## Debug Commands

### Check if conversation exists:
```sql
SELECT * FROM conversations 
WHERE ngo_id = 'YOUR_NGO_ID' 
AND restaurant_id = 'YOUR_RESTAURANT_ID';
```

### Check messages in conversation:
```sql
SELECT * FROM messages 
WHERE conversation_id = 'YOUR_CONVERSATION_ID'
ORDER BY created_at DESC;
```

### Check conversation_details view:
```sql
SELECT * FROM conversation_details 
WHERE ngo_id = 'YOUR_NGO_ID' 
OR restaurant_id = 'YOUR_RESTAURANT_ID';
```

### Check user role:
```sql
SELECT id, role, full_name FROM profiles 
WHERE id = 'YOUR_USER_ID';
```

## Summary

The main fixes were:
1. ✅ Updated viewmodel to query based on user role
2. ✅ Updated model to use `other_party_name` field
3. ⚠️ **YOU NEED TO**: Enable Realtime in Supabase
4. ⚠️ **YOU NEED TO**: Verify database view is updated

After applying these fixes and enabling Realtime, the chat should work bidirectionally!
