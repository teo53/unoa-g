# 01. 아키텍처 현황 (Architecture As-Is)

## 1. 전체 시스템 아키텍처

```
┌─────────────────────────────────────────────────────────────────────┐
│                          CLIENT LAYER                                │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │   Flutter App    │  │   Next.js Web    │  │    Admin Web     │  │
│  │   (Fan/Creator)  │  │   (공개 펀딩)     │  │   (미구현)        │  │
│  │                  │  │                  │  │                  │  │
│  │  - Riverpod      │  │  - App Router    │  │  - 계획됨        │  │
│  │  - go_router     │  │  - RSC           │  │                  │  │
│  │  - Material 3    │  │  - TailwindCSS   │  │                  │  │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         BACKEND LAYER                                │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      Supabase                                 │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────────────────┐ │  │
│  │  │ PostgreSQL │  │  Auth      │  │   Edge Functions       │ │  │
│  │  │ + RLS      │  │  + OAuth   │  │   - payment-webhook    │ │  │
│  │  │ + pgcrypto │  │            │  │   - payout-calculate   │ │  │
│  │  └────────────┘  └────────────┘  │   - payout-statement   │ │  │
│  │                                   │   - identity-verify    │ │  │
│  │  ┌────────────┐  ┌────────────┐  └────────────────────────┘ │  │
│  │  │ Storage    │  │ Realtime   │                              │  │
│  │  │ (미디어)    │  │ (메시지)    │                              │  │
│  │  └────────────┘  └────────────┘                              │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       EXTERNAL SERVICES                              │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │ TossPayments │  │   Firebase   │  │   Sentry     │             │
│  │ (결제)        │  │ (FCM, 분석)  │  │ (에러 추적)   │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. Flutter 앱 아키텍처

### 2.1 레이어 구조

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                           │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ features/                                                   │ │
│  │ ├── auth/       (로그인/가입/인증)                           │ │
│  │ ├── chat/       (팬 채팅 화면)                               │ │
│  │ ├── creator/    (크리에이터 대시보드/CRM)                     │ │
│  │ ├── artist_inbox/ (아티스트 인박스/브로드캐스트)               │ │
│  │ ├── funding/    (펀딩/캠페인)                                │ │
│  │ ├── wallet/     (DT 지갑)                                   │ │
│  │ ├── profile/    (프로필)                                    │ │
│  │ ├── settings/   (설정)                                      │ │
│  │ └── ...                                                     │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ shared/widgets/ (재사용 위젯)                                │ │
│  │ ├── app_scaffold.dart    (플랫폼 인식 레이아웃)              │ │
│  │ ├── bottom_nav_bar.dart  (팬용 하단 네비게이션)              │ │
│  │ ├── creator_bottom_nav_bar.dart (크리에이터용)               │ │
│  │ ├── skeleton_loader.dart (로딩 스켈레톤)                    │ │
│  │ ├── error_boundary.dart  (에러 바운더리)                    │ │
│  │ └── ...                                                     │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      STATE LAYER (Riverpod)                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ providers/                                                  │ │
│  │ ├── auth_provider.dart       (인증 상태)                    │ │
│  │ ├── chat_provider.dart       (채팅 상태)                    │ │
│  │ ├── wallet_provider.dart     (지갑 상태)                    │ │
│  │ ├── realtime_provider.dart   (실시간 구독)                  │ │
│  │ ├── theme_provider.dart      (테마)                         │ │
│  │ └── repository_providers.dart (DI)                          │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                       DATA LAYER                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ data/repositories/ (추상화 + 구현)                          │ │
│  │ ├── chat_repository.dart          (인터페이스)              │ │
│  │ ├── mock_chat_repository.dart     (Mock 구현)               │ │
│  │ ├── supabase_chat_repository.dart (Supabase 구현)           │ │
│  │ ├── supabase_inbox_repository.dart                          │ │
│  │ ├── supabase_profile_repository.dart                        │ │
│  │ └── supabase_wallet_repository.dart                         │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ data/models/ (도메인 모델)                                   │ │
│  │ ├── broadcast_message.dart  (브로드캐스트 메시지)            │ │
│  │ ├── channel.dart            (채널/구독)                     │ │
│  │ ├── reply_quota.dart        (답장 토큰)                     │ │
│  │ ├── user.dart               (사용자 프로필)                 │ │
│  │ └── dt_package.dart         (DT 패키지)                     │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      CORE LAYER                                  │
│  ├── core/config/       (환경 설정)                             │
│  │   ├── app_config.dart      (환경별 설정)                     │
│  │   ├── demo_config.dart     (데모 데이터)                     │
│  │   └── business_config.dart (비즈니스 규칙)                   │
│  ├── core/theme/        (테마/색상/타이포그래피)                 │
│  ├── core/utils/        (유틸리티)                              │
│  │   ├── accessibility_helper.dart                              │
│  │   ├── animation_utils.dart                                   │
│  │   └── responsive_helper.dart                                 │
│  ├── core/supabase/     (Supabase 클라이언트)                   │
│  └── core/monitoring/   (Sentry)                                │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 상태 관리 패턴 (Riverpod)

```dart
// 인증 상태 - Sealed Class 패턴
sealed class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState { ... }
class AuthUnauthenticated extends AuthState {}
class AuthDemoMode extends AuthState { ... }  // 데모 모드 지원
class AuthError extends AuthState { ... }

