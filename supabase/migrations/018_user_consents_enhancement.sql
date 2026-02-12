-- ============================================
-- UNO A - User Consents Enhancement
-- Version: 1.1.0
--
-- Creates user_consents infrastructure and adds audit fields:
-- - document_snapshot_hash: 약관 버전 해시 (증빙용)
-- - revoked_at: 마케팅 동의 철회 시점
-- - consent_history: 동의/철회 이력 추적
-- ============================================

-- ============================================
-- 0. BASE TABLES (create if not exist)
-- ============================================

-- Consent type enum
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'consent_type') THEN
    CREATE TYPE consent_type AS ENUM (
      'terms_of_service',
      'privacy_policy',
      'marketing_email',
      'marketing_push',
      'marketing_sms',
      'age_verification',
      'third_party_sharing'
    );
  END IF;
END;
$$;

-- Consent documents (약관 문서 버전 관리)
CREATE TABLE IF NOT EXISTS public.consent_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  consent_type consent_type NOT NULL,
  version VARCHAR(20) NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  is_required BOOLEAN DEFAULT false,
  effective_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(consent_type, version)
);

-- User consents (사용자 동의 기록)
CREATE TABLE IF NOT EXISTS public.user_consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  consent_type consent_type NOT NULL,
  version VARCHAR(20) NOT NULL,
  agreed BOOLEAN NOT NULL DEFAULT false,
  agreed_at TIMESTAMPTZ DEFAULT NOW(),
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, consent_type)
);

ALTER TABLE user_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE consent_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own consents" ON user_consents;
CREATE POLICY "Users can view own consents"
  ON user_consents FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own consents" ON user_consents;
CREATE POLICY "Users can insert own consents"
  ON user_consents FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own consents" ON user_consents;
CREATE POLICY "Users can update own consents"
  ON user_consents FOR UPDATE
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Anyone can view consent documents" ON consent_documents;
CREATE POLICY "Anyone can view consent documents"
  ON consent_documents FOR SELECT
  USING (true);

-- ============================================
-- 1. USER_CONSENTS 테이블 필드 추가
-- ============================================

-- 약관 문서 스냅샷 해시 (동의 시점의 약관 내용 증빙)
ALTER TABLE user_consents
  ADD COLUMN IF NOT EXISTS document_snapshot_hash TEXT;

-- 동의 철회 시점 (마케팅 동의 등 선택 동의 철회 시)
ALTER TABLE user_consents
  ADD COLUMN IF NOT EXISTS revoked_at TIMESTAMPTZ;

-- 철회 사유 (선택)
ALTER TABLE user_consents
  ADD COLUMN IF NOT EXISTS revocation_reason TEXT;

-- 동의 방식 (web, app, api)
ALTER TABLE user_consents
  ADD COLUMN IF NOT EXISTS consent_method TEXT DEFAULT 'app';

-- ============================================
-- 2. CONSENT_HISTORY 테이블 (동의/철회 이력)
-- ============================================
CREATE TABLE IF NOT EXISTS public.consent_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  consent_type consent_type NOT NULL,
  version VARCHAR(20) NOT NULL,

  -- 액션
  action TEXT NOT NULL CHECK (action IN ('agree', 'revoke', 'update')),

  -- 동의 상태
  agreed BOOLEAN NOT NULL,

  -- 메타데이터
  document_snapshot_hash TEXT,         -- 약관 내용 해시
  ip_address INET,
  user_agent TEXT,
  consent_method TEXT DEFAULT 'app',   -- web, app, api

  -- 타임스탬프
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_consent_history_user ON consent_history(user_id);
CREATE INDEX IF NOT EXISTS idx_consent_history_type ON consent_history(consent_type);
CREATE INDEX IF NOT EXISTS idx_consent_history_created ON consent_history(created_at);

-- RLS
ALTER TABLE consent_history ENABLE ROW LEVEL SECURITY;

-- 본인만 자신의 이력 조회 가능
CREATE POLICY "Users can view own consent history"
  ON consent_history FOR SELECT
  USING (user_id = auth.uid());

