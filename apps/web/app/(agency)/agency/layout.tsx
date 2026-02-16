import Link from 'next/link'
import {
  LayoutDashboard,
  Users,
  UserPlus,
  BarChart3,
  Wallet,
  Receipt,
  Settings,
  UserCog,
  Megaphone,
  ScrollText,
  LogOut,
  ShieldAlert,
  Building2,
} from 'lucide-react'
import { OpsToastProvider } from '@/components/ops/ops-toast'
import { DEMO_MODE } from '@/lib/mock/demo-data'

export default function AgencyLayout({
  children,
}: {
  children: React.ReactNode
}) {
  // Demo mode blocks agency panel access in production
  if (DEMO_MODE && process.env.NODE_ENV === 'production') {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="max-w-md w-full mx-4 bg-white rounded-2xl shadow-lg p-8 text-center">
          <div className="mx-auto w-16 h-16 bg-indigo-100 rounded-full flex items-center justify-center mb-6">
            <ShieldAlert className="w-8 h-8 text-indigo-500" />
          </div>
          <h1 className="text-2xl font-bold text-gray-900 mb-3">
            소속사 인증 필요
          </h1>
          <p className="text-gray-500 mb-6">
            소속사 포탈은 데모 모드에서 사용할 수 없습니다.<br />
            소속사 계정으로 로그인해주세요.
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
      {/* Sticky Header */}
      <header className="sticky top-0 z-50 bg-indigo-900 text-white">
        <div className="h-16 px-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Building2 className="w-6 h-6" />
            <Link href="/agency" className="text-xl font-bold">
              UNO A Agency
            </Link>
          </div>
          <div className="flex items-center gap-4">
            {DEMO_MODE && (
              <span className="text-xs bg-amber-500 text-white px-2 py-0.5 rounded-full">
                DEMO
              </span>
            )}
            <Link
              href="/"
              className="text-sm text-indigo-200 hover:text-white transition-colors"
            >
              홈으로
            </Link>
          </div>
        </div>
      </header>

      <div className="flex">
        {/* Sidebar Navigation */}
        <aside className="hidden md:flex w-64 flex-col border-r border-gray-200 bg-white min-h-[calc(100vh-64px)]">
          <nav className="flex-1 p-4 space-y-1">
            {/* Dashboard */}
            <Link
              href="/agency"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-indigo-50 hover:text-indigo-700 transition-colors"
            >
              <LayoutDashboard className="w-5 h-5" />
              <span>대시보드</span>
            </Link>

            {/* Creator Section */}
            <div className="pt-3 pb-1 px-4">
              <div className="text-xs font-medium text-gray-400 uppercase tracking-wider">크리에이터</div>
            </div>
            <Link
              href="/agency/creators"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-indigo-50 hover:text-indigo-700 transition-colors"
            >
              <Users className="w-5 h-5" />
              <span>소속 크리에이터</span>
            </Link>
            <Link
              href="/agency/creators/register"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-indigo-50 hover:text-indigo-700 transition-colors"
            >
              <UserPlus className="w-5 h-5" />
              <span>크리에이터 등록</span>
            </Link>

            {/* Statistics Section */}
            <div className="pt-3 pb-1 px-4">
              <div className="text-xs font-medium text-gray-400 uppercase tracking-wider">통계</div>
            </div>
            <Link
              href="/agency/statistics"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-indigo-50 hover:text-indigo-700 transition-colors"
            >
              <BarChart3 className="w-5 h-5" />
              <span>전체 통계</span>
            </Link>

            {/* Settlement / Finance Section */}
            <div className="pt-3 pb-1 px-4">
              <div className="text-xs font-medium text-gray-400 uppercase tracking-wider">정산 / 재무</div>
            </div>
            <Link
              href="/agency/settlements"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-indigo-50 hover:text-indigo-700 transition-colors"
            >
              <Wallet className="w-5 h-5" />
              <span>정산 관리</span>
            </Link>
            <Link
              href="/agency/tax"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-indigo-50 hover:text-indigo-700 transition-colors"
            >
              <Receipt className="w-5 h-5" />
              <span>세금 증빙</span>
            </Link>

            {/* Agency Management Section */}
            <div className="pt-3 pb-1 px-4">
              <div className="text-xs font-medium text-gray-400 uppercase tracking-wider">소속사</div>
            </div>
            <Link
              href="/agency/notices"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-indigo-50 hover:text-indigo-700 transition-colors"
            >
              <Megaphone className="w-5 h-5" />
              <span>공지사항</span>
            </Link>
            <Link
              href="/agency/settings"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-indigo-50 hover:text-indigo-700 transition-colors"
            >
              <Settings className="w-5 h-5" />
              <span>설정</span>
            </Link>
            <Link
              href="/agency/settings/staff"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-indigo-50 hover:text-indigo-700 transition-colors"
            >
              <UserCog className="w-5 h-5" />
              <span>스태프 관리</span>
            </Link>
            <Link
              href="/agency/audit"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-indigo-50 hover:text-indigo-700 transition-colors"
            >
              <ScrollText className="w-5 h-5" />
              <span>감사 로그</span>
            </Link>
          </nav>

          {/* Logout */}
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
