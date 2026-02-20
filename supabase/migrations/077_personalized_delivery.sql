-- =============================================
-- 077: Personalized Broadcast Delivery
-- =============================================
-- 브로드캐스트 메시지에 {fanName} 등 개인화 변수 포함 시
-- 각 구독자별 개인화된 콘텐츠를 message_delivery에 저장

-- 1. message_delivery에 개인화 콘텐츠 컬럼 추가
ALTER TABLE message_delivery ADD COLUMN IF NOT EXISTS
  personalized_content TEXT;

-- 2. 개인화 브로드캐스트 처리 함수
-- 메시지의 template_content에 {fanName} 등 변수가 포함된 경우
-- 각 구독자의 message_delivery에 개인화된 content를 저장
CREATE OR REPLACE FUNCTION personalize_broadcast_delivery()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_template TEXT;
  v_record RECORD;
BEGIN
  -- broadcast 메시지만 처리
  IF NEW.delivery_scope != 'broadcast' THEN
    RETURN NEW;
  END IF;

  -- template_content가 있고, 개인화 변수가 포함된 경우만
  v_template := NEW.template_content;
  IF v_template IS NULL OR v_template NOT LIKE '%{%' THEN
    RETURN NEW;
  END IF;

  -- 각 구독자별 개인화 처리
  FOR v_record IN
    SELECT
      md.id AS delivery_id,
      md.user_id,
      COALESCE(up.display_name, '팬') AS fan_name,
      COALESCE(s.tier, 'BASIC') AS tier,
      EXTRACT(DAY FROM now() - s.created_at)::INTEGER AS subscribed_days
    FROM message_delivery md
    JOIN user_profiles up ON up.id = md.user_id
    LEFT JOIN subscriptions s ON s.user_id = md.user_id AND s.channel_id = NEW.channel_id
    WHERE md.message_id = NEW.id
  LOOP
    UPDATE message_delivery
    SET personalized_content = REPLACE(
      REPLACE(
        REPLACE(v_template, '{fanName}', v_record.fan_name),
        '{tier}', v_record.tier
      ),
      '{subscribeDays}', v_record.subscribed_days::TEXT
    )
    WHERE id = v_record.delivery_id;
  END LOOP;

  RETURN NEW;
END;
$$;

-- 3. 트리거: 메시지 INSERT 후 개인화 처리
-- message_delivery가 먼저 생성된 후 동작해야 하므로 AFTER INSERT + deferred 고려
-- 실제로는 Edge Function에서 delivery 생성 후 RPC 호출 방식 권장
-- 여기서는 메시지 내용 업데이트 시에도 처리하도록 UPDATE 트리거 추가
CREATE OR REPLACE FUNCTION trigger_personalize_on_content_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- template_content가 변경된 경우만
  IF OLD.template_content IS DISTINCT FROM NEW.template_content
     AND NEW.template_content IS NOT NULL
     AND NEW.template_content LIKE '%{%' THEN
    PERFORM personalize_broadcast_delivery();
  END IF;
  RETURN NEW;
END;
$$;

-- 4. 인덱스
CREATE INDEX IF NOT EXISTS idx_message_delivery_personalized
  ON message_delivery(message_id) WHERE personalized_content IS NOT NULL;
