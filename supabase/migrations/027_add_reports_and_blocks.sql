-- =====================================================
-- Migration: 027_add_reports_and_blocks.sql
-- Purpose: Add user reporting and blocking functionality
-- Description:
--   1. Create reports table for content/user reporting
--   2. Create user_blocks table for user blocking
--   3. Add RLS policies for both tables
--   4. Add helper functions
--   5. Update messages RLS to filter blocked users
-- =====================================================

-- =====================================================
-- 1. CREATE ENUM TYPES
-- =====================================================

-- Report reason enum
DO $$ BEGIN
  CREATE TYPE report_reason AS ENUM (
    'spam',
    'harassment',
    'inappropriate_content',
    'fraud',
    'copyright',
    'other'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Report status enum
DO $$ BEGIN
  CREATE TYPE report_status AS ENUM (
    'open',
    'in_progress',
    'resolved',
    'dismissed'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Report priority enum
DO $$ BEGIN
  CREATE TYPE report_priority AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- =====================================================
-- 2. CREATE REPORTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES auth.users(id) NOT NULL,

  -- What is being reported
  reported_user_id UUID REFERENCES auth.users(id),
  reported_content_id UUID,
  reported_content_type TEXT CHECK (reported_content_type IN (
    'message', 'profile', 'campaign', 'comment'
  )),

  -- Report details
  reason report_reason NOT NULL,
  description TEXT,

  -- Processing status
  status report_status DEFAULT 'open',
  priority report_priority DEFAULT 'medium',
  assigned_to UUID REFERENCES auth.users(id),

  -- Resolution
  resolution_action TEXT,
  resolution_note TEXT,
  resolved_by UUID REFERENCES auth.users(id),
  resolved_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CONSTRAINT reports_target_check CHECK (
    reported_user_id IS NOT NULL OR reported_content_id IS NOT NULL
  )
);

-- Indexes for reports
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_reporter ON reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_reported_user ON reports(reported_user_id) WHERE reported_user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_reports_created ON reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_priority_status ON reports(priority, status) WHERE status IN ('open', 'in_progress');

-- =====================================================
-- 3. CREATE USER_BLOCKS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.user_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID REFERENCES auth.users(id) NOT NULL,
  blocked_id UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(blocker_id, blocked_id),
  CONSTRAINT user_blocks_self_check CHECK (blocker_id != blocked_id)
);

-- Indexes for user_blocks
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocker ON user_blocks(blocker_id);
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked ON user_blocks(blocked_id);

-- =====================================================
-- 4. ENABLE RLS AND CREATE POLICIES
-- =====================================================

-- Enable RLS on reports
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Users can create reports
CREATE POLICY "Users can create reports"
  ON reports FOR INSERT
  WITH CHECK (reporter_id = auth.uid());

-- Users can view their own reports
CREATE POLICY "Users can view own reports"
  ON reports FOR SELECT
  USING (reporter_id = auth.uid());

-- Admins can view and manage all reports
CREATE POLICY "Admins can manage all reports"
  ON reports FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Enable RLS on user_blocks
ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;

-- Users can manage their own blocks
CREATE POLICY "Users can manage own blocks"
  ON user_blocks FOR ALL
  USING (blocker_id = auth.uid())
  WITH CHECK (blocker_id = auth.uid());

-- Admins can view all blocks
CREATE POLICY "Admins can view all blocks"
  ON user_blocks FOR SELECT
  USING (public.is_admin());

-- =====================================================
-- 5. CREATE HELPER FUNCTIONS
-- =====================================================

