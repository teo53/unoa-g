import { safeExec } from '../../_shared/src/exec.js';
import type { ChecklistItem, PrChecklistResult } from '../../_shared/src/types.js';

interface ChecklistRule {
  category: string;
  item: string;
  required: boolean;
  /** Glob/path patterns that trigger this item */
  triggers: RegExp[];
}

const CHECKLIST_RULES: ChecklistRule[] = [
  // Testing
  {
    category: 'testing',
    item: 'Run flutter test and verify all tests pass',
    required: true,
    triggers: [/\.dart$/],
  },
  {
    category: 'testing',
    item: 'Add or update widget tests for new/changed screens',
    required: false,
    triggers: [/lib\/features\/.*_screen\.dart$/],
  },
  {
    category: 'testing',
    item: 'Run flutter analyze with no new errors',
    required: true,
    triggers: [/\.dart$/],
  },

  // Error UX
  {
    category: 'error-ux',
    item: 'Verify error states are handled with ErrorDisplay widget',
    required: false,
    triggers: [/lib\/features\/.*\.dart$/],
  },
  {
    category: 'error-ux',
    item: 'Check empty states use EmptyState widget',
    required: false,
    triggers: [/lib\/features\/.*_screen\.dart$/],
  },

  // Logging
  {
    category: 'logging',
    item: 'Ensure no print() calls remain (use debugPrint or structured logging)',
    required: true,
    triggers: [/\.dart$/],
  },

  // Migration
  {
    category: 'migration',
    item: 'Review SQL migration for dangerous operations (DROP, TRUNCATE, GRANT ALL)',
    required: true,
    triggers: [/supabase\/migrations\/.*\.sql$/],
  },
  {
    category: 'migration',
    item: 'Verify migration sequence number is contiguous',
    required: true,
    triggers: [/supabase\/migrations\/.*\.sql$/],
  },
  {
    category: 'migration',
    item: 'Test migration rollback plan exists',
    required: false,
    triggers: [/supabase\/migrations\/.*\.sql$/],
  },

  // RLS
  {
    category: 'rls',
    item: 'New tables have ENABLE ROW LEVEL SECURITY + policies',
    required: true,
    triggers: [/supabase\/migrations\/.*\.sql$/],
  },
  {
    category: 'rls',
    item: 'RLS policies follow principle of least privilege',
    required: true,
    triggers: [/rls|policy/i],
  },

  // Rollback
  {
    category: 'rollback',
    item: 'Changes are backward-compatible or have a rollback plan',
    required: false,
    triggers: [/supabase\/migrations\/.*\.sql$/, /pubspec\.yaml$/],
  },

  // Security
  {
    category: 'security',
    item: 'No API keys or secrets hardcoded in source',
    required: true,
    triggers: [/\.dart$/, /\.ts$/, /\.js$/],
  },
  {
    category: 'security',
    item: 'Edge Function authenticates requests (checks Authorization header)',
    required: true,
    triggers: [/supabase\/functions\/.*\.ts$/],
  },

  // UI
  {
    category: 'ui',
    item: 'UI supports both light and dark themes',
    required: false,
    triggers: [/lib\/features\/.*\.dart$/],
  },
  {
    category: 'ui',
    item: 'Korean labels are correct and consistent',
    required: false,
    triggers: [/lib\/features\/.*\.dart$/],
  },
  {
    category: 'ui',
    item: 'Uses Config classes (DemoConfig/BusinessConfig) instead of hardcoded values',
    required: true,
    triggers: [/lib\/.*\.dart$/],
  },

  // Config
  {
    category: 'config',
    item: 'pubspec.yaml changes are intentional (dependencies added/removed)',
    required: true,
    triggers: [/pubspec\.yaml$/],
  },
  {
    category: 'config',
    item: 'Edge Function environment variables documented',
    required: false,
    triggers: [/supabase\/functions\/.*\.ts$/],
  },
];

export async function prChecklist(base?: string): Promise<PrChecklistResult> {
  const baseBranch = base ?? 'main';

  // Get changed files
  const nameResult = await safeExec('git', ['diff', '--name-only', `${baseBranch}...HEAD`], { maxOutputChars: 10000 });
  const files = nameResult.stdout.trim().split('\n').filter(Boolean);

  const checklist: ChecklistItem[] = [];
  const seenItems = new Set<string>();

  for (const rule of CHECKLIST_RULES) {
    for (const file of files) {
      if (rule.triggers.some(t => t.test(file))) {
        if (!seenItems.has(rule.item)) {
          seenItems.add(rule.item);
          checklist.push({
            category: rule.category,
            item: rule.item,
            required: rule.required,
            triggered_by: file,
          });
        }
        break;
      }
    }
  }

  // Determine risk level
  const hasMigration = files.some(f => f.includes('supabase/migrations/'));
  const hasSecurity = files.some(f => f.includes('security') || f.includes('auth') || f.includes('rls'));
  const hasConfig = files.some(f => f === 'pubspec.yaml' || f.includes('app_config'));
  const dartFiles = files.filter(f => f.endsWith('.dart')).length;

  let riskLevel: 'low' | 'medium' | 'high' = 'low';
  if (hasMigration || hasSecurity) riskLevel = 'high';
  else if (hasConfig || dartFiles > 10) riskLevel = 'medium';

  const requiredCount = checklist.filter(c => c.required).length;
  const summary = `${checklist.length} checklist item(s) (${requiredCount} required). Risk: ${riskLevel}. Files: ${files.length}.`;

  return {
    base: baseBranch,
    checklist,
    riskLevel,
    summary,
  };
}
