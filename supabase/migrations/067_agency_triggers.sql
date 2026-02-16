-- ============================================================
-- 067: Agency Triggers & Additional RLS
-- ============================================================
-- Supplements 066_agency_schema.sql with:
-- - agency_id auto-sync trigger
-- - exclusive contract validation
-- - creator self-service contract acceptance (RPC)
-- - additional RLS policies for contract workflow
-- ============================================================

-- ============================================================
-- TRIGGER FUNCTIONS
-- ============================================================

-- ────────────────────────────────────────────────
-- T1. sync_creator_agency_id — Auto-sync agency_id
-- ────────────────────────────────────────────────
-- NOTE: This runs as SECURITY DEFINER in trigger context.
-- auth.uid() returns the user who performed the DML on agency_creators.
-- We do NOT filter by user_id here because:
--   - Agency staff (not the creator) may update contract status
--   - The trigger must work regardless of who performs the status change
--   - RLS on agency_creators already guards who can UPDATE
CREATE OR REPLACE FUNCTION public.sync_creator_agency_id()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- When contract becomes active, set creator_profiles.agency_id
  IF NEW.status = 'active' AND (OLD IS NULL OR OLD.status != 'active') THEN
    UPDATE creator_profiles
    SET agency_id = NEW.agency_id,
        updated_at = now()
    WHERE id = NEW.creator_profile_id;
  END IF;

  -- When contract is terminated or paused from active, clear agency_id
  -- (only if no other active contracts exist for this creator)
  IF OLD IS NOT NULL AND OLD.status = 'active' AND NEW.status IN ('terminated', 'paused') THEN
    UPDATE creator_profiles
    SET agency_id = NULL,
        updated_at = now()
    WHERE id = NEW.creator_profile_id
      AND NOT EXISTS (
        SELECT 1
        FROM agency_creators ac
        WHERE ac.creator_profile_id = NEW.creator_profile_id
          AND ac.status = 'active'
          AND ac.id != NEW.id
      );
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.sync_creator_agency_id IS
  'agency_creators 상태 변경 시 creator_profiles.agency_id 자동 동기화. active→설정, terminated/paused→NULL(다른 active 없을 때).';

-- ────────────────────────────────────────────────
-- T2. validate_exclusive_agency_contract — 1 active contract only
-- ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.validate_exclusive_agency_contract()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing_agency UUID;
BEGIN
  -- Skip validation if not setting to 'active'
  IF NEW.status != 'active' THEN
    RETURN NEW;
  END IF;

  -- Check for other active contracts
  SELECT agency_id INTO v_existing_agency
  FROM agency_creators
  WHERE creator_profile_id = NEW.creator_profile_id
    AND status = 'active'
    AND id != NEW.id
  LIMIT 1;

  IF v_existing_agency IS NOT NULL THEN
    RAISE EXCEPTION '크리에이터는 동시에 여러 에이전시와 활성 계약을 맺을 수 없습니다. 기존 계약을 해지한 후 다시 시도하세요.'
      USING HINT = 'exclusive_contract_violation',
            ERRCODE = '23505';
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.validate_exclusive_agency_contract IS
  '크리에이터가 동시에 여러 에이전시와 활성 계약을 맺는 것을 방지. 1개의 active 계약만 허용.';

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================

