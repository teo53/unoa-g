-- ============================================================
-- 066: Agency Management Schema — 소속사 통합 정산 시스템
-- ============================================================
-- Entertainment agency (소속사) multi-creator management.
-- Consolidated settlement, tax certificates, staff RBAC.
-- ============================================================

-- ────────────────────────────────────────────────
-- 1. agencies — 소속사 (Entertainment company entity)
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.agencies (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,                    -- 소속사 표시명 (e.g., "스타엔터")
  business_name   TEXT NOT NULL,                    -- 상호명 (법적 등록명)
  representative  TEXT NOT NULL,                    -- 대표자명
  business_number TEXT NOT NULL UNIQUE,             -- 사업자등록번호 (XXX-XX-XXXXX)
  email           TEXT NOT NULL,
  phone           TEXT,
  address         TEXT,
  -- Bank info (for consolidated settlement)
  bank_code       TEXT,
  bank_name       TEXT,
  bank_account    TEXT,
  account_holder  TEXT,
  -- Tax
  tax_type        TEXT DEFAULT 'business' CHECK (tax_type IN ('business', 'individual')),
  -- Status
  status          TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'suspended', 'terminated')),
  verified_at     TIMESTAMPTZ,
  verified_by     UUID REFERENCES auth.users(id),
  -- Branding
  logo_url        TEXT,
  website_url     TEXT,
  max_exchange_rate NUMERIC DEFAULT 0.60 CHECK (max_exchange_rate BETWEEN 0 AND 1),  -- 최대환전율 (like 팬더 60%)
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.agencies ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.agencies IS
  '소속사 엔티티. 크리에이터 소속사 관리, 통합 정산, 세무 대리 수행.';
COMMENT ON COLUMN public.agencies.business_number IS
  '사업자등록번호. 고유값이며, 정산/세무 증빙에 사용.';
COMMENT ON COLUMN public.agencies.max_exchange_rate IS
  '소속사가 크리에이터에게 제시하는 최대 환전율 (0.0~1.0). 팬더 기준 60% (0.60).';
COMMENT ON COLUMN public.agencies.verified_at IS
  'Ops admin이 사업자등록증 검증 완료한 시각. NULL = 미검증.';

-- ────────────────────────────────────────────────
-- 2. agency_staff — RBAC for agency team members
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.agency_staff (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id    UUID NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role         TEXT NOT NULL DEFAULT 'viewer' CHECK (role IN ('viewer', 'manager', 'finance', 'admin')),
  display_name TEXT,
  email        TEXT,
  invited_by   UUID REFERENCES auth.users(id),
  invited_at   TIMESTAMPTZ DEFAULT now(),
  accepted_at  TIMESTAMPTZ,                         -- NULL = 초대 대기 중
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (agency_id, user_id)
);

ALTER TABLE public.agency_staff ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.agency_staff IS
  '소속사 팀원 RBAC. viewer < manager < finance < admin. accepted_at NULL이면 초대 대기 중.';
COMMENT ON COLUMN public.agency_staff.role IS
  'viewer: 조회만, manager: 계약/크리에이터 관리, finance: 정산/세무, admin: 전체 권한';
COMMENT ON COLUMN public.agency_staff.accepted_at IS
  '초대 수락 시각. NULL = 초대 이메일 전송 완료, 아직 수락 대기 중.';

-- ────────────────────────────────────────────────
-- 3. agency_creators — Agency↔Creator contract junction
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.agency_creators (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id           UUID NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
  creator_profile_id  UUID NOT NULL REFERENCES creator_profiles(id) ON DELETE CASCADE,
  contract_start      DATE NOT NULL,
  contract_end        DATE,                          -- NULL = 무기한 계약
  revenue_share_rate  NUMERIC NOT NULL DEFAULT 0.10 CHECK (revenue_share_rate BETWEEN 0 AND 1),  -- 소속사 수수료율 (기본 10%)
  settlement_basis    TEXT DEFAULT 'monthly' CHECK (settlement_basis IN ('weekly', 'biweekly', 'monthly')),
  status              TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'paused', 'terminated')),
  contract_document_url TEXT,                        -- 계약서 PDF Storage URL
  power_of_attorney_url TEXT,                        -- 위임장 (like 팬더 — 소속사가 정산 대리 수령)
  contract_notes      TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (agency_id, creator_profile_id)
);

