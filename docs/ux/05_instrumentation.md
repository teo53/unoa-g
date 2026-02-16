# 05. Instrumentation Plan

> UNO A -- 이벤트 추적 설계
> 최종 수정: 2026-02-08

---

## 1. 이벤트 네이밍 규칙

```
{category}_{action}_{detail}

category: auth, message, funding, dashboard, nav, subscription, onboarding
action:   shown, clicked, sent, completed, started, toggled, dismissed
detail:   (선택) 구체적 대상
```

모든 이벤트에 공통 속성:
- `timestamp`: ISO 8601
- `user_id`: 사용자 ID (비로그인 시 anonymous)
- `session_id`: 세션 식별자
- `platform`: web / android / ios
- `is_demo`: boolean (데모 모드 여부)

---

## 2. Authentication Events

| 이벤트 | 속성 | 트리거 시점 |
|--------|------|------------|
| `auth_gate_shown` | `reason` (message_send, funding_checkout, subscribe, profile_view), `screen` (현재 화면 경로) | 비로그인 사용자가 보호 행동 시도 시 |
| `auth_gate_action` | `action` (login, register, demo, dismiss), `reason` (게이트 표시 이유) | Auth Gate 바텀시트에서 선택 시 |
| `login_completed` | `method` (email, social, demo) | 로그인 성공 |
| `logout_completed` | - | 로그아웃 완료 |
| `demo_mode_entered` | `source` (auth_gate, login_screen, home_banner) | 데모 모드 진입 |

---

## 3. Registration Events

| 이벤트 | 속성 | 트리거 시점 |
|--------|------|------------|
| `registration_started` | `source` (auth_gate, login_screen, direct) | 회원가입 화면 진입 |
| `registration_step_completed` | `step_number` (1, 2), `step_name` (basic_info, preferences) | 각 단계 완료 |
| `registration_completed` | `method` (email, social), `total_duration_ms` | 가입 완료 |
| `registration_abandoned` | `step_number`, `last_field_filled` | 가입 중단 (이탈) |

---

## 4. Message Events

| 이벤트 | 속성 | 트리거 시점 |
|--------|------|------------|
| `message_sent` | `channel_id`, `delivery_scope` (broadcast, directReply, donationMessage), `char_count`, `has_media` | 메시지 전송 완료 |
| `message_send_failed` | `channel_id`, `error_reason` (no_token, no_auth, network, unknown) | 메시지 전송 실패 |
| `message_read` | `channel_id`, `message_id`, `delivery_scope` | 메시지 읽음 처리 |
| `reply_token_used` | `channel_id`, `remaining_tokens`, `subscription_tier` | 답글 토큰 사용 |
| `token_explanation_shown` | `channel_id`, `trigger` (first_visit, token_depleted, manual) | 토큰 설명 바텀시트 표시 |
| `heart_reaction_sent` | `channel_id`, `message_id`, `sender_role` (creator) | 하트 반응 전송 (크리에이터) |

---

## 5. Funding Events

| 이벤트 | 속성 | 트리거 시점 |
|--------|------|------------|
| `funding_campaign_viewed` | `campaign_id`, `creator_id`, `current_progress_pct` | 캠페인 상세 조회 |
| `funding_checkout_started` | `campaign_id`, `amount_dt`, `reward_tier` | 결제 프로세스 시작 |
| `funding_checkout_completed` | `campaign_id`, `amount_dt`, `reward_tier`, `payment_method` | 결제 완료 |
| `funding_checkout_failed` | `campaign_id`, `error_reason` (no_auth, insufficient_dt, network) | 결제 실패 |
| `funding_campaign_created` | `campaign_id`, `goal_amount`, `duration_days`, `reward_count` | 캠페인 생성 (크리에이터) |

---

## 6. Navigation Events

| 이벤트 | 속성 | 트리거 시점 |
|--------|------|------------|
| `tab_switched` | `from_tab`, `to_tab`, `role` (fan, creator) | 하단 탭 전환 |
| `screen_viewed` | `screen_name`, `route_path`, `referrer` | 화면 진입 |
| `deep_link_opened` | `url`, `resolved_route`, `success` | 딥링크 진입 |

---

## 7. Subscription Events

| 이벤트 | 속성 | 트리거 시점 |
|--------|------|------------|
| `subscription_started` | `channel_id`, `tier` (BASIC, STANDARD, VIP), `price_krw` | 구독 시작 |
| `subscription_tier_changed` | `channel_id`, `from_tier`, `to_tier` | 티어 변경 |
| `subscription_cancelled` | `channel_id`, `tier`, `subscription_days`, `cancel_reason` | 구독 취소 |
| `subscription_renewed` | `channel_id`, `tier`, `total_months` | 구독 자동 갱신 |

---

## 8. Dashboard Events (Creator)

| 이벤트 | 속성 | 트리거 시점 |
|--------|------|------------|
| `dashboard_section_toggled` | `section` (revenue, subscribers, messages, campaigns), `expanded` (boolean) | 섹션 접기/펼치기 |
| `dashboard_metric_viewed` | `metric_name`, `time_range` (daily, weekly, monthly) | 지표 확인 |
| `crm_fan_profile_viewed` | `fan_id`, `subscription_tier`, `subscription_days` | 팬 프로필 상세 조회 |

---

## 9. Wallet Events

| 이벤트 | 속성 | 트리거 시점 |
|--------|------|------------|
| `dt_charge_started` | `amount_krw`, `payment_method` | DT 구매 시작 |
| `dt_charge_completed` | `amount_krw`, `amount_dt`, `payment_method` | 구매 완료 |
| `dt_spent` | `amount_dt`, `spend_type` (donation, subscription, funding), `recipient_id` | DT 사용 |

---

## 10. Onboarding Events

| 이벤트 | 속성 | 트리거 시점 |
|--------|------|------------|
| `onboarding_banner_shown` | `banner_type` (value_prop, first_subscribe, explore_cta) | 배너 노출 |
| `onboarding_banner_clicked` | `banner_type`, `target_route` | 배너 클릭 |
| `onboarding_banner_dismissed` | `banner_type` | 배너 닫기 |
| `guest_profile_login_clicked` | - | 게스트 프로필에서 로그인 버튼 |

---

## 11. 구현 우선순위

### Phase 1 (MVP)

핵심 퍼널 이벤트:

1. `auth_gate_shown` / `auth_gate_action`
2. `registration_step_completed` / `registration_completed`
3. `message_sent` / `message_send_failed`
4. `subscription_started` / `subscription_cancelled`
5. `funding_checkout_started` / `funding_checkout_completed`

### Phase 2

사용자 행동 분석:

6. `token_explanation_shown`
7. `dashboard_section_toggled`
8. `tab_switched` / `screen_viewed`
9. `dt_charge_completed` / `dt_spent`

### Phase 3

최적화 및 이탈 분석:

10. `registration_abandoned`
11. `onboarding_banner_shown` / `onboarding_banner_clicked`
12. Deep link / referrer 추적

---

## 12. 데이터 파이프라인 (향후)

```
Flutter App
  │
  ├─→ Supabase (자체 이벤트 테이블)
  │     └─→ 대시보드 쿼리
  │
  └─→ Firebase Analytics (선택)
        └─→ BigQuery Export
              └─→ Looker / Metabase
```

**데모 모드 필터링**: `is_demo: true` 이벤트는 프로덕션 분석에서 자동 제외.
