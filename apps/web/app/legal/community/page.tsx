/**
 * 커뮤니티 가이드라인
 *
 * 커뮤니티 행동 규범 및 제재 정책
 */

import { Metadata } from 'next'
import { legalConfig } from '@/lib/config/legal-config'

export const metadata: Metadata = {
  title: `${legalConfig.pages.community.title} | UNO A`,
  description: 'UNO A 커뮤니티 가이드라인',
}

export default function CommunityPage() {
  const { pages, company } = legalConfig

  return (
    <article className="prose prose-gray max-w-none">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">{pages.community.title}</h1>
        <p className="text-sm text-gray-500">최종 수정일: {pages.community.lastUpdated}</p>
      </div>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">1. 가이드라인의 목적</h2>
        <p className="text-gray-700 leading-relaxed">
          UNO A는 크리에이터와 팬이 안전하고 건강하게 소통할 수 있는 커뮤니티를 지향합니다.
          본 가이드라인은 모든 이용자가 존중받고, 긍정적인 경험을 할 수 있도록 행동 규범 및 제재 정책을 규정합니다.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">2. 기본 원칙</h2>
        <ul className="list-disc list-inside space-y-2 text-gray-700">
          <li><strong>존중</strong>: 다른 이용자의 의견과 감정을 존중합니다.</li>
          <li><strong>건전성</strong>: 건전하고 긍정적인 콘텐츠를 공유합니다.</li>
          <li><strong>책임</strong>: 본인의 발언과 행동에 책임을 집니다.</li>
          <li><strong>투명성</strong>: 허위 정보를 유포하지 않고 진실을 공유합니다.</li>
          <li><strong>법준수</strong>: 대한민국 법령을 준수합니다.</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">3. 금지 행위</h2>

        <div className="space-y-6">
          <div>
            <h3 className="text-lg font-semibold text-gray-800 mb-2">3.1 폭력 및 혐오 표현</h3>
            <ul className="list-disc list-inside space-y-1 text-gray-700">
              <li>욕설, 비속어, 저속한 언어 사용</li>
              <li>특정 개인/집단에 대한 차별, 혐오, 비하 발언</li>
              <li>폭력적, 위협적, 공격적인 발언</li>
              <li>성별, 인종, 종교, 장애, 성적 지향에 대한 혐오 표현</li>
            </ul>
          </div>

          <div>
            <h3 className="text-lg font-semibold text-gray-800 mb-2">3.2 스팸 및 도배</h3>
            <ul className="list-disc list-inside space-y-1 text-gray-700">
              <li>동일하거나 유사한 내용을 반복적으로 게시</li>
              <li>무분별한 광고 및 홍보 글</li>
              <li>자동화 도구(봇)를 사용한 메시지 발송</li>
              <li>다른 플랫폼/서비스 유도 링크 무단 게시</li>
            </ul>
          </div>

          <div>
            <h3 className="text-lg font-semibold text-gray-800 mb-2">3.3 사칭 및 허위 정보</h3>
            <ul className="list-disc list-inside space-y-1 text-gray-700">
              <li>크리에이터, 유명인, 회사 관계자 등을 사칭</li>
              <li>허위 정보 유포 및 가짜 뉴스 공유</li>
              <li>타인의 명의를 도용하여 활동</li>
            </ul>
          </div>

          <div>
            <h3 className="text-lg font-semibold text-gray-800 mb-2">3.4 음란물 및 불법 콘텐츠</h3>
            <ul className="list-disc list-inside space-y-1 text-gray-700">
              <li>음란물, 성적 콘텐츠 게시</li>
              <li>불법 물품(마약, 무기 등) 판매 또는 거래 유도</li>
              <li>도박, 사행성 게임 홍보</li>
              <li>저작권을 침해하는 콘텐츠 무단 게시</li>
            </ul>
          </div>

          <div>
            <h3 className="text-lg font-semibold text-gray-800 mb-2">3.5 개인정보 침해</h3>
            <ul className="list-disc list-inside space-y-1 text-gray-700">
              <li>타인의 개인정보(이름, 전화번호, 주소 등) 무단 공개</li>
              <li>사생활 침해(스토킹, 위치 추적 등)</li>
              <li>동의 없이 타인의 사진/영상 게시</li>
            </ul>
          </div>

          <div>
            <h3 className="text-lg font-semibold text-gray-800 mb-2">3.6 부정 행위</h3>
            <ul className="list-disc list-inside space-y-1 text-gray-700">
              <li>계정 도용 또는 해킹 시도</li>
              <li>서비스 취약점 악용</li>
              <li>자전 후원 (본인 또는 지인이 후원하여 수익 조작)</li>
              <li>다중 계정을 사용한 부정 행위</li>
            </ul>
          </div>
        </div>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">4. 제재 단계</h2>
        <p className="text-gray-700 leading-relaxed mb-4">
          회사는 금지 행위 적발 시 다음과 같은 단계적 제재를 시행합니다:
        </p>

        <div className="overflow-x-auto">
          <table className="min-w-full border border-gray-300">
            <thead className="bg-gray-100">
              <tr>
                <th className="border border-gray-300 px-4 py-2 text-left">단계</th>
                <th className="border border-gray-300 px-4 py-2 text-left">제재 내용</th>
                <th className="border border-gray-300 px-4 py-2 text-left">적용 기간</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td className="border border-gray-300 px-4 py-2">1차 경고</td>
                <td className="border border-gray-300 px-4 py-2">경고 메시지 발송, 위반 콘텐츠 삭제</td>
                <td className="border border-gray-300 px-4 py-2">-</td>
              </tr>
              <tr className="bg-gray-50">
                <td className="border border-gray-300 px-4 py-2">2차 경고</td>
                <td className="border border-gray-300 px-4 py-2">계정 일시 정지 (3일)</td>
                <td className="border border-gray-300 px-4 py-2">3일</td>
              </tr>
              <tr>
                <td className="border border-gray-300 px-4 py-2">3차 경고</td>
                <td className="border border-gray-300 px-4 py-2">계정 일시 정지 (7일)</td>
                <td className="border border-gray-300 px-4 py-2">7일</td>
              </tr>
              <tr className="bg-gray-50">
                <td className="border border-gray-300 px-4 py-2">4차 경고</td>
                <td className="border border-gray-300 px-4 py-2">계정 일시 정지 (30일)</td>
                <td className="border border-gray-300 px-4 py-2">30일</td>
              </tr>
              <tr>
                <td className="border border-gray-300 px-4 py-2">5차 이상</td>
                <td className="border border-gray-300 px-4 py-2">계정 영구 정지</td>
                <td className="border border-gray-300 px-4 py-2">영구</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div className="bg-red-50 border border-red-200 rounded-lg p-4 mt-4">
          <p className="text-red-900 font-semibold mb-2">⚠️ 즉시 영구 정지 사유</p>
          <p className="text-gray-700">
            다음 행위는 경고 없이 즉시 계정이 영구 정지됩니다:
          </p>
          <ul className="list-disc list-inside space-y-1 text-gray-700 mt-2">
            <li>불법 물품 판매 또는 거래</li>
            <li>아동/청소년 대상 성범죄 관련 콘텐츠</li>
            <li>사기 행위 (허위 펀딩, 금전 사기 등)</li>
            <li>타인의 생명이나 신체에 위해를 가하는 행위</li>
            <li>회사 또는 서비스를 심각하게 훼손하는 행위</li>
          </ul>
        </div>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">5. 신고 및 제재 절차</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            <strong>신고</strong>: 이용자는 금지 행위를 발견한 경우 서비스 내 신고 기능 또는 고객센터({company.supportEmail})를 통해 신고할 수 있습니다.
          </li>
          <li>
            <strong>검토</strong>: 회사는 신고 접수 후 3영업일 이내에 검토하고, 위반 여부를 판단합니다.
          </li>
          <li>
            <strong>제재</strong>: 위반이 확인된 경우, 제재 단계에 따라 조치하고 해당 이용자에게 통보합니다.
          </li>
          <li>
            <strong>이의제기</strong>: 제재 대상자는 통보 후 7일 이내에 이의제기를 신청할 수 있습니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">6. 이의제기 절차</h2>
        <ol className="list-decimal list-inside space-y-3 text-gray-700">
          <li>
            제재에 이의가 있는 경우, 고객센터({company.supportEmail})로 이의제기 신청서를 제출합니다.
          </li>
          <li>
            이의제기 신청서에는 다음 내용을 포함해야 합니다:
            <ul className="list-disc list-inside ml-6 mt-2 space-y-1">
              <li>계정 정보 (이메일, 닉네임)</li>
              <li>제재 내용 및 날짜</li>
              <li>이의제기 사유 및 증빙 자료</li>
            </ul>
          </li>
          <li>
            회사는 이의제기 접수 후 7영업일 이내에 재검토하고 결과를 통보합니다.
          </li>
          <li>
            재검토 결과 제재가 부당하다고 판단되는 경우, 제재가 해제되고 계정이 복구됩니다.
          </li>
        </ol>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">7. 콘텐츠 삭제 및 게시 중단</h2>
        <p className="text-gray-700 leading-relaxed mb-3">
          회사는 다음의 경우 이용자의 콘텐츠를 삭제하거나 게시를 중단할 수 있습니다:
        </p>
        <ul className="list-disc list-inside space-y-2 text-gray-700">
          <li>본 가이드라인 또는 이용약관 위반</li>
          <li>관련 법령 위반</li>
          <li>제3자의 권리를 침해하는 콘텐츠</li>
          <li>법원, 수사기관 등의 요청</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">8. 가이드라인 개정</h2>
        <p className="text-gray-700 leading-relaxed">
          회사는 필요한 경우 본 가이드라인을 개정할 수 있으며, 개정 시 7일 전에 서비스 내 공지합니다.
          개정된 가이드라인은 공지 후 시행되며, 이용자는 개정된 가이드라인에 동의하지 않는 경우 서비스 이용을 중단할 수 있습니다.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-2xl font-semibold text-gray-900 mb-4">9. 연락처</h2>
        <p className="text-gray-700 leading-relaxed">
          본 가이드라인 관련 문의 또는 신고는 다음 연락처로 문의해 주세요:
        </p>
        <div className="bg-gray-50 border border-gray-200 rounded-lg p-4 mt-4">
          <ul className="list-none space-y-1 text-gray-700">
            <li><strong>고객센터</strong>: <a href={`mailto:${company.supportEmail}`} className="text-blue-600 hover:underline">{company.supportEmail}</a></li>
            <li><strong>대표 전화</strong>: {company.phone}</li>
          </ul>
        </div>
      </section>

      <div className="mt-12 pt-6 border-t border-gray-200">
        <p className="text-sm text-gray-500">
          본 커뮤니티 가이드라인은 {pages.community.lastUpdated}부터 시행됩니다.
        </p>
      </div>
    </article>
  )
}
