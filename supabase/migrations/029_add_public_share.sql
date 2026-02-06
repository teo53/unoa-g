-- 029_add_public_share.sql
-- 전체공개 (Public Share) 기능 - 팬 메시지를 모든 구독자에게 공개

-- messages 테이블에 전체공개 관련 컬럼 추가
ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_public_shared BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS shared_by_artist_id UUID REFERENCES auth.users(id);
ALTER TABLE messages ADD COLUMN IF NOT EXISTS shared_at TIMESTAMPTZ;

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_messages_is_public_shared ON messages(is_public_shared) WHERE is_public_shared = TRUE;
CREATE INDEX IF NOT EXISTS idx_messages_shared_by_artist_id ON messages(shared_by_artist_id) WHERE shared_by_artist_id IS NOT NULL;

-- 전체공개 메시지 조회를 위한 RLS 정책 업데이트
-- 기존 정책에 전체공개 메시지 조회 권한 추가

-- 구독자가 전체공개된 팬 메시지를 볼 수 있도록 정책 추가
CREATE POLICY "Subscribers can view public shared messages"
  ON messages
  FOR SELECT
  TO authenticated
  USING (
    -- 전체공개된 메시지이고
    is_public_shared = TRUE
    AND
    -- 같은 채널의 구독자인 경우
    EXISTS (
      SELECT 1 FROM subscriptions s
      WHERE s.channel_id = messages.channel_id
        AND s.user_id = auth.uid()
        AND s.status = 'active'
    )
  );

-- 크리에이터가 팬 메시지를 전체공개할 수 있도록 업데이트 정책
CREATE POLICY "Artists can public share fan messages"
  ON messages
  FOR UPDATE
  TO authenticated
  USING (
    -- 본인 채널의 메시지인 경우
    EXISTS (
      SELECT 1 FROM channels c
      WHERE c.id = messages.channel_id
        AND c.artist_id = auth.uid()
    )
  )
  WITH CHECK (
    -- 본인 채널의 메시지인 경우
    EXISTS (
      SELECT 1 FROM channels c
      WHERE c.id = messages.channel_id
        AND c.artist_id = auth.uid()
    )
  );

-- 메시지 전체공개 함수
CREATE OR REPLACE FUNCTION public_share_message(
  p_message_id UUID
)
RETURNS TABLE (
  success BOOLEAN,
  message_id UUID,
  shared_at TIMESTAMPTZ
) AS $$
DECLARE
  v_channel_id UUID;
  v_artist_id UUID;
  v_sender_type TEXT;
BEGIN
  -- 메시지 정보 조회
  SELECT m.channel_id, m.sender_type, c.artist_id
  INTO v_channel_id, v_sender_type, v_artist_id
  FROM messages m
  JOIN channels c ON m.channel_id = c.id
  WHERE m.id = p_message_id;

  -- 메시지가 존재하지 않음
  IF v_channel_id IS NULL THEN
    RETURN QUERY SELECT FALSE, p_message_id, NULL::TIMESTAMPTZ;
    RETURN;
  END IF;

  -- 크리에이터만 전체공개 가능
  IF v_artist_id != auth.uid() THEN
    RAISE EXCEPTION 'Only channel owner can public share messages';
  END IF;

  -- 팬 메시지만 전체공개 가능 (아티스트 메시지는 이미 브로드캐스트)
  IF v_sender_type != 'fan' THEN
    RAISE EXCEPTION 'Only fan messages can be public shared';
  END IF;

  -- 전체공개 처리
  UPDATE messages
  SET
    is_public_shared = TRUE,
    shared_by_artist_id = auth.uid(),
    shared_at = now()
  WHERE id = p_message_id
    AND is_public_shared = FALSE; -- 이미 공개된 메시지는 무시

  RETURN QUERY SELECT TRUE, p_message_id, now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 전체공개 취소 함수
CREATE OR REPLACE FUNCTION unshare_public_message(
  p_message_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_channel_id UUID;
  v_artist_id UUID;
BEGIN
  -- 메시지 정보 조회
  SELECT m.channel_id, c.artist_id
  INTO v_channel_id, v_artist_id
  FROM messages m
  JOIN channels c ON m.channel_id = c.id
  WHERE m.id = p_message_id;

  -- 크리에이터만 전체공개 취소 가능
  IF v_artist_id != auth.uid() THEN
    RETURN FALSE;
  END IF;

  -- 전체공개 취소
  UPDATE messages
  SET
    is_public_shared = FALSE,
    shared_by_artist_id = NULL,
    shared_at = NULL
  WHERE id = p_message_id
    AND is_public_shared = TRUE;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON COLUMN messages.is_public_shared IS '팬 메시지가 전체공개되었는지 여부';
COMMENT ON COLUMN messages.shared_by_artist_id IS '메시지를 전체공개한 아티스트 ID';
COMMENT ON COLUMN messages.shared_at IS '전체공개 시각';
COMMENT ON FUNCTION public_share_message IS '팬 메시지를 전체공개 (아티스트만 가능)';
COMMENT ON FUNCTION unshare_public_message IS '전체공개된 메시지 공개 취소';
