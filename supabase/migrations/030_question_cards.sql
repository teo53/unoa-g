-- 030_question_cards.sql
-- Question Card System - 사전 생성된 질문 덱에서 팬이 매일 3개 중 1개 선택

-- ============================================
-- 1. 덱 정의 테이블
-- ============================================
CREATE TABLE IF NOT EXISTS question_decks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,            -- 'maid', 'ex_idol', 'vtuber' 등
  title TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE question_decks IS '질문 카드 덱 정의 (카테고리별)';
COMMENT ON COLUMN question_decks.code IS '덱 고유 코드 (maid, ex_idol 등)';

-- ============================================
-- 2. 질문 카드 뱅크
-- ============================================
CREATE TABLE IF NOT EXISTS question_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deck_id UUID NOT NULL REFERENCES question_decks(id) ON DELETE CASCADE,
  subdeck TEXT NOT NULL,                -- 'icebreaker', 'daily_scene', 'behind_story', 'roleplay_flavor', 'deep_but_safe'
  level INT NOT NULL CHECK (level BETWEEN 1 AND 3),
  language TEXT NOT NULL DEFAULT 'ko',
  card_text TEXT NOT NULL,
  tags TEXT[] NOT NULL DEFAULT '{}'::text[],
  is_active BOOLEAN NOT NULL DEFAULT true,
  fingerprint TEXT UNIQUE NOT NULL,     -- sha256(normalized_text + deck + subdeck + level) 중복 방지
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE question_cards IS '질문 카드 뱅크 (사전 생성, 실시간 생성 금지)';
COMMENT ON COLUMN question_cards.subdeck IS '서브덱 분류 (icebreaker, daily_scene 등)';
COMMENT ON COLUMN question_cards.level IS '친밀도 레벨 (1: 가벼움, 2: 보통, 3: 깊음)';
COMMENT ON COLUMN question_cards.fingerprint IS '중복 방지용 해시';

-- ============================================
-- 3. 크리에이터 질문 설정
-- ============================================
CREATE TABLE IF NOT EXISTS creator_question_prefs (
  creator_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  deck_codes TEXT[] NOT NULL DEFAULT ARRAY['maid','ex_idol']::text[],
  levels_enabled INT[] NOT NULL DEFAULT ARRAY[1,2,3]::int[],
  enabled BOOLEAN NOT NULL DEFAULT true,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE creator_question_prefs IS '크리에이터별 질문 카드 설정';
COMMENT ON COLUMN creator_question_prefs.deck_codes IS '사용할 덱 코드 목록';
COMMENT ON COLUMN creator_question_prefs.levels_enabled IS '활성화할 레벨 목록';

-- ============================================
-- 4. 일일 3-카드 세트 (채널별, KST 날짜별)
-- ============================================
CREATE TABLE IF NOT EXISTS daily_question_sets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  kst_date DATE NOT NULL,
  deck_code TEXT NOT NULL,
  card_ids UUID[] NOT NULL,             -- 정확히 3개
  algorithm_version TEXT NOT NULL DEFAULT 'v1',
  seed TEXT NOT NULL,                   -- 재현 가능한 랜덤 시드
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (channel_id, kst_date)
);

COMMENT ON TABLE daily_question_sets IS '일일 질문 카드 세트 (채널당 하루 1개)';
COMMENT ON COLUMN daily_question_sets.kst_date IS 'KST 기준 날짜';
COMMENT ON COLUMN daily_question_sets.card_ids IS '3개 카드 ID 배열';

