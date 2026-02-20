'use client'

import { useEffect, useState, Suspense } from 'react'
import { createBrowserClient } from '@supabase/ssr'
import { OpsDataTable } from '@/components/ops/ops-data-table'
import { AlertCircle } from 'lucide-react'
import { useSearchParams } from 'next/navigation'

export interface OpsMwEvent extends Record<string, unknown> {
    id: string
    event_type: string
    route: string | null
    actor_id: string | null
    correlation_id: string | null
    created_at: string
    meta: any
}

const columns = [
    {
        key: 'event_type',
        label: 'Event Type',
        sortable: true,
        render: (item: OpsMwEvent) => (
            <span className="bg-gray-100 text-gray-800 px-2 py-1 rounded text-xs font-medium">
                {item.event_type}
            </span>
        )
    },
    { key: 'route', label: 'Route', sortable: true },
    { key: 'actor_id', label: 'Actor ID' },
    {
        key: 'created_at',
        label: 'Created At',
        sortable: true,
        render: (item: OpsMwEvent) => new Date(item.created_at).toLocaleString('ko-KR')
    },
    {
        key: 'correlation_id',
        label: 'Correlation',
        render: (item: OpsMwEvent) => item.correlation_id ? (
            <a href={`/admin/ops/incidents?correlation_id=${item.correlation_id}`} className="text-blue-500 hover:underline">
                {item.correlation_id}
            </a>
        ) : '-'
    }
]

function MwEventsData() {
    const [data, setData] = useState<OpsMwEvent[]>([])
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
                    .from('ops_mw_events')
                    .select('*')
                    .order('created_at', { ascending: false })

                if (correlationId) {
                    query = query.eq('correlation_id', correlationId)
                }

                const { data: events, error } = await query

                if (error) throw error
                setData(events as OpsMwEvent[])
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
            emptyMessage="기록된 Middleware Event가 없습니다."
        />
    )
}

export default function MwEventsPage() {
    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <h1 className="text-2xl font-bold text-gray-900">Middleware Events</h1>
            </div>
            <Suspense fallback={<div className="h-64 animate-pulse bg-gray-100 rounded-lg" />}>
                <MwEventsData />
            </Suspense>
        </div>
    )
}
