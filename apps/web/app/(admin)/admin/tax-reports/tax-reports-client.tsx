'use client'

import { useState } from 'react'
import { FileText, Download, TrendingUp, Calculator, Users } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { formatKRW, formatTaxRate } from '@/lib/utils/format'
import { useToast } from '@/components/ops/ops-toast'
import { businessConfig } from '@/lib/config'

// =====================================================
// Tax Reports Client Component
// - Year filter dropdown
// - CSV export functionality (2 types)
// - Creator tax summaries
// =====================================================

interface CreatorTaxSummary {
  creator_id: string
  creator_name: string
  income_type: string
  tax_rate: number
  total_revenue_krw: number
  platform_fee_krw: number
  taxable_krw: number
  income_tax_krw: number
  local_tax_krw: number
  withholding_total_krw: number
  net_payout_krw: number
  settlement_count: number
}

interface TaxReportsClientProps {
  initialReports: CreatorTaxSummary[]
  isDemoMode: boolean
}

function getIncomeTypeBadge(type: string) {
  switch (type) {
    case 'business_income':
      return <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">사업소득 {formatTaxRate(businessConfig.taxRates.businessIncome)}</Badge>
    case 'other_income':
      return <Badge variant="outline" className="bg-purple-50 text-purple-700 border-purple-200">기타소득 {formatTaxRate(businessConfig.taxRates.otherIncome)}</Badge>
    case 'invoice':
      return <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">세금계산서 {formatTaxRate(businessConfig.taxRates.invoice)}</Badge>
    default:
      return <Badge variant="outline">{type}</Badge>
  }
}

function getIncomeTypeLabel(type: string): string {
  switch (type) {
    case 'business_income': return '사업소득'
    case 'other_income': return '기타소득'
    case 'invoice': return '세금계산서'
    default: return type
  }
}

