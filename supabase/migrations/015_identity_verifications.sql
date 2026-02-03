-- ============================================
-- UNO A - Identity Verifications Schema (PII 분리)
-- Version: 1.0.0
--
-- SECURITY:
-- - 민감정보(PII)를 user_profiles에서 분리하여 별도 테이블로 관리
-- - 모든 PII는 AES-256-GCM으로 암호화되어 저장됨
-- - RLS로 본인만 조회 가능, 삽입/수정은 service_role만 가능
-- ============================================

-- ============================================
-- 1. IDENTITY_VERIFICATIONS TABLE (본인인증 정보)
-- ============================================
CREATE TABLE IF NOT EXISTS public.identity_verifications (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 암호화된 PII 데이터 (AES-256-GCM encrypted)
  real_name_encrypted TEXT,           -- 실명
  phone_encrypted TEXT,               -- 휴대폰 번호
  birth_date_encrypted TEXT,          -- 생년월일 (YYYY-MM-DD)
  gender_encrypted TEXT,              -- 성별 (MALE/FEMALE)
  ci_encrypted TEXT,                  -- 연계정보 (CI)

  -- 비암호화 메타데이터
  carrier TEXT,                       -- 통신사 (SKT, KT, LGU+, etc.)
  is_foreigner BOOLEAN DEFAULT false, -- 외국인 여부
  identity_imp_uid TEXT,              -- PortOne 인증 고유 ID

  -- 타임스탬프
  verified_at TIMESTAMPTZ,            -- 인증 완료 시점
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_identity_verifications_carrier ON identity_verifications(carrier);
CREATE INDEX IF NOT EXISTS idx_identity_verifications_verified ON identity_verifications(verified_at);

-- ============================================
-- 2. USER_PROFILES 테이블에 인증 플래그 필드 추가
-- ============================================
-- 주의: 이 필드들은 플래그만 저장, 실제 PII는 identity_verifications에 저장
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS identity_verified BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS identity_verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS phone_verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS age_verified BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS age_verified_at TIMESTAMPTZ;

-- ============================================
-- 3. RLS POLICIES
-- ============================================
ALTER TABLE identity_verifications ENABLE ROW LEVEL SECURITY;

-- 본인만 자신의 인증 정보 조회 가능
CREATE POLICY "Users can view own identity verification"
  ON identity_verifications FOR SELECT
  USING (id = auth.uid());

-- 삽입/수정은 service_role만 가능 (Edge Function에서만)
-- 일반 사용자는 직접 삽입/수정 불가
-- Note: RLS가 enabled 상태에서 INSERT/UPDATE policy가 없으면
--       service_role 외에는 삽입/수정 불가

-- Admin policy (service_role bypass)
-- Service role은 기본적으로 RLS를 우회하므로 별도 policy 불필요

-- ============================================
-- 4. TRIGGERS
-- ============================================
-- Update updated_at on identity_verifications
CREATE OR REPLACE FUNCTION update_identity_verification_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_identity_verifications_updated_at ON identity_verifications;
CREATE TRIGGER update_identity_verifications_updated_at
  BEFORE UPDATE ON identity_verifications
  FOR EACH ROW
  EXECUTE FUNCTION update_identity_verification_updated_at();

-- ============================================
-- 5. HELPER FUNCTIONS
-- ============================================

-- 사용자의 본인인증 상태 확인
CREATE OR REPLACE FUNCTION public.is_identity_verified(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM identity_verifications
    WHERE id = p_user_id
      AND verified_at IS NOT NULL
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 사용자의 성인 여부 확인 (user_profiles의 age_verified 플래그 사용)
CREATE OR REPLACE FUNCTION public.is_adult_verified(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_age_verified BOOLEAN;
BEGIN
  SELECT age_verified INTO v_age_verified
  FROM user_profiles
  WHERE id = p_user_id;

  RETURN COALESCE(v_age_verified, false);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 권한 부여
GRANT EXECUTE ON FUNCTION public.is_identity_verified(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_adult_verified(UUID) TO authenticated;

-- ============================================
-- 6. AUDIT LOG (선택적 - 감사 목적)
-- ============================================
CREATE TABLE IF NOT EXISTS public.identity_verification_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,                -- 'verification_started', 'verification_completed', 'verification_failed'
  provider TEXT DEFAULT 'portone',     -- 인증 제공자
  imp_uid TEXT,                        -- PortOne 인증 ID
  ip_address INET,                     -- 요청 IP (Edge Function에서 설정)
  user_agent TEXT,                     -- User Agent
  error_code TEXT,                     -- 실패 시 에러 코드
  error_message TEXT,                  -- 실패 시 에러 메시지
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_identity_verification_logs_user ON identity_verification_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_identity_verification_logs_action ON identity_verification_logs(action);
CREATE INDEX IF NOT EXISTS idx_identity_verification_logs_created ON identity_verification_logs(created_at);

-- RLS
ALTER TABLE identity_verification_logs ENABLE ROW LEVEL SECURITY;

-- 본인만 자신의 로그 조회 가능
CREATE POLICY "Users can view own verification logs"
  ON identity_verification_logs FOR SELECT
  USING (user_id = auth.uid());

COMMENT ON TABLE identity_verifications IS 'PII 민감정보 저장 테이블 - 모든 데이터 암호화됨';
COMMENT ON TABLE identity_verification_logs IS '본인인증 감사 로그';