-- ============================================
-- 5. 투표 (1인 1일 1채널 1표)
-- ============================================
CREATE TABLE IF NOT EXISTS daily_question_votes (
  set_id UUID NOT NULL REFERENCES daily_question_sets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  card_id UUID NOT NULL REFERENCES question_cards(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (set_id, user_id)
);

COMMENT ON TABLE daily_question_votes IS '질문 카드 투표 (세트당 유저 1표)';

-- ============================================
-- 6. 쿨다운 추적
-- ============================================
CREATE TABLE IF NOT EXISTS question_card_cooldowns (
  channel_id UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  card_id UUID NOT NULL REFERENCES question_cards(id) ON DELETE CASCADE,
  last_shown_kst_date DATE,
  last_answered_kst_date DATE,
  shown_count INT NOT NULL DEFAULT 0,
  answered_count INT NOT NULL DEFAULT 0,
  PRIMARY KEY (channel_id, card_id)
);

COMMENT ON TABLE question_card_cooldowns IS '카드 쿨다운 추적 (채널별)';
COMMENT ON COLUMN question_card_cooldowns.last_shown_kst_date IS '마지막 노출 날짜';
COMMENT ON COLUMN question_card_cooldowns.last_answered_kst_date IS '마지막 답변 날짜';

-- ============================================
-- 7. 답변 연결
-- ============================================
CREATE TABLE IF NOT EXISTS question_card_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  card_id UUID NOT NULL REFERENCES question_cards(id) ON DELETE CASCADE,
  set_id UUID REFERENCES daily_question_sets(id) ON DELETE SET NULL,
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  answered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (channel_id, card_id, message_id)
);

COMMENT ON TABLE question_card_answers IS '질문 카드에 대한 아티스트 답변 연결';

-- ============================================
-- 8. messages 테이블 확장 (nullable FK)
-- ============================================
ALTER TABLE messages ADD COLUMN IF NOT EXISTS question_card_id UUID REFERENCES question_cards(id);
ALTER TABLE messages ADD COLUMN IF NOT EXISTS question_set_id UUID REFERENCES daily_question_sets(id);

COMMENT ON COLUMN messages.question_card_id IS '답변 대상 질문 카드 ID';
COMMENT ON COLUMN messages.question_set_id IS '관련 일일 세트 ID';

-- ============================================
-- 인덱스 생성
-- ============================================
CREATE INDEX IF NOT EXISTS idx_question_cards_deck_active ON question_cards(deck_id, is_active, level);
CREATE INDEX IF NOT EXISTS idx_question_cards_fingerprint ON question_cards(fingerprint);
CREATE INDEX IF NOT EXISTS idx_daily_sets_channel_date ON daily_question_sets(channel_id, kst_date);
CREATE INDEX IF NOT EXISTS idx_daily_votes_set_card ON daily_question_votes(set_id, card_id);
CREATE INDEX IF NOT EXISTS idx_cooldowns_channel_dates ON question_card_cooldowns(channel_id, last_shown_kst_date, last_answered_kst_date);
CREATE INDEX IF NOT EXISTS idx_answers_channel_card ON question_card_answers(channel_id, card_id);
CREATE INDEX IF NOT EXISTS idx_messages_question_card ON messages(question_card_id) WHERE question_card_id IS NOT NULL;

-- ============================================
-- RLS 정책
-- ============================================

-- question_decks: 인증된 사용자 읽기만 허용
ALTER TABLE question_decks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read active decks"
  ON question_decks
  FOR SELECT
  TO authenticated
  USING (is_active = true);

-- question_cards: 인증된 사용자 읽기만 허용 (활성 카드만)
ALTER TABLE question_cards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read active cards"
  ON question_cards
  FOR SELECT
  TO authenticated
  USING (is_active = true);

-- creator_question_prefs: 본인만 조회/수정
ALTER TABLE creator_question_prefs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can manage own prefs"
  ON creator_question_prefs
  FOR ALL
  TO authenticated
  USING (creator_id = auth.uid())
  WITH CHECK (creator_id = auth.uid());