// Provider 정의
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

// 편의 Provider
final currentProfileProvider = Provider<UserAuthProfile?>((ref) {
  final state = ref.watch(authProvider);
  return switch (state) {
    AuthAuthenticated(:final profile) => profile,
    AuthDemoMode(:final demoProfile) => demoProfile,
    _ => null,
  };
});

final isDemoModeProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is AuthDemoMode;
});

final isCreatorProvider = Provider<bool>((ref) {
  final profile = ref.watch(currentProfileProvider);
  return profile?.role == UserRole.creator;
});
```

### 2.3 라우팅 구조 (go_router)

```dart
// 2개의 ShellRoute로 팬/크리에이터 구분
GoRouter(
  routes: [
    // 팬 Shell (5탭)
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: ... ),           // 홈
        GoRoute(path: '/chat', builder: ... ),       // 채팅 목록
        GoRoute(path: '/funding', builder: ... ),    // 펀딩
        GoRoute(path: '/discover', builder: ... ),   // 탐색
        GoRoute(path: '/profile', builder: ... ),    // 프로필
      ],
    ),

    // 크리에이터 Shell (5탭)
    ShellRoute(
      builder: (_, __, child) => CreatorShell(child: child),
      routes: [
        GoRoute(path: '/creator/dashboard', ... ),   // 대시보드
        GoRoute(path: '/creator/chat', ... ),        // 내 채널
        GoRoute(path: '/creator/funding', ... ),     // 펀딩 관리
        GoRoute(path: '/creator/discover', ... ),    // 탐색
        GoRoute(path: '/creator/profile', ... ),     // 프로필
      ],
    ),

    // 전체화면 라우트 (하단 네비 없음)
    GoRoute(path: '/chat/:artistId', ... ),
    GoRoute(path: '/wallet', ... ),
    GoRoute(path: '/settings', ... ),
    // ...
  ],
);
```

---

## 3. Supabase 데이터베이스 스키마

### 3.1 핵심 테이블

```sql
-- 사용자 프로필
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  display_name TEXT,
  avatar_url TEXT,
  role user_role DEFAULT 'fan',
  is_banned BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 채널 (아티스트당 1개)
CREATE TABLE channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  artist_user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  description TEXT,
  avatar_url TEXT,
  banner_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  subscriber_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 구독
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  channel_id UUID REFERENCES channels(id),
  tier subscription_tier DEFAULT 'BASIC',
  started_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  UNIQUE(user_id, channel_id)
);

-- 메시지
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID REFERENCES channels(id),
  sender_id UUID REFERENCES auth.users(id),
  content TEXT,
  message_type message_type DEFAULT 'text',
  delivery_scope delivery_scope DEFAULT 'broadcast',
  media_url TEXT,
  voice_url TEXT,
  is_edited BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 답장 쿼타
CREATE TABLE reply_quota (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  channel_id UUID REFERENCES channels(id),
  daily_used INTEGER DEFAULT 0,
  daily_limit INTEGER DEFAULT 3,
  reset_at TIMESTAMPTZ,
  UNIQUE(user_id, channel_id)
);

-- 지갑
CREATE TABLE wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) UNIQUE,
  balance_dt INTEGER DEFAULT 0,
  lifetime_purchased_dt INTEGER DEFAULT 0,
  lifetime_spent_dt INTEGER DEFAULT 0,
  lifetime_earned_dt INTEGER DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 원장 (거래 내역)
CREATE TABLE ledger_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID REFERENCES wallets(id),
  amount_dt INTEGER NOT NULL,
  entry_type entry_type NOT NULL,
  description TEXT,
  idempotency_key TEXT UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 크리에이터 정산 계좌 (암호화)
CREATE TABLE creator_payout_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID REFERENCES auth.users(id) UNIQUE,
  bank_name TEXT,
  bank_account_number_encrypted BYTEA,  -- AES-256-GCM 암호화
  account_holder_name TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 감사 로그
CREATE TABLE admin_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,
  target_type TEXT,
  target_id UUID,
  details JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 3.2 RLS 정책 현황

| 테이블 | RLS | SELECT | INSERT | UPDATE | DELETE |
|--------|-----|--------|--------|--------|--------|
| channels | ✅ | public(active) | artist_own | artist_own | - |
| subscriptions | ✅ | user_own + artist_channel | service_role | user_own | - |
| messages | ✅ | subscribed + own | authenticated | sender_own | - |
| reply_quota | ✅ | user_own | service_role | service_role | - |
| wallets | ✅ | user_own | service_role | service_role | - |
| ledger_entries | ✅ | user_own | service_role | - | - |
| creator_payout_accounts | ✅ | creator_own | creator_own | service_role | - |
| admin_audit_log | ✅ | admin_only | **anyone** ⚠️ | - | - |

