# UNO A 결제 동의 요구사항

**작성일: 2026-02-09**
**참조: Makestar 결제 페이지, TossPayments 약관**

---

## 1. 결제 시 필수 동의 항목

Makestar 결제 페이지 분석 결과, 다음 6가지 동의 항목이 필요합니다:

| # | 동의 항목 | 필수 여부 | 약관 링크 |
|---|----------|----------|----------|
| 1 | 주문 내용 확인 및 전체 동의 | ✅ 필수 | - |
| 2 | (필수) 개인정보 수집 동의 | ✅ 필수 | [보기] |
| 3 | (필수) 개인정보 제3자 제공 동의 (PG사) | ✅ 필수 | [보기] |
| 4 | (필수) 결제대행 서비스 이용약관 | ✅ 필수 | [보기] |
| 5 | (필수) 개인(신용)정보 국외 이전 동의 | ✅ 필수 | [보기] |
| 6 | (필수) 메이크스타 개인정보 제3자 제공 동의 | ✅ 필수 | [보기] |

---

## 2. 각 동의 항목 상세

### 2.1 개인정보 수집 동의

**수집 항목:**
- 구매자 정보: 이름, 이메일, 연락처
- 배송 정보: 배송지 주소, 수령인 정보
- 결제 정보: 결제수단, 결제금액

**이용 목적:**
- 상품/서비스 제공
- 결제 및 환불 처리
- 고객 문의 응대

**보유 기간:** 거래 완료 후 5년 (전자상거래법)

---

### 2.2 개인정보 제3자 제공 동의 (PG사)

**제공받는 자:** 토스페이먼츠 주식회사

**제공 목적:**
- 전자지급결제대행 서비스 이용
- 결제 처리 및 정산

**제공 항목:**
- 결제정보 (카드번호, 유효기간, CVC 등)
- 구매자 정보 (이름, 연락처)

**보유 기간:** 결제일로부터 5년

---

### 2.3 결제대행 서비스 이용약관 (TossPayments)

**핵심 내용:**
- 결제대행(PG) 서비스 이용약관에 따른 전자지급결제대행 서비스
- 이용자의 권리 및 의무
- 오류 정정 및 분쟁 해결 절차
- 면책 조항

**약관 원문:** https://pages.tosspayments.com/terms/user

---

### 2.4 개인(신용)정보 국외 이전 동의

**이전되는 국가:** 해외 결제 원천사 소재지

**제공받는 자:**
- Boku (해외 결제)
- PayPal (해외 결제)
- Alipay (해외 결제)

**이전 목적:** 해외 결제수단 처리

**약관 원문:** https://pages.tosspayments.com/terms/homepage/privacy/policy-crossborder

---

### 2.5 UNO A 개인정보 제3자 제공 동의

**제공받는 자:** 크리에이터 (소속사 포함)

**제공 목적:**
- 펀딩 리워드 제공
- 이벤트 참여자 확인
- 굿즈 배송

**제공 항목:**
- 이름, 이메일, 연락처
- 배송 주소 (굿즈 구매 시)
- 생년월일 (이벤트 참여 시)

**보유 기간:** 리워드 제공 완료 또는 이벤트 종료 시까지

---

## 3. 구현 요구사항

### 3.1 UI 컴포넌트

```dart
// 결제 동의 체크박스 그룹
class PaymentConsentForm extends StatefulWidget {
  final Function(bool allAgreed) onConsentChanged;
  
  // 동의 항목들
  final List<ConsentItem> items = [
    ConsentItem(
      id: 'privacy_collection',
      title: '(필수) 개인정보 수집・이용 동의',
      required: true,
      termsUrl: '/legal/privacy-collection',
    ),
    ConsentItem(
      id: 'third_party_pg',
      title: '(필수) 개인정보 제3자 제공 동의 (PG사)',
      required: true,
      termsUrl: '/legal/third-party-pg',
    ),
    ConsentItem(
      id: 'pg_terms',
      title: '(필수) 결제대행 서비스 이용약관',
      required: true,
      termsUrl: 'https://pages.tosspayments.com/terms/user',
      external: true,
    ),
    ConsentItem(
      id: 'cross_border',
      title: '(필수) 개인(신용)정보 국외 이전 동의',
      required: true,
      termsUrl: 'https://pages.tosspayments.com/terms/homepage/privacy/policy-crossborder',
      external: true,
    ),
    ConsentItem(
      id: 'third_party_creator',
      title: '(필수) UNO A 개인정보 제3자 제공 동의',
      required: true,
      termsUrl: '/legal/third-party-creator',
    ),
  ];
}
```

### 3.2 데이터베이스 스키마

```sql
-- 결제 동의 기록 테이블
CREATE TABLE payment_consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  transaction_id UUID NOT NULL,
  
  -- 동의 항목별 체크
  privacy_collection BOOLEAN DEFAULT false,
  third_party_pg BOOLEAN DEFAULT false,
  pg_terms BOOLEAN DEFAULT false,
  cross_border BOOLEAN DEFAULT false,
  third_party_creator BOOLEAN DEFAULT false,
  
  -- 동의 시점 IP 및 타임스탬프
  ip_address INET,
  user_agent TEXT,
  agreed_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- 약관 버전
  terms_version VARCHAR(20) DEFAULT '2026.02.09'
);

-- 인덱스
CREATE INDEX idx_payment_consents_user ON payment_consents(user_id);
CREATE INDEX idx_payment_consents_transaction ON payment_consents(transaction_id);
```

### 3.3 배송 정보 입력 (굿즈/펀딩 리워드)

Makestar 결제 페이지처럼 배송 정보 섹션 필요:

```dart
class ShippingInfoForm extends StatefulWidget {
  // 배송지 정보
  String? savedAddressId;     // 저장된 배송지 선택
  String addressName;         // 배송지 이름 (예: 우리집)
  String country;             // 배송국가/지역
  String postalCode;          // 우편번호
  String address1;            // 기본 주소
  String address2;            // 상세 주소
  String recipientName;       // 수령인 이름
  String phone;               // 연락처
  String? customsId;          // 통관번호 (해외배송 시)
}
```

---

## 4. 미국 배송 관세 안내 (필요 시)

Makestar 결제 페이지에 표시되는 미국 관세 안내:

> 🇺🇸 **미국행 배송 관련 관세 안내**
> 
> **1. 무엇이 달라지나요?**
> - 미국행 배송은 주문 금액(배송비 제외)의 **15% 관세**가 추가로 부과될 수 있습니다.
> - (기존 면세 기준 $800은 더 이상 적용되지 않습니다.)
> 
> **2. 결제 단계에서 선납**
> - FedEx 등 일부 배송사의 경우 배송사 정책에 따라 주문/결제 단계에서 관세를 **선납**합니다.

---

## 5. 참고 법령

- 개인정보 보호법 제17조 (개인정보의 제공)
- 전자상거래법 제13조 (통신판매업자의 신원정보 고지)
- 전자상거래법 제13조 (신원정보 등의 게시)
- 정보통신망법 제22조 (개인정보의 수집・이용 동의)
