export function getP0IncidentEmailTemplate(
    component: string,
    summary: string,
    startedAt: string,
    correlationId: string
) {
    return {
        subject: `[UNO A][P0][${component}] Incident opened — ${summary.substring(0, 30)}`,
        body: `Incident: P0 / ${component}
Summary: ${summary}
Started: ${startedAt}
Correlation: ${correlationId}
Action: admin → Ops → Incidents에서 상세 확인 후, Functions Invocations/Logs + ops_jobs 실패를 교차 확인`
    }
}

export function getBatchFailureEmailTemplate(
    jobType: string,
    failedCount: number,
    totalCount: number,
    p95Ms: string
) {
    return {
        subject: `[UNO A][Spike] Batch Failures for — ${jobType}`,
        body: `Batch Job: ${jobType}
Failed: ${failedCount} / Total: ${totalCount} (Last 24h)
p95 Duration: ${p95Ms}ms
Action: admin → Ops → Jobs에서 failed 항목 필터링 후 에러 로그 확인`
    }
}
