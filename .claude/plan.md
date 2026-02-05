# 크리에이터 UI 전면 재설계 계획

## 핵심 원칙
**"크리에이터가 채팅창에서 메시지를 입력하면 모든 팬에게 자동 브로드캐스트"**
- 별도의 "브로드캐스트" 버튼/화면 불필요
- 팬 메시지는 채팅창에서 직접 확인 (수치는 CRM)
- 아티스트도 다른 아티스트의 팬이 될 수 있음

---

## 1. 제거할 기능들

### 1.1 프로필 화면 (creator_profile_screen.dart)
- [ ] `브로드캐스트` 메뉴 아이템 제거
- [ ] `팬 메시지` 메뉴 아이템 제거
- [ ] "크리에이터 스튜디오" 섹션 → "프로필 관리"로 변경

### 1.2 스튜디오 탭 (creator_dashboard_screen.dart)
- [ ] 불필요한 Quick Actions 제거 (브로드캐스트, 팬 메시지)
- [ ] CRM 화면을 직접 표시하거나 대시보드를 CRM 중심으로 재설계

### 1.3 라우터 (app_router.dart)
- [ ] `/creator/broadcast` 라우트 제거
- [ ] `/artist/inbox` 관련 정리

---

## 2. 수정/개선할 기능들

### 2.1 크리에이터 채팅 탭 재설계
**현재 문제**: ChatListScreen (팬 화면) 사용 중
**해결**: 크리에이터 전용 채팅 화면 구현

구조:
```
CreatorChatTabScreen
├── "내 채널" 섹션 (상단 고정)
│   └── 탭하면 CreatorChatScreen으로 이동 (브로드캐스트 채팅)
└── "구독 아티스트" 섹션 (리스트)
    └── 탭하면 ChatThreadScreenV2로 이동 (팬으로서 채팅)
```

### 2.2 스튜디오 탭 → CRM 대시보드
**현재 문제**: 불필요한 버튼 3개 (브로드캐스트, 팬메시지, CRM)
**해결**: 핵심 통계만 보여주는 대시보드

표시 항목:
- 구독자 수, 이번 달 수익
- 최근 메시지 통계 (발송/확인/답장 비율)
- 수익 구성 (후원, 구독)
- CRM 상세 보기 버튼 (하단)

### 2.3 프로필 화면 재설계
메뉴 구성:
- **프로필 꾸미기** (NEW) - 아바타, 배경, 소개글 편집
- CRM / 수익 관리
- 구독 관리 (내가 구독한 아티스트)
- 지갑
- 설정 (알림, 앱, 고객센터)

### 2.4 프로필 꾸미기 기능 (NEW)
- 프로필 아바타 변경
- 배경 이미지 설정
- 소개글 편집
- 인증 뱃지 표시 설정

---

## 3. 네비게이션 바 확인

현재 구성 (creator_bottom_nav_bar.dart):
1. 홈 → /creator/home (HomeScreen) ✓
2. 채팅 → /creator/chat (수정 필요: CreatorChatTabScreen)
3. 스튜디오 → /creator/studio (수정 필요: CRM 대시보드)
4. 펀딩 → /creator/funding (FundingScreen) ✓
5. 프로필 → /creator/profile (CreatorProfileScreen) ✓

---

## 4. 구현 순서

### Phase 1: 불필요 기능 제거
1. creator_profile_screen.dart - 브로드캐스트/팬메시지 메뉴 제거
2. creator_dashboard_screen.dart - Quick Actions에서 불필요 버튼 제거
3. app_router.dart - 불필요 라우트 정리

### Phase 2: 스튜디오 탭 재설계
1. creator_dashboard_screen.dart를 CRM 중심 대시보드로 재설계
2. 핵심 통계 표시 (브로드캐스트/팬메시지 버튼 없이)

### Phase 3: 채팅 탭 재설계
1. creator_chat_tab_screen.dart 생성 (내 채널 + 구독 아티스트 리스트)
2. app_router.dart 수정

### Phase 4: 프로필 꾸미기 기능
1. creator_profile_edit_screen.dart 생성
2. 프로필 메뉴에 연결

### Phase 5: 테스트 및 검증
1. Flutter 웹 실행
2. 모든 탭 및 기능 테스트
3. 에러 수정

---

## 5. 파일 목록

### 수정 대상
- lib/features/creator/creator_profile_screen.dart
- lib/features/creator/creator_dashboard_screen.dart
- lib/navigation/app_router.dart
- lib/shared/widgets/creator_bottom_nav_bar.dart

### 신규 생성
- lib/features/creator/creator_chat_tab_screen.dart
- lib/features/creator/creator_profile_edit_screen.dart

### 삭제 고려
- lib/features/creator/creator_chat_screen.dart (기능 통합 후)
- lib/features/creator/creator_dm_screen.dart (불필요)
- lib/features/artist_inbox/* (레거시)
