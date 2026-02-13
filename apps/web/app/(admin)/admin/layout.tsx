import Link from 'next/link'
import { LayoutDashboard, FileCheck, Flag, LogOut, Wallet, CreditCard, Calculator, Image, ToggleLeft, ScrollText, Users, Megaphone, ShieldAlert } from 'lucide-react'
import { OpsToastProvider } from '@/components/ops/ops-toast'
import { DEMO_MODE } from '@/lib/mock/demo-data'

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode
}) {
  // 데모 모드에서는 관리자 패널 접근 차단
  if (DEMO_MODE) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="max-w-md w-full mx-4 bg-white rounded-2xl shadow-lg p-8 text-center">
          <div className="mx-auto w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mb-6">
            <ShieldAlert className="w-8 h-8 text-red-500" />
          </div>
          <h1 className="text-2xl font-bold text-gray-900 mb-3">
            관리자 인증 필요
          </h1>
          <p className="text-gray-500 mb-6">
            관리자 패널은 데모 모드에서 사용할 수 없습니다.<br />
            관리자 계정으로 로그인해주세요.
          </p>
          <Link
            href="/"
            className="inline-flex items-center justify-center px-6 py-3 bg-gray-900 text-white rounded-lg hover:bg-gray-800 transition-colors"
          >
            홈으로 돌아가기
          </Link>
        </div>
      </div>
    )
  }

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
