import { Megaphone, Pin } from 'lucide-react'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import { mockAgencyNotices } from '@/lib/mock/demo-agency-data'
import { formatRelativeTime } from '@/lib/utils/format'
import type { AgencyNotice } from '@/lib/agency/agency-types'

async function getNotices(): Promise<AgencyNotice[]> {
  if (DEMO_MODE) {
    return mockAgencyNotices
  }
  // TODO: Call agency-manage Edge Function with action: notice.list
  return mockAgencyNotices
}

export default async function AgencyNoticesPage() {
  const notices = await getNotices()
  const pinned = notices.filter(n => n.is_pinned)
  const regular = notices.filter(n => !n.is_pinned)

  return (
    <div className="max-w-4xl mx-auto">
      {DEMO_MODE && (
        <div className="mb-4 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 text-sm text-amber-800">
          데모 모드 — 샘플 데이터가 표시됩니다
        </div>
      )}

      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">공지사항</h1>
        <p className="text-gray-500 mt-1">플랫폼 공지 및 소속사 내부 공지</p>
      </div>

      {/* Pinned */}
      {pinned.length > 0 && (
        <div className="space-y-3 mb-6">
          {pinned.map((notice) => (
            <div key={notice.id} className="bg-indigo-50 rounded-xl border border-indigo-200 p-4">
              <div className="flex items-start gap-3">
                <Pin className="w-4 h-4 text-indigo-500 mt-1 flex-shrink-0" />
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    {notice.is_platform_notice && (
                      <span className="text-xs bg-indigo-100 text-indigo-700 px-2 py-0.5 rounded-full">플랫폼</span>
                    )}
                    <h3 className="font-semibold text-gray-900">{notice.title}</h3>
                  </div>
                  <p className="text-sm text-gray-700">{notice.content}</p>
                  <div className="text-xs text-gray-400 mt-2">{formatRelativeTime(notice.created_at)}</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Regular Notices */}
      <div className="bg-white rounded-xl border border-gray-200">
        <div className="p-4 border-b border-gray-200">
          <h2 className="font-semibold text-gray-900">전체 공지</h2>
        </div>

        {regular.length === 0 && pinned.length === 0 ? (
          <div className="p-12 text-center">
            <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <Megaphone className="w-8 h-8 text-gray-400" />
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">공지사항이 없습니다</h3>
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {regular.map((notice) => (
              <div key={notice.id} className="p-4">
                <div className="flex items-center gap-2 mb-1">
                  {notice.is_platform_notice ? (
                    <span className="text-xs bg-indigo-100 text-indigo-700 px-2 py-0.5 rounded-full">플랫폼</span>
                  ) : (
                    <span className="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full">내부</span>
                  )}
                  <h3 className="font-medium text-gray-900">{notice.title}</h3>
                </div>
                <p className="text-sm text-gray-600 mt-1">{notice.content}</p>
                <div className="text-xs text-gray-400 mt-2">{formatRelativeTime(notice.created_at)}</div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
