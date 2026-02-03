-- ============================================
-- UNO A - Moderation & Safety Schema
-- Version: 1.1.0
-- ============================================

-- ============================================
-- 1. REPORTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES auth.users(id),

  -- Target (one of these should be set)
  target_type TEXT NOT NULL CHECK (target_type IN ('user', 'message', 'channel', 'private_card')),
  target_user_id UUID REFERENCES auth.users(id),
  target_message_id UUID REFERENCES messages(id),
  target_channel_id UUID REFERENCES channels(id),
  target_card_id UUID REFERENCES private_cards(id),

  -- Report details
  reason TEXT NOT NULL CHECK (reason IN (
    'spam',
    'harassment',
    'hate_speech',
    'inappropriate_content',
    'impersonation',
    'scam',
    'self_harm',
    'violence',
    'copyright',
    'privacy_violation',
    'other'
  )),
  description TEXT,
  evidence_urls TEXT[] DEFAULT '{}',

  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewing', 'resolved', 'dismissed')),
  resolution TEXT,
  resolution_notes TEXT,

  -- Moderation
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,
  action_taken TEXT, -- 'warning', 'message_deleted', 'user_banned', 'content_removed', 'none'

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_reporter ON reports(reporter_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_target_user ON reports(target_user_id) WHERE target_type = 'user';
CREATE INDEX IF NOT EXISTS idx_reports_target_message ON reports(target_message_id) WHERE target_type = 'message';

-- ============================================
-- 2. USER BLOCKS
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_block UNIQUE(blocker_id, blocked_id),
  CONSTRAINT no_self_block CHECK (blocker_id != blocked_id)
);

CREATE INDEX IF NOT EXISTS idx_blocks_blocker ON user_blocks(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocks_blocked ON user_blocks(blocked_id);

-- ============================================
-- 3. HIDDEN FANS (Creator's inbox filter)
-- Fans can still send messages but creator won't see them
-- ============================================
CREATE TABLE IF NOT EXISTS public.hidden_fans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fan_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_hidden_fan UNIQUE(creator_id, fan_id)
);

CREATE INDEX IF NOT EXISTS idx_hidden_creator ON hidden_fans(creator_id);
CREATE INDEX IF NOT EXISTS idx_hidden_fan ON hidden_fans(fan_id);

-- ============================================
-- 4. SPAM DETECTION LOG
-- ============================================
CREATE TABLE IF NOT EXISTS public.spam_detection_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  channel_id UUID REFERENCES channels(id),

  detection_type TEXT NOT NULL, -- 'rate_limit', 'content_filter', 'ml_model', 'keyword'
  risk_score FLOAT,
  triggered_rules TEXT[],

  action_taken TEXT, -- 'blocked', 'flagged', 'shadowban', 'none'

  original_content TEXT,
  metadata JSONB DEFAULT '{}',

  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_spam_user ON spam_detection_log(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_spam_channel ON spam_detection_log(channel_id, created_at DESC);

-- ============================================
-- 5. USER WARNINGS
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_warnings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  issued_by UUID REFERENCES auth.users(id),

  warning_type TEXT NOT NULL CHECK (warning_type IN (
    'spam', 'harassment', 'inappropriate', 'violation', 'other'
  )),
  message TEXT NOT NULL,
  report_id UUID REFERENCES reports(id),

  acknowledged_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ -- Warnings may expire
);

CREATE INDEX IF NOT EXISTS idx_warnings_user ON user_warnings(user_id, created_at DESC);

-- ============================================
-- 6. BAN HISTORY
-- ============================================
CREATE TABLE IF NOT EXISTS public.ban_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  banned_by UUID REFERENCES auth.users(id),

  ban_type TEXT NOT NULL CHECK (ban_type IN ('temporary', 'permanent')),
  reason TEXT NOT NULL,
  report_id UUID REFERENCES reports(id),

  banned_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ, -- NULL for permanent
  unbanned_at TIMESTAMPTZ,
  unbanned_by UUID REFERENCES auth.users(id),
  unban_reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_bans_user ON ban_history(user_id, banned_at DESC);

-- ============================================
-- 7. CRM: FAN NOTES & TAGS
-- ============================================

-- Fan Notes (creator's private notes about fans)
CREATE TABLE IF NOT EXISTS public.fan_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fan_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_fan_notes_creator ON fan_notes(creator_id);
CREATE INDEX IF NOT EXISTS idx_fan_notes_fan ON fan_notes(creator_id, fan_id);

-- Fan Tags
CREATE TABLE IF NOT EXISTS public.fan_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tag_name TEXT NOT NULL,
  tag_color TEXT DEFAULT '#6B7280',
  description TEXT,
  fan_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),

  CONSTRAINT unique_creator_tag UNIQUE(creator_id, tag_name)
);

CREATE INDEX IF NOT EXISTS idx_fan_tags_creator ON fan_tags(creator_id);

