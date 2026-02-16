import { ScrollText, User } from 'lucide-react'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import { mockAgencyAuditLog } from '@/lib/mock/demo-agency-data'
import { formatDateTime } from '@/lib/utils/format'
import type { AgencyAuditEntry } from '@/lib/agency/agency-types'

const ACTION_LABELS: Record<string, string> = {
  'creator.add': '크리에이터 등록',
  'creator.update': '크리에이터 정보 수정',
  'creator.remove': '크리에이터 해지',
  'staff.invite': '스태프 초대',
  'staff.update': '스태프 역할 변경',
  'staff.remove': '스태프 제거',
  'agency.update': '소속사 정보 수정',
  'settlement.request': '정산 승인 요청',
  'tax.upload': '세금 증빙 업로드',
}

const ROLE_LABELS: Record<string, string> = {
  admin: '관리자',
  finance: '재무',
  manager: '매니저',
  viewer: '뷰어',
}

async function getAuditLog(): Promise<AgencyAuditEntry[]> {
  if (DEMO_MODE) {
    return mockAgencyAuditLog
  }
  return mockAgencyAuditLog
}

export default async function AgencyAuditPage() {
  const auditLog = await getAuditLog()

  return (
    <div className="max-w-4xl mx-auto">
      {DEMO_MODE && (
        <div className="mb-4 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 text-sm text-amber-800">
          데모 모드 — 샘플 데이터가 표시됩니다
        </div>
      )}

      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">감사 로그</h1>
        <p className="text-gray-500 mt-1">모든 변경 이력이 기록됩니다</p>
      </div>

      <div className="bg-white rounded-xl border border-gray-200">
        {auditLog.length === 0 ? (
          <div className="p-12 text-center">
            <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <ScrollText className="w-8 h-8 text-gray-400" />
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">감사 로그가 없습니다</h3>
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {auditLog.map((entry) => (
              <div key={entry.id} className="p-4">
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
                    <User className="w-4 h-4 text-gray-400" />
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full">
                        {ROLE_LABELS[entry.actor_role] || entry.actor_role}
                      </span>
                      <span className="font-medium text-gray-900">
                        {ACTION_LABELS[entry.action] || entry.action}
                      </span>
                    </div>

                    {/* Diff */}
                    {(entry.before_data || entry.after_data) && (
                      <div className="mt-2 text-xs bg-gray-50 rounded-lg p-3 space-y-1">
                        {entry.before_data && (
                          <div className="text-red-600">
                            - {JSON.stringify(entry.before_data)}
                          </div>
                        )}
                        {entry.after_data && (
                          <div className="text-green-600">
                            + {JSON.stringify(entry.after_data)}
                          </div>
                        )}
                      </div>
                    )}

                    <div className="text-xs text-gray-400 mt-2">
                      {formatDateTime(entry.created_at)}
                      {entry.entity_type && ` · ${entry.entity_type}`}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