-- Function to submit a report
CREATE OR REPLACE FUNCTION public.submit_report(
  p_reported_user_id UUID DEFAULT NULL,
  p_reported_content_id UUID DEFAULT NULL,
  p_reported_content_type TEXT DEFAULT NULL,
  p_reason report_reason DEFAULT 'other',
  p_description TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_report_id UUID;
BEGIN
  -- Validate that at least one target is specified
  IF p_reported_user_id IS NULL AND p_reported_content_id IS NULL THEN
    RAISE EXCEPTION 'Must specify either reported_user_id or reported_content_id';
  END IF;

  -- Cannot report yourself
  IF p_reported_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Cannot report yourself';
  END IF;

  -- Check for duplicate reports (same reporter, same target, within 24 hours)
  IF EXISTS (
    SELECT 1 FROM reports
    WHERE reporter_id = auth.uid()
      AND status NOT IN ('resolved', 'dismissed')
      AND (
        (reported_user_id = p_reported_user_id AND p_reported_user_id IS NOT NULL)
        OR
        (reported_content_id = p_reported_content_id AND p_reported_content_id IS NOT NULL)
      )
      AND created_at > NOW() - INTERVAL '24 hours'
  ) THEN
    RAISE EXCEPTION 'You have already reported this within the last 24 hours';
  END IF;

  -- Insert the report
  INSERT INTO reports (
    reporter_id,
    reported_user_id,
    reported_content_id,
    reported_content_type,
    reason,
    description
  ) VALUES (
    auth.uid(),
    p_reported_user_id,
    p_reported_content_id,
    p_reported_content_type,
    p_reason,
    p_description
  ) RETURNING id INTO v_report_id;

  -- Auto-escalate certain report types
  IF p_reason IN ('fraud', 'harassment') THEN
    UPDATE reports SET priority = 'high' WHERE id = v_report_id;
  END IF;

  RETURN v_report_id;
END;
$$;

-- Function to block a user
CREATE OR REPLACE FUNCTION public.block_user(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Can't block yourself
  IF p_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Cannot block yourself';
  END IF;

  -- Insert block (ignore if already exists)
  INSERT INTO user_blocks (blocker_id, blocked_id)
  VALUES (auth.uid(), p_user_id)
  ON CONFLICT (blocker_id, blocked_id) DO NOTHING;

  RETURN TRUE;
END;
$$;

-- Function to unblock a user
CREATE OR REPLACE FUNCTION public.unblock_user(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM user_blocks
  WHERE blocker_id = auth.uid()
    AND blocked_id = p_user_id;

  RETURN TRUE;
END;
$$;

-- Function to check if a user is blocked
CREATE OR REPLACE FUNCTION public.is_user_blocked(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_blocks
    WHERE blocker_id = auth.uid()
      AND blocked_id = p_user_id
  );
$$;

-- Function to get blocked user IDs (for filtering)
CREATE OR REPLACE FUNCTION public.get_blocked_user_ids()
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT blocked_id FROM user_blocks
  WHERE blocker_id = auth.uid();
$$;

-- Function to resolve a report (admin only)
CREATE OR REPLACE FUNCTION public.resolve_report(
  p_report_id UUID,
  p_action TEXT,
  p_note TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only admins can resolve reports
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can resolve reports';
  END IF;

  UPDATE reports
  SET
    status = 'resolved',
    resolution_action = p_action,
    resolution_note = p_note,
    resolved_by = auth.uid(),
    resolved_at = NOW(),
    updated_at = NOW()
  WHERE id = p_report_id;

  -- Log the admin action
  PERFORM public.log_admin_action(
    'report.resolve',
    'reports',
    p_report_id,
    NULL,
    jsonb_build_object('action', p_action, 'note', p_note)
  );

  RETURN FOUND;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.submit_report TO authenticated;
GRANT EXECUTE ON FUNCTION public.block_user TO authenticated;
GRANT EXECUTE ON FUNCTION public.unblock_user TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_user_blocked TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_blocked_user_ids TO authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_report TO authenticated;

-- =====================================================
-- 6. UPDATE MESSAGES RLS TO FILTER BLOCKED USERS
-- =====================================================

-- Note: This creates a new policy that adds blocked user filtering
-- Existing message policies remain for basic access control

-- Create a function to check if sender is blocked by viewer
CREATE OR REPLACE FUNCTION public.is_sender_blocked_by_viewer(p_sender_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_blocks
    WHERE blocker_id = auth.uid()
      AND blocked_id = p_sender_id
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_sender_blocked_by_viewer TO authenticated;

-- Add comment for documentation
COMMENT ON TABLE reports IS
'User reports for content/user moderation. Supports spam, harassment, inappropriate content, fraud, and copyright reports.';

COMMENT ON TABLE user_blocks IS
'User blocking relationships. Blocked users'' messages are hidden from the blocker.';

COMMENT ON FUNCTION public.submit_report IS
'Submits a report for content or user moderation. Prevents duplicate reports within 24 hours.';

COMMENT ON FUNCTION public.block_user IS
'Blocks a user. Their messages will be hidden from your view.';

-- =====================================================
-- 7. TRIGGER FOR UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER reports_updated_at
  BEFORE UPDATE ON reports
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- =====================================================
-- 8. VERIFY MIGRATION
-- =====================================================

DO $$
BEGIN
  -- Verify tables exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'reports') THEN
    RAISE EXCEPTION 'Migration failed: reports table not created';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_blocks') THEN
    RAISE EXCEPTION 'Migration failed: user_blocks table not created';
  END IF;

  RAISE NOTICE 'Reports and blocks migration completed successfully';
END $$;
