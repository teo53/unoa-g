# /route — WI 기반 작업 라우팅 (필수 시작점)

## 목표

1. Notion WI(Work Item)를 생성하거나 기존 WI를 연결한다.
2. Slack에 WI 링크 포함 "단일 메시지"를 올리고 스레드로 논의를 고정한다.
3. 변경 유형에 따라 필요한 Gate를 자동 지정하고, 각 Gate 산출물을 만든다.
4. Builder에게 "구현 단위(작은 PR)" 계획을 넘긴다.

## 절차

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  1. WI 확보  │ ──▶ │ 2. Slack 게시│ ──▶ │ 3. Gate 지정 │
│  (생성/링크) │     │ (스레드 고정)│     │ (4종 자동)   │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                  │
                     ┌──────────────┐     ┌───────▼──────┐
                     │ 5. Builder   │ ◀── │ 4. 산출물    │
                     │    Plan 전달 │     │    생성      │
                     └──────────────┘     └──────────────┘
```

### Step 1: WI 확보
- (A) 기존 WI 링크를 받거나
- (B) 새 WI 제목/목표/범위(3줄)를 받아서 Notion에 생성

### Step 2: Slack 게시
- `#proj-unoa-g` 채널에 WI 요약 메시지 게시
- Thread URL 확보

### Step 3: Gate 지정 규칙
| 변경 유형 | 필수 Gate |
|-----------|-----------|
| 결제/정산/토큰/환불/약관 | security + legal + tax + uiux_obs |
| 인증/권한/DB/RLS/마이그레이션 | security (+ uiux_obs if UX 영향) |
| UI 변경/에러 처리/로그 | uiux_obs (+ security if auth 영향) |
| 단순 문서/카피 변경 | 최소 게이트 (uiux_obs) |

### Step 4: Gate 산출물
- 각 Gate subagent 호출 → 산출물 생성
- Slack thread에 순서대로 게시
- Notion WI에 요약 기록

### Step 5: Builder Plan
- 5~12 bullets로 구현 계획 작성
- 다음 단계 안내: `/qa` → `/verify` → `/ship`

## 출력 포맷 (반드시 고정)

```
- WI: <url>
- Slack Thread: <url>
- Gates Required: [security, uiux_obs, legal, tax]
- Blockers: ...
- Builder Plan: ...
- Verification: /qa → /verify → /ship
```
