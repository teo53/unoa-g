export function getP0IncidentSlackBlock(
    component: string,
    summary: string,
    startedAt: string,
    correlationId: string,
    runbookUrl: string
) {
    return {
        text: "P0 Incident Opened",
        blocks: [
            {
                type: "header",
                text: {
                    type: "plain_text",
                    text: "🚨 P0 Incident Opened"
                }
            },
            {
                type: "section",
                text: {
                    type: "mrkdwn",
                    text: `*Component*: \`${component}\`\n*Summary*: ${summary}\n*Started*: ${startedAt}\n*Correlation*: \`${correlationId}\``
                }
            },
            {
                type: "section",
                fields: [
                    {
                        type: "mrkdwn",
                        text: `*Runbook*\n\`${runbookUrl}\``
                    },
                    {
                        type: "mrkdwn",
                        text: "*Owner*\n`@oncall`"
                    }
                ]
            },
            { type: "divider" },
            {
                type: "context",
                elements: [
                    {
                        type: "mrkdwn",
                        text: "Action: Investigate Functions Invocations/Logs + ops_jobs failures"
                    }
                ]
            }
        ]
    }
}

export function getBatchFailureSlackBlock(
    jobType: string,
    failedCount: number,
    totalCount: number,
    p95Ms: string,
    jobsUrl: string
) {
    return {
        text: "Batch Failure Spike",
        blocks: [
            {
                type: "header",
                text: {
                    type: "plain_text",
                    text: "⚠️ Batch Failures Spike"
                }
            },
            {
                type: "section",
                text: {
                    type: "mrkdwn",
                    text: `*job_type*: \`${jobType}\`\n*failed/total(24h)*: \`${failedCount}/${totalCount}\`\n*p95*: \`${p95Ms}ms\`\n*Next*: open \`${jobsUrl}\` and filter \`failed\``
                }
            }
        ]
    }
}