-- ────────────────────────────────────────────────
-- F1. accept_agency_contract — Creator self-service acceptance
-- ────────────────────────────────────────────────
-- Called by the creator to accept or reject an agency contract invitation.
-- Only works on contracts in 'pending' status.
-- Uses 066's log_agency_audit(p_agency_id, ...) signature.
CREATE OR REPLACE FUNCTION public.accept_agency_contract(
  p_contract_id UUID,
  p_accept BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_contract RECORD;
  v_creator_profile_id UUID;
  v_new_status TEXT;
  v_result JSONB;
BEGIN
  -- Fetch contract
  SELECT * INTO v_contract
  FROM agency_creators
  WHERE id = p_contract_id;

  IF v_contract IS NULL THEN
    RAISE EXCEPTION '계약을 찾을 수 없습니다.'
      USING ERRCODE = '22000';
  END IF;

  -- Validate current user is the creator who owns this profile
  SELECT id INTO v_creator_profile_id
  FROM creator_profiles
  WHERE id = v_contract.creator_profile_id
    AND user_id = auth.uid();

  IF v_creator_profile_id IS NULL THEN
    RAISE EXCEPTION '이 계약을 수락/거부할 권한이 없습니다.'
      USING ERRCODE = '42501';
  END IF;

  -- Check contract is in acceptable state (only 'pending')
  -- Note: agency_creators.status CHECK is ('pending', 'active', 'paused', 'terminated')
  IF v_contract.status != 'pending' THEN
    RAISE EXCEPTION '현재 상태에서는 계약을 수락/거부할 수 없습니다. (현재 상태: %)', v_contract.status
      USING ERRCODE = '22000';
  END IF;

  -- Determine new status
  IF p_accept THEN
    v_new_status := 'active';
  ELSE
    v_new_status := 'terminated';
  END IF;

  -- Update contract status
  -- Note: agency_creators has no signed_at/terminated_at columns;
  -- updated_at tracks the last modification timestamp
  UPDATE agency_creators
  SET status = v_new_status,
      updated_at = now()
  WHERE id = p_contract_id;

  -- Log audit using 066's log_agency_audit(p_agency_id, ...) signature
  PERFORM log_agency_audit(
    p_agency_id   => v_contract.agency_id,
    p_action      => CASE WHEN p_accept THEN 'contract_accepted' ELSE 'contract_rejected' END,
    p_entity_type => 'agency_creators',
    p_entity_id   => p_contract_id,
    p_before      => jsonb_build_object(
      'status', v_contract.status
    ),
    p_after       => jsonb_build_object(
      'status', v_new_status
    ),
    p_metadata    => jsonb_build_object(
      'accepted', p_accept,
      'creator_profile_id', v_creator_profile_id
    )
  );

  -- Build result
  v_result := jsonb_build_object(
    'success', true,
    'contract_id', p_contract_id,
    'status', v_new_status,
    'accepted', p_accept
  );

  RETURN v_result;
END;
$$;

COMMENT ON FUNCTION public.accept_agency_contract IS
  '크리에이터가 에이전시 계약 초대를 수락/거부. status: pending → active|terminated.';

-- ============================================================
-- ADDITIONAL RLS POLICIES
-- ============================================================

-- ── agency_creators: creator can view own contracts ──
-- Allows creators to see contracts where they are the subject,
-- even before they accept (for the acceptance UI).
CREATE POLICY "agency_creators_select_own_creator" ON public.agency_creators
  FOR SELECT USING (
    creator_profile_id IN (
      SELECT id
      FROM creator_profiles
      WHERE user_id = auth.uid()
    )
  );

-- ── agencies: authenticated users can view active agencies ──
-- Needed for the contract acceptance UI to show agency name/logo
-- when a creator receives a contract invitation.
CREATE POLICY "agencies_select_for_creator" ON public.agencies
  FOR SELECT USING (
    status = 'active'
    AND auth.uid() IS NOT NULL
  );

-- ============================================================
-- TRIGGER REGISTRATIONS
-- ============================================================

-- ── sync_creator_agency_id trigger ──
DROP TRIGGER IF EXISTS trg_sync_creator_agency_id ON public.agency_creators;
CREATE TRIGGER trg_sync_creator_agency_id
  AFTER INSERT OR UPDATE OF status ON public.agency_creators
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_creator_agency_id();

-- ── validate_exclusive_agency_contract trigger ──
DROP TRIGGER IF EXISTS trg_validate_exclusive_contract ON public.agency_creators;
CREATE TRIGGER trg_validate_exclusive_contract
  BEFORE INSERT OR UPDATE ON public.agency_creators
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_exclusive_agency_contract();

-- ============================================================
-- COMMENTS ON TRIGGERS
-- ============================================================
COMMENT ON TRIGGER trg_sync_creator_agency_id ON public.agency_creators IS
  'agency_creators 상태 변경 시 creator_profiles.agency_id를 자동으로 동기화.';

COMMENT ON TRIGGER trg_validate_exclusive_contract ON public.agency_creators IS
  '크리에이터가 동시에 여러 에이전시와 활성 계약을 맺는 것을 방지 (배타적 계약 규칙).';

-- ============================================================
-- END OF MIGRATION 067
-- ============================================================
