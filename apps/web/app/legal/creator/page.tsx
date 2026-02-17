/**
 * 크리에이터 약관
 *
 * 크리에이터 광고용역비 정산 및 의무 사항
 */

import { Metadata } from 'next'
import { legalConfig } from '@/lib/config/legal-config'

export const metadata: Metadata = {
  title: `${legalConfig.pages.creator.title} | UNO A`,
  description: 'UNO A 크리에이터 약관',
}

export default function CreatorPage() {
  const { pages, company, dt, tax } = legalConfig

  return (
    <article className="prose prose-gray max-w-none">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">{pages.creator.title}</h1>
        <p className="text-sm text-gray-500">최종 수정일: {pages.creator.lastUpdated}</p>
      </div>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제1조 (목적)</h2>
        <p className="text-gray-700 leading-relaxed">
          본 약관은 {company.nameKo}(이하 &ldquo;회사&rdquo;)가 제공하는 크리에이터 서비스의 이용 및 광고용역비 정산에 관한 사항을 규정함을 목적으로 합니다.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제2조 (정의)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li><strong>크리에이터</strong>: 회사의 플랫폼을 통해 콘텐츠를 제공하고 팬과 소통하는 회원</li>
          <li><strong>광고용역비</strong>: 회사가 크리에이터의 콘텐츠 활동에 대해 지급하는 대가</li>
          <li><strong>정산</strong>: 회사가 크리에이터에게 광고용역비를 계산하여 지급하는 절차</li>
          <li><strong>채널</strong>: 크리에이터가 팬과 소통하는 개별 공간</li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제3조 (광고용역비 정산의 법적 성격)</h2>
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
          <p className="text-blue-900 font-semibold mb-2">중요: 정산의 법적 성격</p>
          <p className="text-gray-700">{dt.settlementNote}</p>
        </div>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            크리에이터에 대한 정산은 소비자 결제대금의 전달이 아닌, 회사가 크리에이터의 광고용역 활동에 대해 지급하는 광고용역비입니다.
          </li>
          <li>
            정산 금액은 팬이 사용한 DT 금액과 1:1 대응 관계가 아니며, 회사의 정책에 따라 결정됩니다.
          </li>
          <li>
            크리에이터는 회사와 독립적인 사업자로서 광고용역을 제공하며, 고용관계가 아닙니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제4조 (크리에이터 가입 자격)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            만 19세 이상의 개인 또는 사업자로서, 본 약관에 동의한 자만 크리에이터로 활동할 수 있습니다.
          </li>
          <li>
            정산을 받기 위해서는 다음 서류를 제출해야 합니다:
            <ul className="list-disc list-inside ml-6 mt-2 space-y-1">
              <li>개인: 신분증 사본, 통장 사본</li>
              <li>사업자: 사업자등록증 사본, 통장 사본</li>
            </ul>
          </li>
          <li>
            허위 정보를 제공하거나 타인의 명의를 도용한 경우, 계약이 즉시 해지되며 법적 책임을 질 수 있습니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제5조 (크리에이터의 의무)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            크리에이터는 건전한 콘텐츠를 제공하고 팬과 성실히 소통해야 합니다.
          </li>
          <li>
            크리에이터는 다음 행위를 하여서는 안 됩니다:
            <ul className="list-disc list-inside ml-6 mt-2 space-y-1">
              <li>음란물, 폭력적, 혐오적 콘텐츠 제공</li>
              <li>허위 정보 유포 또는 사기 행위</li>
              <li>타인의 지적재산권 침해 (무단 도용, 표절 등)</li>
              <li>팬의 개인정보를 부정하게 수집하거나 악용</li>
              <li>불법 물품 판매 또는 불법 행위 조장</li>
              <li>외부 플랫폼 유도 (현금 거래, 외부 링크 등)</li>
            </ul>
          </li>
          <li>
            크리에이터는 팬이 구독료 또는 DT를 지불한 경우, 약속한 콘텐츠 및 혜택을 성실히 제공해야 합니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제6조 (정산 기준 및 절차)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>정산 기준</strong>: 회사는 크리에이터의 활동 내역을 기준으로 광고용역비를 산정합니다. 플랫폼 수수료(약 20%)를 차감한 금액이 정산됩니다.
          </li>
          <li>
            <strong>정산 주기</strong>: 매월 1일부터 말일까지의 활동에 대해 익월 15일에 정산합니다.
          </li>
          <li>
            <strong>최소 정산 금액</strong>: 정산 금액이 10,000원 미만인 경우 다음 달로 이월됩니다.
          </li>
          <li>
            <strong>정산 지연</strong>: 정산 정보 오류, 계좌 문제 등으로 인한 지연 시 회사는 크리에이터에게 사전 통보합니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제7조 (세금 및 원천징수)</h2>
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-4">
          <p className="text-yellow-900 font-semibold mb-2">⚠️ 세금 및 원천징수 안내</p>
          <ul className="list-disc list-inside space-y-1 text-gray-700">
            <li><strong>사업소득</strong>: {tax.withholding.businessIncome}</li>
            <li><strong>기타소득</strong>: {tax.withholding.otherIncome}</li>
            <li><strong>세금계산서 발행 사업자</strong>: {tax.withholding.invoice}</li>
          </ul>
        </div>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>개인 크리에이터</strong>: 사업소득 또는 기타소득으로 분류되며, 회사는 소득세법에 따라 원천징수합니다.
          </li>
          <li>
            <strong>사업자 크리에이터</strong>: 세금계산서를 발행하는 경우 원천징수가 없으며, 부가가치세({tax.vat})가 별도로 적용됩니다.
          </li>
          <li>
            <strong>원천징수영수증</strong>: 회사는 매년 2월 말까지 전년도 원천징수영수증을 발급합니다.
          </li>
          <li>
            크리에이터는 본인의 세금 신고 의무를 준수해야 하며, 탈세로 인한 책임은 크리에이터에게 있습니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제8조 (금지행위)</h2>
        <p className="text-gray-700 leading-relaxed mb-3">
          크리에이터는 다음 행위를 절대 하여서는 안 됩니다:
        </p>
        <ul className="list-disc list-inside space-y-2 text-gray-700">
          <li>팬에게 직접 현금 거래 유도 (플랫폼 우회 결제)</li>
          <li>팬의 개인정보를 부정하게 수집하거나 외부 유출</li>
          <li>다른 크리에이터 사칭 또는 허위 정보 유포</li>
          <li>불법 콘텐츠 제공 (음란물, 도박, 불법 물품 등)</li>
          <li>자동화 도구(봇)를 사용한 팬 유치 또는 메시지 발송</li>
          <li>정산 금액 조작 또는 부정 청구</li>
        </ul>
        <p className="text-gray-700 leading-relaxed mt-4">
          위반 시 회사는 계정을 정지하고, 정산을 보류하며, 법적 조치를 취할 수 있습니다.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제9조 (계약 해지)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>크리에이터의 해지</strong>: 크리에이터는 언제든지 계약을 해지할 수 있으며, 해지 시 잔여 정산 금액은 정산일에 지급됩니다.
          </li>
          <li>
            <strong>회사의 해지</strong>: 회사는 다음의 경우 계약을 즉시 해지할 수 있습니다:
            <ul className="list-disc list-inside ml-6 mt-2 space-y-1">
              <li>본 약관 또는 관련 법령 위반</li>
              <li>금지행위 적발</li>
              <li>6개월 이상 활동이 없는 경우</li>
            </ul>
          </li>
          <li>
            계약 해지 시 크리에이터의 콘텐츠는 회사가 정한 기간 동안 유지될 수 있으며, 팬이 구독 중인 경우 구독 종료 시까지 콘텐츠가 제공됩니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제10조 (지적재산권)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            크리에이터가 제공한 콘텐츠의 저작권은 크리에이터에게 있습니다.
          </li>
          <li>
            크리에이터는 회사에 서비스 운영, 마케팅, 프로모션 목적으로 콘텐츠를 사용할 수 있는 비독점적 권리를 부여합니다.
          </li>
          <li>
            크리에이터는 제3자의 지적재산권을 침해하지 않는 콘텐츠만 제공해야 하며, 침해로 인한 법적 책임은 크리에이터에게 있습니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제11조 (면책 조항)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            회사는 크리에이터와 팬 간의 분쟁에 대해 책임을 지지 않습니다.
          </li>
          <li>
            회사는 크리에이터가 제공한 콘텐츠의 진위, 정확성, 적법성에 대해 책임을 지지 않습니다.
          </li>
          <li>
            회사는 천재지변, 전쟁, 서비스 장애 등 불가항력으로 인한 정산 지연 또는 서비스 중단에 대해 책임을 지지 않습니다.
          </li>
        </ol>
      </section>

      <div className="mt-12 pt-6 border-t border-gray-200">
        <p className="text-sm text-gray-500">
          본 크리에이터 약관은 {pages.creator.lastUpdated}부터 시행됩니다.
        </p>
        <p className="text-sm text-gray-500 mt-2">
          크리에이터 문의: {company.supportEmail}
        </p>
      </div>
    </article>
  )
}
