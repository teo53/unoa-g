-- =====================================================
-- Migration: 012_performance_indexes.sql
-- Purpose: Add missing indexes for query performance
-- Description: Creates composite indexes for common
--              query patterns identified in code review
-- =====================================================

-- =====================================================
-- 1. MESSAGES TABLE INDEXES
-- =====================================================

-- Composite index for fetching messages by channel, ordered by time
-- Used by: ChatNotifier.loadMoreMessages(), channel message feeds
CREATE INDEX IF NOT EXISTS idx_messages_channel_sender_time
  ON messages(channel_id, sender_id, created_at DESC);

-- Index for unread message counts
-- Used by: ChatNotifier.markAsRead(), unread badge counts
CREATE INDEX IF NOT EXISTS idx_messages_channel_read
  ON messages(channel_id, is_read, created_at DESC)
  WHERE is_read = false;

-- Index for message search within a channel
-- Used by: Message search functionality
CREATE INDEX IF NOT EXISTS idx_messages_channel_content_gin
  ON messages USING gin(to_tsvector('korean', content))
  WHERE content IS NOT NULL;

-- Index for pinned messages
-- Used by: Fetching pinned messages for a channel
CREATE INDEX IF NOT EXISTS idx_messages_channel_pinned
  ON messages(channel_id, pinned_at DESC)
  WHERE pinned_at IS NOT NULL;

-- =====================================================
-- 2. LEDGER ENTRIES TABLE INDEXES
-- =====================================================

-- Index for transaction history pagination
-- Used by: SupabaseWalletRepository.getTransactionHistory()
CREATE INDEX IF NOT EXISTS idx_ledger_created_at
  ON ledger_entries(created_at DESC);

-- Index for filtering by entry type
-- Used by: Filtering transactions by type (purchase, tip, etc.)
CREATE INDEX IF NOT EXISTS idx_ledger_wallet_type_time
  ON ledger_entries(to_wallet_id, entry_type, created_at DESC);

-- Index for from_wallet queries
CREATE INDEX IF NOT EXISTS idx_ledger_from_wallet_time
  ON ledger_entries(from_wallet_id, created_at DESC)
  WHERE from_wallet_id IS NOT NULL;

-- =====================================================
-- 3. DT_DONATIONS TABLE INDEXES
-- =====================================================

-- Composite index for donation leaderboard
-- Used by: Top donors ranking, donation feeds
CREATE INDEX IF NOT EXISTS idx_donations_channel_amount
  ON dt_donations(to_channel_id, amount_dt DESC, created_at DESC);

-- Index for user donation history
-- Used by: User's donation history
CREATE INDEX IF NOT EXISTS idx_donations_user_time
  ON dt_donations(from_user_id, created_at DESC);

-- Index for creator donation receipts
-- Used by: Creator dashboard donation feed
CREATE INDEX IF NOT EXISTS idx_donations_creator_time
  ON dt_donations(to_creator_id, created_at DESC);

-- =====================================================
-- 4. SUBSCRIPTIONS TABLE INDEXES
-- =====================================================

-- Index for active subscription checks
-- Used by: Checking if user has active subscription to channel
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_channel_active
  ON subscriptions(user_id, channel_id, is_active)
  WHERE is_active = true;

-- Index for channel subscriber counts
-- Used by: Getting subscriber count for a channel
CREATE INDEX IF NOT EXISTS idx_subscriptions_channel_active
  ON subscriptions(channel_id, started_at DESC)
  WHERE is_active = true;

-- Index for expiring subscriptions
-- Used by: Scheduled job to notify expiring subscriptions
CREATE INDEX IF NOT EXISTS idx_subscriptions_expires
  ON subscriptions(expires_at)
  WHERE expires_at IS NOT NULL AND is_active = true;

-- =====================================================
-- 5. REPLY_QUOTA TABLE INDEXES
-- =====================================================

-- Composite index for quota lookups
-- Used by: Check remaining replies, refresh quotas
CREATE INDEX IF NOT EXISTS idx_reply_quota_user_channel
  ON reply_quota(user_id, channel_id);

-- Index for quota refresh job
-- Used by: refresh_reply_quotas trigger function
CREATE INDEX IF NOT EXISTS idx_reply_quota_channel_period
  ON reply_quota(channel_id, period_start DESC);

-- =====================================================
-- 6. DT_PURCHASES TABLE INDEXES
-- =====================================================

-- Index for purchase history
-- Used by: SupabaseWalletRepository.getPurchaseHistory()
CREATE INDEX IF NOT EXISTS idx_purchases_user_status_time
  ON dt_purchases(user_id, status, created_at DESC);

-- Index for refund eligibility check
-- Used by: SupabaseWalletRepository.requestRefund()
CREATE INDEX IF NOT EXISTS idx_purchases_refund_eligible
  ON dt_purchases(user_id, status, refund_eligible_until)
  WHERE status = 'paid' AND refund_eligible_until > now();

-- =====================================================
-- 7. USER_PROFILES TABLE INDEXES
-- =====================================================

-- Index for user search by display name
-- Used by: User search, mention autocomplete
CREATE INDEX IF NOT EXISTS idx_user_profiles_display_name_gin
  ON user_profiles USING gin(to_tsvector('simple', display_name))
  WHERE display_name IS NOT NULL;

-- Index for username lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_username
  ON user_profiles(username)
  WHERE username IS NOT NULL;

-- =====================================================
-- 8. CHANNELS TABLE INDEXES
-- =====================================================

-- Index for channel search by name
CREATE INDEX IF NOT EXISTS idx_channels_name_gin
  ON channels USING gin(to_tsvector('korean', name));

-- Index for active channels
CREATE INDEX IF NOT EXISTS idx_channels_active
  ON channels(is_active, created_at DESC)
  WHERE is_active = true;

-- =====================================================
-- 9. CREATOR_PROFILES TABLE INDEXES
-- =====================================================

-- Index for verified creators search
-- Used by: Discover page, creator search
CREATE INDEX IF NOT EXISTS idx_creator_profiles_verified_category
  ON creator_profiles(verification_status, category)
  WHERE verification_status = 'verified';

-- =====================================================
-- 10. PRIVATE_CARDS TABLE INDEXES
-- =====================================================

-- Index for available cards by channel
CREATE INDEX IF NOT EXISTS idx_private_cards_channel_available
  ON private_cards(channel_id, is_available, created_at DESC)
  WHERE is_available = true;

-- Index for card purchase lookups
CREATE INDEX IF NOT EXISTS idx_private_card_purchases_user_card
  ON private_card_purchases(user_id, card_id);

-- =====================================================
-- ANALYZE TABLES
-- =====================================================
-- Update statistics for query planner
ANALYZE messages;
ANALYZE ledger_entries;
ANALYZE dt_donations;
ANALYZE subscriptions;
ANALYZE reply_quota;
ANALYZE dt_purchases;
ANALYZE user_profiles;
ANALYZE channels;
ANALYZE creator_profiles;

-- =====================================================
-- INDEX DOCUMENTATION
-- =====================================================
COMMENT ON INDEX idx_messages_channel_sender_time IS
'Composite index for efficient message fetching by channel with sender and time ordering.';

COMMENT ON INDEX idx_ledger_created_at IS
'Index for pagination of ledger entries by creation time.';

COMMENT ON INDEX idx_donations_channel_amount IS
'Composite index for donation leaderboards showing top donors per channel.';
