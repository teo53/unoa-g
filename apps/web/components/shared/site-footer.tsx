import Link from 'next/link'
import { cn } from '@/lib/utils/cn'
import { ROUTES } from '@/lib/constants/routes'
import { legalConfig } from '@/lib/config'

interface SiteFooterProps {
  className?: string
}

/**
 * SiteFooter
 *
 * 전자상거래법 필수 사업자정보 포함 푸터.
 * 법적 페이지 링크 + 고객센터 + 사업자정보.
 */
export function SiteFooter({ className }: SiteFooterProps) {
  const { company } = legalConfig

  return (
    <footer className={cn('border-t border-neutral-200 bg-neutral-50', className)}>
      <div className="mx-auto max-w-content px-4 py-10">
        {/* Links Grid */}
        <div className="grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-4">
          {/* 서비스 */}
          <div>
            <h3 className="mb-3 text-sm font-semibold text-neutral-900">서비스</h3>
            <ul className="space-y-2">
              <li><FooterLink href={ROUTES.funding}>펀딩 탐색</FooterLink></li>
              <li><FooterLink href={ROUTES.pricing}>요금제</FooterLink></li>
              <li><FooterLink href={ROUTES.store.dt}>DT 스토어</FooterLink></li>
              <li><FooterLink href={ROUTES.studio.dashboard}>크리에이터 스튜디오</FooterLink></li>
              <li><FooterLink href={ROUTES.agency.dashboard}>소속사 관리</FooterLink></li>
            </ul>
          </div>

          {/* 이용안내 */}
          <div>
            <h3 className="mb-3 text-sm font-semibold text-neutral-900">이용안내</h3>
            <ul className="space-y-2">
              <li><FooterLink href={ROUTES.legal.terms}>이용약관</FooterLink></li>
              <li><FooterLink href={ROUTES.legal.privacy}>개인정보처리방침</FooterLink></li>
              <li><FooterLink href={ROUTES.legal.refund}>환불정책</FooterLink></li>
              <li><FooterLink href={ROUTES.legal.dtUsage}>DT 이용약관</FooterLink></li>
            </ul>
          </div>

          {/* 크리에이터 */}
          <div>
            <h3 className="mb-3 text-sm font-semibold text-neutral-900">크리에이터</h3>
            <ul className="space-y-2">
              <li><FooterLink href={ROUTES.legal.creator}>크리에이터 약관</FooterLink></li>
              <li><FooterLink href={ROUTES.legal.funding}>펀딩 약관</FooterLink></li>
              <li><FooterLink href={ROUTES.legal.settlement}>정산/세무 정책</FooterLink></li>
              <li><FooterLink href={ROUTES.legal.community}>커뮤니티 가이드라인</FooterLink></li>
            </ul>
          </div>

          {/* 고객센터 */}
          <div>
            <h3 className="mb-3 text-sm font-semibold text-neutral-900">고객센터</h3>
            <ul className="space-y-2">
              <li><FooterLink href={`mailto:${company.email}`}>{company.email}</FooterLink></li>
              <li><FooterLink href={ROUTES.legal.company}>사업자정보</FooterLink></li>
            </ul>
          </div>
        </div>

        {/* Divider */}
        <hr className="my-8 border-neutral-200" />

        {/* 사업자정보 (전자상거래법 제13조 필수) */}
        <div className="text-xs leading-relaxed text-neutral-500">
          <p className="font-medium text-neutral-600">{company.name} ({company.nameKo})</p>
          <p className="mt-1">
            대표: {company.ceoName} | 사업자등록번호: {company.businessNumber} | 통신판매업 신고번호: {company.telecomNumber}
          </p>
          <p>주소: {company.address}</p>
          <p>연락처: {company.phone} | 이메일: {company.email}</p>
          <p className="mt-2">
            개인정보보호책임자: {company.privacyOfficer} ({company.privacyOfficerEmail})
          </p>
        </div>

        {/* Copyright */}
        <p className="mt-6 text-xs text-neutral-400">
          &copy; {new Date().getFullYear()} {company.name}. All rights reserved.
        </p>
      </div>
    </footer>
  )
}

function FooterLink({ href, children }: { href: string; children: React.ReactNode }) {
  const isExternal = href.startsWith('mailto:') || href.startsWith('http')

  if (isExternal) {
    return (
      <a href={href} className="text-sm text-neutral-500 transition-colors hover:text-neutral-700">
        {children}
      </a>
    )
  }

  return (
    <Link href={href} className="text-sm text-neutral-500 transition-colors hover:text-neutral-700">
      {children}
    </Link>
  )
}
