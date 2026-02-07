-- ============================================
-- 033: Count unread inbox messages for artist
-- ============================================
-- Replaces hardcoded `unreadMessages = 0` in supabase_inbox_repository.dart
-- Uses message_delivery table's is_read field for tracking.

CREATE OR REPLACE FUNCTION count_unread_inbox_messages(
  p_channel_id UUID,
  p_artist_user_id UUID
)
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT COUNT(*)::INTEGER
  FROM messages m
  WHERE m.channel_id = p_channel_id
    AND m.delivery_scope IN ('direct_reply', 'donation_message')
    AND m.sender_id != p_artist_user_id
    AND m.deleted_at IS NULL
    AND NOT EXISTS (
      SELECT 1
      FROM message_delivery md
      WHERE md.message_id = m.id
        AND md.user_id = p_artist_user_id
        AND md.is_read = true
    );
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION count_unread_inbox_messages(UUID, UUID) TO authenticated;
