# UNO A Configuration Guide

## 환경별 설정 파일

```
config/
├── dev.json       # 개발 환경 (로컬)
├── staging.json   # 스테이징 환경
├── prod.json      # 프로덕션 환경 (CI 시크릿에서 생성)
└── README.md      # 이 파일
```

## dart-define-from-file 워크플로우

Flutter 빌드 시 환경 변수를 JSON 파일로 주입:

```bash
# 개발
flutter run --dart-define-from-file=config/dev.json

# 스테이징
flutter build web --release --dart-define-from-file=config/staging.json

# 프로덕션
flutter build web --release --dart-define-from-file=config/prod.json
```

## 필수 환경 변수

| 변수 | 설명 | 필수 | 예시 |
|------|------|:----:|------|
| `ENV` | 환경 구분 | ✅ | `production` / `staging` / `development` |
| `SUPABASE_URL` | Supabase 프로젝트 URL | ✅ | `https://xxx.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase 익명 키 | ✅ | `eyJ...` |
| `SENTRY_DSN` | Sentry 에러 추적 DSN | ✅ | `https://xxx@sentry.io/xxx` |
| `FIREBASE_PROJECT_ID` | Firebase 프로젝트 ID | ✅ | `unoa-app-prod` |
| `ENABLE_DEMO` | 데모 모드 | ✅ | `false` (프로덕션) |
| `ENABLE_ANALYTICS` | 분석 활성화 | | `true` |
| `ENABLE_CRASH_REPORTING` | 크래시 리포팅 | | `true` |
| `PRIVACY_POLICY_URL` | 개인정보 처리방침 URL | ✅ | `https://unoa.app/legal/privacy` |
| `TERMS_URL` | 서비스 이용약관 URL | ✅ | `https://unoa.app/legal/terms` |

## JSON 파일 형식

```json
{
  "ENV": "production",
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key",
  "SENTRY_DSN": "https://xxx@sentry.io/xxx",
  "FIREBASE_PROJECT_ID": "your-firebase-project",
  "ENABLE_DEMO": "false",
  "ENABLE_ANALYTICS": "true",
  "ENABLE_CRASH_REPORTING": "true",
  "PRIVACY_POLICY_URL": "https://unoa.app/legal/privacy",
  "TERMS_URL": "https://unoa.app/legal/terms"
}
```

## CI/CD 설정

프로덕션 JSON은 **절대 git에 커밋하지 않는다**.
CI/CD 파이프라인에서 시크릿으로 생성:

```yaml
# GitHub Actions 예시
- name: Create prod config
  run: |
    echo '{
      "ENV": "production",
      "SUPABASE_URL": "${{ secrets.SUPABASE_URL }}",
      "SUPABASE_ANON_KEY": "${{ secrets.SUPABASE_ANON_KEY }}",
      "SENTRY_DSN": "${{ secrets.SENTRY_DSN }}",
      "FIREBASE_PROJECT_ID": "${{ secrets.FIREBASE_PROJECT_ID }}",
      "ENABLE_DEMO": "false",
      "ENABLE_ANALYTICS": "true",
      "PRIVACY_POLICY_URL": "${{ secrets.PRIVACY_POLICY_URL }}",
      "TERMS_URL": "${{ secrets.TERMS_URL }}"
    }' > config/prod.json
```

## 주의사항

- `config/prod.json`은 `.gitignore`에 포함
- `ENABLE_DEMO=false` 없이 빌드하면 데모 모드 활성화 위험
- `SENTRY_DSN` 누락 시 에러 추적 무효
- `AppConfig.validate()`가 프로덕션 빌드 시 필수 값 검증
