-- ============================================
-- 078: DT Auto-Charge Config + Challenge System
-- ============================================

-- ============================================
-- Part 1: DT Auto-Charge Configuration
-- ============================================

CREATE TABLE IF NOT EXISTS dt_auto_charge_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  is_enabled BOOLEAN NOT NULL DEFAULT false,
  threshold_dt INT NOT NULL DEFAULT 100
    CHECK (threshold_dt >= 0 AND threshold_dt <= 10000),
  charge_amount_dt INT NOT NULL DEFAULT 1000
    CHECK (charge_amount_dt >= 100 AND charge_amount_dt <= 50000),
  charge_package_id TEXT,  -- references DT package
  billing_key_id TEXT,     -- TossPayments billing key reference
  max_monthly_charges INT NOT NULL DEFAULT 5
    CHECK (max_monthly_charges >= 1 AND max_monthly_charges <= 30),
  charges_this_month INT NOT NULL DEFAULT 0,
  last_charged_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT dt_auto_charge_config_user_unique UNIQUE (user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_auto_charge_enabled
  ON dt_auto_charge_config(is_enabled, threshold_dt)
  WHERE is_enabled = true;

-- RLS
ALTER TABLE dt_auto_charge_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own auto-charge config"
  ON dt_auto_charge_config FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own auto-charge config"
  ON dt_auto_charge_config FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own auto-charge config"
  ON dt_auto_charge_config FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Reset monthly counter (called by scheduled-dispatcher on 1st of month)
CREATE OR REPLACE FUNCTION reset_monthly_auto_charge_counts()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE dt_auto_charge_config
  SET charges_this_month = 0,
      updated_at = now();
END;
$$;


-- ============================================
-- Part 2: Challenge System
-- ============================================

-- Challenge status lifecycle: draft → active → voting → completed → archived
CREATE TABLE IF NOT EXISTS challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  creator_id UUID NOT NULL REFERENCES auth.users(id),
  title TEXT NOT NULL CHECK (char_length(title) BETWEEN 1 AND 100),
  description TEXT CHECK (char_length(description) <= 2000),
  rules TEXT CHECK (char_length(rules) <= 2000),
  challenge_type TEXT NOT NULL DEFAULT 'photo'
    CHECK (challenge_type IN ('photo', 'text', 'video', 'quiz')),
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'active', 'voting', 'completed', 'archived')),
  reward_type TEXT NOT NULL DEFAULT 'dt'
    CHECK (reward_type IN ('dt', 'badge', 'shoutout', 'custom')),
  reward_amount_dt INT DEFAULT 0
    CHECK (reward_amount_dt >= 0 AND reward_amount_dt <= 100000),
  reward_description TEXT,
  max_submissions INT DEFAULT 0,  -- 0 = unlimited
  max_winners INT NOT NULL DEFAULT 1,
  start_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  end_at TIMESTAMPTZ NOT NULL,
  voting_end_at TIMESTAMPTZ,
  thumbnail_url TEXT,
  total_submissions INT NOT NULL DEFAULT 0,
  total_votes INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT challenges_end_after_start CHECK (end_at > start_at),
  CONSTRAINT challenges_voting_after_end CHECK (
    voting_end_at IS NULL OR voting_end_at >= end_at
  )
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_challenges_channel ON challenges(channel_id);
CREATE INDEX IF NOT EXISTS idx_challenges_status ON challenges(status);
CREATE INDEX IF NOT EXISTS idx_challenges_active
  ON challenges(channel_id, status, end_at)
  WHERE status IN ('active', 'voting');

-- RLS
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;

-- Subscribers can view active/voting/completed challenges
CREATE POLICY "Subscribers can view challenges"
  ON challenges FOR SELECT
  USING (
    status IN ('active', 'voting', 'completed')
    OR creator_id = auth.uid()
  );

CREATE POLICY "Creators can manage own challenges"
  ON challenges FOR INSERT
  WITH CHECK (creator_id = auth.uid());

CREATE POLICY "Creators can update own challenges"
  ON challenges FOR UPDATE
  USING (creator_id = auth.uid())
  WITH CHECK (creator_id = auth.uid());


