/**
 * 사업자정보
 *
 * 전자상거래법 제13조 필수 고지 사항
 */

import { Metadata } from 'next'
import { legalConfig } from '@/lib/config/legal-config'

export const metadata: Metadata = {
  title: `${legalConfig.pages.company.title} | UNO A`,
  description: 'UNO A 사업자정보',
}

export default function CompanyPage() {
  const { pages, company } = legalConfig

  return (
    <article className="prose prose-gray max-w-none">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">{pages.company.title}</h1>
        <p className="text-sm text-gray-500">최종 수정일: {pages.company.lastUpdated}</p>
      </div>

      <section className="mb-8">
        <p className="text-gray-700 leading-relaxed mb-6">
          전자상거래법 제13조에 따른 통신판매업자 정보를 다음과 같이 공개합니다.
        </p>

        <div className="overflow-x-auto">
          <table className="min-w-full border border-gray-300">
            <tbody>
              <tr className="bg-gray-50">
                <th className="border border-gray-300 px-4 py-3 text-left font-semibold text-gray-900 w-1/3">
                  항목
                </th>
                <td className="border border-gray-300 px-4 py-3 text-gray-700">
                  내용
                </td>
              </tr>
              <tr>
                <th className="border border-gray-300 px-4 py-3 text-left font-medium text-gray-800">
                  상호 (영문)
                </th>
                <td className="border border-gray-300 px-4 py-3 text-gray-700">
                  {company.name}
                </td>
              </tr>
              <tr className="bg-gray-50">
                <th className="border border-gray-300 px-4 py-3 text-left font-medium text-gray-800">
                  상호 (한글)
                </th>
                <td className="border border-gray-300 px-4 py-3 text-gray-700">
                  {company.nameKo}
                </td>
              </tr>
              <tr>
                <th className="border border-gray-300 px-4 py-3 text-left font-medium text-gray-800">
                  대표자
                </th>
                <td className="border border-gray-300 px-4 py-3 text-gray-700">
                  {company.ceoName}
                </td>
              </tr>
              <tr className="bg-gray-50">
                <th className="border border-gray-300 px-4 py-3 text-left font-medium text-gray-800">
                  사업자등록번호
                </th>
                <td className="border border-gray-300 px-4 py-3 text-gray-700">
                  {company.businessNumber}
                </td>
              </tr>
              <tr>
                <th className="border border-gray-300 px-4 py-3 text-left font-medium text-gray-800">
                  통신판매업 신고번호
                </th>
                <td className="border border-gray-300 px-4 py-3 text-gray-700">
                  {company.telecomNumber}
                </td>
              </tr>
              <tr className="bg-gray-50">
                <th className="border border-gray-300 px-4 py-3 text-left font-medium text-gray-800">
                  사업장 소재지
                </th>
                <td className="border border-gray-300 px-4 py-3 text-gray-700">
                  {company.address}
                </td>
              </tr>
              <tr>
                <th className="border border-gray-300 px-4 py-3 text-left font-medium text-gray-800">
                  대표 전화
                </th>
                <td className="border border-gray-300 px-4 py-3 text-gray-700">
                  {company.phone}
                </td>
              </tr>
              <tr className="bg-gray-50">
                <th className="border border-gray-300 px-4 py-3 text-left font-medium text-gray-800">
                  대표 이메일
                </th>
                <td className="border border-gray-300 px-4 py-3 text-gray-700">
                  <a href={`mailto:${company.email}`} className="text-blue-600 hover:underline">
                    {company.email}
                  </a>
                </td>
              </tr>
              <tr>
                <th className="border border-gray-300 px-4 py-3 text-left font-medium text-gray-800">
                  고객지원 이메일
                </th>
                <td className="border border-gray-300 px-4 py-3 text-gray-700">
                  <a href={`mailto:${company.supportEmail}`} className="text-blue-600 hover:underline">
                    {company.supportEmail}
                  </a>
                </td>
              </tr>
              <tr className="bg-gray-50">
                <th className="border border-gray-300 px-4 py-3 text-left font-medium text-gray-800">
                  개인정보보호책임자
                </th>
                <td className="border border-gray-300 px-4 py-3 text-gray-700">
                  {company.privacyOfficer}
                  <br />
                  <a href={`mailto:${company.privacyOfficerEmail}`} className="text-blue-600 hover:underline">
                    {company.privacyOfficerEmail}
                  </a>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">사업자 등록 정보 확인</h2>
        <p className="text-gray-700 leading-relaxed mb-3">
          사업자등록번호는 국세청 홈택스에서 확인하실 수 있습니다:
        </p>
        <a
          href="https://www.hometax.go.kr/websquare/websquare.html?w2xPath=/ui/pp/index_pp.xml"
          target="_blank"
          rel="noopener noreferrer"
          className="inline-block px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
        >
          국세청 홈택스 사업자 조회
        </a>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">통신판매업 신고 확인</h2>
        <p className="text-gray-700 leading-relaxed mb-3">
          통신판매업 신고번호는 공정거래위원회 사이버몰 사업자 정보에서 확인하실 수 있습니다:
        </p>
        <a
          href="https://www.ftc.go.kr/bizCommPop.do?wrkr_no="
          target="_blank"
          rel="noopener noreferrer"
          className="inline-block px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
        >
          공정거래위원회 통신판매업 조회
        </a>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">소비자 피해 보상</h2>
        <p className="text-gray-700 leading-relaxed">
          회사는 전자상거래법 및 소비자보호법에 따라 소비자 피해 보상에 대한 의무를 준수합니다.
          소비자 피해 보상 관련 문의는 고객지원 이메일({company.supportEmail})로 연락 주시기 바랍니다.
        </p>
      </section>

      <div className="mt-12 pt-6 border-t border-gray-200">
        <p className="text-sm text-gray-500">
          본 사업자정보는 {pages.company.lastUpdated} 기준입니다.
        </p>
      </div>
    </article>
  )
}
