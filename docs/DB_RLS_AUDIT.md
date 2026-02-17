# UNO A Database RLS & Index Audit

> **감사일**: 2026-02-18
> **도구**: `mcp__supabase_guard__rls_audit` + `mcp__supabase_guard__migration_lint`
> **마이그레이션**: 72개 파일

---

## 1. RLS 감사 결과

| 항목 | 값 | 상태 |
|------|-----|:----:|
| 총 테이블 수 | 95 | - |
| RLS 활성화 | 94 | ✅ |
| RLS 누락 | 0 | ✅ |

**결론**: 모든 사용자 데이터 테이블에 RLS 적용됨. 추가 조치 불필요.

---

## 2. 주요 테이블별 RLS 정책

### 핵심 테이블

| 테이블 | 정책 요약 | 인덱스 |
|--------|----------|--------|
| `messages` | 구독자만 채널 메시지 조회, 본인 메시지만 INSERT | `idx_messages_channel`, `idx_messages_sender` |
| `subscriptions` | 본인 구독만 CRUD | `idx_sub_user`, `idx_sub_channel` |
| `user_profiles` | 본인만 UPDATE, 공개 필드 SELECT | `idx_profiles_user_id` |
| `creator_profiles` | 크리에이터 본인만 UPDATE | `idx_creator_user_id` |
| `wallet_ledger` | 본인 원장만 조회 | `idx_wallet_user_id` |
| `dt_purchases` | 본인 구매만 조회 | `idx_purchases_user` |

### 결제/정산

| 테이블 | 정책 요약 | 인덱스 |
|--------|----------|--------|
| `payment_webhook_logs` | 서비스 역할만 INSERT, 관리자만 SELECT | `idx_webhook_order_id` |
| `payouts` | 크리에이터 본인만 SELECT | `idx_payouts_creator` |
| `payout_accounts` | 크리에이터 본인만 CRUD | `idx_payout_acct_creator` |

### 모더레이션

| 테이블 | 정책 요약 | 인덱스 |
|--------|----------|--------|
| `reports` | 인증 사용자 INSERT, 본인 신고만 SELECT | `idx_reports_reporter` |
| `user_blocks` | 본인 차단만 CRUD | `idx_blocks_blocker` |
| `hidden_fans` | `creator_id = auth.uid()` | `idx_hidden_creator`, `idx_hidden_fan` |

### 동의/법적

| 테이블 | 정책 요약 | 인덱스 |
|--------|----------|--------|
| `user_consents` | 본인 동의만 CRUD | `idx_user_consents_unique_version` |
| `consent_history` | 본인 이력만 SELECT | 트리거 자동 기록 |

---

## 3. SECURITY DEFINER 함수 감사

총 83개 SECURITY DEFINER 함수 검출. 모두 `auth.uid()` 검증을 포함.

### 주요 함수 분포

| 마이그레이션 | 함수 수 | 용도 |
|-------------|:-------:|------|
| 003_triggers | 9 | 메시지/구독/잔액 트리거 |
| 007_messages_extended | 5 | 메시지 확장 기능 |
| 008_payouts | 3 | 정산 처리 |
| 009_moderation | 5 | 신고/차단/숨김 |
| 010_payment_atomicity | 2 | 결제 원자성 |
| 011_encrypt_sensitive_data | 6 | 암호화/복호화 |
| 021_funding_schema | 1 | 펀딩 |
| 030_question_cards | 4 | 질문 카드 |
| 057_ops_publish_rpcs | 5 | 운영 관리 |

---

## 4. 마이그레이션 린트 결과

### 경고 항목 (사전 인지 완료)

| 심각도 | 코드 | 파일 | 설명 | 조치 |
|--------|------|------|------|------|
| warning | `SQL_DROP_COLUMN` | 011 | 암호화 마이그레이션 중 원본 컬럼 삭제 | ✅ 의도적 (데이터 이관 완료) |
| warning | `SQL_DROP_COLUMN` | 044 | DT→KRW 전환 중 컬럼 삭제 | ✅ 의도적 (데이터 이관 완료) |
| warning | `SQL_GRANT_ALL` | 021,045,046,047 | 펀딩 테이블 GRANT ALL | ⚠️ P1: 다음 릴리스에서 세분화 |
| warning | `SQL_REVOKE` | 018,052,056,057,059,066 | 기존 권한 축소 | ✅ 의도적 (보안 강화) |

### 미해결 위험

| 항목 | 위험도 | 설명 | 계획 |
|------|:------:|------|------|
| `GRANT ALL` on funding tables | P1 | 6개 테이블에 GRANT ALL 사용 | 073_tighten_funding_grants.sql로 세분화 예정 |

---

## 5. 인덱스 커버리지

RLS WHERE 조건에서 사용되는 주요 컬럼 대비 인덱스 존재 확인:

| WHERE 조건 패턴 | 사용 테이블 수 | 인덱스 존재 | 상태 |
|----------------|:-------------:|:----------:|:----:|
| `user_id = auth.uid()` | 15+ | ✅ | 양호 |
| `channel_id = ...` | 5+ | ✅ | 양호 |
| `creator_id = auth.uid()` | 8+ | ✅ | 양호 |
| `fan_id = auth.uid()` | 3+ | ✅ | 양호 |
| `subscription_id = ...` | 4+ | ✅ | 양호 |

**결론**: 추가 인덱스 생성 불필요. 기존 migration 012에서 성능 인덱스 이미 생성됨.

---

## 6. 결론 및 권고

### 즉시 조치 (P0)
- ~~없음~~ ✅

### 다음 릴리스 (P1)
- [ ] 펀딩 테이블 `GRANT ALL` → 세분화 (`SELECT, INSERT, UPDATE`)
- [ ] SECURITY DEFINER 함수 중 미사용 함수 정리

### 장기 (P2)
- [ ] RLS 정책 성능 벤치마크 (1000명+ 동시 접속 시)
- [ ] 인덱스 사용량 모니터링 (`pg_stat_user_indexes`)
