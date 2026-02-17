/**
 * 펀딩 약관
 *
 * 보상형 크라우드펀딩 약관
 */

import { Metadata } from 'next'
import { legalConfig } from '@/lib/config/legal-config'

export const metadata: Metadata = {
  title: `${legalConfig.pages.funding.title} | UNO A`,
  description: 'UNO A 펀딩 약관',
}

export default function FundingPage() {
  const { pages, company } = legalConfig

  return (
    <article className="prose prose-gray max-w-none">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">{pages.funding.title}</h1>
        <p className="text-sm text-gray-500">최종 수정일: {pages.funding.lastUpdated}</p>
      </div>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제1조 (목적)</h2>
        <p className="text-gray-700 leading-relaxed">
          본 약관은 {company.nameKo}(이하 &ldquo;회사&rdquo;)가 제공하는 보상형 크라우드펀딩 서비스(이하 &ldquo;펀딩 서비스&rdquo;)의 이용에 관한 사항을 규정함을 목적으로 합니다.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제2조 (정의)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li><strong>펀딩</strong>: 크리에이터가 특정 프로젝트를 위해 팬에게 후원을 받는 활동</li>
          <li><strong>펀더</strong>: 펀딩에 참여하여 후원금을 지불한 이용자</li>
          <li><strong>리워드</strong>: 펀딩 성공 시 크리에이터가 펀더에게 제공하는 보상 (굿즈, 콘텐츠 등)</li>
          <li><strong>목표 금액</strong>: 펀딩 성공을 위한 최소 후원금 총액</li>
          <li><strong>펀딩 기간</strong>: 펀딩을 진행하는 시작일부터 종료일까지의 기간</li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제3조 (펀딩의 성격)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>보상형 펀딩</strong>: 본 펀딩은 보상형 크라우드펀딩으로, 펀더는 금전적 수익이 아닌 리워드를 받습니다.
          </li>
          <li>
            <strong>투자가 아님</strong>: 펀딩은 투자가 아니며, 금전적 수익을 기대할 수 없습니다.
          </li>
          <li>
            <strong>프로젝트 지원</strong>: 펀더는 크리에이터의 프로젝트를 지원하는 후원자로서 참여합니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제4조 (펀딩 절차)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>펀딩 생성</strong>: 크리에이터는 펀딩 제목, 목표 금액, 기간, 리워드 등을 설정하여 펀딩을 생성합니다.
          </li>
          <li>
            <strong>검토 및 승인</strong>: 회사는 펀딩 내용을 검토하고, 본 약관 및 관련 법령에 위배되지 않는 경우 승인합니다.
          </li>
          <li>
            <strong>펀딩 진행</strong>: 승인된 펀딩은 설정된 기간 동안 공개되며, 팬은 리워드를 선택하여 후원할 수 있습니다.
          </li>
          <li>
            <strong>결제</strong>: 펀더가 후원을 신청하면 즉시 결제가 진행됩니다. (단, 펀딩 실패 시 전액 환불)
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제5조 (펀딩 성공 및 실패)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>성공 기준</strong>: 펀딩 기간 종료 시점에 목표 금액 이상의 후원금이 모인 경우 펀딩이 성공합니다.
          </li>
          <li>
            <strong>실패 기준</strong>: 펀딩 기간 종료 시점에 목표 금액에 도달하지 못한 경우 펀딩이 실패합니다.
          </li>
          <li>
            <strong>성공 시</strong>: 크리에이터는 후원금을 수령하고, 약속한 리워드를 펀더에게 제공해야 합니다.
          </li>
          <li>
            <strong>실패 시</strong>: 모든 펀더에게 후원금이 전액 자동 환불되며, 리워드 제공 의무가 발생하지 않습니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제6조 (크리에이터의 의무)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>리워드 제공</strong>: 펀딩 성공 시 크리에이터는 약속한 리워드를 정해진 기한 내에 펀더에게 제공해야 합니다.
          </li>
          <li>
            <strong>진행 상황 공유</strong>: 크리에이터는 펀딩 진행 상황 및 리워드 제작/배송 상황을 펀더에게 주기적으로 공지해야 합니다.
          </li>
          <li>
            <strong>정확한 정보 제공</strong>: 크리에이터는 허위 정보를 제공하거나 펀더를 기만해서는 안 됩니다.
          </li>
          <li>
            <strong>지연 안내</strong>: 리워드 제공이 지연되는 경우 사전에 펀더에게 안내하고, 지연 사유를 명확히 설명해야 합니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제7조 (펀더의 권리 및 의무)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>후원 취소</strong>: 펀딩 기간 중에는 후원을 취소할 수 없으며, 펀딩 실패 시에만 자동 환불됩니다.
          </li>
          <li>
            <strong>리워드 수령</strong>: 펀딩 성공 시 펀더는 선택한 리워드를 받을 권리가 있습니다.
          </li>
          <li>
            <strong>정보 제공</strong>: 펀더는 리워드 배송을 위해 정확한 주소 및 연락처를 제공해야 합니다.
          </li>
          <li>
            <strong>프로젝트 지원</strong>: 펀더는 크리에이터의 프로젝트 성공을 위해 건설적인 피드백을 제공할 수 있습니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제8조 (환불 정책)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>펀딩 실패</strong>: 펀딩 실패 시 모든 펀더에게 후원금이 전액 자동 환불됩니다.
          </li>
          <li>
            <strong>펀딩 성공 후</strong>: 펀딩 성공 후에는 단순 변심으로 인한 환불이 불가능합니다.
          </li>
          <li>
            <strong>리워드 미제공</strong>: 크리에이터가 약속한 기한 내에 리워드를 제공하지 않는 경우, 펀더는 전액 환불을 요청할 수 있습니다.
          </li>
          <li>
            <strong>리워드 하자</strong>: 배송 중 파손되거나 하자가 있는 리워드는 교환 또는 환불 처리됩니다.
          </li>
          <li>
            <strong>사기 펀딩</strong>: 크리에이터의 사기 행위가 확인된 경우, 회사는 펀더 보호를 위해 환불 조치를 취합니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제9조 (금지 행위)</h2>
        <p className="text-gray-700 leading-relaxed mb-3">
          크리에이터 및 펀더는 다음 행위를 하여서는 안 됩니다:
        </p>
        <ul className="list-disc list-inside space-y-2 text-gray-700">
          <li><strong>크리에이터</strong>:
            <ul className="list-disc list-inside ml-6 mt-2 space-y-1">
              <li>허위 정보 제공 또는 사기 펀딩</li>
              <li>불법 물품/서비스를 리워드로 제공</li>
              <li>자전 펀딩 (본인 또는 지인이 후원하여 성공률 조작)</li>
              <li>리워드 미제공 또는 약속 위반</li>
            </ul>
          </li>
          <li><strong>펀더</strong>:
            <ul className="list-disc list-inside ml-6 mt-2 space-y-1">
              <li>허위 정보 제공 (배송지, 연락처 등)</li>
              <li>타인 명의 도용</li>
              <li>부당한 환불 요구 또는 악의적 민원</li>
            </ul>
          </li>
        </ul>
        <p className="text-gray-700 leading-relaxed mt-4">
          위반 시 회사는 계정을 정지하고, 법적 조치를 취할 수 있습니다.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제10조 (플랫폼 수수료)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            회사는 펀딩 성공 시 후원금의 일정 비율(약 20%)을 플랫폼 이용 수수료로 받습니다.
          </li>
          <li>
            수수료는 결제 수수료, 서비스 운영 비용 등을 포함하며, 펀딩 생성 전에 크리에이터에게 고지됩니다.
          </li>
          <li>
            크리에이터는 수수료를 차감한 금액을 정산 받습니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제11조 (책임의 제한)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            회사는 크리에이터와 펀더 간의 분쟁에 대해 중재 역할을 할 수 있으나, 법적 책임을 지지 않습니다.
          </li>
          <li>
            회사는 크리에이터가 제공한 펀딩 정보의 진위, 리워드의 품질, 배송 지연 등에 대해 책임을 지지 않습니다.
          </li>
          <li>
            회사는 천재지변, 전쟁, 서비스 장애 등 불가항력으로 인한 펀딩 중단 또는 지연에 대해 책임을 지지 않습니다.
          </li>
          <li>
            다만, 크리에이터의 사기 행위 또는 리워드 미제공이 확인된 경우, 회사는 펀더 보호를 위해 합리적인 조치를 취합니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제12조 (분쟁 해결)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            펀딩 관련 분쟁 발생 시 고객센터({company.supportEmail})를 통해 1차 협의를 진행합니다.
          </li>
          <li>
            협의가 이루어지지 않는 경우, 한국소비자원 또는 소비자분쟁조정위원회에 분쟁조정을 신청할 수 있습니다.
          </li>
          <li>
            법적 분쟁 시 대한민국 법원의 관할을 따릅니다.
          </li>
        </ol>
      </section>

      <div className="mt-12 pt-6 border-t border-gray-200">
        <p className="text-sm text-gray-500">
          본 펀딩 약관은 {pages.funding.lastUpdated}부터 시행됩니다.
        </p>
        <p className="text-sm text-gray-500 mt-2">
          펀딩 문의: {company.supportEmail}
        </p>
      </div>
    </article>
  )
}
