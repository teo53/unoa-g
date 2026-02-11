# UNO A Release Checklist

## 코드 품질

- [ ] `flutter analyze --no-fatal-infos` — 신규 에러 0건
- [ ] `dart format --set-exit-if-changed .` — 포매팅 통과
- [ ] `flutter test` — 모든 테스트 통과
- [ ] `flutter build web --release` — 빌드 성공
- [ ] PR 리뷰 완료

## 환경 설정

- [ ] `config/beta.json` 또는 `config/prod.json` 값 확인
- [ ] `SUPABASE_URL` 실제 프로젝트 URL로 설정
- [ ] `SUPABASE_ANON_KEY` 실제 키로 설정
- [ ] `SENTRY_DSN` 설정 확인
- [ ] `ENABLE_DEMO=false` (프로덕션 빌드 시)
- [ ] `ENABLE_ANALYTICS=true` (프로덕션 빌드 시)

## Android 서명

- [ ] `android/key.properties` 파일 존재 (로컬)
- [ ] keystore 파일 경로 확인
- [ ] CI/CD에 `KEYSTORE_BASE64`, `KEY_PROPERTIES` 시크릿 설정

## 보안

- [ ] API 키가 소스코드에 하드코딩되지 않음
- [ ] `.env` 파일이 `.gitignore`에 포함됨
- [ ] Supabase RLS 정책 활성화 확인
- [ ] `security_guard` precommit gate 통과

## Supabase (백엔드 연동 시)

- [ ] 마이그레이션 적용 (`supabase db push`)
- [ ] RLS 정책 테스트
- [ ] Edge Functions 배포
- [ ] Storage bucket 권한 설정

## 배포

### Android APK
```bash
flutter build apk --release --dart-define-from-file=config/prod.json
```

### Web (Firebase)
```bash
flutter build web --release --dart-define-from-file=config/prod.json
firebase deploy --only hosting
```

### iOS
```bash
flutter build ios --release --dart-define-from-file=config/prod.json
# Xcode Archive → App Store Connect 업로드
```

## 배포 후 확인

- [ ] Sentry에서 에러 수신 정상 동작
- [ ] 데모 모드가 비활성화됨 (프로덕션)
- [ ] Analytics 이벤트 수신 확인
- [ ] 주요 화면 이동 흐름 확인 (홈 → 채팅 → 프로필 → 설정)
- [ ] 다크 모드 전환 정상
- [ ] 크래시 없이 5분 이상 사용 가능

## 롤백 계획

### Web (Firebase)
```bash
firebase hosting:rollback
```

### Android/iOS
- 이전 버전 APK/IPA 재배포
- Play Console / App Store Connect에서 이전 빌드 활성화
