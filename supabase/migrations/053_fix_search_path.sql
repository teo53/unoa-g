-- =====================================================
-- Migration 052: SECURITY DEFINER 함수에 SET search_path 추가
--
-- 문제: 48+ SECURITY DEFINER 함수에 search_path 미고정
--       → 객체 하이재킹(shadowing) 위험
--
-- 수정: 모든 함수에 SET search_path = public 적용
-- 참고: is_admin(UUID)은 050에서 이미 수정됨
--       026/027/030/035/036/048의 함수는 이미 설정됨
-- =====================================================

-- =====================================================
-- Priority 1: 인증/권한 함수
-- =====================================================

-- 004_user_profiles.sql
ALTER FUNCTION public.handle_new_user() SET search_path = public;

-- 005_creator_profiles.sql
ALTER FUNCTION public.handle_new_creator_profile() SET search_path = public;

-- 014_admin_policies.sql (log_admin_action은 026에서 재정의되어 이미 설정됨)

-- =====================================================
-- Priority 2: 금융/결제 함수
-- =====================================================

-- 006_wallet_ledger.sql
ALTER FUNCTION public.process_wallet_transaction(TEXT, UUID, UUID, INTEGER, TEXT, TEXT, UUID, TEXT, JSONB) SET search_path = public;

-- 010_payment_atomicity.sql
ALTER FUNCTION public.process_payment_atomic(UUID, TEXT, UUID, UUID, INTEGER, INTEGER, INTEGER, TEXT) SET search_path = public;
ALTER FUNCTION public.process_refund_atomic(UUID, TEXT) SET search_path = public;

-- 020_fix_atomic_refund_dt.sql
DO $$ BEGIN
  ALTER FUNCTION public.process_refund_atomic_v2(UUID, TEXT, INTEGER) SET search_path = public;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function process_refund_atomic_v2 does not exist, skipping';
END $$;

-- 021_funding_schema.sql
DO $$ BEGIN
  ALTER FUNCTION public.process_funding_pledge(UUID, UUID, UUID, UUID, INT, INT, TEXT, BOOLEAN, TEXT) SET search_path = public;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function process_funding_pledge does not exist, skipping';
END $$;

-- 039_dt_expiration.sql
ALTER FUNCTION public.process_dt_expiration() SET search_path = public;
ALTER FUNCTION public.get_expiring_dt_summary(UUID, INT) SET search_path = public;

-- 040_campaign_failure_refund.sql (044에서 재정의될 수 있음, 둘 다 적용)
ALTER FUNCTION public.refund_failed_campaign_pledges(UUID) SET search_path = public;
ALTER FUNCTION public.complete_expired_campaigns() SET search_path = public;

-- 041_partial_refund.sql
ALTER FUNCTION public.process_partial_refund_atomic(UUID, INT, TEXT) SET search_path = public;
ALTER FUNCTION public.get_purchase_refund_history(UUID) SET search_path = public;

-- 042_chargeback_handling.sql
ALTER FUNCTION public.process_chargeback(UUID, TEXT, TEXT, INT, TEXT) SET search_path = public;
ALTER FUNCTION public.resolve_chargeback(UUID, TEXT, TEXT) SET search_path = public;
ALTER FUNCTION public.get_active_chargebacks() SET search_path = public;

-- 044_funding_dt_to_krw.sql
ALTER FUNCTION public.process_funding_pledge_krw(UUID, UUID, UUID, INT, INT, TEXT, TEXT, TEXT, TEXT, BOOLEAN, TEXT) SET search_path = public;

-- 045_funding_krw_payments.sql
ALTER FUNCTION public.mark_funding_payment_refunded(UUID, INT, TEXT, TEXT) SET search_path = public;

-- 046_settlement_tax.sql
DO $$ BEGIN
  ALTER FUNCTION public.get_withholding_rate(TEXT) SET search_path = public;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function get_withholding_rate does not exist, skipping';
END $$;
DO $$ BEGIN
  ALTER FUNCTION public.get_creator_tax_info(UUID) SET search_path = public;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function get_creator_tax_info does not exist, skipping';
END $$;

-- 047_funding_refund_krw.sql
ALTER FUNCTION public.queue_campaign_refunds(UUID) SET search_path = public;
ALTER FUNCTION public.complete_funding_refund(UUID, TEXT, JSONB) SET search_path = public;
ALTER FUNCTION public.fail_funding_refund(UUID, TEXT, JSONB) SET search_path = public;

-- 008_payouts.sql
ALTER FUNCTION public.log_payout_status_change() SET search_path = public;
ALTER FUNCTION public.request_payout(UUID, DATE, DATE) SET search_path = public;
ALTER FUNCTION public.approve_payout(UUID, TEXT) SET search_path = public;

-- =====================================================
-- Priority 3: 암호화 함수
-- =====================================================

-- 011_encrypt_sensitive_data.sql
ALTER FUNCTION public.encrypt_sensitive(TEXT, TEXT) SET search_path = public;
ALTER FUNCTION public.decrypt_sensitive(TEXT) SET search_path = public;
ALTER FUNCTION public.mask_sensitive(TEXT, INTEGER) SET search_path = public;
ALTER FUNCTION public.get_creator_payout_info(UUID) SET search_path = public;
ALTER FUNCTION public.update_creator_payout_info(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) SET search_path = public;
ALTER FUNCTION public.log_sensitive_access(UUID, TEXT, TEXT) SET search_path = public;

