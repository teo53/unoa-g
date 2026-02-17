'use client'

import { useState } from 'react'
import Link from 'next/link'
import { cn } from '@/lib/utils/cn'
import { ROUTES } from '@/lib/constants/routes'

type HeaderVariant = 'public' | 'studio' | 'admin' | 'agency'

interface SiteHeaderProps {
  variant?: HeaderVariant
  className?: string
}

const variantConfig: Record<HeaderVariant, { label: string; navItems: { label: string; href: string }[] }> = {
  public: {
    label: 'UNO A',
    navItems: [
      { label: '펀딩', href: ROUTES.funding },
      { label: '요금제', href: ROUTES.pricing },
      { label: 'DT 스토어', href: ROUTES.store.dt },
      { label: '크리에이터', href: ROUTES.studio.dashboard },
    ],
  },
  studio: {
    label: 'UNO A Studio',
    navItems: [
      { label: '대시보드', href: ROUTES.studio.dashboard },
      { label: '캠페인', href: ROUTES.studio.campaigns },
    ],
  },
  admin: {
    label: 'UNO A Admin',
    navItems: [
      { label: '대시보드', href: ROUTES.admin.dashboard },
      { label: '캠페인', href: ROUTES.admin.campaigns },
      { label: '정산', href: ROUTES.admin.settlements },
      { label: '세무', href: ROUTES.admin.taxReports },
    ],
  },
  agency: {
    label: 'UNO A Agency',
    navItems: [
      { label: '대시보드', href: ROUTES.agency.dashboard },
      { label: '아티스트', href: ROUTES.agency.artists },
      { label: '정산', href: ROUTES.agency.settlements },
    ],
  },
}

/**
 * SiteHeader
 *
 * 공유 사이트 헤더. variant에 따라 네비게이션 변경.
 * 스티키 + backdrop-blur + 모바일 햄버거 메뉴.
 */
export function SiteHeader({ variant = 'public', className }: SiteHeaderProps) {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const config = variantConfig[variant]

  return (
    <header className={cn('sticky top-0 z-50 border-b border-neutral-200 bg-white/80 backdrop-blur-lg', className)}>
      <div className="mx-auto flex h-14 max-w-content items-center justify-between px-4">
        {/* Logo */}
        <Link href={variant === 'public' ? ROUTES.home : `/${variant}`} className="flex items-center gap-2">
          <span className="text-lg font-bold text-primary-600">{config.label}</span>
        </Link>

        {/* Desktop Nav */}
        <nav className="hidden items-center gap-6 md:flex">
          {config.navItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="text-sm font-medium text-neutral-600 transition-colors hover:text-neutral-900"
            >
              {item.label}
            </Link>
          ))}
        </nav>

        {/* Mobile Hamburger */}
        <button
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          className="flex h-9 w-9 items-center justify-center rounded-lg text-neutral-600 hover:bg-neutral-100 md:hidden"
          aria-label="메뉴 열기"
        >
          {mobileMenuOpen ? (
            <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          ) : (
            <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
            </svg>
          )}
        </button>
      </div>

      {/* Mobile Menu */}
      {mobileMenuOpen && (
        <nav className="border-t border-neutral-100 bg-white px-4 py-3 md:hidden">
          {config.navItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              onClick={() => setMobileMenuOpen(false)}
              className="block rounded-lg px-3 py-2 text-sm font-medium text-neutral-700 hover:bg-neutral-50"
            >
              {item.label}
            </Link>
          ))}
        </nav>
      )}
    </header>
  )
}
