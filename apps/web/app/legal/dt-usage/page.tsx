/**
 * DT 이용약관
 *
 * 디지털 토큰(DT) 법적 정의 및 이용 약관
 */

import { Metadata } from 'next'
import { legalConfig } from '@/lib/config/legal-config'

export const metadata: Metadata = {
  title: `${legalConfig.pages.dtUsage.title} | UNO A`,
  description: 'UNO A DT(Digital Token) 이용약관',
}

export default function DtUsagePage() {
  const { pages, company, dt } = legalConfig

  return (
    <article className="prose prose-gray max-w-none">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">{pages.dtUsage.title}</h1>
        <p className="text-sm text-gray-500">최종 수정일: {pages.dtUsage.lastUpdated}</p>
      </div>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제1조 (목적)</h2>
        <p className="text-gray-700 leading-relaxed">
          본 약관은 {company.nameKo}(이하 &ldquo;회사&rdquo;)가 제공하는 디지털 토큰(이하 &ldquo;DT&rdquo;)의 법적 성격, 구매, 사용 및 환불에 관한 사항을 규정함을 목적으로 합니다.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제2조 (DT의 법적 정의)</h2>
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
          <p className="text-gray-900 font-semibold mb-2">DT (Digital Token)란?</p>
          <p className="text-gray-700">{dt.definition}</p>
        </div>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>법적 성격</strong>: {dt.nature}
          </li>
          <li>
            <strong>전자금융거래법 적용 제외</strong>: DT는 전자금융거래법상 선불전자지급수단이 아니며, 전자지급결제대행업(PG업) 규제 대상이 아닙니다.
          </li>
          <li>
            <strong>금융상품 아님</strong>: DT는 금융상품이 아니며, 투자 수익을 기대할 수 없습니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제3조 (DT의 구매)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            이용자는 회사가 정한 방법으로 DT를 구매할 수 있습니다.
          </li>
          <li>
            DT 구매 시 결제한 금액은 회사에 귀속되며, 이용자는 DT에 대한 이용권을 취득합니다.
          </li>
          <li>
            DT 구매 금액은 회사가 정한 정책에 따라 변경될 수 있으며, 변경 시 사전 공지합니다.
          </li>
          <li>
            미성년자가 DT를 구매하는 경우 법정대리인의 동의가 필요합니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제4조 (DT의 사용)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            이용자는 DT를 사용하여 다음의 서비스를 이용할 수 있습니다:
            <ul className="list-disc list-inside ml-6 mt-2 space-y-1">
              <li>크리에이터에게 후원 메시지 전송</li>
              <li>크리에이터 콘텐츠 해금 (예정)</li>
              <li>프리미엄 기능 이용 (예정)</li>
              <li>기타 회사가 제공하는 유료 서비스</li>
            </ul>
          </li>
          <li>
            DT 사용 시 차감되는 금액은 각 서비스별로 상이하며, 서비스 이용 전에 고지됩니다.
          </li>
          <li>
            사용된 DT는 복구되지 않으며, 환불 대상에서 제외됩니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제5조 (DT의 유효기간)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            DT의 유효기간은 구매일로부터 <strong>{dt.expirationYears}년</strong>입니다.
          </li>
          <li>
            유효기간이 만료된 DT는 자동으로 소멸되며, 소멸된 DT는 복구 또는 환불되지 않습니다.
          </li>
          <li>
            유효기간 만료 30일 전부터 서비스 내 알림 또는 이메일로 안내합니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제6조 (DT의 금지사항)</h2>
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-4">
          <p className="text-red-900 font-semibold mb-2">⚠️ DT는 다음 행위가 엄격히 금지됩니다:</p>
          <ul className="list-disc list-inside space-y-1 text-red-800">
            {dt.prohibitions.map((item, idx) => (
              <li key={idx}>{item}</li>
            ))}
          </ul>
        </div>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>현금 전환 금지</strong>: DT는 어떠한 경우에도 현금으로 전환할 수 없습니다.
          </li>
          <li>
            <strong>양도 금지</strong>: DT는 다른 이용자에게 양도, 대여, 증여할 수 없습니다.
          </li>
          <li>
            <strong>외부 교환 금지</strong>: DT를 외부 플랫폼의 포인트나 가상자산과 교환할 수 없습니다.
          </li>
          <li>
            <strong>도박 사용 금지</strong>: DT를 도박, 사행성 게임 등에 사용할 수 없습니다.
          </li>
          <li>
            위반 시 회사는 해당 이용자의 계정을 정지하고 법적 조치를 취할 수 있습니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제7조 (DT의 환불)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>미사용 DT</strong>: 구매 후 사용하지 않은 DT는 청약철회 기간(7일) 내에 전액 환불 가능합니다.
          </li>
          <li>
            <strong>부분 사용 DT</strong>: DT를 부분 사용한 경우, 미사용 금액에 대해서만 환불 가능합니다.
          </li>
          <li>
            <strong>보너스 DT</strong>: 프로모션으로 지급된 보너스 DT는 환불 대상이 아닙니다.
          </li>
          <li>
            <strong>환불 방법</strong>: 환불 신청은 서비스 내 환불 신청 또는 고객센터({company.supportEmail})를 통해 가능합니다.
          </li>
          <li>
            환불 관련 상세 내용은 별도의 환불정책을 따릅니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제8조 (크리에이터 정산)</h2>
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-4">
          <p className="text-yellow-900 font-semibold mb-2">중요: 크리에이터 정산의 법적 성격</p>
          <p className="text-gray-700">{dt.settlementNote}</p>
        </div>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            이용자가 크리에이터에게 DT를 사용하여 후원한 경우, 회사는 자체 기준에 따라 크리에이터에게 광고용역비를 정산합니다.
          </li>
          <li>
            정산 금액은 DT 사용액과 1:1 대응 관계가 아니며, 회사의 정책에 따라 결정됩니다.
          </li>
          <li>
            크리에이터는 회사와 별도의 크리에이터 약관에 동의하여야 정산을 받을 수 있습니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제9조 (책임의 제한)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            회사는 천재지변, 전쟁, 파업, 서비스 장애 등 불가항력으로 인한 DT 서비스 중단에 대해 책임을 지지 않습니다.
          </li>
          <li>
            이용자의 귀책사유로 인한 DT 손실(계정 도용, 비밀번호 유출 등)에 대해 회사는 책임을 지지 않습니다.
          </li>
          <li>
            회사는 이용자가 DT를 사용하여 크리에이터와 주고받은 콘텐츠의 품질, 진위 여부에 대해 책임을 지지 않습니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제10조 (약관의 변경)</h2>
        <p className="text-gray-700 leading-relaxed">
          회사는 필요한 경우 관련 법령을 위배하지 않는 범위에서 본 약관을 변경할 수 있으며, 변경 시 7일 전에 공지합니다. 이용자가 변경된 약관에 동의하지 않는 경우, 서비스 이용을 중단하고 계약을 해지할 수 있습니다.
        </p>
      </section>

      <div className="mt-12 pt-6 border-t border-gray-200">
        <p className="text-sm text-gray-500">
          본 DT 이용약관은 {pages.dtUsage.lastUpdated}부터 시행됩니다.
        </p>
        <p className="text-sm text-gray-500 mt-2">
          DT 관련 문의: {company.supportEmail}
        </p>
      </div>
    </article>
  )
}