-- 015_identity_verifications.sql
ALTER FUNCTION public.is_identity_verified(UUID) SET search_path = public;
ALTER FUNCTION public.is_adult_verified(UUID) SET search_path = public;

-- 016_creator_payout_accounts.sql
ALTER FUNCTION public.get_primary_payout_account(UUID) SET search_path = public;
ALTER FUNCTION public.can_request_payout(UUID) SET search_path = public;

-- =====================================================
-- Priority 4: 메시지/채팅 함수
-- =====================================================

-- 003_triggers.sql
ALTER FUNCTION public.refresh_reply_quotas() SET search_path = public;
ALTER FUNCTION public.validate_and_decrement_quota() SET search_path = public;
ALTER FUNCTION public.validate_donation_message() SET search_path = public;
ALTER FUNCTION public.validate_donation_reply() SET search_path = public;
ALTER FUNCTION public.create_broadcast_delivery() SET search_path = public;
ALTER FUNCTION public.enable_fallback_quotas(TIMESTAMPTZ) SET search_path = public;
ALTER FUNCTION public.get_user_chat_thread(UUID, INTEGER, UUID) SET search_path = public;
ALTER FUNCTION public.get_artist_inbox(UUID, TEXT, INTEGER, INTEGER) SET search_path = public;
ALTER FUNCTION public.get_chat_quota_summary(UUID, UUID) SET search_path = public;

-- 007_messages_extended.sql
ALTER FUNCTION public.edit_message(UUID, TEXT, INTEGER) SET search_path = public;
ALTER FUNCTION public.delete_message_for_all(UUID) SET search_path = public;
ALTER FUNCTION public.hide_message_for_me(UUID) SET search_path = public;
ALTER FUNCTION public.pin_message(UUID) SET search_path = public;
ALTER FUNCTION public.update_presence(UUID, BOOLEAN, TEXT) SET search_path = public;

-- 013_optimize_quota_refresh.sql
ALTER FUNCTION public.process_quota_refresh_job(UUID) SET search_path = public;
ALTER FUNCTION public.reset_daily_quotas() SET search_path = public;

-- 024_fix_reply_token_policy.sql
ALTER FUNCTION public.consume_reply_token() SET search_path = public;

-- 028_add_message_reactions.sql
ALTER FUNCTION public.update_reaction_count_on_insert() SET search_path = public;
ALTER FUNCTION public.update_reaction_count_on_delete() SET search_path = public;
ALTER FUNCTION public.get_message_reaction_info(UUID) SET search_path = public;
ALTER FUNCTION public.toggle_message_reaction(UUID, TEXT) SET search_path = public;

-- 029_add_public_share.sql
ALTER FUNCTION public.public_share_message(UUID) SET search_path = public;
ALTER FUNCTION public.unshare_public_message(UUID) SET search_path = public;

-- 033_count_unread_inbox.sql
ALTER FUNCTION public.count_unread_inbox_messages(UUID, UUID) SET search_path = public;

-- =====================================================
-- Priority 5: 모더레이션/리포트 함수
-- =====================================================

-- 009_moderation.sql (027에서 v2 버전이 대체했지만 구버전도 존재할 수 있음)
ALTER FUNCTION public.block_user(UUID, TEXT) SET search_path = public;
ALTER FUNCTION public.unblock_user(UUID) SET search_path = public;
ALTER FUNCTION public.hide_fan(UUID, TEXT) SET search_path = public;
ALTER FUNCTION public.unhide_fan(UUID) SET search_path = public;
ALTER FUNCTION public.create_report(TEXT, UUID, TEXT, TEXT, TEXT[]) SET search_path = public;

-- =====================================================
-- Priority 6: 기타 유틸리티 함수
-- =====================================================

-- 017_payment_webhook_logs.sql
DO $$ BEGIN
  ALTER FUNCTION public.get_webhook_events_for_payment(UUID) SET search_path = public;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function get_webhook_events_for_payment does not exist, skipping';
END $$;
ALTER FUNCTION public.get_failed_webhooks_for_retry(INTEGER) SET search_path = public;
DO $$ BEGIN
  ALTER FUNCTION public.mark_webhook_processed(UUID) SET search_path = public;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function mark_webhook_processed does not exist, skipping';
END $$;

-- 018_user_consents_enhancement.sql
ALTER FUNCTION public.log_consent_change() SET search_path = public;
ALTER FUNCTION public.revoke_all_marketing_consents(UUID, TEXT) SET search_path = public;
ALTER FUNCTION public.get_user_consent_summary(UUID) SET search_path = public;

-- 022_funding_storage.sql
ALTER FUNCTION public.track_storage_usage(UUID, TEXT, TEXT, BIGINT, TEXT, UUID) SET search_path = public;

-- 037_celebration_queue_fix.sql (036에서 이미 설정된 버전과 다를 수 있음)
-- get_celebration_queue는 036에서 SET search_path로 정의되었으므로 skip

-- 043_review_improvements.sql
DO $$ BEGIN
  ALTER FUNCTION public.cleanup_old_webhook_logs() SET search_path = public;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function cleanup_old_webhook_logs does not exist, skipping';
END $$;
DO $$ BEGIN
  ALTER FUNCTION public.get_campaign_review_criteria() SET search_path = public;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'Function get_campaign_review_criteria does not exist, skipping';
END $$;
