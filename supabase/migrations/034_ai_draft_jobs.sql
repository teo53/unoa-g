-- ============================================
-- UNO A - AI Draft Jobs (Observability & Caching)
-- Version: 1.0.0
-- ============================================

-- Tracks AI draft generation requests for observability,
-- caching (idempotency), and debugging.

CREATE TABLE IF NOT EXISTS public.ai_draft_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  correlation_id TEXT UNIQUE NOT NULL,

  -- Context
  channel_id UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Idempotency
  idempotency_key TEXT UNIQUE NOT NULL,

  -- Status tracking
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'generating', 'success', 'soft_fail', 'hard_fail')),
  error_code TEXT,
  error_message TEXT,

  -- Cached result
  cached_suggestions JSONB,  -- [{id, label, text}]
  provider TEXT,              -- 'anthropic', 'fallback_template'
  model TEXT,

  -- Metrics
  prompt_tokens INT,
  completion_tokens INT,
  latency_ms INT,
  retry_count INT DEFAULT 0,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ DEFAULT now() + INTERVAL '1 hour'
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_ai_draft_jobs_idempotency
  ON ai_draft_jobs(idempotency_key);
CREATE INDEX IF NOT EXISTS idx_ai_draft_jobs_creator
  ON ai_draft_jobs(creator_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_draft_jobs_status
  ON ai_draft_jobs(status)
  WHERE status IN ('pending', 'generating');
CREATE INDEX IF NOT EXISTS idx_ai_draft_jobs_expires
  ON ai_draft_jobs(expires_at)
  WHERE expires_at IS NOT NULL;

-- RLS
ALTER TABLE ai_draft_jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creator can view own draft jobs"
  ON ai_draft_jobs FOR SELECT
  USING (creator_id = auth.uid());

CREATE POLICY "Creator can insert own draft jobs"
  ON ai_draft_jobs FOR INSERT
  WITH CHECK (creator_id = auth.uid());

CREATE POLICY "Creator can update own draft jobs"
  ON ai_draft_jobs FOR UPDATE
  USING (creator_id = auth.uid());

-- Cleanup function for expired jobs (called by cron)
CREATE OR REPLACE FUNCTION cleanup_expired_draft_jobs()
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
  deleted_count INT;
BEGIN
  DELETE FROM ai_draft_jobs
  WHERE expires_at < now() - INTERVAL '24 hours';
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;
