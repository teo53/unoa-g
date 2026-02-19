# UNO A 실행 계획 (업데이트)

## 목적
- 리뷰에서 나온 보안/라우팅/운영 오동작 이슈를 먼저 해결한다.
- 이후 팬 광고 구매/관리, 광고 노출, 관리자 심사, 라우트/검증까지 순차 적용한다.

## 원칙
- 운영에서 실패를 성공처럼 보이지 않게 처리
- RLS/DB 제약으로 우선 방어
- 데모/운영 동작 분리를 명확히 유지

## 공개 인터페이스 변경
1. `lib/navigation/app_router.dart`
- `/fan-ads/purchase`, `/my-ads` 라우트 추가
- `AppRoutes` 상수 추가

2. `lib/shared/utils/share_utils.dart`
- `shareFundingCampaign`을 `campaignSlug` 우선 링크(`/p/{slug}`)로 변경
- 공유 URL 하드코딩 제거 (설정 기반)

3. `lib/providers/ops_config_provider.dart`
- `OpsPublishedBanner`에 `sourceType`, `fanAdId`(optional) 추가
- 정렬 우선순위: `ops > fan_ad > creator_promo`

4. `apps/web/lib/ops/ops-types.ts`
- `BannerPlacement` 확장: `chat_list`, `funding_top`
- 라벨/권장 규격 상수 업데이트

5. Supabase
- `fan_ads` RLS 강화 (상태/결제 필드 임의 조작 차단)
- `creator_*` 공개 조회 정책에 anon 포함
- `ops_banners` placement 체크 제약 확장

## 단계별 작업

### 1단계: 리뷰 이슈 선해결
1. `supabase/migrations/060_fan_ads.sql`
- `fan_ads_own_insert`에서 `status='pending_review'`, `payment_status='pending'` 강제
- `fan_ads_own_update` fan 허용 전이만 허용(취소 등 제한적)
- `link_type`, `payment_status`, `status` 체크 제약 추가
- `payment_amount_krw > 0` 제약 추가
- `ops_banners` placement 체크에 `chat_list`, `funding_top` 포함

2. `supabase/migrations/059_creator_content_public.sql`
- `*_public_read`를 anon+authenticated 조회 가능하게 조정
- 정책명/주석과 실제 동작 일치

3. `lib/navigation/app_router.dart`
- `/fan-ads/purchase` query `artistId` 파싱
- `/my-ads` 라우트 연결
- `artist_profile_screen.dart` 진입 경로 정합성 보장

4. `lib/providers/fan_ad_provider.dart`
- 비데모에서 실제 조회/삽입/갱신 구현
- `paymentServiceProvider`로 결제 후 `fan_ads` 생성
- 실패는 `false + AsyncError`로 처리

5. `apps/web/lib/hooks/use-artist-profile.ts`
- `artistId` 변경 시 `isLoading/error` 초기화
- `AbortController` 경쟁 요청 정리
- `artistId` URL 인코딩 적용

6. `lib/shared/utils/share_utils.dart`
- 펀딩 링크를 `/p/{slug}` 우선으로 사용
- slug 미제공 시 `/funding` fallback
- 데모 URL 하드코딩 제거

7. 공유 URL 설정 소스 통일
- Flutter는 `app_public_config.flags.share_links.payload.base_url` 사용
- 미설정 시 데모만 fallback, 비데모는 공유 차단+안내

### 2단계: 잔여 구축
1. 팬 광고 화면
- `fan_ad_purchase_screen.dart` 실제 provider 호출 기반 마무리
- `my_ads_screen.dart` 생성
- 상태 필터/통계/취소 액션 연결

2. 광고 위젯/배치
- `native_ad_card.dart` 생성
- 홈/탐색/채팅/펀딩 슬롯 배치

3. 배너 통합
- `ops_config_provider.dart`에서 `source_type` 파싱/정렬 반영
- `chat_list`와 `chat_top` alias 처리

4. 웹 관리자 심사
- `apps/web/app/(admin)/admin/fan-ads/page.tsx` 생성
- 상태 탭/승인/거절/사유 입력 구현
- 승인 시 `ops_banners` 반영 + config refresh

5. 관리자 내비게이션
- `apps/web/app/(admin)/admin/layout.tsx`에 팬 광고 심사 링크 추가

6. 진입점
- `artist_profile_screen.dart` 광고 구매 버튼 유지
- `my_profile_screen.dart`에 내 광고 메뉴 추가

### 3단계: 웹 프로필 라우트 안정화
1. `apps/web/app/artist/[id]/layout.tsx` 생성
2. `apps/web/app/artist/[id]/page.tsx` 보강
- `generateStaticParams`
- `generateMetadata`
- 딥링크 fallback 중복/오동작 정리

### 4단계: 검증/머지 전 리뷰
1. 정적 검사
- `flutter analyze`
- `npm --prefix apps/web run lint`
- `npm --prefix apps/web run type-check`
- `npm --prefix apps/web run build`

2. 기능 시나리오 확인
- 공유 URL 설정 유무/데모 분기
- 팬 광고 3단계 플로우
- 실패 시 성공 UI 미노출
- 광고 슬롯 노출
- 관리자 승인/거절 반영
- anon 공개 조회 확인

3. 보안 회귀
- fan 계정 임의 status/payment 조작 차단
- 타인 광고 조회/수정 차단

4. 머지 전
- `git diff --check`
- 변경 파일 위험도 재분류
- SQL 롤백 초안 포함

## 가정/기본값
1. 공유 URL 단일 소스: `app_public_config.flags.share_links.payload.base_url`
2. 비데모는 실결제 + DB 생성
3. 내 광고는 하단 탭이 아닌 프로필 메뉴 진입
4. `ops_banners`는 `chat_top` 호환 유지 + `chat_list`, `funding_top` 확장
5. 현재 `059/060`은 배포 전 브랜치 상태로 가정
