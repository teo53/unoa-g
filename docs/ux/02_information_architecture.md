# 02. Information Architecture

> UNO A -- 화면 구조 및 라우트 계층
> 최종 수정: 2026-02-08

---

## 1. Fan Bottom Navigation (5탭)

```
┌────────┬────────┬────────┬────────┬────────┐
│  홈    │ 메시지 │  펀딩  │  탐색  │ 프로필 │
│  /     │ /chat  │/funding│/discover│/profile│
└────────┴────────┴────────┴────────┴────────┘
```

| 탭 | 라우트 | 아이콘 | 설명 |
|----|--------|--------|------|
| 홈 | `/` | home | 구독 아티스트 피드, 추천, 배너 |
| 메시지 | `/chat` | chat_bubble | 구독 아티스트 채팅 리스트 |
| 펀딩 | `/funding` | favorite | 크라우드펀딩 캠페인 탐색 |
| 탐색 | `/discover` | explore | 아티스트 검색/카테고리 |
| 프로필 | `/profile` | person | 내 정보, 구독 관리 |

### Fan 하위 라우트

```
/                           # 홈
├── /chat                   # 채팅 리스트
│   └── /chat/:artistId     # 1:1 채팅 스레드 (전체화면)
├── /funding                # 펀딩 탐색
├── /discover               # 아티스트 탐색
│   └── /artist/:artistId   # 아티스트 프로필 (전체화면)
├── /profile                # 내 프로필
├── /wallet                 # DT 지갑 (전체화면)
│   ├── /wallet/charge      # DT 충전
│   └── /wallet/history     # 거래 내역
├── /settings               # 설정 (전체화면)
│   ├── /settings/notifications  # 알림 설정
│   ├── /settings/account        # 계정 설정
│   └── /settings/birthday       # 생일 설정
├── /notifications          # 알림 목록 (전체화면)
├── /subscriptions          # 구독 관리 (전체화면)
└── /help                   # 도움말 (전체화면)
```

---

## 2. Creator Bottom Navigation (5탭)

```
┌──────────┬────────┬────────┬────────┬────────┐
│ 대시보드 │  채팅  │  펀딩  │  탐색  │ 프로필 │
│/creator/ │/creator│/creator│/creator│/creator│
│dashboard │ /chat  │/funding│/discover│/profile│
└──────────┴────────┴────────┴────────┴────────┘
```

| 탭 | 라우트 | 설명 |
|----|--------|------|
| 대시보드 | `/creator/dashboard` | CRM 통합, 구독자 통계, 수익 현황 |
| 채팅 | `/creator/chat` | 2탭 (내 채널 단체톡 + 구독 아티스트) |
| 펀딩 | `/creator/funding` | 내 캠페인 관리 + 타인 캠페인 탐색 |
| 탐색 | `/creator/discover` | 아티스트 탐색 (팬으로서) |
| 프로필 | `/creator/profile` | 크리에이터 프로필 |

### Creator 하위 라우트

```
/creator/dashboard              # 대시보드 (CRM 통합)
├── /creator/chat               # 채팅 탭 (2-tab)
│   ├── 탭1: 내 채널 (단체톡방)
│   └── 탭2: 구독 아티스트
├── /creator/funding            # 펀딩 관리
│   ├── /creator/funding/create           # 캠페인 생성 (전체화면)
│   └── /creator/funding/edit/:campaignId # 캠페인 편집 (전체화면)
├── /creator/discover           # 아티스트 탐색
├── /creator/profile            # 프로필
│   └── /creator/content        # 프로필 편집 (전체화면)
├── /creator/crm                # CRM 상세 (전체화면, 레거시)
├── /creator/private-card       # 프라이빗 카드 (전체화면)
│   └── /creator/private-card/compose  # 카드 작성
└── /artist/inbox               # 레거시 인박스 (하위호환)
```

---

## 3. Route Gate Levels (접근 제어 계층)

### Level 0: Open (비보호)

