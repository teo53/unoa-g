-- =====================================================
-- Migration: 064_funding_tier_waitlist.sql
-- Purpose: Waitlist for sold-out reward tiers
-- Description:
--   Allows fans to subscribe to notifications when
--   a sold-out tier becomes available again.
-- =====================================================

CREATE TABLE IF NOT EXISTS public.funding_tier_waitlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_id UUID NOT NULL REFERENCES funding_reward_tiers(id) ON DELETE CASCADE,
  campaign_id UUID NOT NULL REFERENCES funding_campaigns(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Notification status
  notified_at TIMESTAMPTZ,           -- When the user was notified of availability
  is_active BOOLEAN DEFAULT true,    -- User can cancel their waitlist entry

  created_at TIMESTAMPTZ DEFAULT now()
);

-- Each user can only be on the waitlist once per tier
CREATE UNIQUE INDEX IF NOT EXISTS idx_waitlist_unique_entry
  ON funding_tier_waitlist(tier_id, user_id)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_waitlist_tier ON funding_tier_waitlist(tier_id, is_active);
CREATE INDEX IF NOT EXISTS idx_waitlist_user ON funding_tier_waitlist(user_id, is_active);

-- ============================================
-- RLS POLICIES
-- ============================================
ALTER TABLE funding_tier_waitlist ENABLE ROW LEVEL SECURITY;

-- Users can view their own waitlist entries
CREATE POLICY "Users can view own waitlist entries"
  ON funding_tier_waitlist FOR SELECT
  USING (user_id = auth.uid());

-- Users can insert their own waitlist entries
CREATE POLICY "Users can join waitlist"
  ON funding_tier_waitlist FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Users can update (cancel) their own waitlist entries
CREATE POLICY "Users can cancel own waitlist entries"
  ON funding_tier_waitlist FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

COMMENT ON TABLE funding_tier_waitlist IS '펀딩 리워드 티어 빈자리 알림 대기 목록';