-- Challenge Submissions
CREATE TABLE IF NOT EXISTS challenge_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  fan_id UUID NOT NULL REFERENCES auth.users(id),
  content TEXT CHECK (char_length(content) <= 2000),
  media_url TEXT,
  media_type TEXT CHECK (media_type IN ('image', 'video', NULL)),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected', 'winner')),
  vote_count INT NOT NULL DEFAULT 0,
  creator_comment TEXT,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at TIMESTAMPTZ,
  CONSTRAINT submissions_unique_per_challenge
    UNIQUE (challenge_id, fan_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_submissions_challenge
  ON challenge_submissions(challenge_id, status);
CREATE INDEX IF NOT EXISTS idx_submissions_fan
  ON challenge_submissions(fan_id);
CREATE INDEX IF NOT EXISTS idx_submissions_votes
  ON challenge_submissions(challenge_id, vote_count DESC)
  WHERE status = 'approved';

-- RLS
ALTER TABLE challenge_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Fans can view approved submissions"
  ON challenge_submissions FOR SELECT
  USING (
    status IN ('approved', 'winner')
    OR fan_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM challenges c
      WHERE c.id = challenge_id AND c.creator_id = auth.uid()
    )
  );

CREATE POLICY "Fans can submit to challenges"
  ON challenge_submissions FOR INSERT
  WITH CHECK (fan_id = auth.uid());

CREATE POLICY "Creators can review submissions"
  ON challenge_submissions FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM challenges c
      WHERE c.id = challenge_id AND c.creator_id = auth.uid()
    )
  );


-- Challenge Votes (fans vote on submissions)
CREATE TABLE IF NOT EXISTS challenge_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id UUID NOT NULL REFERENCES challenge_submissions(id) ON DELETE CASCADE,
  voter_id UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT votes_unique_per_submission
    UNIQUE (submission_id, voter_id)
);

ALTER TABLE challenge_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Fans can view votes"
  ON challenge_votes FOR SELECT
  USING (true);

CREATE POLICY "Fans can vote"
  ON challenge_votes FOR INSERT
  WITH CHECK (voter_id = auth.uid());

-- Trigger: increment vote count on submission
CREATE OR REPLACE FUNCTION update_submission_vote_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE challenge_submissions
    SET vote_count = vote_count + 1
    WHERE id = NEW.submission_id;

    UPDATE challenges
    SET total_votes = total_votes + 1,
        updated_at = now()
    WHERE id = (
      SELECT challenge_id FROM challenge_submissions WHERE id = NEW.submission_id
    );
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE challenge_submissions
    SET vote_count = vote_count - 1
    WHERE id = OLD.submission_id;

    UPDATE challenges
    SET total_votes = GREATEST(total_votes - 1, 0),
        updated_at = now()
    WHERE id = (
      SELECT challenge_id FROM challenge_submissions WHERE id = OLD.submission_id
    );
    RETURN OLD;
  END IF;
END;
$$;

CREATE TRIGGER trg_update_vote_count
  AFTER INSERT OR DELETE ON challenge_votes
  FOR EACH ROW EXECUTE FUNCTION update_submission_vote_count();

-- Trigger: increment submission count on challenge
CREATE OR REPLACE FUNCTION update_challenge_submission_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE challenges
    SET total_submissions = total_submissions + 1,
        updated_at = now()
    WHERE id = NEW.challenge_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE challenges
    SET total_submissions = GREATEST(total_submissions - 1, 0),
        updated_at = now()
    WHERE id = OLD.challenge_id;
    RETURN OLD;
  END IF;
END;
$$;

CREATE TRIGGER trg_update_submission_count
  AFTER INSERT OR DELETE ON challenge_submissions
  FOR EACH ROW EXECUTE FUNCTION update_challenge_submission_count();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON dt_auto_charge_config TO authenticated;
GRANT SELECT, INSERT, UPDATE ON challenges TO authenticated;
GRANT SELECT, INSERT ON challenge_submissions TO authenticated;
GRANT UPDATE (status, creator_comment, reviewed_at) ON challenge_submissions TO authenticated;
GRANT SELECT, INSERT, DELETE ON challenge_votes TO authenticated;
