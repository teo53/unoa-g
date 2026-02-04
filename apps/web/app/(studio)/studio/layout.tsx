import Link from 'next/link'
import { LayoutDashboard, Megaphone, Settings, LogOut } from 'lucide-react'

export default function StudioLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="sticky top-0 z-50 bg-white border-b border-gray-200">
        <div className="h-16 px-4 flex items-center justify-between">
          <div className="flex items-center gap-6">
            <Link href="/studio" className="text-xl font-bold text-primary-500">
              UNO A Studio
            </Link>
          </div>
          <div className="flex items-center gap-4">
            <Link
              href="/"
              className="text-sm text-gray-500 hover:text-gray-700 transition-colors"
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
              href="/studio"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <LayoutDashboard className="w-5 h-5" />
              <span>대시보드</span>
            </Link>
            <Link
              href="/studio/campaigns/new"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <Megaphone className="w-5 h-5" />
              <span>새 캠페인</span>
            </Link>
          </nav>

          <div className="p-4 border-t border-gray-200">
            <Link
              href="/settings"
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <Settings className="w-5 h-5" />
              <span>설정</span>
            </Link>
            <button
              className="flex items-center gap-3 px-4 py-3 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors w-full"
            >
              <LogOut className="w-5 h-5" />
              <span>로그아웃</span>
            </button>
          </div>
        </aside>

        {/* Main Content */}
        <main className="flex-1 p-6">
          {children}
        </main>
      </div>
    </div>
  )
}
