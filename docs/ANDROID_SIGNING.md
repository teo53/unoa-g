# Android Release Signing Guide

## 1. Keystore 생성

```bash
keytool -genkey -v \
  -keystore unoa-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias unoa-key
```

프롬프트에 따라 비밀번호와 인증서 정보를 입력합니다.

> **주의**: keystore 파일은 절대 Git에 커밋하지 마세요. `android/.gitignore`에 `*.jks`, `*.keystore`, `key.properties`가 이미 포함되어 있습니다.

## 2. key.properties 생성

`android/key.properties` 파일을 생성합니다:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=unoa-key
storeFile=../unoa-release.jks
```

- `storeFile` 경로는 `android/app/` 기준 상대 경로입니다.
- keystore 파일을 프로젝트 루트에 두면 `storeFile=../../unoa-release.jks`

## 3. 빌드 확인

```bash
# APK 빌드
flutter build apk --release --dart-define-from-file=config/beta.json

# App Bundle 빌드 (Play Store 업로드용)
flutter build appbundle --release --dart-define-from-file=config/prod.json
```

key.properties가 없으면 자동으로 debug 서명으로 폴백됩니다 (개발 편의).

## 4. GitHub Actions CI 설정

### Secrets 등록

GitHub repo > Settings > Secrets and variables > Actions에 등록:

| Secret | 설명 |
|--------|------|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w 0 unoa-release.jks` 출력값 |
| `ANDROID_KEY_PROPERTIES` | `key.properties` 파일 전체 내용 |

### Workflow 예시

```yaml
- name: Decode keystore
  run: |
    echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/unoa-release.jks

- name: Create key.properties
  run: |
    echo "${{ secrets.ANDROID_KEY_PROPERTIES }}" > android/key.properties

- name: Build release APK
  run: flutter build apk --release --dart-define-from-file=config/prod.json
```

## 5. Play Store 업로드 키

Play Console에서 **앱 서명**을 사용하는 경우:
- 위에서 생성한 키는 "업로드 키"가 됩니다.
- Google이 별도의 "앱 서명 키"로 최종 서명합니다.
- 업로드 키를 분실해도 Play Console에서 재설정 가능합니다.
