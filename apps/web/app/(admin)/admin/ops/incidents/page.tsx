'use client'

import { useEffect, useState } from 'react'
import { createBrowserClient } from '@supabase/ssr'
import { OpsDataTable } from '@/components/ops/ops-data-table'
import { AlertCircle } from 'lucide-react'

export interface OpsIncident extends Record<string, unknown> {
    id: string
    severity: string
    component: string
    started_at: string
    ended_at: string | null
    summary: string
    root_cause: string | null
    fix_action: string | null
    owner_staff_id: string | null
    correlation_id: string | null
}

const columns = [
    { key: 'severity', label: 'Severity', sortable: true },
    { key: 'component', label: 'Component', sortable: true },
    {
        key: 'status',
        label: 'Status',
        render: (item: OpsIncident) => item.ended_at ? 'Closed' : 'Open'
    },
    { key: 'summary', label: 'Summary' },
    {
        key: 'started_at',
        label: 'Started At',
        sortable: true,
        render: (item: OpsIncident) => new Date(item.started_at).toLocaleString('ko-KR')
    },
    {
        key: 'ended_at',
        label: 'Ended At',
        render: (item: OpsIncident) => item.ended_at ? new Date(item.ended_at).toLocaleString('ko-KR') : '-'
    },
    {
        key: 'correlation_id',
        label: 'Correlation',
        render: (item: OpsIncident) => item.correlation_id ? (
            <a href={`/admin/ops/jobs?correlation_id=${item.correlation_id}`} className="text-blue-500 hover:underline">
                {item.correlation_id}
            </a>
        ) : '-'
    }
]

export default function IncidentsPage() {
    const [data, setData] = useState<OpsIncident[]>([])
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)

    useEffect(() => {
        async function loadData() {
            try {
                const supabase = createBrowserClient(
                    process.env.NEXT_PUBLIC_SUPABASE_URL!,
                    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
                )
                const { data: incidents, error } = await supabase
                    .from('ops_incidents')
                    .select('*')
                    .order('started_at', { ascending: false })

                if (error) throw error
                setData(incidents as OpsIncident[])
            } catch (err: any) {
                setError(err.message || '데이터를 불러오는 중 오류가 발생했습니다.')
            } finally {
                setLoading(false)
            }
        }
        loadData()
    }, [])

    if (error) {
        return (
            <div className="flex flex-col items-center justify-center p-12 text-red-500">
                <AlertCircle className="w-8 h-8 mb-2" />
                <p>{error}</p>
            </div>
        )
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <h1 className="text-2xl font-bold text-gray-900">Incidents</h1>
            </div>
            <OpsDataTable
                data={data}
                columns={columns}
                loading={loading}
                keyField="id"
                emptyMessage="기록된 인시던트가 없습니다."
            />
        </div>
    )
}
