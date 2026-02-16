-- =====================================================
-- Sprint 0: Preflight Database Smoke Test
-- Purpose: Verify runtime correctness after db reset
-- Usage: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/preflight_db_smoke.sql
-- =====================================================

-- 0) 함수 정의 내 스키마 불일치 참조 탐지
DO $$
DECLARE
  v_cnt int;
BEGIN
  SELECT count(*) INTO v_cnt
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND (
      pg_get_functiondef(p.oid) ILIKE '%remaining_replies%'
      OR pg_get_functiondef(p.oid) ILIKE '%period_start%'
      OR pg_get_functiondef(p.oid) ILIKE '%period_end%'
    );

  IF v_cnt > 0 THEN
    RAISE WARNING 'Detected % function(s) still referencing remaining_replies/period_* (likely pre-patch 013). Run WI-1C (070 patch) first.', v_cnt;
  ELSE
    RAISE NOTICE 'OK: No function definitions reference remaining_replies/period_*';
  END IF;
END $$;

-- 1) 필수 함수 존재 확인
SELECT 'process_payment_atomic' AS required_fn, EXISTS (
  SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='process_payment_atomic'
) AS exists;

SELECT 'toggle_message_reaction' AS required_fn, EXISTS (
  SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='toggle_message_reaction'
) AS exists;

-- 2) reply_quota 핵심 컬럼 존재 확인
DO $$
DECLARE ok boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='reply_quota' AND column_name='tokens_available'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='reply_quota' AND column_name='tokens_used'
  ) INTO ok;

  IF ok THEN RAISE NOTICE 'OK: reply_quota tokens_* columns exist';
  ELSE RAISE WARNING 'reply_quota tokens_* columns missing (schema drift)';
  END IF;
END $$;

-- 3) message_delivery RLS 정책 상태 확인
DO $$
DECLARE
  v_insert_count int;
BEGIN
  SELECT count(*) INTO v_insert_count
  FROM pg_policies
  WHERE tablename = 'message_delivery'
    AND cmd = 'a'; -- 'a' = INSERT (ALL)

  RAISE NOTICE 'message_delivery INSERT policies count: % (expect 1 after WI-1A)', v_insert_count;
END $$;

-- 4) dt_donations idempotency_key 컬럼 존재 확인
DO $$
DECLARE ok boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='dt_donations' AND column_name='idempotency_key'
  ) INTO ok;

  IF ok THEN RAISE NOTICE 'OK: dt_donations.idempotency_key exists';
  ELSE RAISE NOTICE 'INFO: dt_donations.idempotency_key missing (expected before WI-1B)';
  END IF;
END $$;

-- 5) rate_limit RPC 존재 확인
SELECT 'check_and_increment_rate_limit' AS required_fn, EXISTS (
  SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='check_and_increment_rate_limit'
) AS exists;
