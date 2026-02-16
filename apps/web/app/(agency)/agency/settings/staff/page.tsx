'use client'

import { useState } from 'react'
import Link from 'next/link'
import { ArrowLeft, UserPlus, Shield, Mail } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import { mockAgencyStaff } from '@/lib/mock/demo-agency-data'
import type { AgencyStaffRole } from '@/lib/agency/agency-types'

const ROLE_LABELS: Record<AgencyStaffRole, { label: string; description: string; className: string }> = {
  admin: { label: '관리자', description: '모든 권한', className: 'bg-red-100 text-red-700' },
  finance: { label: '재무', description: '정산/세금 관리', className: 'bg-purple-100 text-purple-700' },
  manager: { label: '매니저', description: '크리에이터 관리', className: 'bg-blue-100 text-blue-700' },
  viewer: { label: '뷰어', description: '조회만 가능', className: 'bg-gray-100 text-gray-600' },
}

export default function StaffManagementPage() {
  const [staff] = useState(mockAgencyStaff)
  const [showInvite, setShowInvite] = useState(false)
  const [inviteEmail, setInviteEmail] = useState('')
  const [inviteRole, setInviteRole] = useState<AgencyStaffRole>('viewer')

  return (
    <div className="max-w-4xl mx-auto">
      {DEMO_MODE && (
        <div className="mb-4 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 text-sm text-amber-800">
          데모 모드 — 변경사항이 저장되지 않습니다
        </div>
      )}

      <div className="mb-6">
        <Link href="/agency/settings" className="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-900 mb-3">
          <ArrowLeft className="w-4 h-4" />
          설정
        </Link>
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">스태프 관리</h1>
            <p className="text-gray-500 mt-1">{staff.length}명의 스태프</p>
          </div>
          <Button onClick={() => setShowInvite(!showInvite)}>
            <UserPlus className="w-4 h-4 mr-2" />
            스태프 초대
          </Button>
        </div>
      </div>

      {/* Invite Form */}
      {showInvite && (
        <div className="bg-indigo-50 rounded-xl border border-indigo-200 p-6 mb-6">
          <h3 className="font-semibold text-gray-900 mb-4">새 스태프 초대</h3>
          <div className="flex items-end gap-4">
            <div className="flex-1">
              <label className="block text-sm font-medium text-gray-700 mb-1">이메일</label>
              <input
                type="email"
                value={inviteEmail}
                onChange={(e) => setInviteEmail(e.target.value)}
                placeholder="staff@example.com"
                className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <div className="w-40">
              <label className="block text-sm font-medium text-gray-700 mb-1">역할</label>
              <select
                value={inviteRole}
                onChange={(e) => setInviteRole(e.target.value as AgencyStaffRole)}
                className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="viewer">뷰어</option>
                <option value="manager">매니저</option>
                <option value="finance">재무</option>
                <option value="admin">관리자</option>
              </select>
            </div>
            <Button>
              <Mail className="w-4 h-4 mr-2" />
              초대
            </Button>
          </div>
        </div>
      )}

      {/* Role Legend */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
        {(Object.entries(ROLE_LABELS) as [AgencyStaffRole, typeof ROLE_LABELS[AgencyStaffRole]][]).map(([role, config]) => (
          <div key={role} className="bg-white rounded-lg border border-gray-200 p-3">
            <div className="flex items-center gap-2 mb-1">
              <Shield className="w-4 h-4 text-gray-400" />
              <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${config.className}`}>
                {config.label}
              </span>
            </div>
            <p className="text-xs text-gray-500">{config.description}</p>
          </div>
        ))}
      </div>

      {/* Staff List */}
      <div className="bg-white rounded-xl border border-gray-200">
        <div className="p-4 border-b border-gray-200">
          <h2 className="font-semibold text-gray-900">스태프 목록</h2>
        </div>

        <div className="divide-y divide-gray-100">
          {staff.map((s) => {
            const roleConfig = ROLE_LABELS[s.role]
            return (
              <div key={s.id} className="p-4 flex items-center gap-4">
                <div className="w-10 h-10 bg-indigo-100 rounded-full flex items-center justify-center text-indigo-600 font-bold text-sm flex-shrink-0">
                  {(s.display_name || '?').charAt(0)}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="font-medium text-gray-900">{s.display_name || '이름 없음'}</div>
                  <div className="text-sm text-gray-500">{s.email || '-'}</div>
                </div>
                <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${roleConfig.className}`}>
                  {roleConfig.label}
                </span>
                <div className="text-xs text-gray-400">
                  {s.accepted_at ? '활성' : '초대 대기'}
                </div>
              </div>
            )
          })}
        </div>
      </div>
    </div>
  )
}
