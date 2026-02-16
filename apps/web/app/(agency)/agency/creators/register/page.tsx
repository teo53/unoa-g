'use client'

import { useState } from 'react'
import Link from 'next/link'
import { ArrowLeft, Search, Check, Upload, Info } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { mockCreators, DEMO_MODE } from '@/lib/mock/demo-data'

interface SearchResult {
  id: string
  stage_name: string
  avatar_url: string | null
  subscriber_count: number
  categories: string[]
  has_agency: boolean
}

type RegistrationStep = 'search' | 'terms' | 'confirm'

export default function CreatorRegisterPage() {
  const [step, setStep] = useState<RegistrationStep>('search')
  const [searchQuery, setSearchQuery] = useState('')
  const [searchResults, setSearchResults] = useState<SearchResult[]>([])
  const [selectedCreator, setSelectedCreator] = useState<SearchResult | null>(null)
  const [isSearching, setIsSearching] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [submitted, setSubmitted] = useState(false)

  // Contract terms
  const [contractStart, setContractStart] = useState('')
  const [contractEnd, setContractEnd] = useState('')
  const [isIndefinite, setIsIndefinite] = useState(false)
  const [revenueShareRate, setRevenueShareRate] = useState('10')
  const [settlementPeriod, setSettlementPeriod] = useState('monthly')
  const [notes, setNotes] = useState('')

  async function handleSearch() {
    if (!searchQuery.trim()) return
    setIsSearching(true)

    // Demo mode: search mock creators
    if (DEMO_MODE) {
      await new Promise(r => setTimeout(r, 500))
      const results: SearchResult[] = Object.values(mockCreators)
        .filter(c => c.display_name?.toLowerCase().includes(searchQuery.toLowerCase()))
        .map(c => ({
          id: c.id,
          stage_name: c.display_name || '',
          avatar_url: c.avatar_url || null,
          subscriber_count: Math.floor(Math.random() * 2000) + 100,
          categories: ['K-POP'],
          has_agency: false,
        }))
      setSearchResults(results)
    }
    // TODO: Real search via agency-manage Edge Function
    setIsSearching(false)
  }

  async function handleSubmit() {
    if (!selectedCreator) return
    setIsSubmitting(true)
    await new Promise(r => setTimeout(r, 1000))
    // TODO: Call agency-manage Edge Function with action: creator.add
    setIsSubmitting(false)
    setSubmitted(true)
  }

  if (submitted) {
    return (
      <div className="max-w-2xl mx-auto">
        <div className="bg-white rounded-xl border border-gray-200 p-8 text-center">
          <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6">
            <Check className="w-8 h-8 text-green-600" />
          </div>
          <h2 className="text-xl font-bold text-gray-900 mb-3">등록 신청 완료</h2>
          <p className="text-gray-500 mb-6">
            <strong>{selectedCreator?.stage_name}</strong> 크리에이터에게 소속 계약 초대가 발송되었습니다.<br />
            크리에이터가 수락하면 계약이 활성화됩니다.
          </p>
          <div className="flex items-center justify-center gap-3">
            <Link href="/agency/creators">
              <Button variant="secondary">크리에이터 목록</Button>
            </Link>
            <Link href="/agency">
              <Button>대시보드</Button>
            </Link>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="max-w-3xl mx-auto">
      {DEMO_MODE && (
        <div className="mb-4 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 text-sm text-amber-800">
          데모 모드 — 실제 등록은 발생하지 않습니다
        </div>
      )}

      {/* Back + Header */}
      <div className="mb-6">
        <Link href="/agency/creators" className="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-900 mb-3">
          <ArrowLeft className="w-4 h-4" />
          소속 크리에이터
        </Link>
        <h1 className="text-2xl font-bold text-gray-900">크리에이터 등록</h1>
        <p className="text-gray-500 mt-1">크리에이터를 검색하고 계약 조건을 설정합니다</p>
      </div>

      {/* Step Indicator */}
      <div className="flex items-center gap-2 mb-8">
        {['검색', '계약 조건', '확인'].map((label, i) => {
          const stepNames: RegistrationStep[] = ['search', 'terms', 'confirm']
          const isActive = step === stepNames[i]
          const isComplete = stepNames.indexOf(step) > i
          return (
            <div key={label} className="flex items-center gap-2">
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                isActive ? 'bg-indigo-600 text-white' :
                isComplete ? 'bg-indigo-100 text-indigo-700' :
                'bg-gray-100 text-gray-400'
              }`}>
                {isComplete ? <Check className="w-4 h-4" /> : i + 1}
              </div>
              <span className={`text-sm ${isActive ? 'text-gray-900 font-medium' : 'text-gray-400'}`}>
                {label}
              </span>
              {i < 2 && <div className="w-8 h-px bg-gray-200" />}
            </div>
          )
        })}
      </div>

      {/* Step 1: Search */}
      {step === 'search' && (
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">1단계: 크리에이터 검색</h2>

          <div className="flex items-center gap-3 mb-6">
            <div className="flex-1 relative">
              <Search className="w-4 h-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
                placeholder="아이디 또는 활동명 입력..."
                className="w-full pl-10 pr-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>
            <Button onClick={handleSearch} loading={isSearching}>
              검색
            </Button>
          </div>

          {/* Results */}
          {searchResults.length > 0 && (
            <div className="space-y-2">
              <p className="text-sm text-gray-500 mb-3">{searchResults.length}개 결과</p>
              {searchResults.map((creator) => (
                <div
                  key={creator.id}
                  className={`flex items-center gap-3 p-4 rounded-lg border transition-colors cursor-pointer ${
                    selectedCreator?.id === creator.id
                      ? 'border-indigo-500 bg-indigo-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                  onClick={() => setSelectedCreator(creator)}
                >
                  <div className="w-12 h-12 bg-gray-100 rounded-full overflow-hidden flex-shrink-0">
                    {creator.avatar_url ? (
                      <img src={creator.avatar_url} alt={creator.stage_name} className="w-full h-full object-cover" />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-gray-400 text-lg font-bold">
                        {creator.stage_name.charAt(0)}
                      </div>
                    )}
                  </div>
                  <div className="flex-1">
                    <div className="font-medium text-gray-900">{creator.stage_name}</div>
                    <div className="text-sm text-gray-500">
                      구독자 {creator.subscriber_count.toLocaleString()}명 · {creator.categories.join(', ')}
                    </div>
                  </div>
                  {creator.has_agency ? (
                    <span className="text-xs text-red-500 font-medium">이미 소속사 있음</span>
                  ) : (
                    <span className="text-xs text-green-600 font-medium">소속사 없음</span>
                  )}
                  {selectedCreator?.id === creator.id && (
                    <div className="w-6 h-6 bg-indigo-600 rounded-full flex items-center justify-center flex-shrink-0">
                      <Check className="w-4 h-4 text-white" />
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}

          {searchResults.length === 0 && searchQuery && !isSearching && (
            <div className="text-center py-8 text-gray-500 text-sm">
              검색 결과가 없습니다. 다른 키워드를 시도해보세요.
            </div>
          )}

          <div className="mt-6 flex justify-end">
            <Button
              onClick={() => setStep('terms')}
              disabled={!selectedCreator || selectedCreator.has_agency}
            >
              다음 단계
            </Button>
          </div>
        </div>
      )}

      {/* Step 2: Contract Terms */}
      {step === 'terms' && (
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-1">2단계: 계약 조건</h2>
          <p className="text-sm text-gray-500 mb-6">
            <strong>{selectedCreator?.stage_name}</strong>에 대한 계약 조건을 설정합니다
          </p>

          <div className="space-y-4">
            {/* Contract Period */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">계약 시작일</label>
                <input
                  type="date"
                  value={contractStart}
                  onChange={(e) => setContractStart(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">계약 종료일</label>
                <input
                  type="date"
                  value={contractEnd}
                  onChange={(e) => setContractEnd(e.target.value)}
                  disabled={isIndefinite}
                  className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 disabled:bg-gray-100 disabled:text-gray-400"
                />
                <label className="flex items-center gap-2 mt-2">
                  <input
                    type="checkbox"
                    checked={isIndefinite}
                    onChange={(e) => { setIsIndefinite(e.target.checked); if (e.target.checked) setContractEnd('') }}
                    className="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                  />
                  <span className="text-sm text-gray-600">무기한 계약</span>
                </label>
              </div>
            </div>

            {/* Revenue Share */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">정산율 (소속사 몫)</label>
              <div className="flex items-center gap-2">
                <input
                  type="number"
                  min="1"
                  max="50"
                  value={revenueShareRate}
                  onChange={(e) => setRevenueShareRate(e.target.value)}
                  className="w-24 px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
                <span className="text-sm text-gray-600">%</span>
                <span className="text-xs text-gray-400 ml-2">
                  (크리에이터 {100 - Number(revenueShareRate)}% / 소속사 {revenueShareRate}%)
                </span>
              </div>
            </div>

            {/* Settlement Period */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">정산 기준</label>
              <select
                value={settlementPeriod}
                onChange={(e) => setSettlementPeriod(e.target.value)}
                className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="weekly">주간</option>
                <option value="biweekly">격주</option>
                <option value="monthly">월간</option>
              </select>
            </div>

            {/* Document Upload */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">계약서 PDF</label>
                <div className="flex items-center gap-2 p-3 border border-dashed border-gray-300 rounded-lg cursor-pointer hover:border-indigo-400 transition-colors">
                  <Upload className="w-5 h-5 text-gray-400" />
                  <span className="text-sm text-gray-500">파일 업로드</span>
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  위임장 PDF <span className="text-gray-400">(선택)</span>
                </label>
                <div className="flex items-center gap-2 p-3 border border-dashed border-gray-300 rounded-lg cursor-pointer hover:border-indigo-400 transition-colors">
                  <Upload className="w-5 h-5 text-gray-400" />
                  <span className="text-sm text-gray-500">파일 업로드</span>
                </div>
                <div className="flex items-start gap-1.5 mt-2">
                  <Info className="w-3.5 h-3.5 text-indigo-500 mt-0.5 flex-shrink-0" />
                  <span className="text-xs text-indigo-600">
                    위임장이 있으면 정산금이 소속사로 일괄 지급됩니다
                  </span>
                </div>
              </div>
            </div>

            {/* Notes */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">메모</label>
              <textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                rows={3}
                placeholder="추가 메모 (선택사항)"
                className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
          </div>

          <div className="mt-6 flex items-center justify-between">
            <Button variant="ghost" onClick={() => setStep('search')}>
              이전 단계
            </Button>
            <Button onClick={() => setStep('confirm')} disabled={!contractStart}>
              다음 단계
            </Button>
          </div>
        </div>
      )}

      {/* Step 3: Confirm */}
      {step === 'confirm' && (
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-6">3단계: 등록 확인</h2>

          <div className="bg-gray-50 rounded-lg p-4 space-y-3 mb-6">
            <div className="flex items-center gap-3 pb-3 border-b border-gray-200">
              <div className="w-12 h-12 bg-gray-100 rounded-full overflow-hidden">
                {selectedCreator?.avatar_url ? (
                  <img src={selectedCreator.avatar_url} alt="" className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-gray-400 text-lg font-bold">
                    {selectedCreator?.stage_name.charAt(0)}
                  </div>
                )}
              </div>
              <div>
                <div className="font-medium text-gray-900">{selectedCreator?.stage_name}</div>
                <div className="text-sm text-gray-500">
                  구독자 {selectedCreator?.subscriber_count.toLocaleString()}명
                </div>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-y-2 text-sm">
              <div className="text-gray-500">계약기간</div>
              <div className="text-gray-900">
                {contractStart} ~ {isIndefinite ? '무기한' : contractEnd || '-'}
              </div>
              <div className="text-gray-500">정산율 (소속사)</div>
              <div className="text-gray-900">{revenueShareRate}%</div>
              <div className="text-gray-500">정산 기준</div>
              <div className="text-gray-900">
                {settlementPeriod === 'weekly' ? '주간' : settlementPeriod === 'biweekly' ? '격주' : '월간'}
              </div>
              {notes && (
                <>
                  <div className="text-gray-500">메모</div>
                  <div className="text-gray-900">{notes}</div>
                </>
              )}
            </div>
          </div>

          <div className="bg-indigo-50 rounded-lg p-4 mb-6">
            <p className="text-sm text-indigo-700">
              등록을 완료하면 <strong>{selectedCreator?.stage_name}</strong> 크리에이터에게 소속 계약 초대 알림이 발송됩니다.
              크리에이터가 수락하면 계약이 활성화되며, 거절하면 자동으로 해지됩니다.
            </p>
          </div>

          <div className="flex items-center justify-between">
            <Button variant="ghost" onClick={() => setStep('terms')}>
              이전 단계
            </Button>
            <Button onClick={handleSubmit} loading={isSubmitting}>
              등록 신청
            </Button>
          </div>
        </div>
      )}
    </div>
  )
}
