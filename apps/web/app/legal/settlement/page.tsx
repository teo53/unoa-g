/**
 * 정산/세무 정책
 *
 * 크리에이터 정산 및 세무 처리 정책
 */

import { Metadata } from 'next'
import { legalConfig } from '@/lib/config/legal-config'

export const metadata: Metadata = {
  title: `${legalConfig.pages.settlement.title} | UNO A`,
  description: 'UNO A 정산/세무 정책',
}

export default function SettlementPage() {
  const { pages, company, tax, dt } = legalConfig

  return (
    <article className="prose prose-gray max-w-none">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">{pages.settlement.title}</h1>
        <p className="text-sm text-gray-500">최종 수정일: {pages.settlement.lastUpdated}</p>
      </div>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제1조 (목적)</h2>
        <p className="text-gray-700 leading-relaxed">
          본 정책은 {company.nameKo}(이하 &ldquo;회사&rdquo;)가 크리에이터에게 지급하는 광고용역비의 정산 및 세무 처리 절차를 규정함을 목적으로 합니다.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제2조 (정산의 법적 성격)</h2>
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
          <p className="text-blue-900 font-semibold mb-2">중요: 정산의 법적 정의</p>
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
            회사는 전자금융거래법상 전자지급결제대행업자(PG업자)가 아니며, 크리에이터 정산은 총매법(전자상거래법) 기반 광고용역비 지급입니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제3조 (매출인식 2단계 구조)</h2>
        <p className="text-gray-700 leading-relaxed mb-4">
          회사는 다음과 같은 2단계 매출인식 구조를 따릅니다:
        </p>
        <div className="overflow-x-auto">
          <table className="min-w-full border border-gray-300">
            <thead className="bg-gray-100">
              <tr>
                <th className="border border-gray-300 px-4 py-2 text-left">단계</th>
                <th className="border border-gray-300 px-4 py-2 text-left">시점</th>
                <th className="border border-gray-300 px-4 py-2 text-left">회계 처리</th>
                <th className="border border-gray-300 px-4 py-2 text-left">세무 처리</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td className="border border-gray-300 px-4 py-2 font-semibold">1단계</td>
                <td className="border border-gray-300 px-4 py-2">DT 구매 시</td>
                <td className="border border-gray-300 px-4 py-2">{tax.revenueRecognition.stage1}</td>
                <td className="border border-gray-300 px-4 py-2">과세 미발생 (선수금)</td>
              </tr>
              <tr className="bg-gray-50">
                <td className="border border-gray-300 px-4 py-2 font-semibold">2단계</td>
                <td className="border border-gray-300 px-4 py-2">DT 사용 시</td>
                <td className="border border-gray-300 px-4 py-2">{tax.revenueRecognition.stage2}</td>
                <td className="border border-gray-300 px-4 py-2">매출 인식 + VAT 발생</td>
              </tr>
            </tbody>
          </table>
        </div>
        <p className="text-sm text-gray-600 mt-4">
          이 구조는 국세청 유권해석 및 회계기준(K-IFRS 15)에 따라 설계되었습니다.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제4조 (부가가치세)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>적용 세율</strong>: {tax.vat}
          </li>
          <li>
            <strong>과세 시점</strong>: DT 사용 시 (즉, 크리에이터 후원, 콘텐츠 해금 등)
          </li>
          <li>
            <strong>사업자 크리에이터</strong>: 세금계산서를 발행하는 사업자는 부가가치세를 별도로 신고/납부해야 합니다.
          </li>
          <li>
            <strong>개인 크리에이터</strong>: 간이과세자 또는 면세 사업자의 경우 부가가치세 적용이 달라질 수 있으며, 세무사와 상담을 권장합니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제5조 (소득세 원천징수)</h2>
        <p className="text-gray-700 leading-relaxed mb-4">
          크리에이터 정산 시 소득세법에 따라 원천징수가 적용됩니다:
        </p>
        <div className="overflow-x-auto">
          <table className="min-w-full border border-gray-300">
            <thead className="bg-gray-100">
              <tr>
                <th className="border border-gray-300 px-4 py-2 text-left">구분</th>
                <th className="border border-gray-300 px-4 py-2 text-left">소득 유형</th>
                <th className="border border-gray-300 px-4 py-2 text-left">원천징수율</th>
                <th className="border border-gray-300 px-4 py-2 text-left">비고</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td className="border border-gray-300 px-4 py-2">개인 (프리랜서)</td>
                <td className="border border-gray-300 px-4 py-2">사업소득</td>
                <td className="border border-gray-300 px-4 py-2">{tax.withholding.businessIncome}</td>
                <td className="border border-gray-300 px-4 py-2">정기적 활동</td>
              </tr>
              <tr className="bg-gray-50">
                <td className="border border-gray-300 px-4 py-2">개인 (일시적)</td>
                <td className="border border-gray-300 px-4 py-2">기타소득</td>
                <td className="border border-gray-300 px-4 py-2">{tax.withholding.otherIncome}</td>
                <td className="border border-gray-300 px-4 py-2">일시적 활동</td>
              </tr>
              <tr>
                <td className="border border-gray-300 px-4 py-2">사업자 (세금계산서)</td>
                <td className="border border-gray-300 px-4 py-2">사업소득</td>
                <td className="border border-gray-300 px-4 py-2">0% (원천징수 없음)</td>
                <td className="border border-gray-300 px-4 py-2">{tax.withholding.invoice}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mt-4">
          <p className="text-yellow-900 font-semibold mb-2">참고</p>
          <ul className="list-disc list-inside space-y-1 text-gray-700">
            <li>원천징수는 회사가 정산 시 자동으로 차감하여 국세청에 신고/납부합니다.</li>
            <li>크리에이터는 5월 종합소득세 신고 시 원천징수된 금액을 기납부세액으로 공제받을 수 있습니다.</li>
          </ul>
        </div>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제6조 (정산 주기 및 방법)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>정산 주기</strong>: 매월 1일부터 말일까지의 활동에 대해 익월 15일에 정산합니다.
            <ul className="list-disc list-inside ml-6 mt-2 space-y-1">
              <li>예시: 2월 1일~28일 활동 → 3월 15일 지급</li>
            </ul>
          </li>
          <li>
            <strong>최소 정산 금액</strong>: 정산 금액이 10,000원 미만인 경우 다음 달로 이월됩니다.
          </li>
          <li>
            <strong>정산 방법</strong>: 크리에이터가 등록한 계좌로 자동 이체됩니다.
          </li>
          <li>
            <strong>정산 수수료</strong>: 플랫폼 이용 수수료 약 20%가 차감된 금액이 정산됩니다.
          </li>
          <li>
            <strong>세금 차감</strong>: 원천징수 대상인 경우 세금이 추가로 차감됩니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제7조 (정산 내역 확인)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            크리에이터는 서비스 내 정산 페이지에서 다음 정보를 확인할 수 있습니다:
            <ul className="list-disc list-inside ml-6 mt-2 space-y-1">
              <li>총 수익 (팬 후원 + 펀딩 수익 등)</li>
              <li>플랫폼 수수료 차감 금액</li>
              <li>원천징수 세액</li>
              <li>실제 지급 금액</li>
              <li>지급 예정일</li>
            </ul>
          </li>
          <li>
            정산 내역은 월별, 분기별, 연도별로 조회 가능하며, CSV 파일로 다운로드할 수 있습니다.
          </li>
          <li>
            정산 내역에 오류가 있는 경우 고객센터({company.supportEmail})로 문의해 주세요.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제8조 (원천징수영수증 발급)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            회사는 매년 2월 말까지 전년도 원천징수영수증을 발급합니다.
          </li>
          <li>
            원천징수영수증은 서비스 내 정산 페이지에서 다운로드 가능합니다.
          </li>
          <li>
            원천징수영수증은 5월 종합소득세 신고 시 필요하므로, 반드시 보관해 주세요.
          </li>
          <li>
            재발급이 필요한 경우 고객센터({company.supportEmail})로 요청하실 수 있습니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제9조 (세금 신고 의무)</h2>
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-4">
          <p className="text-red-900 font-semibold mb-2">⚠️ 중요: 크리에이터의 세금 신고 의무</p>
          <p className="text-gray-700">
            크리에이터는 본인의 소득에 대해 세법상 신고 의무를 준수해야 하며, 탈세로 인한 법적 책임은 크리에이터에게 있습니다.
          </p>
        </div>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>개인 크리에이터</strong>: 매년 5월에 종합소득세를 신고/납부해야 합니다.
          </li>
          <li>
            <strong>사업자 크리에이터</strong>: 부가가치세(1월, 7월) 및 종합소득세(5월)를 신고/납부해야 합니다.
          </li>
          <li>
            <strong>세무 상담</strong>: 회사는 세무 상담을 제공하지 않으며, 크리에이터는 세무사와 상담을 권장합니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제10조 (정산 지연 및 보류)</h2>
        <p className="text-gray-700 leading-relaxed mb-3">
          다음의 경우 정산이 지연되거나 보류될 수 있습니다:
        </p>
        <ul className="list-disc list-inside space-y-2 text-gray-700">
          <li>계좌 정보 오류 또는 미등록</li>
          <li>정산 금액이 최소 금액(10,000원) 미만</li>
          <li>부정 행위 또는 약관 위반 의심</li>
          <li>세무 정보 미제출 (사업자등록증, 신분증 사본 등)</li>
          <li>법적 분쟁 또는 수사기관 요청</li>
        </ul>
        <p className="text-gray-700 leading-relaxed mt-4">
          정산 지연 또는 보류 시 회사는 크리에이터에게 사전 통보하며, 사유가 해소되면 즉시 정산이 진행됩니다.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제11조 (정산 관련 증빙 보관)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            회사는 국세기본법에 따라 정산 관련 증빙을 5년간 보관합니다.
          </li>
          <li>
            크리에이터도 원천징수영수증, 정산 내역 등을 5년간 보관할 것을 권장합니다.
          </li>
          <li>
            세무조사 시 증빙 자료가 필요하므로, 반드시 보관해 주세요.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제12조 (해외 크리에이터</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            해외 거주 크리에이터의 경우, 한국 세법이 아닌 거주국 세법이 적용됩니다.
          </li>
          <li>
            회사는 한국-거주국 간 조세 조약에 따라 원천징수를 처리할 수 있습니다.
          </li>
          <li>
            해외 크리에이터는 본인의 거주국 세법에 따라 소득 신고 의무를 준수해야 합니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제13조 (정책 변경</h2>
        <p className="text-gray-700 leading-relaxed">
          회사는 세법 개정, 회계기준 변경 등으로 인해 본 정책을 변경할 수 있으며, 변경 시 30일 전에 공지합니다.
          크리에이터는 변경된 정책에 동의하지 않는 경우 계약을 해지할 수 있습니다.
        </p>
      </section>

      <div className="mt-12 pt-6 border-t border-gray-200">
        <p className="text-sm text-gray-500">
          본 정산/세무 정책은 {pages.settlement.lastUpdated}부터 시행됩니다.
        </p>
        <p className="text-sm text-gray-500 mt-2">
          정산 문의: {company.supportEmail}
        </p>
        <p className="text-sm text-gray-500 mt-2">
          본 정책은 법률 자문이 아니며, 세무 관련 사항은 전문 세무사와 상담하시기 바랍니다.
        </p>
      </div>
    </article>
  )
}
