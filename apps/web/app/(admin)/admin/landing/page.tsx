'use client'

import { useState, useEffect } from 'react'
import { Save, RotateCcw, ExternalLink, Plus, Trash2, GripVertical } from 'lucide-react'
import { LANDING_DEFAULTS, type LandingContent, type LandingFeature, type LandingStat } from '@/lib/config/landing-defaults'
import { DEMO_MODE } from '@/lib/mock/demo-data'

const ICON_OPTIONS = [
  'MessageCircle', 'CreditCard', 'Heart', 'Vote', 'Cake', 'Sparkles',
  'Star', 'Music', 'Camera', 'Gift', 'Shield', 'Zap', 'Users', 'Globe',
]

export default function LandingEditorPage() {
  const [content, setContent] = useState<LandingContent>(LANDING_DEFAULTS)
  const [isSaving, setIsSaving] = useState(false)
  const [saveStatus, setSaveStatus] = useState<'idle' | 'success' | 'error'>('idle')
  const [isDirty, setIsDirty] = useState(false)

  // Load content on mount
  useEffect(() => {
    if (DEMO_MODE) return

    const url = process.env.NEXT_PUBLIC_SUPABASE_URL
    const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
    if (!url || !key) return

    fetch(`${url}/rest/v1/landing_content?id=eq.main&select=*`, {
      headers: { apikey: key, Authorization: `Bearer ${key}` },
    })
      .then((r) => r.json())
      .then((rows) => {
        if (Array.isArray(rows) && rows.length > 0) {
          setContent(rows[0] as LandingContent)
        }
      })
      .catch(() => {})
  }, [])

  const handleSave = async () => {
    setIsSaving(true)
    setSaveStatus('idle')

    if (DEMO_MODE) {
      // In demo mode, just simulate save
      await new Promise((r) => setTimeout(r, 800))
      setSaveStatus('success')
      setIsDirty(false)
      setIsSaving(false)
      setTimeout(() => setSaveStatus('idle'), 3000)
      return
    }

    try {
      const { saveLandingContent } = await import('@/lib/hooks/use-landing-content')
      const ok = await saveLandingContent(content)
      setSaveStatus(ok ? 'success' : 'error')
      if (ok) setIsDirty(false)
    } catch {
      setSaveStatus('error')
    }
    setIsSaving(false)
    setTimeout(() => setSaveStatus('idle'), 3000)
  }

  const handleReset = () => {
    if (confirm('기본값으로 초기화하시겠습니까?')) {
      setContent(LANDING_DEFAULTS)
      setIsDirty(true)
    }
  }

  const update = <K extends keyof LandingContent>(key: K, value: LandingContent[K]) => {
    setContent((prev) => ({ ...prev, [key]: value }))
    setIsDirty(true)
  }

  const updateFeature = (index: number, field: keyof LandingFeature, value: string) => {
    const updated = [...content.features]
    updated[index] = { ...updated[index], [field]: value }
    update('features', updated)
  }

  const addFeature = () => {
    update('features', [
      ...content.features,
      { icon: 'Star', title: '새 기능', description: '설명을 입력하세요' },
    ])
  }

  const removeFeature = (index: number) => {
    update('features', content.features.filter((_, i) => i !== index))
  }

  const updateStat = (index: number, field: keyof LandingStat, value: string | number) => {
    const updated = [...content.stats]
    updated[index] = { ...updated[index], [field]: value }
    update('stats', updated)
  }

  return (
    <div className="max-w-4xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">랜딩페이지 편집</h1>
          <p className="text-sm text-gray-500 mt-1">
            공개 랜딩페이지의 텍스트, 기능 카드, 통계 수치를 편집합니다
          </p>
        </div>
        <div className="flex items-center gap-3">
          {saveStatus === 'success' && (
            <span className="text-sm text-green-600 font-medium">저장 완료!</span>
          )}
          {saveStatus === 'error' && (
            <span className="text-sm text-red-600 font-medium">저장 실패</span>
          )}
          <button
            onClick={handleReset}
            className="flex items-center gap-2 px-4 py-2 text-gray-600 bg-white border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors text-sm"
          >
            <RotateCcw className="w-4 h-4" />
            초기화
          </button>
          <a
            href="/"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 px-4 py-2 text-gray-600 bg-white border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors text-sm"
          >
            <ExternalLink className="w-4 h-4" />
            미리보기
          </a>
          <button
            onClick={handleSave}
            disabled={isSaving || !isDirty}
            className="flex items-center gap-2 px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-gray-800 transition-colors text-sm disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Save className="w-4 h-4" />
            {isSaving ? '저장 중...' : '저장'}
          </button>
        </div>
      </div>

      {DEMO_MODE && (
        <div className="mb-6 px-4 py-3 bg-amber-50 border border-amber-200 rounded-lg text-sm text-amber-800">
          데모 모드: 변경사항은 세션 내에서만 유지됩니다. 실제 저장은 Supabase 연결 후 가능합니다.
        </div>
      )}

      <div className="space-y-8">
        {/* Hero Section */}
        <section className="bg-white rounded-xl border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">히어로 섹션</h2>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                메인 헤드라인
              </label>
              <input
                type="text"
                value={content.hero_headline}
                onChange={(e) => update('hero_headline', e.target.value)}
                className="w-full px-4 py-2.5 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500/30 focus:border-primary-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                서브 헤드라인
              </label>
              <textarea
                value={content.hero_subheadline}
                onChange={(e) => update('hero_subheadline', e.target.value)}
                rows={2}
                className="w-full px-4 py-2.5 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500/30 focus:border-primary-500 resize-none"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  기본 CTA 버튼
                </label>
                <input
                  type="text"
                  value={content.hero_cta_primary}
                  onChange={(e) => update('hero_cta_primary', e.target.value)}
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500/30 focus:border-primary-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  보조 CTA 버튼
                </label>
                <input
                  type="text"
                  value={content.hero_cta_secondary}
                  onChange={(e) => update('hero_cta_secondary', e.target.value)}
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500/30 focus:border-primary-500"
                />
              </div>
            </div>
          </div>
        </section>

        {/* Features Section */}
        <section className="bg-white rounded-xl border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">기능 카드</h2>
            <button
              onClick={addFeature}
              className="flex items-center gap-1 text-sm text-primary-600 hover:text-primary-700 font-medium"
            >
              <Plus className="w-4 h-4" />
              추가
            </button>
          </div>
          <div className="space-y-4">
            {content.features.map((feature, i) => (
              <div
                key={i}
                className="flex gap-3 p-4 bg-gray-50 rounded-lg border border-gray-100"
              >
                <div className="flex-shrink-0 pt-2 text-gray-300 cursor-grab">
                  <GripVertical className="w-4 h-4" />
                </div>
                <div className="flex-1 grid grid-cols-[120px_1fr] gap-3">
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1">아이콘</label>
                    <select
                      value={feature.icon}
                      onChange={(e) => updateFeature(i, 'icon', e.target.value)}
                      className="w-full px-2 py-1.5 text-sm border border-gray-200 rounded-md"
                    >
                      {ICON_OPTIONS.map((icon) => (
                        <option key={icon} value={icon}>{icon}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1">제목</label>
                    <input
                      type="text"
                      value={feature.title}
                      onChange={(e) => updateFeature(i, 'title', e.target.value)}
                      className="w-full px-3 py-1.5 text-sm border border-gray-200 rounded-md"
                    />
                  </div>
                  <div className="col-span-2">
                    <label className="block text-xs font-medium text-gray-500 mb-1">설명</label>
                    <input
                      type="text"
                      value={feature.description}
                      onChange={(e) => updateFeature(i, 'description', e.target.value)}
                      className="w-full px-3 py-1.5 text-sm border border-gray-200 rounded-md"
                    />
                  </div>
                </div>
                <button
                  onClick={() => removeFeature(i)}
                  className="flex-shrink-0 p-1 text-gray-400 hover:text-red-500 transition-colors"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ))}
          </div>
        </section>

        {/* Stats Section */}
        <section className="bg-white rounded-xl border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">통계 수치</h2>
          <div className="grid grid-cols-2 gap-4">
            {content.stats.map((stat, i) => (
              <div key={i} className="p-4 bg-gray-50 rounded-lg border border-gray-100">
                <div className="grid grid-cols-2 gap-3 mb-3">
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1">접두사</label>
                    <input
                      type="text"
                      value={stat.prefix}
                      onChange={(e) => updateStat(i, 'prefix', e.target.value)}
                      placeholder="₩"
                      className="w-full px-3 py-1.5 text-sm border border-gray-200 rounded-md"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1">접미사</label>
                    <input
                      type="text"
                      value={stat.suffix}
                      onChange={(e) => updateStat(i, 'suffix', e.target.value)}
                      placeholder="+"
                      className="w-full px-3 py-1.5 text-sm border border-gray-200 rounded-md"
                    />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1">숫자</label>
                    <input
                      type="number"
                      value={stat.value}
                      onChange={(e) => updateStat(i, 'value', parseInt(e.target.value) || 0)}
                      className="w-full px-3 py-1.5 text-sm border border-gray-200 rounded-md"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1">라벨</label>
                    <input
                      type="text"
                      value={stat.label}
                      onChange={(e) => updateStat(i, 'label', e.target.value)}
                      className="w-full px-3 py-1.5 text-sm border border-gray-200 rounded-md"
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>

      {/* Sticky save bar */}
      {isDirty && (
        <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 shadow-lg z-50">
          <div className="max-w-4xl mx-auto px-6 py-3 flex items-center justify-between">
            <span className="text-sm text-amber-600 font-medium">
              저장되지 않은 변경사항이 있습니다
            </span>
            <button
              onClick={handleSave}
              disabled={isSaving}
              className="flex items-center gap-2 px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors text-sm font-medium disabled:opacity-50"
            >
              <Save className="w-4 h-4" />
              {isSaving ? '저장 중...' : '변경사항 저장'}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