-- Fan Tag Assignments
CREATE TABLE IF NOT EXISTS public.fan_tag_assignments (
  fan_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES fan_tags(id) ON DELETE CASCADE,
  assigned_by UUID REFERENCES auth.users(id),
  assigned_at TIMESTAMPTZ DEFAULT now(),

  PRIMARY KEY(fan_id, tag_id)
);

CREATE INDEX IF NOT EXISTS idx_tag_assignments_tag ON fan_tag_assignments(tag_id);
CREATE INDEX IF NOT EXISTS idx_tag_assignments_fan ON fan_tag_assignments(fan_id);

-- ============================================
-- 8. CAMPAIGNS (Broadcast tools)
-- ============================================
CREATE TABLE IF NOT EXISTS public.campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES auth.users(id),
  channel_id UUID NOT NULL REFERENCES channels(id),

  name TEXT NOT NULL,
  description TEXT,

  -- Target audience
  target_segment JSONB NOT NULL DEFAULT '{}',
  -- Example: {"tiers": ["VIP", "STANDARD"], "min_days": 30, "tags": ["active"], "min_spend_dt": 100}
  estimated_reach INT,
  actual_reach INT,

  -- Content
  message_content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text',
  media_url TEXT,

  -- Scheduling
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,

  -- A/B Testing
  is_ab_test BOOLEAN DEFAULT false,
  variant_b_content TEXT,
  variant_b_percentage INT DEFAULT 50,

  -- Stats
  recipients_count INT DEFAULT 0,
  delivered_count INT DEFAULT 0,
  opened_count INT DEFAULT 0,
  replied_count INT DEFAULT 0,

  -- Status
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'sending', 'sent', 'cancelled', 'failed')),
  error_message TEXT,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_campaigns_creator ON campaigns(creator_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_campaigns_channel ON campaigns(channel_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_campaigns_scheduled ON campaigns(scheduled_at) WHERE status = 'scheduled';
CREATE INDEX IF NOT EXISTS idx_campaigns_status ON campaigns(status);

-- ============================================
-- 9. RLS POLICIES
-- ============================================
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE hidden_fans ENABLE ROW LEVEL SECURITY;
ALTER TABLE spam_detection_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_warnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE ban_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE fan_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE fan_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE fan_tag_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;

-- Reports
CREATE POLICY "Users can create reports"
  ON reports FOR INSERT
  WITH CHECK (reporter_id = auth.uid());

CREATE POLICY "Users can view own reports"
  ON reports FOR SELECT
  USING (reporter_id = auth.uid());

CREATE POLICY "Admins can manage all reports"
  ON reports FOR ALL
  USING (EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'));

-- User Blocks
CREATE POLICY "Users can manage own blocks"
  ON user_blocks FOR ALL
  USING (blocker_id = auth.uid());

CREATE POLICY "Users can see if they are blocked"
  ON user_blocks FOR SELECT
  USING (blocked_id = auth.uid());

-- Hidden Fans
CREATE POLICY "Creators can manage hidden fans"
  ON hidden_fans FOR ALL
  USING (creator_id = auth.uid());

-- Spam Detection Log
CREATE POLICY "Admins can view spam logs"
  ON spam_detection_log FOR SELECT
  USING (EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'));

-- User Warnings
CREATE POLICY "Users can view own warnings"
  ON user_warnings FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can acknowledge own warnings"
  ON user_warnings FOR UPDATE
  USING (user_id = auth.uid());

-- Ban History
CREATE POLICY "Admins can manage bans"
  ON ban_history FOR ALL
  USING (EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'));

-- Fan Notes
CREATE POLICY "Creators can manage own fan notes"
  ON fan_notes FOR ALL
  USING (creator_id = auth.uid());

-- Fan Tags
CREATE POLICY "Creators can manage own tags"
  ON fan_tags FOR ALL
  USING (creator_id = auth.uid());

-- Fan Tag Assignments
CREATE POLICY "Creators can manage tag assignments"
  ON fan_tag_assignments FOR ALL
  USING (
    EXISTS (SELECT 1 FROM fan_tags ft WHERE ft.id = fan_tag_assignments.tag_id AND ft.creator_id = auth.uid())
  );

-- Campaigns
CREATE POLICY "Creators can manage own campaigns"
  ON campaigns FOR ALL
  USING (creator_id = auth.uid());

-- ============================================
-- 10. HELPER FUNCTIONS
-- ============================================

-- Check if user is blocked
CREATE OR REPLACE FUNCTION public.is_blocked(p_user_id UUID, p_by_user_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_blocks
    WHERE blocker_id = p_by_user_id AND blocked_id = p_user_id
  );
$$ LANGUAGE sql STABLE;

-- Check if fan is hidden by creator
CREATE OR REPLACE FUNCTION public.is_fan_hidden(p_fan_id UUID, p_creator_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM hidden_fans
    WHERE creator_id = p_creator_id AND fan_id = p_fan_id
  );
$$ LANGUAGE sql STABLE;

-- Block user
CREATE OR REPLACE FUNCTION public.block_user(p_user_id UUID, p_reason TEXT DEFAULT NULL)
RETURNS user_blocks AS $$
DECLARE
  v_block user_blocks;
BEGIN
  INSERT INTO user_blocks (blocker_id, blocked_id, reason)
  VALUES (auth.uid(), p_user_id, p_reason)
  ON CONFLICT (blocker_id, blocked_id) DO NOTHING
  RETURNING * INTO v_block;

  RETURN v_block;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Unblock user
CREATE OR REPLACE FUNCTION public.unblock_user(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  DELETE FROM user_blocks
  WHERE blocker_id = auth.uid() AND blocked_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Hide fan (for creators)
CREATE OR REPLACE FUNCTION public.hide_fan(p_fan_id UUID, p_reason TEXT DEFAULT NULL)
RETURNS hidden_fans AS $$
DECLARE
  v_hidden hidden_fans;
BEGIN
  -- Verify caller is a creator
  IF NOT EXISTS (SELECT 1 FROM creator_profiles WHERE user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Only creators can hide fans';
  END IF;

  INSERT INTO hidden_fans (creator_id, fan_id, reason)
  VALUES (auth.uid(), p_fan_id, p_reason)
  ON CONFLICT (creator_id, fan_id) DO NOTHING
  RETURNING * INTO v_hidden;

  RETURN v_hidden;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Unhide fan
CREATE OR REPLACE FUNCTION public.unhide_fan(p_fan_id UUID)
RETURNS VOID AS $$
BEGIN
  DELETE FROM hidden_fans
  WHERE creator_id = auth.uid() AND fan_id = p_fan_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create report
CREATE OR REPLACE FUNCTION public.create_report(
  p_target_type TEXT,
  p_target_id UUID,
  p_reason TEXT,
  p_description TEXT DEFAULT NULL,
  p_evidence_urls TEXT[] DEFAULT '{}'
)
RETURNS reports AS $$
DECLARE
  v_report reports;
BEGIN
  INSERT INTO reports (
    reporter_id,
    target_type,
    target_user_id,
    target_message_id,
    target_channel_id,
    target_card_id,
    reason,
    description,
    evidence_urls
  ) VALUES (
    auth.uid(),
    p_target_type,
    CASE WHEN p_target_type = 'user' THEN p_target_id ELSE NULL END,
    CASE WHEN p_target_type = 'message' THEN p_target_id ELSE NULL END,
    CASE WHEN p_target_type = 'channel' THEN p_target_id ELSE NULL END,
    CASE WHEN p_target_type = 'private_card' THEN p_target_id ELSE NULL END,
    p_reason,
    p_description,
    p_evidence_urls
  ) RETURNING * INTO v_report;

  RETURN v_report;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get fan segments for campaign targeting
CREATE OR REPLACE FUNCTION public.get_fans_for_segment(
  p_channel_id UUID,
  p_segment JSONB
)
RETURNS TABLE (fan_id UUID, tier TEXT, days_subscribed INT, total_spent_dt BIGINT) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.user_id as fan_id,
    s.tier,
    EXTRACT(DAY FROM (now() - s.started_at))::INT as days_subscribed,
    COALESCE(SUM(d.amount_dt), 0)::BIGINT as total_spent_dt
  FROM subscriptions s
  LEFT JOIN dt_donations d ON d.from_user_id = s.user_id AND d.to_channel_id = s.channel_id
  WHERE s.channel_id = p_channel_id
    AND s.is_active = true
    AND (
      p_segment->'tiers' IS NULL
      OR s.tier = ANY(ARRAY(SELECT jsonb_array_elements_text(p_segment->'tiers')))
    )
  GROUP BY s.user_id, s.tier, s.started_at
  HAVING
    (p_segment->>'min_days' IS NULL OR EXTRACT(DAY FROM (now() - s.started_at)) >= (p_segment->>'min_days')::INT)
    AND (p_segment->>'min_spend_dt' IS NULL OR COALESCE(SUM(d.amount_dt), 0) >= (p_segment->>'min_spend_dt')::INT);
END;
$$ LANGUAGE plpgsql STABLE;

-- Update fan tag count trigger
CREATE OR REPLACE FUNCTION public.update_fan_tag_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE fan_tags SET fan_count = fan_count + 1 WHERE id = NEW.tag_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE fan_tags SET fan_count = fan_count - 1 WHERE id = OLD.tag_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_tag_count ON fan_tag_assignments;
CREATE TRIGGER update_tag_count
  AFTER INSERT OR DELETE ON fan_tag_assignments
  FOR EACH ROW
  EXECUTE FUNCTION public.update_fan_tag_count();