누구나 접근 가능. 로그인 불필요.

| 라우트 | 화면 | 비고 |
|--------|------|------|
| `/` | 홈 | 가치 제안 배너 + 추천 아티스트 |
| `/discover` | 탐색 | 검색, 카테고리, 인기 아티스트 |
| `/funding` | 펀딩 | 캠페인 리스트 열람 |
| `/artist/:artistId` | 아티스트 프로필 | 소개, 구독 티어 확인 |

**목적**: 비로그인 사용자에게 플랫폼 가치를 먼저 보여주어 가입 동기 부여.

### Level 1: Action-Gated (행동 게이트)

화면 자체는 접근 가능하나, **특정 행동** 시 인증 필요.

| 행동 | 트리거 지점 | Gate UI |
|------|------------|---------|
| 메시지 전송 | `chat_input_bar_v2.dart` 전송 버튼 | 로그인 바텀시트 |
| 펀딩 결제 | `funding_checkout_screen.dart` 결제 버튼 | 로그인 바텀시트 |
| 구독 신청 | 아티스트 프로필 구독 버튼 | 로그인 바텀시트 |
| DT 충전 | `/wallet/charge` 충전 버튼 | 로그인 바텀시트 |
| 후원 메시지 | 채팅 내 후원 버튼 | 로그인 바텀시트 |

**Gate 컴포넌트**: `auth_gate.dart` -- 바텀시트 형태로 로그인/회원가입/데모 옵션 제공.

```
┌─────────────────────────┐
│   로그인이 필요합니다     │
│                         │
│   [로그인]  [회원가입]   │
│   [데모로 체험하기]      │
└─────────────────────────┘
```

### Level 2: Route-Gated (라우트 보호)

라우트 자체에 접근 불가. 인증 + 역할 필요.

| 라우트 패턴 | 필요 권한 | 미인증 시 |
|-------------|----------|-----------|
| `/creator/*` | 크리에이터 계정 | `/login`으로 리다이렉트 |
| `/chat/:artistId` | 로그인 + 구독 | 로그인 후 구독 유도 |
| `/wallet/*` | 로그인 | `/login`으로 리다이렉트 |
| `/settings/*` | 로그인 | `/login`으로 리다이렉트 |

---

## 4. Navigation Flow Diagram

```
[비로그인 사용자]
    │
    ├─→ / (홈: 가치 제안)
    ├─→ /discover (탐색)
    ├─→ /funding (펀딩 열람)
    ├─→ /artist/:id (프로필 열람)
    │
    └─→ 행동 시도 (메시지, 결제 등)
         │
         ├─→ Auth Gate 바텀시트
         │    ├─→ 로그인 → 행동 계속
         │    ├─→ 회원가입 → /register → 행동 계속
         │    └─→ 데모 체험 → Demo Mode 진입
         │
         └─→ /creator/* 접근 시도
              └─→ /login 리다이렉트

[로그인 사용자 - Fan]
    │
    ├─→ 5탭 네비게이션 전체 사용
    ├─→ 채팅 (구독 아티스트)
    ├─→ 지갑, 설정, 알림
    └─→ 크리에이터 전환 가능

[로그인 사용자 - Creator]
    │
    ├─→ Creator 5탭 네비게이션
    ├─→ 대시보드 (CRM, 통계)
    ├─→ 채팅 (단체톡방 + 구독 아티스트)
    └─→ 펀딩 캠페인 관리
```

---

## 5. 현재 vs 목표 상태

| 항목 | 현재 (`initialLocation`) | 목표 |
|------|--------------------------|------|
| 첫 진입 | `/login` (강제 로그인) | `/` (홈, 비보호) |
| 행동 게이트 | 없음 (silent fail) | `auth_gate.dart` 바텀시트 |
| 크리에이터 보호 | 없음 | Route guard (`/creator/*`) |
| 프로필 (비로그인) | MockData 표시 | 게스트 뷰 (로그인 유도) |
