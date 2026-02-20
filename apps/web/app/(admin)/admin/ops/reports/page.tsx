'use client'

import { useEffect, useState } from 'react'
import { createBrowserClient } from '@supabase/ssr'
import { AlertCircle, TrendingUp, Activity, ShieldAlert, CheckCircle2, XCircle } from 'lucide-react'
import {
    BarChart,
    Bar,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    ResponsiveContainer,
    LineChart,
    Line,
    Legend
} from 'recharts'

interface DailySummary {
    open_incidents: any[]
    jobs_failures: any[]
    mw_events_top: any[]
}

interface WeeklyTrend {
    incidents_trend: any[]
    jobs_failures_trend: any[]
    mw_rate_limited_trend: any[]
}

export default function ReportsPage() {
    const [daily, setDaily] = useState<DailySummary | null>(null)
    const [weekly, setWeekly] = useState<WeeklyTrend | null>(null)
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)

    useEffect(() => {
        async function loadData() {
            try {
                const supabase = createBrowserClient(
                    process.env.NEXT_PUBLIC_SUPABASE_URL!,
                    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
                )

                const [dailyRes, weeklyRes] = await Promise.all([
                    supabase.rpc('ops_get_daily_summary'),
                    supabase.rpc('ops_get_weekly_trend')
                ])

                if (dailyRes.error) throw dailyRes.error
                if (weeklyRes.error) throw weeklyRes.error

                setDaily(dailyRes.data as DailySummary)
                setWeekly(weeklyRes.data as WeeklyTrend)
            } catch (err: any) {
                setError(err.message || '리포트 데이터를 불러오는 중 오류가 발생했습니다.')
            } finally {
                setLoading(false)
            }
        }
        loadData()
    }, [])

    if (loading) {
        return (
            <div className="space-y-6">
                <h1 className="text-2xl font-bold text-gray-900">Ops Reports</h1>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    {[1, 2, 3].map((i) => (
                        <div key={i} className="h-40 bg-gray-100 rounded-xl animate-pulse" />
                    ))}
                </div>
            </div>
        )
    }

    if (error) {
        return (
            <div className="flex flex-col items-center justify-center p-12 text-red-500">
                <AlertCircle className="w-8 h-8 mb-2" />
                <p>{error}</p>
            </div>
        )
    }

    return (
        <div className="space-y-8">
            <div className="flex items-center justify-between">
                <h1 className="text-2xl font-bold text-gray-900">Ops Reports Overview</h1>
                <button
                    onClick={() => alert('테스트 알림이 전송되었습니다. (실제 연동은 API 라우트 구현 필요)')}
                    className="bg-gray-100 hover:bg-gray-200 text-gray-800 px-4 py-2 rounded-lg text-sm font-medium transition-colors"
                >
                    Test Alerts 연동
                </button>
            </div>

            {/* Daily Summary (24h) */}
            <section className="space-y-4">
                <h2 className="text-xl font-bold text-gray-800 border-b pb-2">Daily Summary (Last 24h)</h2>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">

                    {/* Open Incidents */}
                    <div className="bg-white border rounded-xl p-4 shadow-sm">
                        <h3 className="font-semibold text-gray-700 mb-4 flex items-center gap-2">
                            <ShieldAlert className="w-5 h-5 text-red-500" />
                            Open Incidents
                        </h3>
                        {daily?.open_incidents && daily.open_incidents.length > 0 ? (
                            <ul className="space-y-3">
                                {daily.open_incidents.map((inc, i) => (
                                    <li key={i} className="flex justify-between items-center text-sm">
                                        <span className="font-medium">{inc.component}</span>
                                        <div className="flex items-center gap-2">
                                            <span className={`px-2 py-0.5 rounded text-xs font-bold ${inc.severity === 'P0' ? 'bg-red-100 text-red-700' :
                                                inc.severity === 'P1' ? 'bg-orange-100 text-orange-700' :
                                                    'bg-yellow-100 text-yellow-700'
                                                }`}>
                                                {inc.severity}
                                            </span>
                                            <span className="bg-gray-100 px-2 py-0.5 rounded">{inc.open_cnt} open</span>
                                        </div>
                                    </li>
                                ))}
                            </ul>
                        ) : (
                            <div className="text-center text-gray-400 py-6 flex flex-col items-center">
                                <CheckCircle2 className="w-8 h-8 text-green-400 mb-2" />
                                <p>No open incidents</p>
                            </div>
                        )}
                    </div>

                    {/* Jobs Failures */}
                    <div className="bg-white border rounded-xl p-4 shadow-sm">
                        <h3 className="font-semibold text-gray-700 mb-4 flex items-center gap-2">
                            <Activity className="w-5 h-5 text-orange-500" />
                            Jobs Failures & p95
                        </h3>
                        {daily?.jobs_failures && daily.jobs_failures.length > 0 ? (
                            <ul className="space-y-3">
                                {daily.jobs_failures.slice(0, 5).map((job, i) => (
                                    <li key={i} className="flex justify-between items-center text-sm">
                                        <span className="font-medium truncate max-w-[120px]" title={job.job_type}>{job.job_type}</span>
                                        <div className="text-right">
                                            <div className="text-red-600 font-bold">{job.failed} fails</div>
                                            <div className="text-xs text-gray-500">p95: {Math.round(job.p95_ms)}ms</div>
                                        </div>
                                    </li>
                                ))}
                            </ul>
                        ) : (
                            <p className="text-center text-gray-500 py-4">No job data</p>
                        )}
                    </div>

                    {/* Middleware Events */}
                    <div className="bg-white border rounded-xl p-4 shadow-sm">
                        <h3 className="font-semibold text-gray-700 mb-4 flex items-center gap-2">
                            <TrendingUp className="w-5 h-5 text-blue-500" />
                            Top Middleware Events
                        </h3>
                        {daily?.mw_events_top && daily.mw_events_top.length > 0 ? (
                            <ul className="space-y-3">
                                {daily.mw_events_top.slice(0, 5).map((event, i) => (
                                    <li key={i} className="flex justify-between items-center text-sm">
                                        <span className="font-medium bg-gray-100 px-2 py-0.5 rounded">{event.event_type}</span>
                                        <span className="font-bold text-gray-700">{event.cnt}</span>
                                    </li>
                                ))}
                            </ul>
                        ) : (
                            <p className="text-center text-gray-500 py-4">No event data</p>
                        )}
                    </div>

                </div>
            </section>

            {/* Weekly Trends (7d) */}
            <section className="space-y-4">
                <h2 className="text-xl font-bold text-gray-800 border-b pb-2">Weekly Trends (Last 7d)</h2>
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

                    {/* Wait, adding recharts charts */}
                    <div className="bg-white border rounded-xl p-4 shadow-sm">
                        <h3 className="font-semibold text-gray-700 mb-4 text-center">Incidents & MTTR Trend</h3>
                        <div className="h-64">
                            {weekly?.incidents_trend && weekly.incidents_trend.length > 0 ? (
                                <ResponsiveContainer width="100%" height="100%">
                                    <LineChart data={weekly.incidents_trend} margin={{ top: 5, right: 5, left: -20, bottom: 5 }}>
                                        <CartesianGrid strokeDasharray="3 3" vertical={false} />
                                        <XAxis dataKey="day" tickFormatter={(val: any) => new Date(val).toLocaleDateString('ko-KR', { month: 'short', day: 'numeric' })} fontSize={12} />
                                        <YAxis yAxisId="left" fontSize={12} />
                                        <YAxis yAxisId="right" orientation="right" fontSize={12} />
                                        <Tooltip labelFormatter={(val: any) => new Date(val).toLocaleDateString()} />
                                        <Legend />
                                        <Line yAxisId="left" type="monotone" dataKey="incidents" stroke="#ef4444" name="Incidents" strokeWidth={2} />
                                        <Line yAxisId="right" type="monotone" dataKey="avg_mttr_min" stroke="#3b82f6" name="Avg MTTR (min)" strokeWidth={2} />
                                    </LineChart>
                                </ResponsiveContainer>
                            ) : (
                                <div className="h-full flex items-center justify-center text-gray-400">Not enough data</div>
                            )}
                        </div>
                    </div>

                    <div className="bg-white border rounded-xl p-4 shadow-sm">
                        <h3 className="font-semibold text-gray-700 mb-4 text-center">Jobs Failures Trend</h3>
                        <div className="h-64">
                            {weekly?.jobs_failures_trend && weekly.jobs_failures_trend.length > 0 ? (
                                <ResponsiveContainer width="100%" height="100%">
                                    <BarChart data={weekly.jobs_failures_trend} margin={{ top: 5, right: 5, left: -20, bottom: 5 }}>
                                        <CartesianGrid strokeDasharray="3 3" vertical={false} />
                                        <XAxis dataKey="day" tickFormatter={(val: any) => new Date(val).toLocaleDateString('ko-KR', { month: 'short', day: 'numeric' })} fontSize={12} />
                                        <YAxis fontSize={12} />
                                        <Tooltip labelFormatter={(val: any) => new Date(val).toLocaleDateString()} />
                                        <Legend />
                                        <Bar dataKey="total" fill="#94a3b8" name="Total Jobs" radius={[4, 4, 0, 0]} />
                                        <Bar dataKey="failed" fill="#f97316" name="Failed Jobs" radius={[4, 4, 0, 0]} />
                                    </BarChart>
                                </ResponsiveContainer>
                            ) : (
                                <div className="h-full flex items-center justify-center text-gray-400">Not enough data</div>
                            )}
                        </div>
                    </div>

                </div>
            </section>

        </div>
    )
}