-- daily_question_sets: 채널 구독자 또는 소유자만 조회
ALTER TABLE daily_question_sets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Channel members can view daily sets"
  ON daily_question_sets
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM subscriptions
      WHERE channel_id = daily_question_sets.channel_id
        AND user_id = auth.uid()
        AND is_active = true
    )
    OR EXISTS (
      SELECT 1 FROM channels
      WHERE id = daily_question_sets.channel_id
        AND artist_id = auth.uid()
    )
  );

-- daily_question_votes: 본인 투표만 삽입, 채널 멤버 조회
ALTER TABLE daily_question_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own vote"
  ON daily_question_votes
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own votes"
  ON daily_question_votes
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Channel owners can view all votes"
  ON daily_question_votes
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM daily_question_sets dqs
      JOIN channels c ON c.id = dqs.channel_id
      WHERE dqs.id = daily_question_votes.set_id
        AND c.artist_id = auth.uid()
    )
  );

-- question_card_cooldowns: 채널 소유자만 조회/수정
ALTER TABLE question_card_cooldowns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Channel owners can manage cooldowns"
  ON question_card_cooldowns
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM channels
      WHERE id = question_card_cooldowns.channel_id
        AND artist_id = auth.uid()
    )
  );

-- question_card_answers: 채널 멤버 조회, 소유자 삽입
ALTER TABLE question_card_answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Channel members can view answers"
  ON question_card_answers
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM subscriptions
      WHERE channel_id = question_card_answers.channel_id
        AND user_id = auth.uid()
        AND is_active = true
    )
    OR EXISTS (
      SELECT 1 FROM channels
      WHERE id = question_card_answers.channel_id
        AND artist_id = auth.uid()
    )
  );

CREATE POLICY "Channel owners can insert answers"
  ON question_card_answers
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM channels
      WHERE id = question_card_answers.channel_id
        AND artist_id = auth.uid()
    )
  );

-- ============================================
-- RPC 함수
-- ============================================

-- A) KST 날짜 헬퍼
CREATE OR REPLACE FUNCTION get_kst_date()
RETURNS DATE
LANGUAGE plpgsql STABLE
AS $$
BEGIN
  RETURN (now() AT TIME ZONE 'Asia/Seoul')::date;
END;
$$;

COMMENT ON FUNCTION get_kst_date IS 'KST 기준 현재 날짜 반환';

-- B) 일일 질문 세트 조회/생성
CREATE OR REPLACE FUNCTION get_or_create_daily_question_set(p_channel_id UUID)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_kst_date DATE;
  v_deck_code TEXT;
  v_set_id UUID;
  v_card_ids UUID[];
  v_existing_set RECORD;
  v_result JSONB;
  v_artist_id UUID;
