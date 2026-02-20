'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { LayoutDashboard, FileCheck, Flag, LogOut, Wallet, CreditCard, Calculator, Image, ToggleLeft, ScrollText, Users, Megaphone, ShieldAlert, Globe, Lock } from 'lucide-react'
import { OpsToastProvider } from '@/components/ops/ops-toast'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import { createClient } from '@/lib/supabase/client'

const DEMO_ADMIN_KEY = 'unoa_admin_auth'
const DEMO_PASSWORD = process.env.NEXT_PUBLIC_DEMO_ADMIN_PASSWORD ?? ''

function DemoGate({ children }: { children: React.ReactNode }) {
  const [isAuthed, setIsAuthed] = useState(false)
  const [password, setPassword] = useState('')
  const [error, setError] = useState(false)
  const isDemoPasswordConfigured = DEMO_PASSWORD.length > 0

  useEffect(() => {
    if (typeof window !== 'undefined') {
      const stored = sessionStorage.getItem(DEMO_ADMIN_KEY)
      if (stored === 'true') setIsAuthed(true)
    }
  }, [])

  if (isAuthed) return <>{children}</>

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (!isDemoPasswordConfigured) {
      setError(true)
      return
    }
    if (password === DEMO_PASSWORD) {
      sessionStorage.setItem(DEMO_ADMIN_KEY, 'true')
      setIsAuthed(true)
      setError(false)
    } else {
      setError(true)
    }
  }

  return (
    <div className="min-h-screen bg-gray-100 flex items-center justify-center">
      <div className="max-w-md w-full mx-4 bg-white rounded-2xl shadow-lg p-8 text-center">
        <div className="mx-auto w-16 h-16 bg-amber-100 rounded-full flex items-center justify-center mb-6">
          <Lock className="w-8 h-8 text-amber-600" />
        </div>
        <h1 className="text-2xl font-bold text-gray-900 mb-3">
          관리자 패널
        </h1>
        <p className="text-gray-500 mb-6 text-sm">
          데모 모드에서는 비밀번호가 필요합니다.
          <br />
          {!isDemoPasswordConfigured && (
            <span className="text-xs text-red-500 mt-1 inline-block">
              NEXT_PUBLIC_DEMO_ADMIN_PASSWORD 환경변수가 설정되지 않았습니다.
            </span>
          )}
        </p>
        <form onSubmit={handleSubmit} className="space-y-4">
          <input
            type="password"
            value={password}
            onChange={(e) => { setPassword(e.target.value); setError(false) }}
            placeholder="비밀번호 입력"
            className={`w-full px-4 py-3 rounded-lg border ${error ? 'border-red-300 bg-red-50' : 'border-gray-200'} focus:outline-none focus:ring-2 focus:ring-primary-500/30 focus:border-primary-500 transition-colors`}
            autoFocus
          />
          {error && (
            <p className="text-sm text-red-500">
              {isDemoPasswordConfigured
                ? '비밀번호가 틀렸습니다'
                : '데모 관리자 비밀번호가 설정되지 않았습니다'}
            </p>
          )}
          <button
            type="submit"
            disabled={!isDemoPasswordConfigured}
            className="w-full px-6 py-3 bg-gray-900 text-white rounded-lg hover:bg-gray-800 transition-colors font-medium"
          >
            확인
          </button>
        </form>
        <Link
          href="/"
          className="inline-block mt-4 text-sm text-gray-400 hover:text-gray-600 transition-colors"
        >
          홈으로 돌아가기
        </Link>
      </div>
    </div>
  )
}

function AdminAuthGate({ children }: { children: React.ReactNode }) {
  const [status, setStatus] = useState<'loading' | 'authorized' | 'unauthorized'>('loading')

  useEffect(() => {
    let isMounted = true

    async function verifyAdminAccess() {
      const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
      const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
      if (!supabaseUrl || !supabaseAnonKey) {
        if (isMounted) setStatus('unauthorized')
        return
      }

      const supabase = createClient()
      const {
        data: { session },
        error: sessionError,
      } = await supabase.auth.getSession()

      if (sessionError || !session?.user?.id) {
        if (isMounted) setStatus('unauthorized')
        return
      }

      const { data: profile, error: profileError } = await supabase
        .from('user_profiles')
        .select('role')
        .eq('id', session.user.id)
        .single()

      const userRole = (profile as { role?: string } | null)?.role

      if (!isMounted) return

      if (profileError || userRole !== 'admin') {
        setStatus('unauthorized')
        return
      }

      setStatus('authorized')
    }

    void verifyAdminAccess()

    return () => {
      isMounted = false
    }
  }, [])

  if (status === 'loading') {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="max-w-md w-full mx-4 bg-white rounded-2xl shadow-lg p-8 text-center">
          <p className="text-sm text-gray-600">관리자 권한 확인 중...</p>
        </div>
      </div>
    )
  }

  if (status === 'unauthorized') {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="max-w-md w-full mx-4 bg-white rounded-2xl shadow-lg p-8 text-center">
          <div className="mx-auto w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mb-6">
            <ShieldAlert className="w-8 h-8 text-red-600" />
          </div>
          <h1 className="text-2xl font-bold text-gray-900 mb-3">접근 권한 없음</h1>
          <p className="text-gray-500 mb-6 text-sm">
            관리자 계정으로 인증된 사용자만 접근할 수 있습니다.
          </p>
          <Link
            href="/"
            className="inline-block px-6 py-3 bg-gray-900 text-white rounded-lg hover:bg-gray-800 transition-colors font-medium"
          >
            홈으로 이동
          </Link>
        </div>
      </div>
    )
  }

  return <>{children}</>
}

function AdminShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-gray-100">
      {/* Header */}
      <header className="sticky top-0 z-50 bg-gray-900 text-white">
        <div className="h-16 px-4 flex items-center justify-between">
          <div className="flex items-center gap-6">
            <Link href="/admin" className="text-xl font-bold">
              UNO A Admin
            </Link>
          </div>
          <div className="flex items-center gap-4">
            {DEMO_MODE && (
              <span className="text-xs bg-amber-500/20 text-amber-300 px-2 py-1 rounded">
                Demo
              </span>
            )}
            <Link
              href="/"
              className="text-sm text-gray-300 hover:text-white transition-colors"
            >
              홈으로
            </Link>
          </div>
        </div>
      </header>

      <div className="flex">
        {/* Sidebar */}
        <aside className="hidden md:flex w-64 flex-col border-r border-gray-200 bg-white min-h-[calc(100vh-64px)]">
          <nav className="flex-1 p-4 space-y-1">
            <Link
              href="/admin"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <LayoutDashboard className="w-5 h-5" />
              <span>대시보드</span>
            </Link>
            <Link
              href="/admin"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <FileCheck className="w-5 h-5" />
              <span>캠페인 심사</span>
            </Link>

            {/* Separator */}
            <div className="pt-2 pb-1 px-4">
              <div className="text-xs font-medium text-gray-400 uppercase tracking-wider">정산 / 결제</div>
            </div>

            <Link
              href="/admin/settlements"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <Wallet className="w-5 h-5" />
              <span>정산 관리</span>
            </Link>
            <Link
              href="/admin/funding-payments"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <CreditCard className="w-5 h-5" />
              <span>펀딩 결제</span>
            </Link>
            <Link
              href="/admin/tax-reports"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <Calculator className="w-5 h-5" />
              <span>세금 보고서</span>
            </Link>

            {/* Separator */}
            <div className="pt-2 pb-1 px-4">
              <div className="text-xs font-medium text-gray-400 uppercase tracking-wider">관리</div>
            </div>

            <Link
              href="/admin/reports"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <Flag className="w-5 h-5" />
              <span>신고 관리</span>
            </Link>
            <Link
              href="/admin/creators"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <Users className="w-5 h-5" />
              <span>크리에이터 관리</span>
            </Link>

            {/* Ops CRM Section */}
            <div className="pt-2 pb-1 px-4">
              <div className="text-xs font-medium text-gray-400 uppercase tracking-wider">운영 (Ops)</div>
            </div>

            <Link
              href="/admin/ops"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <Megaphone className="w-5 h-5" />
              <span>Ops 대시보드</span>
            </Link>
            <Link
              href="/admin/ops/banners"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <Image className="w-5 h-5" />
              <span>배너 관리</span>
            </Link>
            <Link
              href="/admin/ops/flags"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <ToggleLeft className="w-5 h-5" />
              <span>기능 플래그</span>
            </Link>
            <Link
              href="/admin/ops/audit"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <ScrollText className="w-5 h-5" />
              <span>감사 로그</span>
            </Link>
            <Link
              href="/admin/ops/staff"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <Users className="w-5 h-5" />
              <span>스태프 관리</span>
            </Link>

            {/* Content Management Section */}
            <div className="pt-2 pb-1 px-4">
              <div className="text-xs font-medium text-gray-400 uppercase tracking-wider">콘텐츠</div>
            </div>

            <Link
              href="/admin/landing"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <Globe className="w-5 h-5" />
              <span>랜딩페이지</span>
            </Link>
            <Link
              href="/admin/ops/assets"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <Image className="w-5 h-5" />
              <span>이미지 관리</span>
            </Link>
          </nav>

          <div className="p-4 border-t border-gray-200">
            <button className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors w-full">
              <LogOut className="w-5 h-5" />
              <span>로그아웃</span>
            </button>
          </div>
        </aside>

        {/* Main Content */}
        <main className="flex-1 p-6">
          <OpsToastProvider>
            {children}
          </OpsToastProvider>
        </main>
      </div>
    </div>
  )
}

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode
}) {
  if (DEMO_MODE) {
    return (
      <DemoGate>
        <AdminShell>{children}</AdminShell>
      </DemoGate>
    )
  }

  return (
    <AdminAuthGate>
      <AdminShell>{children}</AdminShell>
    </AdminAuthGate>
  )
}
