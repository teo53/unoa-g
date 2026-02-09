import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { z } from "zod";

import { McpServer, ResourceTemplate } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const CHECKLIST_DIR = path.join(__dirname, "checklists");

function readChecklistOrThrow(fileName) {
  const full = path.join(CHECKLIST_DIR, fileName);
  if (!fs.existsSync(full)) throw new Error(`Checklist not found: ${full}`);
  return fs.readFileSync(full, "utf-8");
}

function existsRel(repoRoot, rel) {
  return fs.existsSync(path.join(repoRoot, rel));
}

const server = new McpServer({
  name: "unoa-review",
  version: "0.1.0",
});

// ---- Resources: checklists ----
server.resource(
  "uiux_checklist",
  "review://checklists/uiux",
  { description: "UNO-A UI/UX Review Checklist — Heuristic + flow-based UI/UX audit checklist." },
  async (uri) => ({
    contents: [{ uri: uri.href, text: readChecklistOrThrow("uiux.md") }],
  })
);

server.resource(
  "legal_kr_checklist",
  "review://checklists/legal_kr",
  { description: "UNO-A Legal Issue-Spotting Checklist (KR) — KR-oriented legal/compliance issue-spotting checklist." },
  async (uri) => ({
    contents: [{ uri: uri.href, text: readChecklistOrThrow("legal_kr.md") }],
  })
);

server.resource(
  "tax_kr_checklist",
  "review://checklists/tax_kr",
  { description: "UNO-A Tax Issue-Spotting Checklist (KR) — KR-oriented tax/accounting issue-spotting checklist." },
  async (uri) => ({
    contents: [{ uri: uri.href, text: readChecklistOrThrow("tax_kr.md") }],
  })
);

// ---- Tools ----
server.tool(
  "risk_map",
  "Return prioritized paths/components to review (uiux/legal/tax). No secrets.",
  {
    repoRoot: z.string().default(process.cwd()),
  },
  async ({ repoRoot }) => {
    const candidates = {
      uiux: [
        "lib/features",
        "lib/navigation",
        "lib/core/theme",
        "lib/core/utils/accessibility_helper.dart",
        "lib/features/funding",
        "lib/features/wallet",
      ],
      legal: [
        "supabase/migrations/018_user_consents_enhancement.sql",
        "supabase/migrations/015_identity_verifications.sql",
        "supabase/migrations/011_encrypt_sensitive_data.sql",
        "supabase/functions/verify-identity/index.ts",
        "supabase/functions/refund-process/index.ts",
        "supabase/functions/payment-webhook/index.ts",
      ],
      tax: [
        "supabase/functions/payment-checkout/index.ts",
        "supabase/functions/payment-webhook/index.ts",
        "supabase/functions/payout-calculate/index.ts",
        "supabase/functions/payout-statement/index.ts",
        "supabase/functions/refund-process/index.ts",
        "supabase/migrations/006_wallet_ledger.sql",
        "supabase/migrations/008_payouts.sql",
        "supabase/migrations/010_payment_atomicity.sql",
        "supabase/migrations/021_funding_schema.sql",
      ],
    };

    const withExistence = Object.fromEntries(
      Object.entries(candidates).map(([k, arr]) => [
        k,
        arr.map((p) => ({ path: p, exists: existsRel(repoRoot, p) })),
      ])
    );

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(
            {
              repoRoot,
              prioritized: withExistence,
              notes: [
                "Do NOT output secrets. Only paths + existence flags.",
                "Reviewer should open existing:true files and match against checklists.",
              ],
            },
            null,
            2
          ),
        },
      ],
    };
  }
);

server.tool(
  "review_output_template",
  "Returns the required report format (severity, evidence, fix plan, disclaimers).",
  {},
  async () => {
    const template = `
# Review Report Template

## Summary (<=5 lines)

## Findings (Table)
| Severity | Domain | User Impact | Evidence (file:line) | Recommendation | Effort (S/M/L) | Needs Pro (Y/N) |
|---|---|---|---|---|---|---|

Severity rules:
- P0: Legal/financial/security blocker, data loss, refund/settlement break, identity/consent fatal gaps
- P1: High conversion/retention impact, accessibility failure, major UX friction, incomplete disclosures
- P2: Nice-to-have improvements, polish, minor copy/visual consistency

## Fix Plan
- PR1:
- PR2:
- Tests/QA:

## Disclaimer (MUST)
- This is issue-spotting, not legal/tax advice. Final review by attorney/CPA required.
- KR/Global jurisdiction may differ; confirm applicability.
`.trim();

    return { content: [{ type: "text", text: template }] };
  }
);

