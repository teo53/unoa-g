/**
 * 환불정책
 *
 * 전자상거래법 기반 청약철회 및 환불 정책
 */

import { Metadata } from 'next'
import { legalConfig } from '@/lib/config/legal-config'

export const metadata: Metadata = {
  title: `${legalConfig.pages.refund.title} | UNO A`,
  description: 'UNO A 환불정책',
}

export default function RefundPage() {
  const { pages, company, refund } = legalConfig

  return (
    <article className="prose prose-gray max-w-none">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">{pages.refund.title}</h1>
        <p className="text-sm text-gray-500">최종 수정일: {pages.refund.lastUpdated}</p>
      </div>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제1조 (목적)</h2>
        <p className="text-gray-700 leading-relaxed">
          본 환불정책은 {company.nameKo}(이하 &ldquo;회사&rdquo;)가 제공하는 서비스의 청약철회 및 환불 절차를 규정하며, 전자상거래법, 소비자보호법 등 관련 법령을 준수합니다.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제2조 (청약철회)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>청약철회 기간</strong>: 구매일로부터 {refund.periodDays}일 이내에 청약철회를 요청할 수 있습니다.
          </li>
          <li>
            <strong>청약철회 방법</strong>: 서비스 내 환불 신청 또는 고객센터({company.supportEmail})를 통해 신청 가능합니다.
          </li>
          <li>
            <strong>청약철회 효과</strong>: 청약철회 시 구매금액 전액이 환불됩니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제3조 (환불 처리)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>처리 기한</strong>: 환불 신청 접수 후 {refund.processingDays}영업일 이내에 처리됩니다.
          </li>
          <li>
            <strong>환불 방법</strong>: 결제 수단에 따라 다음과 같이 환불됩니다:
            <ul className="list-disc list-inside ml-6 mt-2 space-y-1">
              <li><strong>신용카드</strong>: 카드사 승인 취소 (승인 취소 시점에 따라 결제 취소 또는 익월 청구 차감)</li>
              <li><strong>계좌이체</strong>: 환불 계좌로 입금 ({refund.processingDays}영업일 소요)</li>
              <li><strong>기타 간편결제</strong>: 해당 결제사 정책에 따라 처리</li>
            </ul>
          </li>
          <li>
            <strong>지연 배상</strong>: 회사가 환불을 지연하는 경우 {refund.delayRateNote}을 가산하여 지급합니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제4조 (환불 불가 사유)</h2>
        <p className="text-gray-700 leading-relaxed mb-3">
          다음 각 호의 경우 환불이 제한됩니다:
        </p>
        <ul className="list-disc list-inside space-y-2 text-gray-700">
          {refund.nonRefundable.map((item, idx) => (
            <li key={idx}>{item}</li>
          ))}
          <li>청약철회 기간({refund.periodDays}일)이 경과한 경우 (단, 정당한 사유가 있는 경우 예외)</li>
          <li>구독권의 경우, 이용기간이 시작된 후에는 일할 계산하여 잔여 금액 환불</li>
          <li>프로모션 또는 할인 혜택으로 무료/저가 제공된 DT</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제5조 (DT 환불)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>미사용 DT</strong>: 구매 후 사용하지 않은 DT는 청약철회 기간 내에 전액 환불 가능합니다.
          </li>
          <li>
            <strong>부분 사용 DT</strong>: DT를 부분 사용한 경우, 미사용 금액에 대해서만 환불 가능합니다.
          </li>
          <li>
            <strong>보너스 DT</strong>: 프로모션으로 지급된 보너스 DT는 환불 대상이 아닙니다.
          </li>
          <li>
            <strong>유효기간 만료</strong>: 구매일로부터 5년 경과 시 DT는 자동 소멸되며, 소멸된 DT는 환불되지 않습니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제6조 (펀딩 리워드 환불)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>펀딩 실패</strong>: 펀딩이 목표 금액에 도달하지 못한 경우 결제 금액 전액이 자동 환불됩니다.
          </li>
          <li>
            <strong>펀딩 성공 후</strong>: 펀딩 성공 후에는 크리에이터의 리워드 제공 의무가 발생하므로, 단순 변심으로 인한 환불은 불가능합니다.
          </li>
          <li>
            <strong>리워드 미제공</strong>: 크리에이터가 약속한 기한 내에 리워드를 제공하지 않는 경우, 전액 환불 요청이 가능합니다.
          </li>
          <li>
            <strong>배송 중 파손</strong>: 배송 중 파손된 리워드는 교환 또는 환불 처리됩니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제7조 (구독 환불)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>구독 취소</strong>: 구독은 언제든지 취소 가능하며, 취소 시점부터 자동 결제가 중단됩니다.
          </li>
          <li>
            <strong>일할 환불</strong>: 구독 기간 중 취소한 경우, 잔여 기간에 대한 금액을 일할 계산하여 환불합니다.
          </li>
          <li>
            <strong>환불 제외</strong>: 이미 제공된 혜택(메시지 답장 토큰, 프라이빗 카드 등)은 환불 금액 산정 시 차감됩니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제8조 (환불 수수료)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            회사의 귀책사유로 인한 환불 시 수수료는 회사가 부담합니다.
          </li>
          <li>
            소비자의 단순 변심으로 인한 환불 시, 결제 수수료 등 실제 발생한 비용을 차감한 금액이 환불됩니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제9조 (분쟁 해결)</h2>
        <p className="text-gray-700 leading-relaxed mb-3">
          환불 관련 분쟁이 발생한 경우 다음 절차를 따릅니다:
        </p>
        <ol className="list-decimal list-inside space-y-2 text-gray-700">
          <li>고객센터({company.supportEmail})를 통한 1차 협의</li>
          <li>협의가 이루어지지 않는 경우, 한국소비자원 또는 소비자분쟁조정위원회에 분쟁조정 신청 가능</li>
          <li>법적 분쟁 시 대한민국 법원의 관할을 따름</li>
        </ol>
      </section>

      <div className="mt-12 pt-6 border-t border-gray-200">
        <p className="text-sm text-gray-500">
          본 환불정책은 {pages.refund.lastUpdated}부터 시행됩니다.
        </p>
        <p className="text-sm text-gray-500 mt-2">
          환불 관련 문의: {company.supportEmail}
        </p>
      </div>
    </article>
  )
}
