'use client'

import { useEffect, useState } from 'react'
import { Plus, Trash2, Shield } from 'lucide-react'
import { listStaff, upsertStaff, removeStaff } from '@/lib/ops/ops-client'
import type { OpsStaff, OpsRole } from '@/lib/ops/ops-types'
import { ROLE_LABELS } from '@/lib/ops/ops-types'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import { OpsConfirmModal } from '@/components/ops/ops-confirm-modal'

const ROLE_COLORS: Record<OpsRole, string> = {
  viewer: 'bg-gray-100 text-gray-700',
  operator: 'bg-blue-100 text-blue-700',
  publisher: 'bg-green-100 text-green-700',
  admin: 'bg-purple-100 text-purple-700',
}

export default function StaffPage() {
  const [staff, setStaff] = useState<OpsStaff[]>([])
  const [loading, setLoading] = useState(true)
  const [showAdd, setShowAdd] = useState(false)
  const [newUserId, setNewUserId] = useState('')
  const [newRole, setNewRole] = useState<OpsRole>('viewer')
  const [newName, setNewName] = useState('')
  const [saving, setSaving] = useState(false)
  const [removeTarget, setRemoveTarget] = useState<string | null>(null)
  const [removing, setRemoving] = useState(false)

  useEffect(() => {
    async function load() {
      try {
        const data = await listStaff()
        setStaff(data)
      } catch {
        // silent
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [])

  async function handleAdd() {
    if (!newUserId.trim()) return
    setSaving(true)
    try {
      const member = await upsertStaff(newUserId.trim(), newRole, newName.trim() || undefined)
      setStaff((prev) => [member, ...prev.filter((s) => s.user_id !== member.user_id)])
      setShowAdd(false)
      setNewUserId('')
      setNewName('')
    } catch {
      // handled
    } finally {
      setSaving(false)
    }
  }

  async function handleRemoveConfirm() {
    if (!removeTarget) return
    setRemoving(true)
    try {
      await removeStaff(removeTarget)
      setStaff((prev) => prev.filter((s) => s.user_id !== removeTarget))
    } catch {
      // handled
    } finally {
      setRemoving(false)
      setRemoveTarget(null)
    }
  }

  async function handleRoleChange(userId: string, newRoleValue: OpsRole) {
    try {
      const member = await upsertStaff(userId, newRoleValue)
      setStaff((prev) =>
        prev.map((s) => (s.user_id === userId ? member : s))
      )
    } catch {
      // handled
    }
  }

  if (loading) {
    return (
      <div className="space-y-4">
        <h1 className="text-2xl font-bold text-gray-900">스태프 관리</h1>
        {[1, 2, 3].map((i) => (
          <div key={i} className="h-16 bg-gray-100 rounded-lg animate-pulse" />
        ))}
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">스태프 관리</h1>
          <p className="text-sm text-gray-500 mt-1">Ops CRM 접근 권한을 관리합니다</p>
        </div>
        <button
          className="inline-flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 text-sm font-medium"
          onClick={() => setShowAdd(!showAdd)}
        >
          <Plus className="w-4 h-4" />
          스태프 추가
        </button>
      </div>

      {/* RBAC Legend */}
      <div className="flex flex-wrap gap-2">
        {(Object.entries(ROLE_LABELS) as [OpsRole, string][]).map(([role, label]) => (
          <span
            key={role}
            className={`text-xs px-2 py-1 rounded-full ${ROLE_COLORS[role]}`}
          >
            {label}
          </span>
        ))}
      </div>

      {/* Add form */}
      {showAdd && (
        <div className="bg-white border border-gray-200 rounded-lg p-4 space-y-3">
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="block text-xs text-gray-500 mb-1">사용자 ID (UUID)</label>
              <input
                type="text"
                className="w-full border border-gray-300 rounded px-3 py-2 text-sm"
                placeholder="00000000-0000-0000-0000-000000000000"
                value={newUserId}
                onChange={(e) => setNewUserId(e.target.value)}
              />
            </div>
            <div>
              <label className="block text-xs text-gray-500 mb-1">표시 이름</label>
              <input
                type="text"
                className="w-full border border-gray-300 rounded px-3 py-2 text-sm"
                placeholder="운영자 이름"
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
              />
            </div>
            <div>
              <label className="block text-xs text-gray-500 mb-1">역할</label>
              <select
                className="w-full border border-gray-300 rounded px-3 py-2 text-sm"
                value={newRole}
                onChange={(e) => setNewRole(e.target.value as OpsRole)}
              >
                {(Object.entries(ROLE_LABELS) as [OpsRole, string][]).map(([role, label]) => (
                  <option key={role} value={role}>{label}</option>
                ))}
              </select>
            </div>
          </div>
          <div className="flex gap-2">
            <button
              className="px-4 py-2 bg-purple-600 text-white rounded text-sm disabled:opacity-50"
              disabled={saving || !newUserId}
              onClick={handleAdd}
            >
              {saving ? '추가 중...' : '추가'}
            </button>
            <button
              className="px-4 py-2 text-gray-500 text-sm"
              onClick={() => setShowAdd(false)}
            >
              취소
            </button>
          </div>
        </div>
      )}

      {/* Staff list */}
      {DEMO_MODE && staff.length === 0 ? (
        <div className="text-center py-12 bg-white border border-gray-200 rounded-lg">
          <Shield className="w-12 h-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500">데모 모드에서는 스태프 관리가 제한됩니다</p>
          <p className="text-sm text-gray-400 mt-1">실제 Supabase 연결 시 활성화됩니다</p>
        </div>
      ) : (
        <div className="bg-white border border-gray-200 rounded-lg divide-y">
          {staff.map((member) => (
            <div key={member.id} className="flex items-center gap-4 p-4">
              <div className="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center text-gray-500 text-sm font-medium">
                {(member.display_name || '?')[0].toUpperCase()}
              </div>
              <div className="flex-1 min-w-0">
                <p className="font-medium text-gray-900 truncate">
                  {member.display_name || member.user_id.slice(0, 8)}
                </p>
                <p className="text-xs text-gray-400 truncate">
                  {member.user?.email || member.user_id}
                </p>
              </div>
              <select
                className={`text-xs px-3 py-1.5 rounded-full font-medium ${ROLE_COLORS[member.role]}`}
                value={member.role}
                onChange={(e) => handleRoleChange(member.user_id, e.target.value as OpsRole)}
              >
                {(Object.entries(ROLE_LABELS) as [OpsRole, string][]).map(([role, label]) => (
                  <option key={role} value={role}>{label}</option>
                ))}
              </select>
              <button
                className="p-2 text-red-400 hover:text-red-600 hover:bg-red-50 rounded"
                onClick={() => setRemoveTarget(member.user_id)}
                title="제거"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          ))}
        </div>
      )}

      {/* Remove Confirm Modal */}
      <OpsConfirmModal
        open={!!removeTarget}
        onClose={() => setRemoveTarget(null)}
        onConfirm={handleRemoveConfirm}
        title="스태프 제거"
        description="이 스태프를 제거하시겠습니까? Ops CRM 접근 권한이 해제됩니다."
        variant="danger"
        confirmLabel="제거"
        loading={removing}
      />
    </div>
  )
}
