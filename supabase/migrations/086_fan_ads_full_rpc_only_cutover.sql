-- ============================================================
-- Migration 086: fan_ads full RPC-only cutover
-- ============================================================
-- 적용 시점:
--   - 앱 배포 후 7일 경과 OR 신규 버전 활성 세션 95% 도달 중 먼저 충족
--
-- 목적:
--   - authenticated 직접 UPDATE 경로를 완전히 폐쇄하고
--   - fan_ads 상태 변경을 RPC 경로로만 강제
-- ============================================================

-- 방어적으로 기존 UPDATE 정책 제거
DROP POLICY IF EXISTS fan_ads_own_update ON public.fan_ads;
DROP POLICY IF EXISTS fan_ads_ops_update ON public.fan_ads;

-- 테이블 직접 UPDATE 권한 회수
REVOKE UPDATE ON public.fan_ads FROM authenticated;

