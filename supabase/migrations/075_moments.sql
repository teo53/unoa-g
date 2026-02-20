-- =============================================
-- 075: Fan Moments System
-- =============================================
-- 팬이 수집한 특별 순간들 (프라이빗 카드, 하이라이트 메시지, 미디어 등)
-- 자동 수집 트리거 + 수동 추가 지원

-- 1. fan_moments 테이블
CREATE TABLE IF NOT EXISTS fan_moments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fan_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  channel_id UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  source_type TEXT NOT NULL CHECK (source_type IN (
    'private_card',    -- 프라이빗 카드 수신
    'highlight',       -- 아티스트가 하이라이트한 내 메시지
    'media_message',   -- 미디어 포함 메시지 (이미지/영상)
    'donation_reply',  -- 후원 답장 (1:1)
    'welcome',         -- 웰컴 메시지
    'manual'           -- 팬이 직접 저장
  )),
  source_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  source_card_id UUID,  -- private_cards 테이블 참조 (존재 시)
  title TEXT,
  content TEXT,
  media_url TEXT,
  media_type TEXT CHECK (media_type IN ('image', 'video', 'voice', NULL)),
  thumbnail_url TEXT,
  artist_name TEXT,
  artist_avatar_url TEXT,
  is_favorite BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  collected_at TIMESTAMPTZ DEFAULT now() NOT NULL  -- 모먼트가 수집된 시점
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_fan_moments_fan_id ON fan_moments(fan_id);
CREATE INDEX IF NOT EXISTS idx_fan_moments_channel_id ON fan_moments(channel_id);
CREATE INDEX IF NOT EXISTS idx_fan_moments_source_type ON fan_moments(source_type);
CREATE INDEX IF NOT EXISTS idx_fan_moments_fan_channel ON fan_moments(fan_id, channel_id);
CREATE INDEX IF NOT EXISTS idx_fan_moments_collected_at ON fan_moments(collected_at DESC);
CREATE INDEX IF NOT EXISTS idx_fan_moments_favorite ON fan_moments(fan_id, is_favorite) WHERE is_favorite = true;

-- 2. RLS 정책
ALTER TABLE fan_moments ENABLE ROW LEVEL SECURITY;

-- 팬은 자신의 모먼트만 조회/수정/삭제 가능
CREATE POLICY fan_moments_select ON fan_moments
  FOR SELECT USING (fan_id = auth.uid());

CREATE POLICY fan_moments_insert ON fan_moments
  FOR INSERT WITH CHECK (fan_id = auth.uid());

CREATE POLICY fan_moments_update ON fan_moments
  FOR UPDATE USING (fan_id = auth.uid());

CREATE POLICY fan_moments_delete ON fan_moments
  FOR DELETE USING (fan_id = auth.uid());

-- 3. 자동 모먼트 생성 트리거: 프라이빗 카드 수신 시
CREATE OR REPLACE FUNCTION create_moment_on_private_card()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_artist_name TEXT;
  v_artist_avatar TEXT;
BEGIN
  -- delivery_scope가 'private_card'인 메시지만 처리
  IF NEW.delivery_scope != 'private_card' THEN
    RETURN NEW;
  END IF;

  -- target_user_id가 있어야 모먼트 생성
  IF NEW.target_user_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- 아티스트 정보 조회
  SELECT display_name, avatar_url
  INTO v_artist_name, v_artist_avatar
  FROM user_profiles
  WHERE id = NEW.sender_id;

  -- 모먼트 자동 생성
  INSERT INTO fan_moments (
    fan_id, channel_id, source_type, source_message_id,
    title, content, media_url, media_type, thumbnail_url,
    artist_name, artist_avatar_url, collected_at
  ) VALUES (
    NEW.target_user_id,
    NEW.channel_id,
    'private_card',
    NEW.id,
    '프라이빗 카드',
    NEW.content,
    NEW.media_url,
    CASE
      WHEN NEW.message_type = 'image' THEN 'image'
      WHEN NEW.message_type = 'video' THEN 'video'
      WHEN NEW.message_type = 'voice' THEN 'voice'
      ELSE NULL
    END,
    NEW.media_url,  -- 썸네일은 원본과 동일 (추후 리사이즈)
    v_artist_name,
    v_artist_avatar,
    NEW.created_at
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_moment_on_private_card
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION create_moment_on_private_card();

-- 4. 자동 모먼트 생성 트리거: 메시지 하이라이트 시
CREATE OR REPLACE FUNCTION create_moment_on_highlight()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_artist_name TEXT;
  v_artist_avatar TEXT;
  v_channel_creator_id UUID;
BEGIN
  -- is_highlighted가 false → true로 변경된 경우만
  IF NOT (OLD.is_highlighted = false AND NEW.is_highlighted = true) THEN
    RETURN NEW;
  END IF;

  -- 팬 메시지만 모먼트 생성 (아티스트 메시지는 제외)
  IF NEW.sender_type != 'fan' THEN
    RETURN NEW;
  END IF;

  -- 채널 크리에이터 정보 조회
  SELECT c.creator_id INTO v_channel_creator_id
  FROM channels c WHERE c.id = NEW.channel_id;

  SELECT display_name, avatar_url
  INTO v_artist_name, v_artist_avatar
  FROM user_profiles
  WHERE id = v_channel_creator_id;

  -- 중복 방지
  IF EXISTS (
    SELECT 1 FROM fan_moments
    WHERE fan_id = NEW.sender_id
      AND source_message_id = NEW.id
      AND source_type = 'highlight'
  ) THEN
    RETURN NEW;
  END IF;

  INSERT INTO fan_moments (
    fan_id, channel_id, source_type, source_message_id,
    title, content, media_url, media_type,
    artist_name, artist_avatar_url, collected_at
  ) VALUES (
    NEW.sender_id,
    NEW.channel_id,
    'highlight',
    NEW.id,
    '하이라이트된 메시지',
    NEW.content,
    NEW.media_url,
    CASE
      WHEN NEW.message_type = 'image' THEN 'image'
      WHEN NEW.message_type = 'video' THEN 'video'
      WHEN NEW.message_type = 'voice' THEN 'voice'
      ELSE NULL
    END,
    v_artist_name,
    v_artist_avatar,
    now()
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_moment_on_highlight
  AFTER UPDATE ON messages
  FOR EACH ROW
  EXECUTE FUNCTION create_moment_on_highlight();