---

## 4. Edge Functions

### 4.1 현재 구현된 함수

```
supabase/functions/
├── payment-webhook/         # TossPayments 웹훅 처리
│   ├── 서명 검증 (HMAC-SHA256)
│   ├── Idempotency 체크 (payment_webhook_logs)
│   └── 지갑 업데이트 (atomic)
│
├── payout-calculate/        # 정산 계산
│   ├── 기간별 수익 집계
│   ├── 수수료 계산 (80/20)
│   └── 정산서 생성
│
├── payout-statement/        # 정산서 PDF 생성
│   ├── PDF 렌더링
│   ├── 계좌 정보 복호화
│   └── 다운로드 URL 생성
│
└── identity-verification/   # 본인 인증
    └── KYC 처리 (미완성)
```

### 4.2 웹훅 처리 흐름

```
TossPayments → Edge Function → Supabase
    │
    ▼
┌────────────────────────────────────────┐
│ 1. 서명 검증 (HMAC-SHA256)              │
│    - 타이밍 안전 비교                    │
│    - 개발환경에서만 bypass 허용          │
└────────────────────────────────────────┘
    │
    ▼
┌────────────────────────────────────────┐
│ 2. Idempotency 체크                     │
│    - payment_webhook_logs에서 중복 확인  │
│    - 이미 처리된 이벤트면 skip           │
└────────────────────────────────────────┘
    │
    ▼
┌────────────────────────────────────────┐
│ 3. 결제 검증                            │
│    - TossPayments API로 결제 상태 확인   │
│    - 금액/주문ID 매칭                   │
└────────────────────────────────────────┘
    │
    ▼
┌────────────────────────────────────────┐
│ 4. 지갑 업데이트 (Atomic)                │
│    - 트랜잭션 시작                       │
│    - 잔액 증가                          │
│    - 원장 기록                          │
│    - 트랜잭션 커밋                       │
└────────────────────────────────────────┘
```

---

## 5. 외부 서비스 연동

### 5.1 Firebase

```yaml
# 사용 중인 Firebase 서비스
- firebase_core: 초기화
- firebase_messaging: 푸시 알림 (FCM)
- firebase_analytics: 사용자 분석

# 상태
- FCM: 템플릿만 구현 (fcm_service.dart)
- Analytics: 이벤트 트래킹 미구현
```

### 5.2 TossPayments

```typescript
// 연동 상태
- 웹훅 서명 검증: ✅ 구현됨
- 결제 생성 API: ⚠️ 부분 구현
- 결제 확인 API: ✅ 구현됨
- 환불 API: ❌ 미구현
```

### 5.3 Sentry

```dart
// lib/core/monitoring/sentry_service.dart
- 에러 캡처: ✅ 구현됨
- 사용자 컨텍스트: ✅ 구현됨
- 커스텀 이벤트: ⚠️ 부분 구현
```

---

## 6. 배포 인프라

```
┌─────────────────────────────────────────────┐
│              Firebase Hosting               │
│  https://unoa-app-demo.web.app             │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │    Flutter Web Build                │   │
│  │    (build/web/)                     │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│              Supabase Cloud                 │
│  - PostgreSQL                              │
│  - Auth                                    │
│  - Storage                                 │
│  - Edge Functions                          │
│  - Realtime                               │
└─────────────────────────────────────────────┘
```

---

## 7. 의존성 요약

### 7.1 Flutter 주요 패키지

| 카테고리 | 패키지 | 버전 |
|----------|--------|------|
| 상태관리 | flutter_riverpod | ^2.4.10 |
| 라우팅 | go_router | ^14.0.0 |
| 백엔드 | supabase_flutter | ^2.3.4 |
| 푸시 | firebase_messaging | ^15.1.7 |
| 미디어 | image_picker, video_player | latest |
| 오디오 | record, just_audio | ^5.1.2, ^0.9.40 |
| 모니터링 | sentry_flutter | ^8.10.0 |
| 스토리지 | hive_flutter | latest |

### 7.2 Supabase 확장

```sql
-- 사용 중인 PostgreSQL 확장
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";  -- 암호화용
```

---

## 8. 아키텍처 강점

1. **명확한 레이어 분리**: UI → State → Data → Core
2. **리포지토리 패턴**: Mock/Real 구현 분리로 테스트 용이
3. **Sealed Class 상태**: 타입 안전한 상태 관리
4. **RLS 전면 적용**: 서버 측 데이터 보안
5. **설정 중앙화**: DemoConfig, BusinessConfig로 하드코딩 방지
6. **데모 모드**: 백엔드 없이 앱 테스트 가능

## 9. 아키텍처 개선 필요 사항

1. **어드민 레이어 부재**: 운영 도구 없음
2. **모더레이션 인프라 부재**: 신고/차단 처리 흐름 없음
3. **캐싱 전략 부재**: Hive 있으나 실제 캐싱 미구현
4. **오프라인 지원 부재**: connectivity_plus 있으나 미적용
5. **에러 리포팅 통합 미완**: Sentry 있으나 이벤트 트래킹 부족
