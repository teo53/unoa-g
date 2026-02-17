# UNO A Store Privacy Checklist

> **문서 버전**: 1.0
> **대상**: Google Play Data Safety + Apple App Privacy Details

---

## 1. SDK별 데이터 수집 매트릭스

| SDK | 수집 데이터 | 용도 | 로컬 저장 | 서버 전송 |
|-----|-----------|------|:---------:|:---------:|
| `supabase_flutter` | 이메일, 유저ID, IP, 디바이스 정보 | 인증, 데이터 동기화 | ❌ | ✅ |
| `sentry_flutter` | 크래시 로그, 디바이스 모델, OS/앱 버전 | 에러 추적 | ❌ | ✅ |
| `firebase_messaging` | FCM 토큰, 디바이스ID | 푸시 알림 | ✅ | ✅ |
| `firebase_analytics` | 앱 이벤트, 세션, 화면 조회 | 분석 | ❌ | ✅ |
| TossPayments (WebView) | 결제 카드 정보 | 결제 처리 | ❌ (PG 처리) | ✅ (PG만) |
| `hive_flutter` | 로컬 설정, 캐시 | 오프라인 지원 | ✅ | ❌ |
| `shared_preferences` | 테마, 언어 설정 | 사용자 설정 | ✅ | ❌ |
| `image_picker` | 사진/영상 (사용자 선택) | 프로필, 콘텐츠 | ❌ | ✅ (업로드 시) |
| `connectivity_plus` | 네트워크 상태 | 연결 확인 | ❌ | ❌ |

---

## 2. Google Play Data Safety

### 데이터 유형별 선언

#### 개인 정보
| 데이터 유형 | 수집 여부 | 공유 여부 | 용도 |
|-----------|:--------:|:--------:|------|
| 이메일 주소 | ✅ | ❌ | 계정 관리, 인증 |
| 이름/닉네임 | ✅ | ✅ (다른 사용자에게 표시) | 앱 기능 |
| 프로필 사진 | ✅ | ✅ (다른 사용자에게 표시) | 앱 기능 |
| 생년월일 | ✅ | ❌ | 연령 확인 (법적 의무) |
| 전화번호 | ❌ | ❌ | - |

#### 금융 정보
| 데이터 유형 | 수집 여부 | 공유 여부 | 용도 |
|-----------|:--------:|:--------:|------|
| 결제 정보 | ✅ (PG 처리) | ❌ (앱 미저장) | 인앱 구매 |
| 구매 내역 | ✅ | ❌ | 거래 기록 |

#### 기기/기술 정보
| 데이터 유형 | 수집 여부 | 공유 여부 | 용도 |
|-----------|:--------:|:--------:|------|
| 크래시 로그 | ✅ | ❌ | 앱 안정성 (Sentry) |
| 앱 성능 | ✅ | ❌ | 분석 (Firebase) |
| 기기 ID | ✅ | ❌ | 푸시 알림 (FCM) |

### 보안 관행 선언

- [x] 전송 중 데이터 암호화 (HTTPS/TLS)
- [x] 데이터 삭제 요청 지원 (계정 삭제 시)
- [x] 독립 보안 검토 수행

---

## 3. Apple App Privacy Details

### Privacy Nutrition Labels

#### Data Used to Track You
- **없음** (제3자 광고 추적 없음)

#### Data Linked to You
| 카테고리 | 데이터 유형 | 용도 |
|---------|-----------|------|
| Contact Info | 이메일 | 계정 관리 |
| Identifiers | 유저 ID | 앱 기능 |
| User Content | 사진, 메시지 | 앱 기능 |
| Purchase History | 인앱 구매 | 앱 기능 |

#### Data Not Linked to You
| 카테고리 | 데이터 유형 | 용도 |
|---------|-----------|------|
| Diagnostics | 크래시 데이터 | 앱 안정성 |
| Diagnostics | 성능 데이터 | 분석 |
| Usage Data | 제품 상호작용 | 분석 |

---

## 4. 개인정보 처리방침 필수 항목

URL 설정: `AppConfig.privacyPolicyUrl` (dart-define: `PRIVACY_POLICY_URL`)

### 필수 포함 내용

1. **수집 항목**: 이메일, 닉네임, 프로필 사진, 생년월일, 구매 내역
2. **수집 목적**: 서비스 제공, 인증, 법적 의무(연령 확인), 분석, 에러 추적
3. **보유 기간**:
   - 계정 정보: 탈퇴 후 30일 (삭제 유예)
   - 거래 기록: 5년 (전자상거래법)
   - 동의 기록: 서비스 이용 기간 + 3년
4. **제3자 제공**: TossPayments (결제 처리), Sentry (에러 추적), Firebase (분석/푸시)
5. **사용자 권리**: 열람, 정정, 삭제, 동의 철회
6. **개인정보 보호 책임자**: [담당자 정보]
7. **쿠키/추적**: Firebase Analytics (옵트아웃 가능)

---

## 5. 서비스 이용약관 필수 항목

URL 설정: `AppConfig.termsOfServiceUrl` (dart-define: `TERMS_URL`)

### 필수 포함 내용

1. 서비스 정의 및 범위
2. 회원 가입 및 탈퇴
3. DT(디지털 토큰) 이용 조건 및 환불 정책
4. 구독 서비스 조건 (자동 갱신, 해지)
5. 금지 행위 (스팸, 혐오, 사칭 등)
6. 지적재산권
7. 면책 조항
8. 분쟁 해결 (관할 법원)

---

## 6. 제출 전 최종 체크리스트

### Google Play
- [ ] Data Safety 설문 모든 항목 작성
- [ ] 개인정보 처리방침 URL 등록 및 접근 가능 확인
- [ ] 서비스 이용약관 URL 등록
- [ ] 앱 콘텐츠 등급 설문 완료
- [ ] 스크린샷 업로드 (한국어)

### Apple App Store
- [ ] App Privacy Details 모든 항목 작성
- [ ] Privacy Policy URL 등록
- [ ] App Rating 설정
- [ ] App Preview / Screenshots (한국어)
- [ ] 미성년자 보호 관련 설정 (연령 확인 기능 있음)