ALTER TABLE public.agency_creators ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.agency_creators IS
  '소속사↔크리에이터 계약 연결. revenue_share_rate는 소속사가 가져가는 비율.';
COMMENT ON COLUMN public.agency_creators.revenue_share_rate IS
  '소속사 수수료율 (0.0~1.0). 크리에이터 실수령액 = (정산액 - 플랫폼수수료) × (1 - revenue_share_rate)';
COMMENT ON COLUMN public.agency_creators.power_of_attorney_url IS
  '위임장. 소속사가 크리에이터 대신 정산금 수령할 수 있는 법적 근거.';

-- ────────────────────────────────────────────────
-- 4. agency_settlements — Agency-level consolidated settlements
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.agency_settlements (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id              UUID NOT NULL REFERENCES agencies(id),
  period_start           DATE NOT NULL,
  period_end             DATE NOT NULL,
  total_creators         INT NOT NULL DEFAULT 0,
  total_gross_krw        BIGINT NOT NULL DEFAULT 0,      -- 전체 총매출 (플랫폼수수료 공제 전)
  total_platform_fee_krw BIGINT NOT NULL DEFAULT 0,      -- 플랫폼수수료 (20%)
  total_creator_net_krw  BIGINT NOT NULL DEFAULT 0,      -- 크리에이터 실수령 합계 (소속사수수료 공제 전)
  agency_commission_krw  BIGINT NOT NULL DEFAULT 0,      -- 소속사 수수료 (각 크리에이터 revenue_share_rate 합산)
  agency_tax_type        TEXT DEFAULT 'business_income', -- 사업소득세 / 기타소득세
  agency_tax_rate        NUMERIC DEFAULT 0.033,          -- 소속사 원천징수율 (기본 3.3%)
  agency_tax_krw         BIGINT NOT NULL DEFAULT 0,      -- 소속사 원천징수 세액
  agency_net_krw         BIGINT NOT NULL DEFAULT 0,      -- 소속사 최종 수령액 (수수료 - 세금)
  status                 TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending_review', 'approved', 'processing', 'paid', 'cancelled')),
  reviewed_by            UUID REFERENCES auth.users(id),
  reviewed_at            TIMESTAMPTZ,
  review_notes           TEXT,
  bank_transfer_id       TEXT,                           -- 은행 이체 거래번호
  paid_at                TIMESTAMPTZ,
  creator_breakdown      JSONB DEFAULT '[]',             -- 크리에이터별 상세 내역 [{creator_id, gross, platform_fee, net, agency_commission}, ...]
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.agency_settlements ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.agency_settlements IS
  '소속사 통합 정산. 소속 크리에이터들의 수익을 합산하여 소속사에게 일괄 지급.';
COMMENT ON COLUMN public.agency_settlements.total_gross_krw IS
  '전체 크리에이터 총매출 (플랫폼수수료 공제 전). 플랫폼 관점에서 발생한 매출액.';
COMMENT ON COLUMN public.agency_settlements.agency_commission_krw IS
  '소속사가 가져가는 수수료 합계. 각 크리에이터별 (net × revenue_share_rate) 합산.';
COMMENT ON COLUMN public.agency_settlements.creator_breakdown IS
  'JSONB 배열. 크리에이터별 상세: [{creator_id, gross_krw, platform_fee_krw, net_krw, agency_commission_krw}]';

-- ────────────────────────────────────────────────
-- 5. agency_tax_certificates — Tax clearance certificate tracking
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.agency_tax_certificates (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id       UUID NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
  year            INT NOT NULL,
  month           INT NOT NULL CHECK (month BETWEEN 1 AND 12),
  document_type   TEXT NOT NULL DEFAULT 'tax_clearance' CHECK (document_type IN ('tax_clearance', 'business_income', 'tax_invoice', 'withholding')),
  document_url    TEXT,                              -- Storage URL (PDF)
  status          TEXT NOT NULL DEFAULT 'not_submitted' CHECK (status IN ('not_submitted', 'submitted', 'approved', 'rejected')),
  submission_deadline TIMESTAMPTZ,
  submitted_at    TIMESTAMPTZ,
  reviewed_by     UUID REFERENCES auth.users(id),
  reviewed_at     TIMESTAMPTZ,
  review_notes    TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (agency_id, year, month, document_type)
);

ALTER TABLE public.agency_tax_certificates ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.agency_tax_certificates IS
  '소속사 세무 증빙 서류 제출 추적. 사업소득원천징수영수증, 세금계산서 등.';
COMMENT ON COLUMN public.agency_tax_certificates.document_type IS
  'tax_clearance: 납세증명서, business_income: 사업소득원천징수영수증, tax_invoice: 세금계산서, withholding: 원천징수이행상황신고서';

-- ────────────────────────────────────────────────
-- 6. agency_notices — Announcements for agencies
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.agency_notices (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id     UUID REFERENCES agencies(id) ON DELETE CASCADE,  -- NULL = 전체 소속사 대상 플랫폼 공지
  title         TEXT NOT NULL,
  content       TEXT NOT NULL,
  category      TEXT NOT NULL DEFAULT 'general' CHECK (category IN ('general', 'settlement', 'policy', 'system', 'tax')),
  is_pinned     BOOLEAN DEFAULT false,
  published_at  TIMESTAMPTZ,                         -- NULL = 임시저장
  created_by    UUID NOT NULL REFERENCES auth.users(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.agency_notices ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.agency_notices IS
  '소속사 공지사항. agency_id NULL이면 전체 소속사 대상 플랫폼 공지.';
COMMENT ON COLUMN public.agency_notices.agency_id IS
  'NULL = 전체 소속사에 노출, UUID = 특정 소속사만 조회 가능.';

-- ────────────────────────────────────────────────
-- 7. agency_audit_log — Immutable audit trail
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.agency_audit_log (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id   UUID NOT NULL REFERENCES agencies(id),
  actor_id    UUID NOT NULL REFERENCES auth.users(id),
  actor_role  TEXT NOT NULL,
  action      TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id   UUID,
  before      JSONB,      -- Changed fields only (diff, not full row)
  after       JSONB,      -- Changed fields only (diff, not full row)
  metadata    JSONB DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.agency_audit_log ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_agency_audit_agency
  ON public.agency_audit_log (agency_id);
CREATE INDEX IF NOT EXISTS idx_agency_audit_entity
  ON public.agency_audit_log (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_agency_audit_actor
  ON public.agency_audit_log (actor_id);
CREATE INDEX IF NOT EXISTS idx_agency_audit_created
  ON public.agency_audit_log (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_agency_audit_diff
  ON public.agency_audit_log USING GIN (after jsonb_path_ops);

COMMENT ON TABLE public.agency_audit_log IS
  '소속사 관련 모든 변경 이력 추적 (불변 로그). 감사 증적용.';
COMMENT ON COLUMN public.agency_audit_log.before IS
  'JSONB diff: only fields that changed (old values). NULL for create actions.';
COMMENT ON COLUMN public.agency_audit_log.after IS
  'JSONB diff: only fields that changed (new values). NULL for delete actions.';

-- ────────────────────────────────────────────────
-- 8. Modify creator_profiles — Add agency_id FK
-- ────────────────────────────────────────────────
ALTER TABLE public.creator_profiles
  ADD COLUMN IF NOT EXISTS agency_id UUID REFERENCES agencies(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_creator_profiles_agency
  ON public.creator_profiles(agency_id);

COMMENT ON COLUMN public.creator_profiles.agency_id IS
  '소속사 FK. agency_creators 계약이 active일 때 자동으로 설정됨. NULL = 개인 크리에이터.';

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- ────────────────────────────────────────────────
-- F1. is_agency_staff — Role-level check for agency staff
-- ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_agency_staff(
  p_agency_id UUID,
  min_role TEXT DEFAULT 'viewer'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_role TEXT;
  role_levels CONSTANT INT[] := ARRAY[1, 2, 3, 4]; -- viewer, manager, finance, admin
  role_names  CONSTANT TEXT[] := ARRAY['viewer', 'manager', 'finance', 'admin'];
  v_user_level INT;
  v_min_level  INT;
BEGIN
  -- Check auth
  IF auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Get current user role for this agency
  SELECT role INTO v_role
  FROM agency_staff
  WHERE agency_id = p_agency_id
    AND user_id = auth.uid()
    AND accepted_at IS NOT NULL;  -- 초대 수락 완료한 staff만

  IF v_role IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Map role names to levels
  v_user_level := array_position(role_names, v_role);
  v_min_level  := array_position(role_names, min_role);

  IF v_user_level IS NULL OR v_min_level IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN v_user_level >= v_min_level;
END;
$$;

COMMENT ON FUNCTION public.is_agency_staff IS
  '소속사 팀원 권한 체크. viewer(1) < manager(2) < finance(3) < admin(4). accepted_at NOT NULL 필수.';

-- ────────────────────────────────────────────────
-- F2. get_user_agency_id — Get user's primary agency
-- ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_user_agency_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_agency_id UUID;
BEGIN
  -- Return first accepted agency (user can be in multiple agencies)
  SELECT agency_id INTO v_agency_id
  FROM agency_staff
  WHERE user_id = auth.uid()
    AND accepted_at IS NOT NULL
  ORDER BY created_at ASC
  LIMIT 1;

  RETURN v_agency_id;
END;
$$;

COMMENT ON FUNCTION public.get_user_agency_id IS
  '현재 user가 소속된 첫 번째 agency_id 반환. 복수 소속 가능 시 가장 오래된 것.';

-- ────────────────────────────────────────────────
-- F3. log_agency_audit — Diff-only audit logging
-- ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.log_agency_audit(
  p_agency_id   UUID,
  p_action      TEXT,
  p_entity_type TEXT,
  p_entity_id   UUID,
  p_before      JSONB DEFAULT NULL,
  p_after       JSONB DEFAULT NULL,
  p_metadata    JSONB DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor_role TEXT;
  v_diff_before JSONB;
  v_diff_after  JSONB;
  v_log_id UUID;
BEGIN
  -- Get actor role
  SELECT role INTO v_actor_role
  FROM agency_staff
  WHERE user_id = auth.uid()
    AND agency_id = p_agency_id;

  -- Calculate diff: only changed fields
  IF p_before IS NOT NULL AND p_after IS NOT NULL THEN
    -- Extract keys that differ between before and after
    SELECT
      jsonb_object_agg(key, p_before -> key),
      jsonb_object_agg(key, p_after -> key)
    INTO v_diff_before, v_diff_after
    FROM (
      SELECT key
      FROM jsonb_each(p_after)
      WHERE p_before -> key IS DISTINCT FROM p_after -> key
      UNION
      SELECT key
      FROM jsonb_each(p_before)
      WHERE NOT p_after ? key
    ) diff_keys(key);
  ELSE
    -- Create: no before; Delete: no after
    v_diff_before := p_before;
    v_diff_after  := p_after;
  END IF;

  INSERT INTO agency_audit_log (
    agency_id, actor_id, actor_role, action, entity_type, entity_id,
    before, after, metadata
  ) VALUES (
    p_agency_id,
    auth.uid(),
    COALESCE(v_actor_role, 'unknown'),
    p_action,
    p_entity_type,
    p_entity_id,
    v_diff_before,
    v_diff_after,
    p_metadata
  )
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$;

COMMENT ON FUNCTION public.log_agency_audit IS
  '소속사 감사 로그 기록. ops_audit_log와 동일한 diff-only 패턴.';

-- ============================================================
-- RLS POLICIES
-- ============================================================

-- ── agencies ──
CREATE POLICY "agencies_select_own_staff" ON public.agencies
  FOR SELECT USING (
    is_agency_staff(id, 'viewer')
  );

CREATE POLICY "agencies_select_ops_staff" ON public.agencies
  FOR SELECT USING (
    is_ops_staff('operator')
  );

CREATE POLICY "agencies_all_ops_staff" ON public.agencies
  FOR ALL USING (
    is_ops_staff('operator')
  );

-- ── agency_staff ──
CREATE POLICY "agency_staff_select_same_agency" ON public.agency_staff
  FOR SELECT USING (
    is_agency_staff(agency_id, 'viewer')
  );

CREATE POLICY "agency_staff_insert_admin" ON public.agency_staff
  FOR INSERT WITH CHECK (
    is_agency_staff(agency_id, 'admin')
  );

CREATE POLICY "agency_staff_update_admin" ON public.agency_staff
  FOR UPDATE USING (
    is_agency_staff(agency_id, 'admin')
  );

CREATE POLICY "agency_staff_delete_admin" ON public.agency_staff
  FOR DELETE USING (
    is_agency_staff(agency_id, 'admin')
  );

-- ── agency_creators ──
CREATE POLICY "agency_creators_select_same_agency" ON public.agency_creators
  FOR SELECT USING (
    is_agency_staff(agency_id, 'viewer')
    OR is_ops_staff('operator')
  );

CREATE POLICY "agency_creators_insert_admin" ON public.agency_creators
  FOR INSERT WITH CHECK (
    is_agency_staff(agency_id, 'admin')
    OR is_ops_staff('operator')
  );

CREATE POLICY "agency_creators_update_admin" ON public.agency_creators
  FOR UPDATE USING (
    is_agency_staff(agency_id, 'admin')
    OR is_ops_staff('operator')
  );

CREATE POLICY "agency_creators_delete_admin" ON public.agency_creators
  FOR DELETE USING (
    is_agency_staff(agency_id, 'admin')
    OR is_ops_staff('operator')
  );

-- ── agency_settlements ──
CREATE POLICY "agency_settlements_select_finance" ON public.agency_settlements
  FOR SELECT USING (
    is_agency_staff(agency_id, 'finance')
    OR is_ops_staff('operator')
  );

CREATE POLICY "agency_settlements_all_ops_staff" ON public.agency_settlements
  FOR ALL USING (
    is_ops_staff('operator')
  );

-- ── agency_tax_certificates ──
CREATE POLICY "agency_tax_select_finance" ON public.agency_tax_certificates
  FOR SELECT USING (
    is_agency_staff(agency_id, 'finance')
    OR is_ops_staff('operator')
  );

CREATE POLICY "agency_tax_insert_finance" ON public.agency_tax_certificates
  FOR INSERT WITH CHECK (
    is_agency_staff(agency_id, 'finance')
    OR is_ops_staff('operator')
  );

CREATE POLICY "agency_tax_update_finance" ON public.agency_tax_certificates
  FOR UPDATE USING (
    is_agency_staff(agency_id, 'finance')
    OR is_ops_staff('operator')
  );

-- ── agency_notices ──
CREATE POLICY "agency_notices_select_staff" ON public.agency_notices
  FOR SELECT USING (
    -- Platform-wide notices (agency_id IS NULL) visible to all agency staff
    (agency_id IS NULL AND get_user_agency_id() IS NOT NULL)
    -- Agency-specific notices visible to same agency staff
    OR is_agency_staff(agency_id, 'viewer')
  );

CREATE POLICY "agency_notices_all_ops_staff" ON public.agency_notices
  FOR ALL USING (
    is_ops_staff('operator')
  );

-- ── agency_audit_log ──
CREATE POLICY "agency_audit_select_same_agency" ON public.agency_audit_log
  FOR SELECT USING (
    is_agency_staff(agency_id, 'viewer')
    OR is_ops_staff('operator')
  );

-- No insert/update/delete via client; only via log_agency_audit() SECURITY DEFINER

-- ============================================================
-- GRANTS (Least Privilege)
-- ============================================================
REVOKE ALL ON agencies FROM authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON agencies TO authenticated;

REVOKE ALL ON agency_staff FROM authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON agency_staff TO authenticated;

REVOKE ALL ON agency_creators FROM authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON agency_creators TO authenticated;

REVOKE ALL ON agency_settlements FROM authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON agency_settlements TO authenticated;

REVOKE ALL ON agency_tax_certificates FROM authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON agency_tax_certificates TO authenticated;

REVOKE ALL ON agency_notices FROM authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON agency_notices TO authenticated;

REVOKE ALL ON agency_audit_log FROM authenticated;
GRANT SELECT ON agency_audit_log TO authenticated;  -- read-only

-- ============================================================
-- UPDATED_AT TRIGGERS
-- ============================================================
-- Reuse ops_set_updated_at() function from migration 056

CREATE TRIGGER trg_agencies_updated
  BEFORE UPDATE ON agencies
  FOR EACH ROW EXECUTE FUNCTION ops_set_updated_at();

CREATE TRIGGER trg_agency_staff_updated
  BEFORE UPDATE ON agency_staff
  FOR EACH ROW EXECUTE FUNCTION ops_set_updated_at();

CREATE TRIGGER trg_agency_creators_updated
  BEFORE UPDATE ON agency_creators
  FOR EACH ROW EXECUTE FUNCTION ops_set_updated_at();

CREATE TRIGGER trg_agency_settlements_updated
  BEFORE UPDATE ON agency_settlements
  FOR EACH ROW EXECUTE FUNCTION ops_set_updated_at();

CREATE TRIGGER trg_agency_tax_certificates_updated
  BEFORE UPDATE ON agency_tax_certificates
  FOR EACH ROW EXECUTE FUNCTION ops_set_updated_at();

CREATE TRIGGER trg_agency_notices_updated
  BEFORE UPDATE ON agency_notices
  FOR EACH ROW EXECUTE FUNCTION ops_set_updated_at();

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_agencies_status
  ON public.agencies (status);
CREATE INDEX IF NOT EXISTS idx_agencies_business_number
  ON public.agencies (business_number);

CREATE INDEX IF NOT EXISTS idx_agency_staff_agency
  ON public.agency_staff (agency_id);
CREATE INDEX IF NOT EXISTS idx_agency_staff_user
  ON public.agency_staff (user_id);

CREATE INDEX IF NOT EXISTS idx_agency_creators_agency
  ON public.agency_creators (agency_id);
CREATE INDEX IF NOT EXISTS idx_agency_creators_profile
  ON public.agency_creators (creator_profile_id);
CREATE INDEX IF NOT EXISTS idx_agency_creators_status
  ON public.agency_creators (status);

CREATE INDEX IF NOT EXISTS idx_agency_settlements_agency
  ON public.agency_settlements (agency_id);
CREATE INDEX IF NOT EXISTS idx_agency_settlements_period
  ON public.agency_settlements (period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_agency_settlements_status
  ON public.agency_settlements (status);

-- Prevent duplicate settlements for the same agency + period
CREATE UNIQUE INDEX IF NOT EXISTS uq_agency_settlements_agency_period
  ON public.agency_settlements (agency_id, period_start, period_end)
  WHERE status != 'cancelled';

CREATE INDEX IF NOT EXISTS idx_agency_tax_agency_period
  ON public.agency_tax_certificates (agency_id, year, month);

CREATE INDEX IF NOT EXISTS idx_agency_notices_agency
  ON public.agency_notices (agency_id);
CREATE INDEX IF NOT EXISTS idx_agency_notices_category
  ON public.agency_notices (category);

-- ============================================================
-- STORAGE BUCKET: agency-documents
-- ============================================================
-- Note: Storage bucket creation is typically done via Dashboard
-- or supabase CLI. Included here as documentation / reference.
-- If using CLI: supabase storage create agency-documents --public=false
--
-- Bucket policies should be:
--   READ:  only agency_staff (finance+) for same agency OR ops_staff
--   WRITE: only agency_staff (finance+) for same agency OR ops_staff
--
-- 계약서, 위임장, 세무 증빙 서류 업로드용.
-- Storage path format: {agency_id}/contracts/{contract_id}.pdf
--                      {agency_id}/tax/{year}/{month}/document.pdf
