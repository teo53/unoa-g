/**
 * Legal Pages Layout
 *
 * 법적 문서 공통 레이아웃: 좌측 목차 + 본문 영역
 */

import Link from 'next/link'
import { ROUTES } from '@/lib/constants/routes'
import { legalConfig } from '@/lib/config/legal-config'

const legalPages = [
  { href: ROUTES.legal.terms, label: legalConfig.pages.terms.title },
  { href: ROUTES.legal.privacy, label: legalConfig.pages.privacy.title },
  { href: ROUTES.legal.refund, label: legalConfig.pages.refund.title },
  { href: ROUTES.legal.company, label: legalConfig.pages.company.title },
  { href: ROUTES.legal.dtUsage, label: legalConfig.pages.dtUsage.title },
  { href: ROUTES.legal.creator, label: legalConfig.pages.creator.title },
  { href: ROUTES.legal.funding, label: legalConfig.pages.funding.title },
  { href: ROUTES.legal.community, label: legalConfig.pages.community.title },
  { href: ROUTES.legal.settlement, label: legalConfig.pages.settlement.title },
]

export default function LegalLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 py-6">
          <Link href={ROUTES.home} className="text-2xl font-bold text-gray-900">
            UNO A
          </Link>
        </div>
      </header>

      {/* Main Layout */}
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="flex flex-col lg:flex-row gap-8">
          {/* Sidebar - Table of Contents */}
          <aside className="w-full lg:w-64 flex-shrink-0">
            <div className="bg-white rounded-lg border border-gray-200 p-6 sticky top-8">
              <h2 className="text-lg font-bold text-gray-900 mb-4">법적 문서</h2>
              <nav className="space-y-2">
                {legalPages.map((page) => (
                  <Link
                    key={page.href}
                    href={page.href}
                    className="block px-3 py-2 text-sm text-gray-700 hover:bg-gray-100 rounded-md transition-colors"
                  >
                    {page.label}
                  </Link>
                ))}
              </nav>
            </div>
          </aside>

          {/* Main Content */}
          <main className="flex-1 bg-white rounded-lg border border-gray-200 p-8 lg:p-12">
            {children}
          </main>
        </div>
      </div>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-200 mt-16">
        <div className="max-w-7xl mx-auto px-4 py-8">
          <div className="text-center text-sm text-gray-500">
            <p>&copy; 2026 {legalConfig.company.nameKo}. All rights reserved.</p>
            <p className="mt-2">
              문의: <a href={`mailto:${legalConfig.company.supportEmail}`} className="text-blue-600 hover:underline">{legalConfig.company.supportEmail}</a>
            </p>
          </div>
        </div>
      </footer>
    </div>
  )
}
