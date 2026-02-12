# UNO A - Fan-Creator Chat Platform

UNO A는 팬과 크리에이터를 연결하는 1:1 프리미엄 채팅 플랫폼입니다.

## 주요 기능

### 팬 기능
- **구독 기반 채팅**: 팬은 월 4,900원으로 좋아하는 크리에이터와 1:1 채팅
- **DT 후원 시스템**: 디지털 토큰(DT)으로 크리에이터에게 후원
- **일일 답장 쿼터**: 구독 등급에 따른 일일 답장 횟수 제한
- **글자수 제한 성장**: 구독 기간에 따라 메시지 글자수 제한 증가
- **실시간 알림**: 새 메시지, 후원 알림 실시간 수신

### 크리에이터 기능
- **WYSIWYG 콘텐츠 관리**: 팬에게 보이는 화면과 동일한 편집 환경
- **미디어 전송 확인**: 사진/음성 전송 전 팬 뷰 미리보기 및 확인
- **개인화 메시지**: `{팬이름}`, `{구독일수}`, `{티어}` 변수로 메시지 개인화
- **프로필 편집**: 변경 사항이 어떤 화면에 영향주는지 실시간 확인
- **CRM 대시보드**: 팬 관리, 수익 통계, 구독 분석

## 기술 스택

### Frontend (Flutter)
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **API Client**: Supabase Flutter SDK
- **Image Caching**: CachedNetworkImage
- **Local Storage**: SharedPreferences

### Backend (Supabase)
- **Database**: PostgreSQL
- **Authentication**: Supabase Auth (OAuth, Email)
- **Realtime**: Supabase Realtime (채팅, Presence)
- **Storage**: Supabase Storage (이미지, 미디어)
- **Serverless Functions**: Deno Edge Functions

### Payment
- **PG사**: TossPayments (한국)
- **Webhook**: 서명 검증 + 원자적 트랜잭션

## 프로젝트 구조

```
unoa-g-main/
├── lib/                          # Flutter 앱 소스코드
│   ├── core/                     # 핵심 유틸리티
│   │   ├── supabase/            # Supabase 클라이언트 설정
│   │   ├── theme/               # 앱 테마 및 색상
│   │   └── services/            # 에러 처리, 로깅 서비스
│   ├── data/                     # 데이터 레이어
│   │   ├── models/              # 데이터 모델 (User, Channel, Message 등)
│   │   ├── repositories/        # 데이터 접근 추상화
│   │   ├── services/            # 비즈니스 로직 서비스
│   │   └── mock/                # Mock 데이터 (개발용)
│   ├── features/                 # 기능별 화면
│   │   ├── auth/                # 인증 (로그인, 회원가입)
│   │   ├── chat/                # 채팅 (목록, 스레드)
│   │   ├── creator/             # 크리에이터 전용
│   │   │   ├── creator_content_manager_screen.dart  # WYSIWYG 콘텐츠 관리
│   │   │   ├── creator_profile_edit_screen.dart     # 프로필 편집
│   │   │   ├── helpers/         # 개인화 미리보기 헬퍼
│   │   │   └── widgets/         # 팬 뷰 미리보기, 메시지 편집 위젯
│   │   ├── artist_inbox/        # 브로드캐스트 작성 (미디어 확인 포함)
│   │   ├── wallet/              # 지갑 (충전, 후원)
│   │   ├── settings/            # 설정
│   │   └── discover/            # 크리에이터 탐색
│   ├── providers/                # Riverpod Providers
│   │   ├── auth_provider.dart   # 인증 상태 관리
│   │   ├── chat_provider.dart   # 채팅 상태 관리
│   │   └── wallet_provider.dart # 지갑 상태 관리
│   ├── navigation/               # GoRouter 라우팅
│   └── shared/                   # 공용 위젯
├── supabase/                     # 백엔드 (Supabase)
│   ├── migrations/              # 데이터베이스 스키마 (14개 마이그레이션)
│   │   ├── 001_users_profiles.sql
│   │   ├── 002_channels_subscriptions.sql
│   │   ├── 003_triggers.sql
│   │   └── ...
│   └── functions/               # Edge Functions (서버리스)
│       ├── payment-checkout/    # 결제 세션 생성
│       ├── payment-webhook/     # 결제 완료 처리
│       └── settlement-batch/    # 정산 배치
├── android/                      # Android 플랫폼 설정
├── ios/                          # iOS 플랫폼 설정
└── test/                         # 테스트 코드
```

## 시작하기

### 필수 조건

- Flutter SDK 3.0 이상
- Dart SDK 3.0 이상
- Supabase 계정
- TossPayments 계정 (결제 기능)

### 설치

1. **레포지토리 클론**
```bash
git clone https://github.com/your-org/unoa-g.git
cd unoa-g-main
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **환경 설정 (선택)**
```bash
# config/dev.json을 열어 Supabase 키 입력 (기본값으로도 데모 모드 실행 가능)
# 자세한 내용은 아래 "환경 변수" 섹션 참조
```

4. **Supabase 프로젝트 설정**
```bash
# Supabase CLI 설치
npm install -g supabase