BEGIN
  v_kst_date := get_kst_date();

  -- 채널 아티스트 ID 조회
  SELECT artist_id INTO v_artist_id FROM channels WHERE id = p_channel_id;

  IF v_artist_id IS NULL THEN
    RAISE EXCEPTION 'Channel not found';
  END IF;

  -- 채널 접근 검증 (구독자 또는 소유자)
  IF NOT EXISTS (
    SELECT 1 FROM subscriptions
    WHERE channel_id = p_channel_id
      AND user_id = auth.uid()
      AND is_active = true
  ) AND v_artist_id != auth.uid() THEN
    RAISE EXCEPTION 'Access denied to channel';
  END IF;

  -- 기존 세트 확인
  SELECT * INTO v_existing_set FROM daily_question_sets
  WHERE channel_id = p_channel_id AND kst_date = v_kst_date;

  IF v_existing_set.id IS NOT NULL THEN
    -- 기존 세트 반환 (카드 + 투표수 + 유저 투표)
    SELECT jsonb_build_object(
      'set_id', v_existing_set.id,
      'kst_date', v_existing_set.kst_date,
      'deck_code', v_existing_set.deck_code,
      'cards', (
        SELECT jsonb_agg(
          jsonb_build_object(
            'id', qc.id,
            'card_text', qc.card_text,
            'level', qc.level,
            'subdeck', qc.subdeck,
            'tags', qc.tags,
            'vote_count', COALESCE((
              SELECT COUNT(*)::int
              FROM daily_question_votes dqv
              WHERE dqv.set_id = v_existing_set.id
                AND dqv.card_id = qc.id
            ), 0)
          )
        )
        FROM question_cards qc
        WHERE qc.id = ANY(v_existing_set.card_ids)
      ),
      'user_vote', (
        SELECT card_id
        FROM daily_question_votes
        WHERE set_id = v_existing_set.id
          AND user_id = auth.uid()
      ),
      'total_votes', (
        SELECT COUNT(*)::int
        FROM daily_question_votes
        WHERE set_id = v_existing_set.id
      )
    ) INTO v_result;

    RETURN v_result;
  END IF;

  -- 덱 코드 결정 (크리에이터 설정 또는 기본값)
  SELECT COALESCE(
    (
      SELECT deck_codes[1]
      FROM creator_question_prefs
      WHERE creator_id = v_artist_id
        AND enabled = true
    ),
    'ex_idol'  -- 기본 덱
  ) INTO v_deck_code;

  -- 카드 샘플링 (레벨 분포: L1, L1, L2 우선)
  -- 쿨다운: 답변 60일, 노출 14일 제외
  WITH candidate_cards AS (
    SELECT qc.id, qc.level, qc.subdeck, qc.tags,
           ROW_NUMBER() OVER (
             PARTITION BY qc.level
             ORDER BY md5(qc.id::text || p_channel_id::text || v_kst_date::text)
           ) as rn
    FROM question_cards qc
    JOIN question_decks qd ON qd.id = qc.deck_id
    LEFT JOIN question_card_cooldowns qcc
      ON qcc.channel_id = p_channel_id AND qcc.card_id = qc.id
    WHERE qd.code = v_deck_code
      AND qc.is_active = true
      AND qc.language = 'ko'
      AND (qcc.last_answered_kst_date IS NULL OR qcc.last_answered_kst_date < v_kst_date - 60)
      AND (qcc.last_shown_kst_date IS NULL OR qcc.last_shown_kst_date < v_kst_date - 14)
  ),
  level1_cards AS (
    SELECT id FROM candidate_cards WHERE level = 1 AND rn <= 2
  ),
  level2_cards AS (
    SELECT id FROM candidate_cards WHERE level = 2 AND rn <= 1
  ),
  selected AS (
    SELECT id FROM level1_cards
    UNION ALL
    SELECT id FROM level2_cards
    LIMIT 3
  )
  SELECT ARRAY(SELECT id FROM selected) INTO v_card_ids;

  -- 3개 미만이면 완화 조건 적용 (쿨다운 무시)
  IF array_length(v_card_ids, 1) IS NULL OR array_length(v_card_ids, 1) < 3 THEN
    SELECT ARRAY(
      SELECT qc.id
      FROM question_cards qc
      JOIN question_decks qd ON qd.id = qc.deck_id
      WHERE qd.code = v_deck_code
        AND qc.is_active = true
        AND qc.language = 'ko'
      ORDER BY md5(qc.id::text || p_channel_id::text || v_kst_date::text)
      LIMIT 3
    ) INTO v_card_ids;
  END IF;

  -- 카드가 없으면 에러
  IF array_length(v_card_ids, 1) IS NULL OR array_length(v_card_ids, 1) = 0 THEN
    RETURN jsonb_build_object(
      'error', 'no_cards_available',
      'message', 'No question cards available for this deck'
    );
  END IF;

  -- 새 세트 삽입
  INSERT INTO daily_question_sets (channel_id, kst_date, deck_code, card_ids, seed)
  VALUES (
    p_channel_id,
    v_kst_date,
    v_deck_code,
    v_card_ids,
    md5(p_channel_id::text || v_kst_date::text || v_deck_code)
  )
  RETURNING id INTO v_set_id;

  -- 쿨다운 업데이트
  INSERT INTO question_card_cooldowns (channel_id, card_id, last_shown_kst_date, shown_count)
  SELECT p_channel_id, unnest(v_card_ids), v_kst_date, 1
  ON CONFLICT (channel_id, card_id) DO UPDATE SET
    last_shown_kst_date = EXCLUDED.last_shown_kst_date,
    shown_count = question_card_cooldowns.shown_count + 1;

  -- 결과 반환
  SELECT jsonb_build_object(
    'set_id', v_set_id,
    'kst_date', v_kst_date,
    'deck_code', v_deck_code,
    'cards', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', qc.id,
          'card_text', qc.card_text,
          'level', qc.level,
          'subdeck', qc.subdeck,
          'tags', qc.tags,
          'vote_count', 0
        )
      )
      FROM question_cards qc
      WHERE qc.id = ANY(v_card_ids)
    ),
    'user_vote', NULL,
    'total_votes', 0
  ) INTO v_result;

  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION get_or_create_daily_question_set IS '일일 질문 세트 조회 또는 생성 (KST 기준)';