-- ============================================
-- 3. TRIGGER: 동의 변경 시 히스토리 자동 기록
-- ============================================
CREATE OR REPLACE FUNCTION log_consent_change()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO consent_history (
      user_id, consent_type, version, action, agreed,
      document_snapshot_hash, ip_address, user_agent, consent_method
    ) VALUES (
      NEW.user_id, NEW.consent_type, NEW.version,
      'agree', NEW.agreed,
      NEW.document_snapshot_hash, NEW.ip_address, NEW.user_agent, NEW.consent_method
    );
  ELSIF TG_OP = 'UPDATE' THEN
    -- 동의 상태가 변경된 경우만 기록
    IF OLD.agreed IS DISTINCT FROM NEW.agreed THEN
      INSERT INTO consent_history (
        user_id, consent_type, version, action, agreed,
        document_snapshot_hash, ip_address, user_agent, consent_method
      ) VALUES (
        NEW.user_id, NEW.consent_type, NEW.version,
        CASE WHEN NEW.agreed THEN 'agree' ELSE 'revoke' END,
        NEW.agreed,
        NEW.document_snapshot_hash, NEW.ip_address, NEW.user_agent, NEW.consent_method
      );
    -- 버전이 변경된 경우 (약관 업데이트 재동의)
    ELSIF OLD.version IS DISTINCT FROM NEW.version THEN
      INSERT INTO consent_history (
        user_id, consent_type, version, action, agreed,
        document_snapshot_hash, ip_address, user_agent, consent_method
      ) VALUES (
        NEW.user_id, NEW.consent_type, NEW.version,
        'update', NEW.agreed,
        NEW.document_snapshot_hash, NEW.ip_address, NEW.user_agent, NEW.consent_method
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_consent_change ON user_consents;
CREATE TRIGGER on_consent_change
  AFTER INSERT OR UPDATE ON user_consents
  FOR EACH ROW
  EXECUTE FUNCTION log_consent_change();

-- ============================================
-- 4. HELPER FUNCTIONS
-- ============================================

-- 약관 문서 해시 생성 (SHA-256)
CREATE OR REPLACE FUNCTION generate_document_hash(p_content TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN encode(digest(p_content, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 마케팅 동의 철회
CREATE OR REPLACE FUNCTION revoke_marketing_consent(
  p_user_id UUID,
  p_consent_type consent_type,
  p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE user_consents
  SET
    agreed = false,
    revoked_at = NOW(),
    revocation_reason = p_reason,
    updated_at = NOW()
  WHERE user_id = p_user_id
    AND consent_type = p_consent_type
    AND agreed = true;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 사용자의 모든 마케팅 동의 일괄 철회
CREATE OR REPLACE FUNCTION revoke_all_marketing_consents(
  p_user_id UUID,
  p_reason TEXT DEFAULT 'User requested opt-out'
)
RETURNS INT AS $$
DECLARE
  revoked_count INT;
BEGIN
  UPDATE user_consents
  SET
    agreed = false,
    revoked_at = NOW(),
    revocation_reason = p_reason,
    updated_at = NOW()
  WHERE user_id = p_user_id
    AND consent_type IN ('marketing_email', 'marketing_push', 'marketing_sms')
    AND agreed = true;

  GET DIAGNOSTICS revoked_count = ROW_COUNT;
  RETURN revoked_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 사용자의 동의 상태 요약 조회
CREATE OR REPLACE FUNCTION get_user_consent_summary(p_user_id UUID)
RETURNS TABLE (
  consent_type consent_type,
  version VARCHAR(20),
  agreed BOOLEAN,
  agreed_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  is_required BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    uc.consent_type,
    uc.version,
    uc.agreed,
    uc.agreed_at,
    uc.revoked_at,
    cd.is_required
  FROM user_consents uc
  LEFT JOIN consent_documents cd ON cd.consent_type = uc.consent_type AND cd.version = uc.version
  WHERE uc.user_id = p_user_id
  ORDER BY cd.is_required DESC, uc.consent_type;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 권한 부여
GRANT EXECUTE ON FUNCTION revoke_marketing_consent(UUID, consent_type, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION revoke_all_marketing_consents(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_consent_summary(UUID) TO authenticated;

-- ============================================
-- 5. UNIQUE INDEX 보강 (동일 버전 재동의 방지)
-- ============================================
-- 기존 UNIQUE(user_id, consent_type) 제약을 version 포함으로 변경
-- 주의: 기존 제약 조건이 있으면 먼저 삭제 필요

-- 기존 제약 조건 확인 및 삭제 (안전하게)
DO $$
BEGIN
  -- 기존 unique constraint가 있으면 삭제
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'user_consents_user_id_consent_type_key'
  ) THEN
    ALTER TABLE user_consents DROP CONSTRAINT user_consents_user_id_consent_type_key;
  END IF;
END;
$$;

-- 새로운 unique index 생성 (user_id, consent_type, version)
-- 동일 사용자가 같은 consent_type에 대해 여러 버전 동의 가능
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_consents_unique_version
  ON user_consents(user_id, consent_type, version);

-- ============================================
-- 6. CONSENT_DOCUMENTS에 해시 필드 추가
-- ============================================
ALTER TABLE consent_documents
  ADD COLUMN IF NOT EXISTS content_hash TEXT;

-- 기존 문서의 해시 계산
UPDATE consent_documents
SET content_hash = encode(digest(content, 'sha256'), 'hex')
WHERE content_hash IS NULL;

-- 새 문서 삽입 시 해시 자동 생성
CREATE OR REPLACE FUNCTION auto_generate_document_hash()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.content_hash IS NULL THEN
    NEW.content_hash := encode(digest(NEW.content, 'sha256'), 'hex');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_document_insert ON consent_documents;
CREATE TRIGGER on_document_insert
  BEFORE INSERT OR UPDATE OF content ON consent_documents
  FOR EACH ROW
  EXECUTE FUNCTION auto_generate_document_hash();

COMMENT ON TABLE consent_history IS '동의/철회 이력 추적 테이블';
COMMENT ON COLUMN user_consents.document_snapshot_hash IS '동의 시점의 약관 내용 SHA-256 해시';
COMMENT ON COLUMN user_consents.revoked_at IS '동의 철회 시점 (마케팅 동의 등)';
