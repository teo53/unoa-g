# UI/약관/문서 문구 전수 인벤토리 및 수정안

> 작성일: 2026-02-16
> 근거: `tax,law/deep-research-report (2).md` 컴플라이언스 보고서
> 목적: 통신판매업자(총매법) 모델 정합성 확보 + 전자지급업 오인 완전 제거

---

## 1. 금칙어 세트 (전수 제거 대상)

| # | 금칙어 | 대체어 | 이유 |
|---|--------|--------|------|
| 1 | 선불전자지급수단 | 서비스 전용 디지털 이용권 | 전자금융거래법 분류 오인 |
| 2 | 전자금융거래법 / 전자금융거래 | (삭제) 또는 전자상거래법 | 잘못된 법적 근거 |
| 3 | DT 충전 | DT 구매 | "예치/충전" 전자지급 프레이밍 제거 |
| 4 | 충전하기 | DT 구매 | 동일 |
| 5 | 선불 충전 크레딧 | 서비스 전용 디지털 이용권 | 법적 분류 오인 제거 |
| 6 | 출금 | 정산 지급 / 지급 신청 | "환전/현금화" 연상 제거 |
| 7 | DT가 충전되었습니다 | DT 구매가 완료되었습니다 | 팬/크리에이터 "지급" 충돌 방지 |
| 8 | 연 15% (UI/약관) | 대통령령이 정하는 지연이자율 | 시행령 개정 시 "허위 고지" 리스크 |

---

## 2. 전수 인벤토리

### 2.1 lib/ (Dart UI 코드)

| 파일 | 라인 | 현행 문구 | 수정안 |
|------|------|----------|--------|
| `wallet/wallet_screen.dart` | L138 | `'충전하기'` | `'DT 구매'` |
| `wallet/wallet_screen.dart` | L196 | `'선불 충전 크레딧'` | `'서비스 전용 디지털 이용권'` |
| `wallet/wallet_screen.dart` | L219 | `'DT 충전'` | `'DT 구매'` |
| `wallet/dt_charge_screen.dart` | L47 | `'DT 충전'` | `'DT 구매'` |
| `wallet/dt_charge_screen.dart` | L74 | `'충전할 금액을 선택하세요'` | `'구매할 금액을 선택하세요'` |
| `wallet/dt_charge_screen.dart` | L160 | `'선불전자지급수단(선불 크레딧)으로'` | `'서비스 전용 디지털 이용권으로'` |
| `wallet/dt_charge_screen.dart` | L163 | `'(전자금융거래법)'` | `'(서비스 정책)'` |
| `wallet/dt_charge_screen.dart` | L225 | `'DT 충전 시'` | `'DT 구매 시'` |
| `wallet/dt_charge_screen.dart` | L285 | `'충전 완료'` | `'구매 완료'` |
| `wallet/dt_charge_screen.dart` | L289 | `'DT가 충전되었습니다!'` | `'DT 구매가 완료되었습니다!'` |
| `wallet/transaction_history_screen.dart` | L98 | `Tab(text: '충전')` | `Tab(text: '구매')` |
| `wallet/transaction_history_screen.dart` | L427 | `'충전 후 7일 이내'` | `'구매 후 7일 이내'` |
| `wallet/transaction_history_screen.dart` | L473 | `'충전 후 7일이 경과'` | `'구매 후 7일이 경과'` |
| `wallet/transaction_history_screen.dart` | L500 | `'DT 충전 내역'` | `'DT 구매 내역'` |
| `settings/terms_screen.dart` | L76 | `'선불 충전 크레딧'` | `'서비스 전용 디지털 이용권'` |
| `settings/terms_screen.dart` | L88 | `'선불 충전 크레딧'` | `'서비스 전용 디지털 이용권'` |
| `settings/terms_screen.dart` | L89 | `'DT 충전 시'` | `'DT 구매 시'` |
| `settings/fee_policy_screen.dart` | L64 | `'DT 충전', '무료', '결제 금액 = 충전 금액'` | `'DT 구매', '무료', '결제 금액 = 구매 금액'` |
| `settings/refund_policy_screen.dart` | L63 | `'선불전자지급수단(선불 크레딧)'` | `'서비스 전용 디지털 이용권'` |
| `settings/refund_policy_screen.dart` | L68 | `'전자금융거래법에 따릅니다'` | `'서비스 정책에 따릅니다'` |
| `settings/refund_policy_screen.dart` | L166 | `'전자금융거래법'` | 삭제 |
| `payment/widgets/payment_consent_form.dart` | L28 | `'전자금융거래 이용약관'` | `'결제대행 서비스 이용약관'` |
| `payment/widgets/payment_consent_form.dart` | L27 | `'PG 서비스 이용약관'` | `'결제대행 서비스 이용약관'` |
| `notifications/notifications_screen.dart` | L88 | `'DT 충전 완료'` | `'DT 구매 완료'` |
| `notifications/notifications_screen.dart` | L89 | `'DT가 충전되었습니다'` | `'DT 구매가 완료되었습니다'` |
| `help/help_center_screen.dart` | L105 | `'DT 충전 및 사용'` | `'DT 구매 및 사용'` |
| `help/help_center_screen.dart` | L107 | `'DT는 어떻게 충전하나요?'` | `'DT는 어떻게 구매하나요?'` |
| `creator/creator_dashboard_screen.dart` | L451 | `'출금'` | `'정산 지급'` |
| `creator/creator_crm_screen.dart` | L192 | `'출금'` | `'정산 지급'` |
| `creator/creator_crm_screen.dart` | L241 | `'출금'` | `'정산 지급'` |
| `creator/creator_crm_screen.dart` | L242 | `'수익을 출금하고'` | `'수익을 지급받고'` |
| `creator/creator_profile_screen.dart` | L82 | `'출금'` | `'정산 지급'` |
| `creator/creator_profile_screen.dart` | L107 | `'DT 충전'` | `'DT 구매'` |
| `creator/widgets/crm_withdrawal_tab.dart` | ~20개소 | 모든 `'출금'` | `'지급'` 계열 |
| `creator/widgets/crm_revenue_tab.dart` | L203 | `'출금 가능'` | `'지급 가능'` |
| `providers/wallet_provider.dart` | L131 | `'충전'` | `'구매'` |
| `providers/wallet_provider.dart` | L141 | `'출금'` | `'정산 지급'` |
| `providers/wallet_provider.dart` | L317 | `'DT 충전'` | `'DT 구매'` |
| `providers/wallet_provider.dart` | L398 | `'충전 시뮬레이션'` | `'구매 시뮬레이션'` |
| `providers/wallet_provider.dart` | L417 | `'DT 충전 (데모)'` | `'DT 구매 (데모)'` |
| `data/repositories/supabase_wallet_repository.dart` | L143 | `'DT 충전'` | `'DT 구매'` |
| `data/mock/mock_data.dart` | L318 | `'DT 충전 (스탠다드)'` | `'DT 구매 (스탠다드)'` |
| `shared/widgets/error_boundary.dart` | L392 | `'DT를 충전하거나'` | `'DT를 구매하거나'` |