-- C) 투표
CREATE OR REPLACE FUNCTION vote_daily_question(p_set_id UUID, p_card_id UUID)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_set RECORD;
  v_result JSONB;
BEGIN
  -- 세트 조회
  SELECT * INTO v_set FROM daily_question_sets WHERE id = p_set_id;

  IF v_set.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'set_not_found');
  END IF;

  -- 채널 접근 권한 확인
  IF NOT EXISTS (
    SELECT 1 FROM subscriptions
    WHERE channel_id = v_set.channel_id
      AND user_id = auth.uid()
      AND is_active = true
  ) AND NOT EXISTS (
    SELECT 1 FROM channels
    WHERE id = v_set.channel_id
      AND artist_id = auth.uid()
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'access_denied');
  END IF;

  -- 카드가 세트에 속하는지 확인
  IF NOT (p_card_id = ANY(v_set.card_ids)) THEN
    RETURN jsonb_build_object('success', false, 'error', 'card_not_in_set');
  END IF;

  -- 이미 투표했는지 확인
  IF EXISTS (SELECT 1 FROM daily_question_votes WHERE set_id = p_set_id AND user_id = auth.uid()) THEN
    RETURN jsonb_build_object('success', false, 'error', 'already_voted');
  END IF;

  -- 투표 삽입
  INSERT INTO daily_question_votes (set_id, user_id, card_id)
  VALUES (p_set_id, auth.uid(), p_card_id);

  -- 업데이트된 카운트 반환
  SELECT jsonb_build_object(
    'success', true,
    'user_vote', p_card_id,
    'vote_counts', (
      SELECT jsonb_object_agg(card_id, cnt)
      FROM (
        SELECT card_id, COUNT(*)::int as cnt
        FROM daily_question_votes
        WHERE set_id = p_set_id
        GROUP BY card_id
      ) t
    ),
    'total_votes', (
      SELECT COUNT(*)::int
      FROM daily_question_votes
      WHERE set_id = p_set_id
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION vote_daily_question IS '질문 카드 투표 (1인 1일 1채널 1표)';

-- D) 답변 마킹 (크리에이터 전용)
CREATE OR REPLACE FUNCTION mark_question_answered(
  p_channel_id UUID,
  p_card_id UUID,
  p_message_id UUID,
  p_set_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- 크리에이터 권한 확인
  IF NOT EXISTS (SELECT 1 FROM channels WHERE id = p_channel_id AND artist_id = auth.uid()) THEN
    RETURN jsonb_build_object('success', false, 'error', 'not_channel_owner');
  END IF;

  -- 답변 연결 삽입
  INSERT INTO question_card_answers (channel_id, card_id, set_id, message_id)
  VALUES (p_channel_id, p_card_id, p_set_id, p_message_id)
  ON CONFLICT (channel_id, card_id, message_id) DO NOTHING;

  -- 쿨다운 업데이트
  INSERT INTO question_card_cooldowns (channel_id, card_id, last_answered_kst_date, answered_count)
  VALUES (p_channel_id, p_card_id, get_kst_date(), 1)
  ON CONFLICT (channel_id, card_id) DO UPDATE SET
    last_answered_kst_date = EXCLUDED.last_answered_kst_date,
    answered_count = question_card_cooldowns.answered_count + 1;

  -- 메시지에 질문 카드 연결
  UPDATE messages
  SET question_card_id = p_card_id, question_set_id = p_set_id
  WHERE id = p_message_id;

  RETURN jsonb_build_object('success', true, 'answered_at', now());
END;
$$;

COMMENT ON FUNCTION mark_question_answered IS '질문 카드에 대한 아티스트 답변 마킹';

-- E) 투표 현황 조회 (크리에이터용)
CREATE OR REPLACE FUNCTION get_todays_question_stats(p_channel_id UUID)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_kst_date DATE;
  v_set RECORD;
  v_result JSONB;
BEGIN
  v_kst_date := get_kst_date();

  -- 크리에이터 권한 확인
  IF NOT EXISTS (SELECT 1 FROM channels WHERE id = p_channel_id AND artist_id = auth.uid()) THEN
    RETURN jsonb_build_object('error', 'not_channel_owner');
  END IF;

  -- 오늘 세트 조회
  SELECT * INTO v_set FROM daily_question_sets
  WHERE channel_id = p_channel_id AND kst_date = v_kst_date;

  IF v_set.id IS NULL THEN
    RETURN jsonb_build_object(
      'has_set', false,
      'kst_date', v_kst_date
    );
  END IF;

  -- 투표 통계 반환
  SELECT jsonb_build_object(
    'has_set', true,
    'set_id', v_set.id,
    'kst_date', v_kst_date,
    'deck_code', v_set.deck_code,
    'total_votes', (
      SELECT COUNT(*)::int FROM daily_question_votes WHERE set_id = v_set.id
    ),
    'cards', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', qc.id,
          'card_text', qc.card_text,
          'level', qc.level,
          'subdeck', qc.subdeck,
          'vote_count', COALESCE((
            SELECT COUNT(*)::int
            FROM daily_question_votes dqv
            WHERE dqv.set_id = v_set.id AND dqv.card_id = qc.id
          ), 0),
          'is_answered', EXISTS (
            SELECT 1 FROM question_card_answers qca
            WHERE qca.channel_id = p_channel_id
              AND qca.card_id = qc.id
              AND qca.set_id = v_set.id
          )
        )
        ORDER BY COALESCE((
          SELECT COUNT(*)::int
          FROM daily_question_votes dqv
          WHERE dqv.set_id = v_set.id AND dqv.card_id = qc.id
        ), 0) DESC
      )
      FROM question_cards qc
      WHERE qc.id = ANY(v_set.card_ids)
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION get_todays_question_stats IS '오늘의 질문 카드 투표 현황 (크리에이터용)';

-- ============================================
-- 초기 덱 정의 (카드는 031_seed_question_cards.sql에서 임포트)
-- ============================================
INSERT INTO question_decks (code, title, description) VALUES
  ('ex_idol', '전 아이돌', '전 아이돌/연습생 크리에이터용 질문 덱'),
  ('maid', '메이드', '메이드 컨셉 크리에이터용 질문 덱'),
  ('vtuber', 'VTuber', 'VTuber 크리에이터용 질문 덱'),
  ('actor', '배우/모델', '배우/모델 크리에이터용 질문 덱')
ON CONFLICT (code) DO NOTHING;

-- 질문 카드 데이터는 031_seed_question_cards.sql에서 800개 임포트됨
-- content/question_card_deck_800.jsonl 파일 기반
