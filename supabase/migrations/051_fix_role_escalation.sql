-- =====================================================
-- Migration 050: Role Escalation 차단
--
-- 문제: user_profiles UPDATE 정책이 role 컬럼 변경을 막지 않아
--       일반 유저가 스스로 admin으로 승격 가능.
--       admin_users 테이블은 049에서 참조하지만 생성된 적 없음.
--
-- 수정:
--   1. admin_users 테이블 생성
--   2. BEFORE UPDATE 트리거로 보호 필드 변경 차단
--   3. is_admin() 함수를 admin_users 기반으로 재작성
-- =====================================================

-- =====================================================
-- 1. admin_users 테이블 생성
-- 049_security_fixes.sql에서 이미 참조하고 있으므로 반드시 필요
-- =====================================================

CREATE TABLE IF NOT EXISTS public.admin_users (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  granted_by UUID REFERENCES auth.users(id),
  granted_at TIMESTAMPTZ DEFAULT now(),
  notes TEXT
);

ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- admin 자신의 레코드만 조회 가능
CREATE POLICY admin_users_self_select ON admin_users
  FOR SELECT
  USING (auth.uid() = user_id);

-- INSERT/UPDATE/DELETE는 RLS로 모두 차단 — service_role만 가능
CREATE POLICY admin_users_deny_insert ON admin_users
  FOR INSERT WITH CHECK (false);

CREATE POLICY admin_users_deny_update ON admin_users
  FOR UPDATE USING (false);

CREATE POLICY admin_users_deny_delete ON admin_users
  FOR DELETE USING (false);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_admin_users_granted_at ON admin_users(granted_at);

-- =====================================================
-- 2. BEFORE UPDATE 트리거: 보호 필드 변경 차단
-- service_role이 아닌 호출에서 role, is_banned 등 변경 방지
-- =====================================================

CREATE OR REPLACE FUNCTION public.protect_user_profile_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  jwt_role TEXT;
BEGIN
  -- JWT의 role 클레임 확인 (Supabase에서 service_role은 'service_role')
  jwt_role := coalesce(
    current_setting('request.jwt.claim.role', true),
    current_setting('role', true),
    'anon'
  );

  -- service_role이 아니면 보호 필드를 원래 값으로 강제 복원
  IF jwt_role IS DISTINCT FROM 'service_role' THEN
    NEW.role := OLD.role;
    NEW.is_banned := OLD.is_banned;
    NEW.banned_at := OLD.banned_at;
    NEW.ban_reason := OLD.ban_reason;
    NEW.ban_expires_at := OLD.ban_expires_at;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_user_profile_fields_trigger ON user_profiles;
CREATE TRIGGER protect_user_profile_fields_trigger
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION protect_user_profile_fields();

-- =====================================================
-- 3. is_admin() 함수 재작성
-- user_profiles.role 대신 admin_users 테이블 기반
-- search_path 고정 추가
-- =====================================================

CREATE OR REPLACE FUNCTION public.is_admin(p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM admin_users WHERE user_id = p_user_id
  );
END;
$$;

-- 기존 권한 유지
GRANT EXECUTE ON FUNCTION public.is_admin(UUID) TO authenticated;

-- =====================================================
-- 4. 기존 admin role 사용자를 admin_users로 마이그레이션
-- 이미 user_profiles.role='admin'인 사용자가 있다면 옮김
-- =====================================================

INSERT INTO admin_users (user_id, notes)
SELECT id, 'Migrated from user_profiles.role=admin'
FROM user_profiles
WHERE role = 'admin'
ON CONFLICT (user_id) DO NOTHING;
