/**
 * 이용약관
 *
 * 전자상거래법 제13조 기반 서비스 이용약관
 */

import { Metadata } from 'next'
import { legalConfig } from '@/lib/config/legal-config'

export const metadata: Metadata = {
  title: `${legalConfig.pages.terms.title} | UNO A`,
  description: 'UNO A 서비스 이용약관',
}

export default function TermsPage() {
  const { pages, company, dt } = legalConfig

  return (
    <article className="prose prose-gray max-w-none">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">{pages.terms.title}</h1>
        <p className="text-sm text-gray-500">최종 수정일: {pages.terms.lastUpdated}</p>
      </div>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제1조 (목적)</h2>
        <p className="text-gray-700 leading-relaxed">
          본 약관은 {company.nameKo}(이하 &ldquo;회사&rdquo;)가 운영하는 UNO A 서비스(이하 &ldquo;서비스&rdquo;)의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제2조 (정의)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li><strong>서비스</strong>: 회사가 제공하는 크리에이터-팬 소통 플랫폼 및 관련 디지털 서비스</li>
          <li><strong>이용자</strong>: 서비스에 접속하여 본 약관에 따라 회사가 제공하는 서비스를 이용하는 회원 및 비회원</li>
          <li><strong>회원</strong>: 서비스에 회원가입을 한 자로서, 서비스의 정보를 지속적으로 제공받으며 서비스를 계속적으로 이용할 수 있는 자</li>
          <li><strong>크리에이터</strong>: 서비스를 통해 콘텐츠를 제공하고 팬과 소통하는 회원</li>
          <li><strong>DT (Digital Token)</strong>: {dt.definition}</li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제3조 (통신판매업자로서의 지위)</h2>
        <p className="text-gray-700 leading-relaxed mb-3">
          회사는 전자상거래법상 통신판매업자로서 다음과 같은 정보를 제공합니다:
        </p>
        <ul className="list-disc list-inside space-y-2 text-gray-700">
          <li>상호: {company.name} ({company.nameKo})</li>
          <li>대표자: {company.ceoName}</li>
          <li>사업자등록번호: {company.businessNumber}</li>
          <li>통신판매업신고번호: {company.telecomNumber}</li>
          <li>주소: {company.address}</li>
          <li>전화번호: {company.phone}</li>
          <li>이메일: {company.email}</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제4조 (약관의 효력 및 변경)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>본 약관은 서비스 화면에 게시하거나 기타의 방법으로 공지함으로써 효력이 발생합니다.</li>
          <li>회사는 필요한 경우 관련 법령을 위배하지 않는 범위에서 본 약관을 변경할 수 있습니다.</li>
          <li>약관을 변경하는 경우 적용일자 및 변경사유를 명시하여 현행약관과 함께 서비스 초기화면에 그 적용일자 7일 전부터 공지합니다.</li>
          <li>이용자가 변경된 약관에 동의하지 않는 경우, 서비스 이용을 중단하고 이용계약을 해지할 수 있습니다.</li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제5조 (이용계약의 성립)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>이용계약은 이용자가 회원가입 절차를 완료하고 회사가 이를 승낙함으로써 성립합니다.</li>
          <li>회원가입 시 실명 및 실제 정보를 기입해야 하며, 타인의 정보를 도용하거나 허위정보를 기재한 경우 법적 보호를 받을 수 없습니다.</li>
          <li>만 14세 미만의 아동은 회원가입을 할 수 없습니다.</li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제6조 (DT의 법적 성격)</h2>
        <p className="text-gray-700 leading-relaxed mb-3">
          DT는 다음과 같은 법적 성격을 가집니다:
        </p>
        <ul className="list-disc list-inside space-y-2 text-gray-700">
          <li><strong>정의</strong>: {dt.definition}</li>
          <li><strong>성격</strong>: {dt.nature}</li>
          <li><strong>유효기간</strong>: 구매일로부터 {dt.expirationYears}년</li>
          <li><strong>금지사항</strong>: {dt.prohibitions.join(', ')}</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제7조 (이용자의 의무)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>이용자는 다음 행위를 하여서는 안 됩니다:
            <ul className="list-disc list-inside ml-6 mt-2 space-y-1">
              <li>타인의 정보 도용</li>
              <li>허위 정보 기재 또는 허위 사실 유포</li>
              <li>회사 또는 제3자의 지적재산권 침해</li>
              <li>음란물, 욕설, 혐오표현 등 유해 콘텐츠 게시</li>
              <li>서비스 운영을 방해하는 행위</li>
              <li>관련 법령을 위반하는 행위</li>
            </ul>
          </li>
          <li>이용자는 본 약관 및 관련 법령을 준수하여야 합니다.</li>
          <li>이용자는 자신의 계정정보를 안전하게 관리할 책임이 있습니다.</li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제8조 (서비스의 제공 및 중단)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>회사는 연중무휴 1일 24시간 서비스를 제공함을 원칙으로 합니다.</li>
          <li>회사는 다음 각 호에 해당하는 경우 서비스 제공을 일시적으로 중단할 수 있습니다:
            <ul className="list-disc list-inside ml-6 mt-2 space-y-1">
              <li>시스템 정기점검, 증설 및 교체를 위한 경우</li>
              <li>천재지변, 비상사태 등 불가항력적 사유가 있는 경우</li>
              <li>서비스 이용의 폭주 등으로 정상적인 서비스 이용에 지장이 있는 경우</li>
            </ul>
          </li>
          <li>회사는 서비스 중단 시 사전에 공지하며, 부득이한 사유가 있는 경우 사후에 공지할 수 있습니다.</li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제9조 (결제 및 환불)</h2>
        <p className="text-gray-700 leading-relaxed">
          결제 및 환불에 관한 사항은 별도의 환불정책 및 DT 이용약관에 따릅니다.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제10조 (분쟁해결)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>회사와 이용자 간 발생한 분쟁에 관한 소송은 민사소송법에 따른 관할법원에 제기합니다.</li>
          <li>회사와 이용자 간에 제기된 소송에는 대한민국 법을 적용합니다.</li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제11조 (개인정보보호)</h2>
        <p className="text-gray-700 leading-relaxed">
          회사는 관련 법령이 정하는 바에 따라 이용자의 개인정보를 보호하기 위해 노력합니다. 개인정보의 보호 및 이용에 대해서는 관련 법령 및 회사의 개인정보처리방침이 적용됩니다.
        </p>
      </section>

      <div className="mt-12 pt-6 border-t border-gray-200">
        <p className="text-sm text-gray-500">
          본 약관은 {pages.terms.lastUpdated}부터 시행됩니다.
        </p>
      </div>
    </article>
  )
}
