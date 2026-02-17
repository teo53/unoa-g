/**
 * 개인정보처리방침
 *
 * 개인정보보호법 기반 개인정보 처리방침
 */

import { Metadata } from 'next'
import { legalConfig } from '@/lib/config/legal-config'

export const metadata: Metadata = {
  title: `${legalConfig.pages.privacy.title} | UNO A`,
  description: 'UNO A 개인정보처리방침',
}

export default function PrivacyPage() {
  const { pages, company } = legalConfig

  return (
    <article className="prose prose-gray max-w-none">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">{pages.privacy.title}</h1>
        <p className="text-sm text-gray-500">최종 수정일: {pages.privacy.lastUpdated}</p>
      </div>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제1조 (개인정보의 처리 목적)</h2>
        <p className="text-gray-700 leading-relaxed mb-3">
          {company.nameKo}(이하 &ldquo;회사&rdquo;)는 다음의 목적을 위하여 개인정보를 처리합니다. 처리하고 있는 개인정보는 다음의 목적 이외의 용도로는 이용되지 않으며, 이용 목적이 변경되는 경우에는 개인정보보호법에 따라 별도의 동의를 받는 등 필요한 조치를 이행할 예정입니다.
        </p>
        <ul className="list-disc list-inside space-y-2 text-gray-700">
          <li>회원가입 및 회원 관리</li>
          <li>서비스 제공 및 콘텐츠 전송</li>
          <li>결제 및 환불 처리</li>
          <li>고객 문의 응대 및 민원 처리</li>
          <li>마케팅 및 광고 활용 (동의한 경우)</li>
          <li>서비스 개선 및 통계 분석</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제2조 (처리하는 개인정보의 항목)</h2>
        <div className="space-y-4">
          <div>
            <h3 className="text-lg font-semibold text-gray-800 mb-2">1. 필수 수집 항목</h3>
            <ul className="list-disc list-inside space-y-1 text-gray-700">
              <li>이름, 이메일 주소, 휴대전화번호</li>
              <li>생년월일 (만 14세 미만 이용 제한)</li>
              <li>비밀번호 (암호화 저장)</li>
              <li>서비스 이용 기록, 접속 로그, 쿠키, 접속 IP 정보</li>
            </ul>
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-800 mb-2">2. 선택 수집 항목</h3>
            <ul className="list-disc list-inside space-y-1 text-gray-700">
              <li>프로필 사진, 닉네임, 자기소개</li>
              <li>관심사 및 선호 크리에이터</li>
            </ul>
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-800 mb-2">3. 결제 시 수집 항목</h3>
            <ul className="list-disc list-inside space-y-1 text-gray-700">
              <li>신용카드 정보 (카드번호, 유효기간 - PG사 처리)</li>
              <li>계좌 정보 (계좌번호, 은행명 - 환불 시)</li>
              <li>결제 승인 번호, 거래 내역</li>
            </ul>
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-800 mb-2">4. 크리에이터 추가 항목</h3>
            <ul className="list-disc list-inside space-y-1 text-gray-700">
              <li>실명, 주민등록번호 (또는 사업자등록번호)</li>
              <li>정산 계좌 정보 (은행명, 계좌번호, 예금주명)</li>
              <li>소득세 원천징수 관련 정보</li>
            </ul>
          </div>
        </div>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제3조 (개인정보의 제3자 제공)</h2>
        <p className="text-gray-700 leading-relaxed mb-3">
          회사는 원칙적으로 이용자의 개인정보를 제1조(개인정보의 처리 목적)에서 명시한 범위 내에서만 처리하며, 이용자의 동의, 법률의 특별한 규정 등 개인정보보호법 제17조 및 제18조에 해당하는 경우에만 개인정보를 제3자에게 제공합니다.
        </p>
        <div className="overflow-x-auto">
          <table className="min-w-full border border-gray-300">
            <thead className="bg-gray-100">
              <tr>
                <th className="border border-gray-300 px-4 py-2 text-left">제공받는 자</th>
                <th className="border border-gray-300 px-4 py-2 text-left">제공 목적</th>
                <th className="border border-gray-300 px-4 py-2 text-left">제공 항목</th>
                <th className="border border-gray-300 px-4 py-2 text-left">보유 기간</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td className="border border-gray-300 px-4 py-2">PG사 (결제대행사)</td>
                <td className="border border-gray-300 px-4 py-2">결제 처리</td>
                <td className="border border-gray-300 px-4 py-2">이름, 결제정보</td>
                <td className="border border-gray-300 px-4 py-2">결제 완료 후 5년</td>
              </tr>
              <tr>
                <td className="border border-gray-300 px-4 py-2">크리에이터</td>
                <td className="border border-gray-300 px-4 py-2">메시지 전송, 리워드 발송</td>
                <td className="border border-gray-300 px-4 py-2">닉네임, 메시지 내용, 주소 (리워드 발송 시)</td>
                <td className="border border-gray-300 px-4 py-2">서비스 이용 기간</td>
              </tr>
              <tr>
                <td className="border border-gray-300 px-4 py-2">배송 대행사</td>
                <td className="border border-gray-300 px-4 py-2">리워드 배송</td>
                <td className="border border-gray-300 px-4 py-2">이름, 연락처, 주소</td>
                <td className="border border-gray-300 px-4 py-2">배송 완료 후 3개월</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제4조 (개인정보의 처리 및 보유기간)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li><strong>회원정보</strong>: 회원 탈퇴 시까지 (단, 관련 법령에 따라 보존 필요 시 해당 기간 동안 보관)</li>
          <li><strong>결제정보</strong>: 전자상거래법에 따라 결제 완료 후 5년</li>
          <li><strong>세법상 증빙</strong>: 국세기본법에 따라 5년</li>
          <li><strong>소비자 불만 및 분쟁 처리 기록</strong>: 전자상거래법에 따라 3년</li>
          <li><strong>접속 로그</strong>: 통신비밀보호법에 따라 3개월</li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제5조 (개인정보의 파기)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>회사는 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체 없이 해당 개인정보를 파기합니다.</li>
          <li>개인정보 파기의 절차 및 방법은 다음과 같습니다:
            <ul className="list-disc list-inside ml-6 mt-2 space-y-1">
              <li><strong>파기절차</strong>: 불필요한 개인정보는 개인정보보호책임자의 승인을 거쳐 파기</li>
              <li><strong>파기방법</strong>: 전자적 파일은 복구 불가능한 방법으로 영구 삭제, 종이 문서는 분쇄기로 분쇄 또는 소각</li>
            </ul>
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제6조 (이용자의 권리와 행사 방법)</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>이용자는 언제든지 개인정보 열람, 정정, 삭제, 처리정지를 요구할 수 있습니다.</li>
          <li>권리 행사는 서비스 내 설정 페이지 또는 고객센터({company.supportEmail})를 통해 가능합니다.</li>
          <li>회사는 요청을 받은 날로부터 10일 이내에 조치 결과를 통지합니다.</li>
          <li>만 14세 미만 아동의 법정대리인은 아동의 개인정보에 대한 열람, 정정, 삭제를 요구할 수 있습니다.</li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제7조 (개인정보의 안전성 확보 조치)</h2>
        <p className="text-gray-700 leading-relaxed mb-3">
          회사는 개인정보보호법 제29조에 따라 다음과 같이 안전성 확보에 필요한 기술적/관리적 조치를 하고 있습니다:
        </p>
        <ul className="list-disc list-inside space-y-2 text-gray-700">
          <li>개인정보 암호화 (비밀번호, 주민등록번호 등)</li>
          <li>해킹 등에 대비한 기술적 대책 (방화벽, 침입탐지시스템)</li>
          <li>개인정보 취급 직원의 최소화 및 교육</li>
          <li>개인정보 접근 권한 관리 및 접근 통제</li>
          <li>접속 기록의 위변조 방지 조치</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제8조 (개인정보보호책임자)</h2>
        <p className="text-gray-700 leading-relaxed mb-3">
          회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만처리 및 피해구제 등을 위하여 아래와 같이 개인정보보호책임자를 지정하고 있습니다:
        </p>
        <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
          <p className="text-gray-700"><strong>개인정보보호책임자</strong></p>
          <ul className="list-none space-y-1 text-gray-700 mt-2">
            <li>성명: {company.privacyOfficer}</li>
            <li>이메일: {company.privacyOfficerEmail}</li>
            <li>연락처: {company.phone}</li>
          </ul>
        </div>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">제9조 (권익침해 구제방법)</h2>
        <p className="text-gray-700 leading-relaxed mb-3">
          개인정보 침해로 인한 구제를 받기 위하여 개인정보분쟁조정위원회, 한국인터넷진흥원 개인정보침해신고센터 등에 분쟁해결이나 상담 등을 신청할 수 있습니다:
        </p>
        <ul className="list-disc list-inside space-y-2 text-gray-700">
          <li>개인정보분쟁조정위원회: (국번없이) 1833-6972 (www.kopico.go.kr)</li>
          <li>개인정보침해신고센터: (국번없이) 118 (privacy.kisa.or.kr)</li>
          <li>대검찰청 사이버범죄수사단: (국번없이) 1301 (www.spo.go.kr)</li>
          <li>경찰청 사이버안전국: (국번없이) 182 (cyberbureau.police.go.kr)</li>
        </ul>
      </section>

      <div className="mt-12 pt-6 border-t border-gray-200">
        <p className="text-sm text-gray-500">
          본 개인정보처리방침은 {pages.privacy.lastUpdated}부터 시행됩니다.
        </p>
      </div>
    </article>
  )
}
