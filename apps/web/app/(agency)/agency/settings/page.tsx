'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { Building2, Save, UserCog } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import { getAgencySettings, updateAgencySettings } from '@/lib/agency/agency-client'
import type { Agency } from '@/lib/agency/agency-types'

export default function AgencySettingsPage() {
  const [agency, setAgency] = useState<Agency | null>(null)
  const [isSaving, setIsSaving] = useState(false)

  useEffect(() => {
    getAgencySettings().then(setAgency)
  }, [])

  async function handleSave() {
    if (!agency) return
    setIsSaving(true)
    try {
      const updated = await updateAgencySettings({
        name: agency.name,
        representative_name: agency.representative_name,
        contact_email: agency.contact_email,
        contact_phone: agency.contact_phone,
        bank_name: agency.bank_name,
        bank_account_number: agency.bank_account_number,
        bank_account_holder: agency.bank_account_holder,
      })
      setAgency(updated)
    } catch (error) {
      console.error('Failed to update agency settings:', error)
    } finally {
      setIsSaving(false)
    }
  }

  if (!agency) return <div className="text-center py-12">로딩 중...</div>

  return (
    <div className="max-w-3xl mx-auto">
      {DEMO_MODE && (
        <div className="mb-4 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 text-sm text-amber-800">
          데모 모드 — 변경사항이 저장되지 않습니다
        </div>
      )}

      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">소속사 설정</h1>
          <p className="text-gray-500 mt-1">소속사 기본 정보 및 정산 계좌</p>
        </div>
        <Link href="/agency/settings/staff">
          <Button variant="outline">
            <UserCog className="w-4 h-4 mr-2" />
            스태프 관리
          </Button>
        </Link>
      </div>

      {/* Agency Profile */}
      <div className="bg-white rounded-xl border border-gray-200 p-6 mb-6">
        <div className="flex items-center gap-3 mb-6">
          <Building2 className="w-5 h-5 text-gray-400" />
          <h2 className="font-semibold text-gray-900">기본 정보</h2>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">소속사명</label>
            <input
              type="text"
              value={agency.name}
              onChange={(e) => setAgency({ ...agency, name: e.target.value })}
              className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">대표자명</label>
              <input
                type="text"
                value={agency.representative_name || ''}
                onChange={(e) => setAgency({ ...agency, representative_name: e.target.value })}
                className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">사업자등록번호</label>
              <input
                type="text"
                value={agency.business_registration_number || ''}
                disabled
                className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm bg-gray-50 text-gray-500"
              />
              <p className="text-xs text-gray-400 mt-1">사업자등록번호는 변경할 수 없습니다</p>
            </div>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">연락처 이메일</label>
              <input
                type="email"
                value={agency.contact_email || ''}
                onChange={(e) => setAgency({ ...agency, contact_email: e.target.value })}
                className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">전화번호</label>
              <input
                type="tel"
                value={agency.contact_phone || ''}
                onChange={(e) => setAgency({ ...agency, contact_phone: e.target.value })}
                className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
          </div>
        </div>
      </div>

      {/* Bank Account */}
      <div className="bg-white rounded-xl border border-gray-200 p-6 mb-6">
        <h2 className="font-semibold text-gray-900 mb-4">정산 계좌</h2>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">은행명</label>
            <input
              type="text"
              value={agency.bank_name || ''}
              onChange={(e) => setAgency({ ...agency, bank_name: e.target.value })}
              className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">계좌번호</label>
            <input
              type="text"
              value={agency.bank_account_number || ''}
              onChange={(e) => setAgency({ ...agency, bank_account_number: e.target.value })}
              className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">예금주</label>
            <input
              type="text"
              value={agency.bank_account_holder || ''}
              onChange={(e) => setAgency({ ...agency, bank_account_holder: e.target.value })}
              className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>
        </div>
      </div>

      <div className="flex justify-end">
        <Button onClick={handleSave} loading={isSaving}>
          <Save className="w-4 h-4 mr-2" />
          저장
        </Button>
      </div>
    </div>
  )
}
