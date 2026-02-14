'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { AlertTriangle, Eye, Send, Ban, X, Filter } from 'lucide-react'

type ReportType = 'spam' | 'inappropriate_profile' | 'copyright' | 'fraud' | 'harassment'
type ReportStatus = 'pending' | 'reviewing' | 'resolved' | 'dismissed'

interface Report {
  id: string
  reporter_name: string
  reported_user_name: string
  type: ReportType
  description: string
  status: ReportStatus
  created_at: string
  evidence_count: number
}

const mockReports: Report[] = [
  { id: 'rpt-001', reporter_name: '하늘덕후', reported_user_name: '스팸봇123', type: 'spam', description: '반복적인 광고 메시지를 보내고 있습니다. 같은 내용의 메시지를 여러 채널에 동시 발송합니다.', status: 'pending', created_at: '2026-02-10T09:30:00Z', evidence_count: 3 },
  { id: 'rpt-002', reporter_name: '별빛팬', reported_user_name: '악성유저', type: 'harassment', description: '다른 팬들에게 지속적으로 비방성 메시지를 보내고 있습니다. 욕설과 인신공격이 포함되어 있습니다.', status: 'reviewing', created_at: '2026-02-09T14:20:00Z', evidence_count: 5 },
  { id: 'rpt-003', reporter_name: '음악사랑', reported_user_name: '가짜아이돌', type: 'inappropriate_profile', description: '타인의 사진을 도용하여 프로필을 만들었습니다. 실제 아티스트 사칭이 의심됩니다.', status: 'pending', created_at: '2026-02-08T11:45:00Z', evidence_count: 2 },
  { id: 'rpt-004', reporter_name: '팬클럽회장', reported_user_name: '피싱시도자', type: 'fraud', description: '개인정보를 요구하는 메시지를 보내고 있습니다. 가짜 이벤트 당첨을 미끼로 결제 정보를 요청합니다.', status: 'resolved', created_at: '2026-02-07T16:10:00Z', evidence_count: 7 },
  { id: 'rpt-005', reporter_name: '조용한팬', reported_user_name: '무단전재자', type: 'copyright', description: '아티스트의 독점 콘텐츠를 외부 플랫폼에 무단으로 게시하고 있습니다.', status: 'dismissed', created_at: '2026-02-06T08:55:00Z', evidence_count: 1 },
]

const typeLabels: Record<ReportType, string> = {
  spam: '스팸',
  inappropriate_profile: '부적절 프로필',
  copyright: '저작권',
  fraud: '사기',
  harassment: '괴롭힘',
}

const statusLabels: Record<ReportStatus, string> = {
  pending: '대기중',
  reviewing: '검토중',
  resolved: '해결됨',
  dismissed: '기각됨',
}

const statusColors: Record<ReportStatus, string> = {
  pending: 'bg-yellow-100 text-yellow-800',
  reviewing: 'bg-blue-100 text-blue-800',
  resolved: 'bg-green-100 text-green-800',
  dismissed: 'bg-gray-100 text-gray-800',
}