### 2.2 docs/audit/ (감사 문서)

| 파일 | 수정 건수 | 비고 |
|------|----------|------|
| `00-executive-summary.md` | 2건 | 선불식 결제수단, 충전금 |
| `02-user-journeys-and-ux-gaps.md` | ~19건 | DT 충전 전체 교체 |
| `04-security-privacy-payments-audit.md` | 1건 | L505 전자금융거래법 |
| `05-ops-admin-moderation-audit.md` | 2건 | L450, L466 DT 충전 |
| `06-legal-tax-checklist.md` | ~57건 | 전면 재작성 필요 |
| `08-prd-spec-deltas.md` | 1건 | L152 DT 충전 결제 |
| `10-open-questions.md` | 3건 | Q12 선불전자지급수단 |

### 2.3 docs/legal/

| 파일 | 수정 건수 | 비고 |
|------|----------|------|
| `tax_classification_guide.md` | 전면 교체 | 총매법 모델로 재작성 |
| `payment_consent_requirements.md` | 2건 | 전자금융거래법 참조 |

### 2.4 docs/ux/

| 파일 | 수정 건수 | 비고 |
|------|----------|------|
| `01_customer_journey.md` | 2건 | DT 충전 |
| `02_information_architecture.md` | 2건 | DT 충전 |
| `05_instrumentation.md` | 2건 | DT 충전 이벤트명 |
| `06_review_checklist.md` | 1건 | DT 충전 |

### 2.5 supabase/

| 파일 | 수정 건수 | 비고 |
|------|----------|------|
| `functions/payment-checkout/index.ts` | 1건 | 선불전자지급수단 충전 과세 주석 |
| `migrations/039_dt_expiration.sql` | 2건 | 전자금융거래법 주석 |
| `migrations/010_payment_atomicity.sql` | 1건 | DT 충전 문자열 |

### 2.6 기타

| 파일 | 수정 건수 | 비고 |
|------|----------|------|
| `test/data/models/transaction_test.dart` | 3건 | DT 충전 테스트 문자열 |
| `README.md` | 1건 | DT 충전 패키지 |
| `CLAUDE.md` | 1건 | 출금 |
| `stitch/uno_a_wallet_&_dt_screen/code.html` | 2건 | 충전하기, DT 충전 |
| `tools/unoa-review-mcp/checklists/uiux.md` | 1건 | 충전 |
| `docs/BETA_TESTING.md` | 1건 | DT 충전 |

### 2.7 변경 제외

| 파일 | 이유 |
|------|------|
| `tax,law/deep-research-report (2).md` | 원본 보고서, 수정 대상 아님 |
| `token_explanation_sheet.dart` L71 | "답글 토큰 3개가 충전됩니다" — DT 무관 |
| `premium_shimmer.dart` 주석 | 내부 코드 주석 |
| DB 컬럼명 (`charge_dt` 등) | 스키마 변경 불포함 |

---

## 3. 수정 총계

| 카테고리 | 파일 수 | 총 수정 건수 |
|----------|---------|-------------|
| lib/ (Dart) | ~21 | ~85건 |
| docs/audit/ | 7 | ~85건 |
| docs/legal/ | 2 | 전면교체+2건 |
| docs/ux/ | 4 | 7건 |
| supabase/ | 3 | 4건 |
| 기타 (test/README/CLAUDE/stitch/tools) | 5 | 8건 |
| **합계** | **~42 수정 + ~10 신규** | **~190건+** |