function downloadCSV(filename: string, content: string) {
  // Add BOM for Excel UTF-8 support
  const BOM = '\uFEFF'
  const blob = new Blob([BOM + content], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(url)
}

export default function TaxReportsClient({
  initialReports,
  isDemoMode,
}: TaxReportsClientProps) {
  const [selectedYear, setSelectedYear] = useState<number>(2026)
  const summaries = initialReports
  const toast = useToast()

  const totalRevenue = summaries.reduce((sum, s) => sum + s.total_revenue_krw, 0)
  const totalFees = summaries.reduce((sum, s) => sum + s.platform_fee_krw, 0)
  const totalWithholding = summaries.reduce((sum, s) => sum + s.withholding_total_krw, 0)
  const totalPayout = summaries.reduce((sum, s) => sum + s.net_payout_krw, 0)

  // Export withholding CSV
  const handleExportWithholding = () => {
    const headers = [
      '크리에이터명',
      '크리에이터ID',
      '소득유형',
      '세율(%)',
      '총수익',
      '플랫폼수수료',
      '과세소득',
      '소득세',
      '지방소득세',
      '원천징수 합계',
      '순지급액',
    ]

    const rows = summaries.map(s => [
      s.creator_name,
      s.creator_id,
      getIncomeTypeLabel(s.income_type),
      s.tax_rate.toString(),
      s.total_revenue_krw.toString(),
      s.platform_fee_krw.toString(),
      s.taxable_krw.toString(),
      s.income_tax_krw.toString(),
      s.local_tax_krw.toString(),
      s.withholding_total_krw.toString(),
      s.net_payout_krw.toString(),
    ])

    const csvContent = [
      headers.join(','),
      ...rows.map(row => row.join(',')),
    ].join('\n')

    downloadCSV(`원천징수_${selectedYear}.csv`, csvContent)
    toast.success('원천징수 CSV 내보내기 완료', `${summaries.length}명의 크리에이터 데이터가 포함되었습니다.`)
  }

  // Export income summary CSV
  const handleExportIncomeSummary = () => {
    const headers = [
      '크리에이터명',
      '크리에이터ID',
      '소득유형',
      '총수익',
      `플랫폼 수수료(${businessConfig.platformCommissionPercent}%)`,
      '과세소득',
      '원천징수합계',
      '순지급액',
      '정산건수',
    ]

    const rows = summaries.map(s => [
      s.creator_name,
      s.creator_id,
      getIncomeTypeLabel(s.income_type),
      s.total_revenue_krw.toString(),
      s.platform_fee_krw.toString(),
      s.taxable_krw.toString(),
      s.withholding_total_krw.toString(),
      s.net_payout_krw.toString(),
      s.settlement_count.toString(),
    ])

    const csvContent = [
      headers.join(','),
      ...rows.map(row => row.join(',')),
    ].join('\n')

    downloadCSV(`소득집계_${selectedYear}.csv`, csvContent)
    toast.success('소득 집계 CSV 내보내기 완료', `${summaries.length}명의 크리에이터 데이터가 포함되었습니다.`)
  }

  return (
    <div className="max-w-6xl mx-auto">
      {/* Demo Banner */}
      {isDemoMode && (
        <div className="mb-4 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 text-sm text-amber-800">
          Demo Mode - Mock tax data is displayed
        </div>
      )}

      {/* Header */}
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">세금 보고서</h1>
          <p className="text-gray-500 mt-1">원천징수 내역 및 크리에이터별 소득 집계</p>
        </div>
        <div className="flex gap-2 items-center">
          {/* Year Filter */}
          <select
            value={selectedYear}
            onChange={(e) => setSelectedYear(Number(e.target.value))}
            className="px-3 py-2 border border-gray-200 rounded-lg text-sm text-gray-900 bg-white hover:bg-gray-50 transition-colors"
          >
            <option value={2025}>2025년</option>
            <option value={2026}>2026년</option>
          </select>

          {/* Export Buttons */}
          <Button
            variant="outline"
            size="sm"
            onClick={handleExportWithholding}
          >
            <Download className="w-4 h-4 mr-1" />
            원천징수 CSV
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={handleExportIncomeSummary}
          >
            <Download className="w-4 h-4 mr-1" />
            소득 집계 CSV
          </Button>
        </div>
      </div>

      {/* Summary Stats */}
      <div className="grid grid-cols-4 gap-4 mb-8">
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
              <TrendingUp className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <div className="text-lg font-bold text-gray-900">{formatKRW(totalRevenue)}</div>
              <div className="text-sm text-gray-500">총 수익</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center">
              <FileText className="w-5 h-5 text-orange-600" />
            </div>
            <div>
              <div className="text-lg font-bold text-gray-900">{formatKRW(totalFees)}</div>
              <div className="text-sm text-gray-500">플랫폼 수수료</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center">
              <Calculator className="w-5 h-5 text-red-600" />
            </div>
            <div>
              <div className="text-lg font-bold text-gray-900">{formatKRW(totalWithholding)}</div>
              <div className="text-sm text-gray-500">원천징수 합계</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
              <Users className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <div className="text-2xl font-bold text-gray-900">{summaries.length}</div>
              <div className="text-sm text-gray-500">크리에이터</div>
            </div>
          </div>
        </div>
      </div>

      {/* Income Type Distribution */}
      <div className="grid grid-cols-3 gap-4 mb-8">
        {['business_income', 'other_income', 'invoice'].map(type => {
          const creators = summaries.filter(s => s.income_type === type)
          const typeTotal = creators.reduce((sum, s) => sum + s.withholding_total_krw, 0)
          const labels: Record<string, string> = {
            business_income: `사업소득 (${formatTaxRate(businessConfig.taxRates.businessIncome)})`,
            other_income: `기타소득 (${formatTaxRate(businessConfig.taxRates.otherIncome)})`,
            invoice: `세금계산서 (${formatTaxRate(businessConfig.taxRates.invoice)})`,
          }
          return (
            <div key={type} className="bg-white rounded-xl p-4 border border-gray-200">
              <div className="text-sm text-gray-500 mb-1">{labels[type]}</div>
              <div className="text-xl font-bold text-gray-900">{creators.length}명</div>
              <div className="text-sm text-gray-500 mt-1">원천징수: {formatKRW(typeTotal)}</div>
            </div>
          )
        })}
      </div>

      {/* Creator Tax Table */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="p-4 border-b border-gray-200">
          <h2 className="font-semibold text-gray-900">크리에이터별 원천징수 내역</h2>
        </div>

        {summaries.length === 0 ? (
          <div className="p-12 text-center">
            <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <FileText className="w-8 h-8 text-gray-400" />
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">데이터 없음</h3>
            <p className="text-gray-500">해당 기간의 정산 데이터가 없습니다</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 text-gray-500 text-left">
                <tr>
                  <th className="px-4 py-3 font-medium">크리에이터</th>
                  <th className="px-4 py-3 font-medium">소득 유형</th>
                  <th className="px-4 py-3 font-medium text-right">총 수익</th>
                  <th className="px-4 py-3 font-medium text-right">플랫폼 수수료</th>
                  <th className="px-4 py-3 font-medium text-right">과세 대상</th>
                  <th className="px-4 py-3 font-medium text-right">소득세</th>
                  <th className="px-4 py-3 font-medium text-right">지방소득세</th>
                  <th className="px-4 py-3 font-medium text-right">원천징수 합계</th>
                  <th className="px-4 py-3 font-medium text-right">순 지급액</th>
                  <th className="px-4 py-3 font-medium text-center">정산 수</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {summaries.map((s) => (
                  <tr key={s.creator_id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3">
                      <div className="font-medium text-gray-900">{s.creator_name}</div>
                    </td>
                    <td className="px-4 py-3">
                      {getIncomeTypeBadge(s.income_type)}
                    </td>
                    <td className="px-4 py-3 text-right font-medium text-gray-900">
                      {formatKRW(s.total_revenue_krw)}
                    </td>
                    <td className="px-4 py-3 text-right text-gray-500">
                      -{formatKRW(s.platform_fee_krw)}
                    </td>
                    <td className="px-4 py-3 text-right text-gray-700">
                      {formatKRW(s.taxable_krw)}
                    </td>
                    <td className="px-4 py-3 text-right text-red-500">
                      -{formatKRW(s.income_tax_krw)}
                    </td>
                    <td className="px-4 py-3 text-right text-red-400">
                      -{formatKRW(s.local_tax_krw)}
                    </td>
                    <td className="px-4 py-3 text-right font-medium text-red-600">
                      -{formatKRW(s.withholding_total_krw)}
                    </td>
                    <td className="px-4 py-3 text-right font-bold text-gray-900">
                      {formatKRW(s.net_payout_krw)}
                    </td>
                    <td className="px-4 py-3 text-center text-gray-600">
                      {s.settlement_count}
                    </td>
                  </tr>
                ))}
              </tbody>
              <tfoot className="bg-gray-50 font-medium text-gray-900">
                <tr>
                  <td className="px-4 py-3">합계</td>
                  <td className="px-4 py-3"></td>
                  <td className="px-4 py-3 text-right">{formatKRW(totalRevenue)}</td>
                  <td className="px-4 py-3 text-right text-gray-500">-{formatKRW(totalFees)}</td>
                  <td className="px-4 py-3 text-right">{formatKRW(totalRevenue - totalFees)}</td>
                  <td className="px-4 py-3 text-right text-red-500">
                    -{formatKRW(summaries.reduce((s, c) => s + c.income_tax_krw, 0))}
                  </td>
                  <td className="px-4 py-3 text-right text-red-400">
                    -{formatKRW(summaries.reduce((s, c) => s + c.local_tax_krw, 0))}
                  </td>
                  <td className="px-4 py-3 text-right text-red-600">-{formatKRW(totalWithholding)}</td>
                  <td className="px-4 py-3 text-right font-bold">{formatKRW(totalPayout)}</td>
                  <td className="px-4 py-3 text-center">
                    {summaries.reduce((s, c) => s + c.settlement_count, 0)}
                  </td>
                </tr>
              </tfoot>
            </table>
          </div>
        )}
      </div>

      {/* Tax Info Card */}
      <div className="mt-8 bg-blue-50 rounded-xl border border-blue-200 p-6">
        <h3 className="font-semibold text-blue-900 mb-3">원천징수 안내</h3>
        <div className="grid grid-cols-3 gap-6 text-sm text-blue-800">
          <div>
            <div className="font-medium mb-1">사업소득 ({formatTaxRate(businessConfig.taxRates.businessIncome)})</div>
            <p className="text-blue-600">소득세 3.0% + 지방소득세 0.3%</p>
            <p className="text-blue-600">개인 크리에이터 기본 적용</p>
          </div>
          <div>
            <div className="font-medium mb-1">기타소득 ({formatTaxRate(businessConfig.taxRates.otherIncome)})</div>
            <p className="text-blue-600">소득세 8.0% + 지방소득세 0.8%</p>
            <p className="text-blue-600">일회성/비정기 소득에 적용</p>
          </div>
          <div>
            <div className="font-medium mb-1">세금계산서 ({formatTaxRate(businessConfig.taxRates.invoice)})</div>
            <p className="text-blue-600">사업자 등록 크리에이터</p>
            <p className="text-blue-600">원천징수 없이 세금계산서 발행</p>
          </div>
        </div>
      </div>
    </div>
  )
}