export default function ReportsPage() {
  const [reports, setReports] = useState<Report[]>(mockReports)
  const [statusFilter, setStatusFilter] = useState<ReportStatus | 'all'>('all')
  const [typeFilter, setTypeFilter] = useState<ReportType | 'all'>('all')
  const [toast, setToast] = useState<{ message: string; visible: boolean }>({ message: '', visible: false })

  const showToast = (message: string) => {
    setToast({ message, visible: true })
    setTimeout(() => setToast({ message: '', visible: false }), 3000)
  }

  const filteredReports = reports.filter(report => {
    const matchesStatus = statusFilter === 'all' || report.status === statusFilter
    const matchesType = typeFilter === 'all' || report.type === typeFilter
    return matchesStatus && matchesType
  })

  const stats = {
    pending: reports.filter(r => r.status === 'pending').length,
    reviewing: reports.filter(r => r.status === 'reviewing').length,
    resolved: reports.filter(r => r.status === 'resolved').length,
    dismissed: reports.filter(r => r.status === 'dismissed').length,
  }

  const updateReportStatus = (id: string, newStatus: ReportStatus) => {
    setReports(prev => prev.map(report =>
      report.id === id ? { ...report, status: newStatus } : report
    ))
  }

  const handleStartReview = (report: Report) => {
    if (window.confirm(`"${report.reported_user_name}"에 대한 신고 검토를 시작하시겠습니까?`)) {
      updateReportStatus(report.id, 'reviewing')
      showToast('검토를 시작했습니다')
    }
  }

  const handleSendWarning = (report: Report) => {
    if (window.confirm(`"${report.reported_user_name}"에게 경고를 발송하시겠습니까?`)) {
      showToast(`${report.reported_user_name}에게 경고를 발송했습니다`)
    }
  }

  const handleSuspendAccount = (report: Report) => {
    if (window.confirm(`"${report.reported_user_name}"의 계정을 정지하시겠습니까? 이 작업은 신중하게 결정해야 합니다.`)) {
      updateReportStatus(report.id, 'resolved')
      showToast(`${report.reported_user_name}의 계정을 정지했습니다`)
    }
  }

  const handleDismiss = (report: Report) => {
    if (window.confirm(`이 신고를 기각하시겠습니까?`)) {
      updateReportStatus(report.id, 'dismissed')
      showToast('신고를 기각했습니다')
    }
  }

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return new Intl.DateTimeFormat('ko-KR', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    }).format(date)
  }

  const truncate = (text: string, maxLength: number) => {
    if (text.length <= maxLength) return text
    return text.slice(0, maxLength) + '...'
  }

  return (
    <div className="max-w-7xl mx-auto">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">신고 관리</h1>
        <p className="text-gray-500 mt-1">사용자 신고 내역을 관리합니다</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div className="text-sm text-yellow-600 font-medium">대기중</div>
          <div className="text-2xl font-bold text-yellow-900 mt-1">{stats.pending}</div>
        </div>
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <div className="text-sm text-blue-600 font-medium">검토중</div>
          <div className="text-2xl font-bold text-blue-900 mt-1">{stats.reviewing}</div>
        </div>
        <div className="bg-green-50 border border-green-200 rounded-lg p-4">
          <div className="text-sm text-green-600 font-medium">해결됨</div>
          <div className="text-2xl font-bold text-green-900 mt-1">{stats.resolved}</div>
        </div>
        <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
          <div className="text-sm text-gray-600 font-medium">기각됨</div>
          <div className="text-2xl font-bold text-gray-900 mt-1">{stats.dismissed}</div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white border border-gray-200 rounded-lg p-4 mb-6">
        <div className="flex items-center gap-3 mb-3">
          <Filter className="w-4 h-4 text-gray-500" />
          <span className="text-sm font-medium text-gray-700">필터</span>
        </div>
        <div className="flex flex-wrap gap-3">
          <div className="flex items-center gap-2">
            <label className="text-sm text-gray-600">상태:</label>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as ReportStatus | 'all')}
              className="text-sm border border-gray-300 rounded-md px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">전체</option>
              <option value="pending">대기중</option>
              <option value="reviewing">검토중</option>
              <option value="resolved">해결됨</option>
              <option value="dismissed">기각됨</option>
            </select>
          </div>
          <div className="flex items-center gap-2">
            <label className="text-sm text-gray-600">유형:</label>
            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value as ReportType | 'all')}
              className="text-sm border border-gray-300 rounded-md px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">전체</option>
              <option value="spam">스팸</option>
              <option value="inappropriate_profile">부적절 프로필</option>
              <option value="copyright">저작권</option>
              <option value="fraud">사기</option>
              <option value="harassment">괴롭힘</option>
            </select>
          </div>
        </div>
      </div>

      {/* Reports Table */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">신고자</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">대상</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">유형</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">설명</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">상태</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">날짜</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">증거</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">액션</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {filteredReports.length === 0 ? (
                <tr>
                  <td colSpan={8} className="px-4 py-12 text-center text-gray-500">
                    필터 조건에 맞는 신고가 없습니다
                  </td>
                </tr>
              ) : (
                filteredReports.map(report => (
                  <tr key={report.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-sm text-gray-900">{report.reporter_name}</td>
                    <td className="px-4 py-3 text-sm font-medium text-gray-900">{report.reported_user_name}</td>
                    <td className="px-4 py-3">
                      <Badge variant="outline" className="text-xs">
                        {typeLabels[report.type]}
                      </Badge>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-600 max-w-xs">
                      {truncate(report.description, 50)}
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${statusColors[report.status]}`}>
                        {statusLabels[report.status]}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-500 whitespace-nowrap">
                      {formatDate(report.created_at)}
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-900">
                      <div className="flex items-center gap-1">
                        <AlertTriangle className="w-4 h-4 text-orange-500" />
                        <span>{report.evidence_count}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1">
                        {report.status === 'pending' && (
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => handleStartReview(report)}
                            className="h-8 px-2"
                            title="검토 시작"
                          >
                            <Eye className="w-4 h-4" />
                          </Button>
                        )}
                        {(report.status === 'pending' || report.status === 'reviewing') && (
                          <>
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => handleSendWarning(report)}
                              className="h-8 px-2"
                              title="경고 발송"
                            >
                              <Send className="w-4 h-4" />
                            </Button>
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => handleSuspendAccount(report)}
                              className="h-8 px-2 text-red-600 hover:text-red-700"
                              title="계정 정지"
                            >
                              <Ban className="w-4 h-4" />
                            </Button>
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => handleDismiss(report)}
                              className="h-8 px-2"
                              title="기각"
                            >
                              <X className="w-4 h-4" />
                            </Button>
                          </>
                        )}
                        {(report.status === 'resolved' || report.status === 'dismissed') && (
                          <span className="text-xs text-gray-400">완료됨</span>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Toast Notification */}
      {toast.visible && (
        <div className="fixed bottom-4 right-4 bg-gray-900 text-white px-4 py-3 rounded-lg shadow-lg animate-in fade-in slide-in-from-bottom-2">
          {toast.message}
        </div>
      )}
    </div>
  )
}
