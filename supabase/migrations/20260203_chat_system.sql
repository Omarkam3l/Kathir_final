-- =====================================================
-- CHAT SYSTEM FOR NGO DASHBOARD
-- =====================================================
-- This migration creates the chat/messaging system
-- allowing NGOs to communicate with restaurants
-- =====================================================

-- =====================================================
-- TABLE: conversations
-- =====================================================

CREATE TABLE IF NOT EXISTS public.conversations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  ngo_id uuid NOT NULL,
  restaurant_id uuid NOT NULL,
  last_message_at timestamp with time zone NULL DEFAULT now(),
  created_at timestamp with time zone NULL DEFAULT now(),
  
  CONSTRAINT conversations_pkey PRIMARY KEY (id),
  CONSTRAINT conversations_ngo_id_fkey FOREIGN KEY (ngo_id) REFERENCES profiles (id) ON DELETE CASCADE,
  CONSTRAINT conversations_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES profiles (id) ON DELETE CASCADE,
  CONSTRAINT conversations_unique_pair UNIQUE (ngo_id, restaurant_id)
) TABLESPACE pg_default;

-- Indexes for conversations
CREATE INDEX IF NOT EXISTS idx_conversations_ngo_id ON public.conversations USING btree (ngo_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_conversations_restaurant_id ON public.conversations USING btree (restaurant_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_conversations_last_message_at ON public.conversations USING btree (last_message_at DESC) TABLESPACE pg_default;

-- =====================================================
-- TABLE: messages
-- =====================================================

CREATE TABLE IF NOT EXISTS public.messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL,
  sender_id uuid NOT NULL,
  content text NOT NULL,
  is_read boolean NULL DEFAULT false,
  created_at timestamp with time zone NULL DEFAULT now(),
  
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE,
  CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES profiles (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- Indexes for messages
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages USING btree (conversation_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages USING btree (sender_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages USING btree (created_at DESC) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_messages_is_read ON public.messages USING btree (is_read) TABLESPACE pg_default;

-- =====================================================
-- FUNCTION: Update conversation last_message_at
-- =====================================================

CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET last_message_at = NEW.created_at
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update last_message_at
DROP TRIGGER IF EXISTS trg_update_conversation_last_message ON messages;
CREATE TRIGGER trg_update_conversation_last_message
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION update_conversation_last_message();

-- =====================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Conversations Policies
CREATE POLICY "Users can view their own conversations"
ON conversations FOR SELECT
TO authenticated
USING (ngo_id = auth.uid() OR restaurant_id = auth.uid());

CREATE POLICY "NGOs can create conversations"
ON conversations FOR INSERT
TO authenticated
WITH CHECK (ngo_id = auth.uid());

CREATE POLICY "Restaurants can create conversations"
ON conversations FOR INSERT
TO authenticated
WITH CHECK (restaurant_id = auth.uid());

-- Messages Policies
CREATE POLICY "Users can view messages in their conversations"
ON messages FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM conversations
    WHERE conversations.id = messages.conversation_id
    AND (conversations.ngo_id = auth.uid() OR conversations.restaurant_id = auth.uid())
  )
);

CREATE POLICY "Users can send messages in their conversations"
ON messages FOR INSERT
TO authenticated
WITH CHECK (
  sender_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM conversations
    WHERE conversations.id = messages.conversation_id
    AND (conversations.ngo_id = auth.uid() OR conversations.restaurant_id = auth.uid())
  )
);

CREATE POLICY "Users can update their own messages"
ON messages FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM conversations
    WHERE conversations.id = messages.conversation_id
    AND (conversations.ngo_id = auth.uid() OR conversations.restaurant_id = auth.uid())
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM conversations
    WHERE conversations.id = messages.conversation_id
    AND (conversations.ngo_id = auth.uid() OR conversations.restaurant_id = auth.uid())
  )
);

-- =====================================================
-- VIEW: conversation_details
-- =====================================================

CREATE OR REPLACE VIEW conversation_details AS
SELECT 
  c.id,
  c.ngo_id,
  c.restaurant_id,
  c.last_message_at,
  c.created_at,
  ngo.full_name as ngo_name,
  ngo.avatar_url as ngo_avatar,
  rest.full_name as restaurant_name,
  r.restaurant_name as restaurant_business_name,
  rest.avatar_url as restaurant_avatar,
  (
    SELECT content 
    FROM messages 
    WHERE conversation_id = c.id 
    ORDER BY created_at DESC 
    LIMIT 1
  ) as last_message,
  (
    SELECT COUNT(*) 
    FROM messages 
    WHERE conversation_id = c.id 
    AND is_read = false 
    AND sender_id != auth.uid()
  ) as unread_count,
  -- Add fields to identify the other party based on current user
  CASE 
    WHEN c.ngo_id = auth.uid() THEN c.restaurant_id
    WHEN c.restaurant_id = auth.uid() THEN c.ngo_id
    ELSE NULL
  END as other_party_id,
  CASE 
    WHEN c.ngo_id = auth.uid() THEN COALESCE(r.restaurant_name, rest.full_name, 'Restaurant')
    WHEN c.restaurant_id = auth.uid() THEN COALESCE(ngo.full_name, 'NGO')
    ELSE NULL
  END as other_party_name,
  CASE 
    WHEN c.ngo_id = auth.uid() THEN rest.avatar_url
    WHEN c.restaurant_id = auth.uid() THEN ngo.avatar_url
    ELSE NULL
  END as other_party_avatar
FROM conversations c
LEFT JOIN profiles ngo ON c.ngo_id = ngo.id
LEFT JOIN profiles rest ON c.restaurant_id = rest.id
LEFT JOIN restaurants r ON c.restaurant_id = r.profile_id
ORDER BY c.last_message_at DESC;

-- Grant access to view
GRANT SELECT ON conversation_details TO authenticated;

-- =====================================================
-- SUMMARY
-- =====================================================
-- Created tables: conversations, messages
-- Created indexes for performance
-- Created trigger to update last_message_at
-- Created RLS policies for security
-- Created view for conversation details
-- =====================================================