// ---- Prompts ----
function buildPromptMessages({ title, checklistUri, focusPaths }) {
  const msg = `
${title}

1) 먼저 risk_map tool을 호출해서 'exists:true' 경로를 확보해라.
2) 아래 focusPaths의 파일/코드를 열어서(Flutter UI, Supabase functions, migrations) 체크리스트에 매핑해 누락/리스크를 찾는다.
3) 결과 출력은 반드시 review_output_template의 포맷을 따른다.
4) 체크리스트 리소스를 참조하라: ${checklistUri}

focusPaths:
${focusPaths.map((p) => `- ${p}`).join("\n")}
`.trim();

  return [
    {
      role: "user",
      content: { type: "text", text: msg },
    },
  ];
}

server.prompt(
  "uiux_review",
  "Run a UX audit across key flows (onboarding, DM, wallet, funding, settings) using checklist.",
  { repoRoot: z.string().default(process.cwd()) },
  async ({ repoRoot }) => ({
    messages: buildPromptMessages({
      title: "UNO-A UI/UX Review",
      checklistUri: "review://checklists/uiux",
      focusPaths: [
        "lib/features/auth/**",
        "lib/features/chat/**",
        "lib/features/wallet/**",
        "lib/features/funding/**",
        "lib/features/settings/**",
        "lib/core/utils/accessibility_helper.dart",
        "lib/navigation/app_router.dart",
      ],
    }),
  })
);

server.prompt(
  "legal_review_kr",
  "Spot missing disclosures/consents/refund/settlement clauses and high-risk compliance gaps (KR-oriented).",
  { repoRoot: z.string().default(process.cwd()) },
  async () => ({
    messages: buildPromptMessages({
      title: "UNO-A Legal/Compliance Review (KR) — Issue Spotting",
      checklistUri: "review://checklists/legal_kr",
      focusPaths: [
        "supabase/migrations/*consent*",
        "supabase/migrations/*identity*",
        "supabase/migrations/*encrypt*",
        "supabase/functions/verify-identity/**",
        "supabase/functions/payment-*",
        "supabase/functions/refund-*",
        "supabase/functions/payout-*",
        "lib/features/funding/**",
        "lib/features/wallet/**",
        "lib/features/settings/**",
      ],
    }),
  })
);

server.prompt(
  "tax_review_kr",
  "Spot tax/accounting risk around wallet/credits, platform fees, payouts, refunds, revenue recognition (KR-oriented).",
  { repoRoot: z.string().default(process.cwd()) },
  async () => ({
    messages: buildPromptMessages({
      title: "UNO-A Tax/Accounting Review (KR) — Issue Spotting",
      checklistUri: "review://checklists/tax_kr",
      focusPaths: [
        "supabase/migrations/006_wallet_ledger.sql",
        "supabase/migrations/008_payouts.sql",
        "supabase/migrations/010_payment_atomicity.sql",
        "supabase/functions/payment-*",
        "supabase/functions/refund-*",
        "supabase/functions/payout-*",
        "lib/features/wallet/**",
        "lib/features/funding/**",
      ],
    }),
  })
);

server.prompt(
  "release_gate",
  "Before shipping: ensure no P0/P1 blockers remain, and list required docs/policies/UX fixes.",
  {},
  async () => ({
    messages: [
      {
        role: "user",
        content: {
          type: "text",
          text: [
            "UNO-A Release Gate (P0/P1)",
            "",
            "1) risk_map 를 먼저 호출해서 exists:true 핵심 경로를 확보해라.",
            "2) UI/UX, Legal(KR), Tax(KR) 체크리스트 리소스를 모두 참조해라:",
            "   - review://checklists/uiux",
            "   - review://checklists/legal_kr",
            "   - review://checklists/tax_kr",
            "3) P0/P1만 추려서 Findings 테이블로 정리하고, 남은 블로커가 0인지 판단해라.",
            "4) 배포 전 필수 문서/고지(약관/개인정보/환불/정산/수수료/미성년/CS/사업자정보 등) 체크 여부를 명시해라.",
            "5) 반드시 review_output_template 포맷 + Disclaimer 포함.",
          ].join("\n"),
        },
      },
    ],
  })
);

// ---- Start server ----
const transport = new StdioServerTransport();
await server.connect(transport);

// IMPORTANT: no stdout logs. If needed, use console.error only.
console.error("[unoa-review] MCP server started (stdio).");
