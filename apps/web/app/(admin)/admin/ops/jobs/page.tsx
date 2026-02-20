'use client'

import { useEffect, useState, Suspense } from 'react'
import { createBrowserClient } from '@supabase/ssr'
import { OpsDataTable } from '@/components/ops/ops-data-table'
import { AlertCircle } from 'lucide-react'
import { useSearchParams } from 'next/navigation'

export interface OpsJob extends Record<string, unknown> {
    id: string
    job_type: string
    status: string
    trigger: string
    attempt: number
    max_attempts: number
    started_at: string
    ended_at: string | null
    duration_ms: number | null
    correlation_id: string | null
    error_code: string | null
    error_message: string | null
}

const columns = [
    { key: 'job_type', label: 'Job Type', sortable: true },
    {
        key: 'status',
        label: 'Status',
        sortable: true,
        render: (item: OpsJob) => (
            <span className={item.status === 'failed' ? 'text-red-500 font-bold' : item.status === 'succeeded' ? 'text-green-500' : 'text-yellow-500'}>
                {item.status.toUpperCase()}
            </span>
        )
    },
    { key: 'trigger', label: 'Trigger' },
    {
        key: 'started_at',
        label: 'Started At',
        sortable: true,
        render: (item: OpsJob) => new Date(item.started_at).toLocaleString('ko-KR')
    },
    { key: 'duration_ms', label: 'Duration (ms)', sortable: true },
    { key: 'error_message', label: 'Error' },
    {
        key: 'correlation_id',
        label: 'Correlation',
        render: (item: OpsJob) => item.correlation_id ? (
            <a href={`/admin/ops/mw-events?correlation_id=${item.correlation_id}`} className="text-blue-500 hover:underline">
                {item.correlation_id}
            </a>
        ) : '-'
    }
]

function JobsData() {
    const [data, setData] = useState<OpsJob[]>([])
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)

    const searchParams = useSearchParams()
    const correlationId = searchParams.get('correlation_id')

    useEffect(() => {
        async function loadData() {
            try {
                const supabase = createBrowserClient(
                    process.env.NEXT_PUBLIC_SUPABASE_URL!,
                    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
                )

                let query = supabase
                    .from('ops_jobs')
                    .select('*')
                    .order('started_at', { ascending: false })

                if (correlationId) {
                    query = query.eq('correlation_id', correlationId)
                }

                const { data: jobs, error } = await query

                if (error) throw error
                setData(jobs as OpsJob[])
            } catch (err: any) {
                setError(err.message || '데이터를 불러오는 중 오류가 발생했습니다.')
            } finally {
                setLoading(false)
            }
        }
        loadData()
    }, [correlationId])

    if (error) {
        return (
            <div className="flex flex-col items-center justify-center p-12 text-red-500">
                <AlertCircle className="w-8 h-8 mb-2" />
                <p>{error}</p>
            </div>
        )
    }

    return (
        <OpsDataTable
            data={data}
            columns={columns}
            loading={loading}
            keyField="id"
            emptyMessage="기록된 Job이 없습니다."
        />
    )
}

export default function JobsPage() {
    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <h1 className="text-2xl font-bold text-gray-900">Jobs</h1>
            </div>
            <Suspense fallback={<div className="h-64 animate-pulse bg-gray-100 rounded-lg" />}>
                <JobsData />
            </Suspense>
        </div>
    )
}
