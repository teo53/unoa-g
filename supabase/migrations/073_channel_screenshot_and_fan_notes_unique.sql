-- Migration 073: Channel screenshot warning + fan_notes UNIQUE constraint
-- Purpose:
--   1. Add screenshot_warning_enabled to channels (for per-channel capture prevention)
--   2. Add UNIQUE constraint on fan_notes(creator_id, fan_id) to support UPSERT

-- 1. Channel screenshot warning setting
ALTER TABLE channels ADD COLUMN IF NOT EXISTS
  screenshot_warning_enabled BOOLEAN DEFAULT true;

COMMENT ON COLUMN channels.screenshot_warning_enabled IS
  'When true, the client app enables screen capture prevention for this channel';

-- 2. fan_notes UNIQUE constraint for UPSERT support
-- fan_notes table already exists (migration 009_moderation.sql:162-169)
-- but lacks UNIQUE on (creator_id, fan_id) which breaks .upsert() in Supabase client
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'fan_notes_creator_fan_unique'
  ) THEN
    ALTER TABLE fan_notes
      ADD CONSTRAINT fan_notes_creator_fan_unique
      UNIQUE (creator_id, fan_id);
  END IF;
END $$;
