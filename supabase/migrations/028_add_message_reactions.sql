-- 028_add_message_reactions.sql
-- Message Reactions (하트 반응) 테이블

-- 리액션 테이블 생성
CREATE TABLE IF NOT EXISTS message_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  emoji TEXT NOT NULL DEFAULT 'heart',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- 같은 사용자가 같은 메시지에 같은 리액션 중복 방지
  UNIQUE(message_id, user_id, emoji)
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_message_reactions_message_id ON message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_user_id ON message_reactions(user_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_created_at ON message_reactions(created_at DESC);

-- messages 테이블에 reaction_count 컬럼 추가 (캐시용)
ALTER TABLE messages ADD COLUMN IF NOT EXISTS reaction_count INTEGER NOT NULL DEFAULT 0;

-- RLS 활성화
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;

-- RLS 정책: 본인의 리액션만 추가 가능
DROP POLICY IF EXISTS "Users can add their own reactions" ON message_reactions;
CREATE POLICY "Users can add their own reactions"
  ON message_reactions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- RLS 정책: 본인의 리액션만 삭제 가능
DROP POLICY IF EXISTS "Users can delete their own reactions" ON message_reactions;
CREATE POLICY "Users can delete their own reactions"
  ON message_reactions
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- RLS 정책: 같은 채널 구독자만 리액션 조회 가능
DROP POLICY IF EXISTS "Channel subscribers can view reactions" ON message_reactions;
CREATE POLICY "Channel subscribers can view reactions"
  ON message_reactions
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM messages m
      JOIN subscriptions s ON m.channel_id = s.channel_id
      WHERE m.id = message_reactions.message_id
        AND s.user_id = auth.uid()
        AND s.is_active = true
    )
    OR
    -- 또는 채널 소유자 (크리에이터)
    EXISTS (
      SELECT 1 FROM messages m
      JOIN channels c ON m.channel_id = c.id
      WHERE m.id = message_reactions.message_id
        AND c.artist_id = auth.uid()
    )
  );

-- 리액션 추가 시 카운트 증가 트리거
CREATE OR REPLACE FUNCTION update_reaction_count_on_insert()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE messages
  SET reaction_count = reaction_count + 1
  WHERE id = NEW.message_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_reaction_count_insert ON message_reactions;
CREATE TRIGGER trigger_update_reaction_count_insert
  AFTER INSERT ON message_reactions
  FOR EACH ROW
  EXECUTE FUNCTION update_reaction_count_on_insert();

-- 리액션 삭제 시 카운트 감소 트리거
CREATE OR REPLACE FUNCTION update_reaction_count_on_delete()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE messages
  SET reaction_count = GREATEST(0, reaction_count - 1)
  WHERE id = OLD.message_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_reaction_count_delete ON message_reactions;
CREATE TRIGGER trigger_update_reaction_count_delete
  AFTER DELETE ON message_reactions
  FOR EACH ROW
  EXECUTE FUNCTION update_reaction_count_on_delete();

-- 특정 메시지의 리액션 개수와 현재 사용자 리액션 여부를 조회하는 함수
CREATE OR REPLACE FUNCTION get_message_reaction_info(p_message_id UUID)
RETURNS TABLE (
  reaction_count INTEGER,
  has_reacted BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    m.reaction_count,
    EXISTS (
      SELECT 1 FROM message_reactions mr
      WHERE mr.message_id = p_message_id
        AND mr.user_id = auth.uid()
        AND mr.emoji = 'heart'
    ) AS has_reacted
  FROM messages m
  WHERE m.id = p_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 리액션 토글 함수 (추가/삭제)
CREATE OR REPLACE FUNCTION toggle_message_reaction(
  p_message_id UUID,
  p_emoji TEXT DEFAULT 'heart'
)
RETURNS TABLE (
  reaction_count INTEGER,
  has_reacted BOOLEAN
) AS $$
DECLARE
  v_existing_id UUID;
BEGIN
  -- 기존 리액션 확인
  SELECT id INTO v_existing_id
  FROM message_reactions
  WHERE message_id = p_message_id
    AND user_id = auth.uid()
    AND emoji = p_emoji;

  IF v_existing_id IS NOT NULL THEN
    -- 이미 있으면 삭제
    DELETE FROM message_reactions WHERE id = v_existing_id;
  ELSE
    -- 없으면 추가
    INSERT INTO message_reactions (message_id, user_id, emoji)
    VALUES (p_message_id, auth.uid(), p_emoji);
  END IF;

  -- 최신 상태 반환
  RETURN QUERY SELECT * FROM get_message_reaction_info(p_message_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON TABLE message_reactions IS '메시지 리액션 (하트 반응)';
COMMENT ON COLUMN message_reactions.emoji IS '리액션 이모지 (예: heart, ❤️)';
COMMENT ON FUNCTION toggle_message_reaction IS '메시지 리액션 토글 (추가/삭제)';