# 프로젝트 링크
supabase link --project-ref your-project-ref

# 마이그레이션 실행
supabase db push
```

5. **앱 실행**
```bash
# 개발 모드
flutter run

# 릴리즈 빌드
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## 환경 변수

이 프로젝트는 `--dart-define` 또는 `--dart-define-from-file`을 사용합니다.
(`.env` 파일은 사용하지 않습니다.)

### 개발 모드 (빠른 시작)
```bash
flutter run  # 기본값: development 환경, 데모 모드 활성화
```

### dart-define-from-file 사용 (권장)
```bash
# 개발
flutter run --dart-define-from-file=config/dev.json

# 베타 테스트
flutter build apk --release --dart-define-from-file=config/beta.json

# 프로덕션 (CI에서 시크릿 주입)
flutter build appbundle --release --dart-define-from-file=config/prod.json
```

### 개별 dart-define 사용
```bash
flutter run \
  --dart-define=ENV=beta \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-key \
  --dart-define=SENTRY_DSN=https://xxx@sentry.io/xxx
```

### 환경변수 목록

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `ENV` | `development` / `beta` / `staging` / `production` | `development` |
| `SUPABASE_URL` | Supabase 프로젝트 URL | (placeholder) |
| `SUPABASE_ANON_KEY` | Supabase 익명 키 | (빈 문자열) |
| `SENTRY_DSN` | Sentry 에러 추적 DSN | (빈 문자열) |
| `FIREBASE_PROJECT_ID` | Firebase 프로젝트 ID | `unoa-app-demo` |
| `ENABLE_DEMO` | 데모 모드 활성화 | dev/beta: `true` |
| `ENABLE_ANALYTICS` | 분석 활성화 | prod: `true` |
| `ENABLE_CRASH_REPORTING` | 크래시 리포팅 | prod/beta/staging: `true` |

> **주의**: `config/*.json`에는 비밀키를 직접 저장하지 마세요. CI/CD에서는 시크릿으로 관리합니다.

## 테스트

```bash
# 단위 테스트
flutter test

# 통합 테스트
flutter test integration_test/

# 코드 분석
flutter analyze
```

## 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App (lib/)                   │
├─────────────────────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│  │  Auth   │  │  Chat   │  │ Wallet  │  │ Profile │   │
│  │ Screen  │  │ Screen  │  │ Screen  │  │ Screen  │   │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘   │
│       │            │            │            │         │
│       └────────────┴─────┬──────┴────────────┘         │
│                          │                              │
│               ┌──────────▼──────────┐                  │
│               │     Providers       │ (Riverpod)       │
│               │  auth, chat, wallet │                  │
│               └──────────┬──────────┘                  │
│                          │                              │
│               ┌──────────▼──────────┐                  │
│               │      Services       │                  │
│               │ chat, wallet, notif │                  │
│               └──────────┬──────────┘                  │
│                          │                              │
│               ┌──────────▼──────────┐                  │
│               │    Repositories     │                  │
│               │ Supabase 연결 추상화│                  │
│               └──────────┬──────────┘                  │
└──────────────────────────┼──────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                   Supabase Backend                      │
├─────────────────────────────────────────────────────────┤
│  PostgreSQL    │  Auth   │  Storage  │  Edge Functions │
│  (14개 테이블)  │ (OAuth) │ (이미지)   │ (결제, 정산)    │
└─────────────────────────────────────────────────────────┘
```

### 데이터 흐름

1. **화면 (Screen)** → 사용자 인터랙션 처리
2. **Provider** → 상태 관리 및 비즈니스 로직 조율
3. **Service** → 비즈니스 규칙 적용 (유효성 검사, 계산 등)
4. **Repository** → 데이터 접근 추상화
5. **Supabase** → 데이터 저장 및 실시간 동기화

## 주요 모델

| 모델 | 설명 |
|------|------|
| `UserAuthProfile` | 인증 및 권한 정보 (role, isBanned 등) |
| `UserDisplayProfile` | UI 표시용 정보 (tier, dtBalance 등) |
| `Channel` | 크리에이터 채널 |
| `Subscription` | 구독 정보 |
| `BroadcastMessage` | 채팅 메시지 |
| `ReplyQuota` | 일일 답장 쿼터 |
| `DtPackage` | DT 충전 패키지 |

## 보안

- **결제 Webhook**: HMAC-SHA256 서명 검증
- **민감정보**: pgcrypto 컬럼 레벨 암호화
- **트랜잭션**: PostgreSQL 저장 프로시저로 원자성 보장
- **RLS**: Row Level Security로 데이터 접근 제어

## 기여

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 라이선스

This project is proprietary software. All rights reserved.

## 연락처

- 이슈: GitHub Issues
- 이메일: support@unoa.app
