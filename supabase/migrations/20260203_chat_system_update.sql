-- =====================================================
-- UPDATE CHAT SYSTEM VIEW FOR BIDIRECTIONAL SUPPORT
-- =====================================================
-- This updates the conversation_details view to work
-- for both NGOs and restaurants
-- =====================================================

-- Drop the old view
DROP VIEW IF EXISTS conversation_details;

-- Create updated view with bidirectional support
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
-- Updated conversation_details view to support:
-- - Bidirectional conversations (NGO <-> Restaurant)
-- - Dynamic other_party fields based on current user
-- - Works for both NGO and Restaurant dashboards
-- =====================================================
