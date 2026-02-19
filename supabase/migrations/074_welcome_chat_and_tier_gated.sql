-- ============================================================
-- Migration 074: Welcome Chat Trigger + Tier-Gated Content
-- ============================================================
-- Sprint 2: B-4 웰컴 채팅 + B-5 티어별 콘텐츠 접근제어
-- ============================================================

-- 1. 메시지 테이블에 최소 티어 필드 추가 (티어별 콘텐츠 접근제어)
ALTER TABLE messages ADD COLUMN IF NOT EXISTS
  min_tier_required TEXT DEFAULT NULL
  CHECK (min_tier_required IN ('BASIC', 'STANDARD', 'VIP', NULL));

COMMENT ON COLUMN messages.min_tier_required IS
  'Minimum subscription tier required to view this message. NULL = visible to all tiers.';

-- 2. delivery_scope에 welcome 추가 (기존 CHECK 제약 교체)
-- 기존 제약 삭제 후 새로운 제약 추가
DO $
BEGIN
  -- Drop existing constraint if it exists
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'messages_delivery_scope_check'
  ) THEN
    ALTER TABLE messages DROP CONSTRAINT messages_delivery_scope_check;
  END IF;
END $;

ALTER TABLE messages ADD CONSTRAINT messages_delivery_scope_check
  CHECK (delivery_scope IN (
    'broadcast', 'direct_reply', 'donation_message', 'donation_reply',
    'public_share', 'private_card', 'welcome'
  ));

-- 3. 웰컴 메시지 자동 전송 함수
CREATE OR REPLACE FUNCTION send_welcome_message()
RETURNS TRIGGER AS $
DECLARE
  v_settings RECORD;
  v_channel_id UUID;
  v_fan_name TEXT;
  v_rendered_message TEXT;
BEGIN
  -- 신규 구독이 아니면 무시
  IF NEW.is_active IS NOT TRUE THEN
    RETURN NEW;
  END IF;

  -- 크리에이터 설정 조회
  SELECT cs.auto_welcome_enabled, cs.welcome_message, cs.welcome_media_url, cs.welcome_media_type
  INTO v_settings
  FROM creator_settings cs
  JOIN channels ch ON ch.artist_id = cs.creator_id
  WHERE ch.id = NEW.channel_id;

  -- 자동 웰컴이 비활성화면 무시
  IF v_settings IS NULL OR v_settings.auto_welcome_enabled IS NOT TRUE THEN
    RETURN NEW;
  END IF;

  -- 팬 이름 조회
  SELECT display_name INTO v_fan_name
  FROM user_profiles
  WHERE user_id = NEW.user_id;

  -- 메시지 템플릿 렌더링 (서버사이드 {nickname} 치환)
  v_rendered_message := REPLACE(
    COALESCE(v_settings.welcome_message, '안녕하세요! 제 채널에 와주셔서 감사합니다.'),
    '{nickname}',
    COALESCE(v_fan_name, '팬')
  );

  -- 채널의 아티스트 ID 조회
  SELECT artist_id INTO v_channel_id
  FROM channels
  WHERE id = NEW.channel_id;

  -- 웰컴 메시지 삽입 (delivery_scope = 'welcome', target_user_id = 팬)
  INSERT INTO messages (
    channel_id,
    sender_id,
    sender_type,
    delivery_scope,
    target_user_id,
    content,
    template_content,
    message_type,
    media_url
  ) VALUES (
    NEW.channel_id,
    v_channel_id,  -- 아티스트 ID
    'artist',
    'welcome',
    NEW.user_id,   -- 팬에게만 표시
    v_rendered_message,
    v_settings.welcome_message,  -- 원본 템플릿 보존
    CASE WHEN v_settings.welcome_media_url IS NOT NULL
      THEN COALESCE(v_settings.welcome_media_type, 'text')
      ELSE 'text'
    END,
    v_settings.welcome_media_url
  );

  RETURN NEW;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. 구독 생성 시 웰컴 메시지 트리거
DROP TRIGGER IF EXISTS trigger_send_welcome_message ON subscriptions;
CREATE TRIGGER trigger_send_welcome_message
  AFTER INSERT ON subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION send_welcome_message();

-- 5. 인덱스: 티어 기반 메시지 필터링
CREATE INDEX IF NOT EXISTS idx_messages_min_tier
  ON messages (channel_id, min_tier_required)
  WHERE min_tier_required IS NOT NULL;

-- 6. 웰컴 메시지 RLS (팬은 자신의 웰컴 메시지만 볼 수 있음)
-- 기존 messages RLS에 welcome scope 포함되므로 추가 정책 불필요
-- target_user_id 기반 필터링은 기존 chat_repository에서 처리
