-- ============================================================
-- Migration 079: fan_ads table + RLS
-- 팬이 아티스트 프로필에 광고를 구매·관리하는 테이블.
-- RLS로 임의 상태 조작 차단, payment_amount > 0 강제.
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- 1. 테이블 생성
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.fan_ads (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 광고 구매자(팬)
  fan_user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 광고 노출 대상 아티스트 채널
  artist_channel_id   UUID NOT NULL REFERENCES public.channels(id) ON DELETE CASCADE,

  -- 광고 소재
  title               TEXT NOT NULL CHECK (char_length(title) BETWEEN 1 AND 50),
  body                TEXT          CHECK (char_length(body) <= 100),
  image_url           TEXT,
  link_url            TEXT,
  link_type           TEXT NOT NULL DEFAULT 'external'
                      CHECK (link_type IN ('internal', 'external', 'none')),

  -- 노출 기간
  start_at            TIMESTAMPTZ NOT NULL,
  end_at              TIMESTAMPTZ NOT NULL,
  CHECK (end_at > start_at),

  -- 결제
  payment_amount_krw  INT NOT NULL CHECK (payment_amount_krw > 0),
  payment_status      TEXT NOT NULL DEFAULT 'pending'
                      CHECK (payment_status IN ('pending', 'paid', 'refunded', 'failed')),
  payment_ref         TEXT,   -- PG 트랜잭션 ID (서버 기록 전용)

  -- 심사/상태
  -- 팬이 직접 쓸 수 있는 값: pending_review 만
  -- 이후 상태 전이는 ops_admin 역할만 가능
  status              TEXT NOT NULL DEFAULT 'pending_review'
                      CHECK (status IN ('pending_review', 'approved', 'active',
                                        'completed', 'rejected', 'cancelled')),
  rejection_reason    TEXT,

  -- 통계 (서버 집계)
  impressions         INT NOT NULL DEFAULT 0 CHECK (impressions >= 0),
  clicks              INT NOT NULL DEFAULT 0 CHECK (clicks >= 0),

  -- ops_banners 연결 (승인 후 자동 생성된 배너 ID)
  ops_banner_id       UUID REFERENCES public.ops_banners(id) ON DELETE SET NULL,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────
-- 2. 인덱스
-- ─────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_fan_ads_fan_user
  ON public.fan_ads (fan_user_id, status);

CREATE INDEX IF NOT EXISTS idx_fan_ads_channel_active
  ON public.fan_ads (artist_channel_id, status)
  WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_fan_ads_ops_banner
  ON public.fan_ads (ops_banner_id)
  WHERE ops_banner_id IS NOT NULL;

-- ─────────────────────────────────────────────────────────────
-- 3. updated_at 트리거
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_fan_ads_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_fan_ads_updated_at
  BEFORE UPDATE ON public.fan_ads
  FOR EACH ROW EXECUTE FUNCTION public.set_fan_ads_updated_at();

-- ─────────────────────────────────────────────────────────────
-- 4. RLS 활성화
-- ─────────────────────────────────────────────────────────────
ALTER TABLE public.fan_ads ENABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────────
-- 5. RLS 정책
-- ─────────────────────────────────────────────────────────────

-- 5-1. 본인 광고만 조회 가능
CREATE POLICY fan_ads_own_select
  ON public.fan_ads
  FOR SELECT
  TO authenticated
  USING (fan_user_id = auth.uid());

-- 5-2. 삽입: 반드시 status='pending_review', payment_status='pending' 로만 생성
--       fan_user_id는 auth.uid()로 고정 (임의 사용자 ID 삽입 불가)
CREATE POLICY fan_ads_own_insert
  ON public.fan_ads
  FOR INSERT
  TO authenticated
  WITH CHECK (
    fan_user_id      = auth.uid()
    AND status          = 'pending_review'
    AND payment_status  = 'pending'
    AND ops_banner_id  IS NULL
    AND impressions     = 0
    AND clicks          = 0
  );

-- 5-3. 업데이트: 팬이 허용하는 전이는 '취소 요청(cancelled)' 뿐,
--       단 status='pending_review'인 본인 광고에서만 가능.
--       payment_status, ops_banner_id, impressions, clicks, rejection_reason 변경 금지.
CREATE POLICY fan_ads_own_update
  ON public.fan_ads
  FOR UPDATE
  TO authenticated
  USING (
    fan_user_id = auth.uid()
    AND status  = 'pending_review'
  )
  WITH CHECK (
    fan_user_id      = auth.uid()
    AND status          = 'cancelled'
    -- 변경 불가 필드는 기존 값 유지 강제
    AND payment_status  = (SELECT payment_status FROM public.fan_ads WHERE id = fan_ads.id)
    AND ops_banner_id   IS NOT DISTINCT FROM (SELECT ops_banner_id FROM public.fan_ads WHERE id = fan_ads.id)
    AND impressions     = (SELECT impressions   FROM public.fan_ads WHERE id = fan_ads.id)
    AND clicks          = (SELECT clicks        FROM public.fan_ads WHERE id = fan_ads.id)
  );

-- 5-4. 삭제: 팬 직접 삭제 금지 (서비스 롤만 가능)
--       명시적 정책 없음 = 기본 DENY

-- ─────────────────────────────────────────────────────────────
-- 6. 권한
-- ─────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE ON public.fan_ads TO authenticated;
GRANT ALL ON public.fan_ads TO service_role;

-- ─────────────────────────────────────────────────────────────
-- 7. 코멘트
-- ─────────────────────────────────────────────────────────────
COMMENT ON TABLE  public.fan_ads IS '팬이 아티스트 프로필에 게재하는 유료 광고. 심사 후 ops_banners로 연결.';
COMMENT ON COLUMN public.fan_ads.status IS
  'pending_review: 심사 대기 | approved: 심사 통과(미활성) | active: 노출 중 | completed: 기간 만료 | rejected: 거절 | cancelled: 팬 취소';
COMMENT ON COLUMN public.fan_ads.payment_ref IS
  'PG 트랜잭션 ID. payment-checkout Edge Function이 기록, 클라이언트는 읽기 전용.';
