'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { Image, ToggleLeft, Clock, AlertCircle, ArrowRight } from 'lucide-react'
import { getDashboardStats } from '@/lib/ops/ops-client'
import type { OpsDashboardStats, OpsAuditEntry } from '@/lib/ops/ops-types'

const ACTION_LABELS: Record<string, string> = {
  'banner.create': '배너 생성',
  'banner.update': '배너 수정',
  'banner.submit_review': '검수 요청',
  'banner.publish': '배너 게시',
  'banner.rollback': '배너 롤백',
  'banner.archive': '배너 보관',
  'flag.create': '플래그 생성',
  'flag.update': '플래그 수정',
  'flag.publish': '플래그 게시',
  'flag.rollback': '플래그 롤백',
  'asset.upload': '에셋 업로드',
  'staff.create': '스태프 추가',
}

function StatCard({
  label,
  value,
  icon: Icon,
  href,
  color,
}: {
  label: string
  value: number
  icon: React.ComponentType<{ className?: string }>
  href: string
  color: string
}) {
  return (
    <Link
      href={href}
      className="bg-white border border-gray-200 rounded-xl p-6 hover:shadow-md transition-shadow"
    >
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-500">{label}</p>
          <p className="text-3xl font-bold mt-1">{value}</p>
        </div>
        <div className={`w-12 h-12 rounded-lg flex items-center justify-center ${color}`}>
          <Icon className="w-6 h-6 text-white" />
        </div>
      </div>
    </Link>
  )
}

function AuditRow({ entry }: { entry: OpsAuditEntry }) {
  return (
    <div className="flex items-center gap-3 py-3 border-b border-gray-100 last:border-0">
      <div className="w-2 h-2 rounded-full bg-blue-500 shrink-0" />
      <div className="flex-1 min-w-0">
        <p className="text-sm text-gray-900 truncate">
          {ACTION_LABELS[entry.action] || entry.action}
        </p>
        <p className="text-xs text-gray-500">
          {entry.actor_role} &middot;{' '}
          {new Date(entry.created_at).toLocaleString('ko-KR')}
        </p>
      </div>
    </div>
  )
}

export default function OpsPage() {
  const [stats, setStats] = useState<OpsDashboardStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function load() {
      try {
        const data = await getDashboardStats()
        setStats(data)
      } catch (err) {
        setError(err instanceof Error ? err.message : '데이터를 불러올 수 없습니다')
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [])

  if (loading) {
    return (
      <div className="space-y-6">
        <h1 className="text-2xl font-bold text-gray-900">Ops 대시보드</h1>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-28 bg-gray-100 rounded-xl animate-pulse" />
          ))}
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex flex-col items-center gap-4 py-12">
        <AlertCircle className="w-12 h-12 text-red-400" />
        <p className="text-gray-600">{error}</p>
        <button
          className="text-sm text-blue-600 underline"
          onClick={() => window.location.reload()}
        >
          다시 시도
        </button>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Ops 대시보드</h1>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <StatCard
          label="활성 배너"
          value={stats?.activeBanners ?? 0}
          icon={Image}
          href="/admin/ops/banners?status=published"
          color="bg-blue-500"
        />
        <StatCard
          label="활성 플래그"
          value={stats?.activeFlags ?? 0}
          icon={ToggleLeft}
          href="/admin/ops/flags?status=published"
          color="bg-green-500"
        />
        <StatCard
          label="검수 대기"
          value={stats?.pendingReview ?? 0}
          icon={Clock}
          href="/admin/ops/banners?status=in_review"
          color="bg-yellow-500"
        />
      </div>

      {/* Recent Activity */}
      <div className="bg-white border border-gray-200 rounded-xl">
        <div className="flex items-center justify-between p-4 border-b border-gray-200">
          <h2 className="font-semibold text-gray-900">최근 변경</h2>
          <Link
            href="/admin/ops/audit"
            className="text-sm text-blue-600 hover:text-blue-700 flex items-center gap-1"
          >
            전체 보기 <ArrowRight className="w-3 h-3" />
          </Link>
        </div>
        <div className="p-4">
          {stats?.recentChanges && stats.recentChanges.length > 0 ? (
            stats.recentChanges.map((entry) => (
              <AuditRow key={entry.id} entry={entry} />
            ))
          ) : (
            <p className="text-sm text-gray-500 text-center py-4">
              아직 변경 이력이 없습니다.
            </p>
          )}
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Link
          href="/admin/ops/banners/new"
          className="flex items-center gap-3 p-4 bg-white border border-gray-200 rounded-xl hover:shadow-md transition-shadow"
        >
          <div className="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
            <Image className="w-5 h-5 text-blue-600" />
          </div>
          <div>
            <p className="font-medium text-gray-900">새 배너 만들기</p>
            <p className="text-sm text-gray-500">광고 이미지 등록 및 배치</p>
          </div>
          <ArrowRight className="w-4 h-4 text-gray-400 ml-auto" />
        </Link>
        <Link
          href="/admin/ops/flags"
          className="flex items-center gap-3 p-4 bg-white border border-gray-200 rounded-xl hover:shadow-md transition-shadow"
        >
          <div className="w-10 h-10 rounded-lg bg-green-50 flex items-center justify-center">
            <ToggleLeft className="w-5 h-5 text-green-600" />
          </div>
          <div>
            <p className="font-medium text-gray-900">기능 플래그 관리</p>
            <p className="text-sm text-gray-500">A/B 테스트 및 기능 활성화</p>
          </div>
          <ArrowRight className="w-4 h-4 text-gray-400 ml-auto" />
        </Link>
      </div>
    </div>
  )
}
