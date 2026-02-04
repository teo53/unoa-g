/**
 * Sentry Integration for Supabase Edge Functions (Deno)
 *
 * Provides error tracking and performance monitoring for Edge Functions.
 * Uses Sentry's Deno SDK with additional filtering for sensitive data.
 */

// Sentry DSN from environment
const SENTRY_DSN = Deno.env.get('SENTRY_DSN');
const ENVIRONMENT = Deno.env.get('ENVIRONMENT') || 'production';
const FUNCTION_NAME = Deno.env.get('FUNCTION_NAME') || 'unknown';

// Simple in-memory rate limiting to prevent spam
let lastErrorTime = 0;
let errorCount = 0;
const RATE_LIMIT_WINDOW = 60000; // 1 minute
const RATE_LIMIT_MAX = 10; // max 10 errors per minute

/**
 * Check if we should rate limit this error
 */
function shouldRateLimit(): boolean {
  const now = Date.now();
  if (now - lastErrorTime > RATE_LIMIT_WINDOW) {
    errorCount = 0;
    lastErrorTime = now;
  }
  errorCount++;
  return errorCount > RATE_LIMIT_MAX;
}

/**
 * Sensitive keywords to filter from error messages
 */
const SENSITIVE_KEYWORDS = [
  'password',
  'token',
  'secret',
  'api_key',
  'apikey',
  'authorization',
  'bearer',
  'credit_card',
  'card_number',
  'cvv',
  'ssn',
  '주민등록',
  '계좌번호',
];

/**
 * Check if text contains sensitive data
 */
function containsSensitiveData(text: string): boolean {
  const lowerText = text.toLowerCase();
  return SENSITIVE_KEYWORDS.some((keyword) => lowerText.includes(keyword));
}

/**
 * Filter sensitive data from object
 */
function filterSensitiveData(obj: Record<string, unknown>): Record<string, unknown> {
  const filtered: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(obj)) {
    const lowerKey = key.toLowerCase();
    if (SENSITIVE_KEYWORDS.some((keyword) => lowerKey.includes(keyword))) {
      filtered[key] = '[FILTERED]';
    } else if (typeof value === 'string' && containsSensitiveData(value)) {
      filtered[key] = '[FILTERED]';
    } else if (typeof value === 'object' && value !== null) {
      filtered[key] = filterSensitiveData(value as Record<string, unknown>);
    } else {
      filtered[key] = value;
    }
  }
  return filtered;
}

/**
 * Sentry event payload structure
 */
interface SentryEvent {
  event_id: string;
  timestamp: string;
  platform: string;
  level: 'fatal' | 'error' | 'warning' | 'info' | 'debug';
  logger: string;
  server_name: string;
  environment: string;
  exception?: {
    values: Array<{
      type: string;
      value: string;
      stacktrace?: {
        frames: Array<{
          filename: string;
          function: string;
          lineno?: number;
          colno?: number;
        }>;
      };
    }>;
  };
  message?: string;
  extra?: Record<string, unknown>;
  tags?: Record<string, string>;
  user?: {
    id?: string;
    email?: string;
    ip_address?: string;
  };
  request?: {
    url?: string;
    method?: string;
    headers?: Record<string, string>;
  };
}

/**
 * Generate UUID v4
 */
function generateUUID(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

/**
 * Send event to Sentry
 */
async function sendToSentry(event: SentryEvent): Promise<void> {
  if (!SENTRY_DSN) {
    console.log('[Sentry] DSN not configured, logging locally:', event.message || event.exception?.values?.[0]?.value);
    return;
  }

  if (shouldRateLimit()) {
    console.warn('[Sentry] Rate limited, skipping event');
    return;
  }

  try {
    // Parse DSN: https://{public_key}@{host}/{project_id}
    const dsnUrl = new URL(SENTRY_DSN);
    const publicKey = dsnUrl.username;
    const projectId = dsnUrl.pathname.replace('/', '');
    const sentryHost = dsnUrl.host;

    const storeUrl = `https://${sentryHost}/api/${projectId}/store/`;

    const response = await fetch(storeUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Sentry-Auth': `Sentry sentry_version=7, sentry_client=deno-edge/1.0.0, sentry_key=${publicKey}`,
      },
      body: JSON.stringify(event),
    });

    if (!response.ok) {
      console.error('[Sentry] Failed to send event:', response.status, await response.text());
    }
  } catch (error) {
    console.error('[Sentry] Error sending event:', error);
  }
}

/**
 * Capture an exception
 */
export async function captureException(
  error: Error,
  options?: {
    extra?: Record<string, unknown>;
    tags?: Record<string, string>;
    user?: { id?: string; email?: string };
    request?: Request;
    level?: 'fatal' | 'error' | 'warning';
  }
): Promise<string> {
  const eventId = generateUUID().replace(/-/g, '');

  // Parse stack trace
  const stackLines = error.stack?.split('\n').slice(1) || [];
  const frames = stackLines.map((line) => {
    const match = line.match(/at\s+(.+?)\s+\((.+?):(\d+):(\d+)\)/) ||
                  line.match(/at\s+(.+?):(\d+):(\d+)/);
    if (match) {
      return {
        function: match[1] || 'anonymous',
        filename: match[2] || 'unknown',
        lineno: parseInt(match[3]) || undefined,
        colno: parseInt(match[4]) || undefined,
      };
    }
    return { function: line.trim(), filename: 'unknown' };
  }).reverse(); // Sentry wants oldest frame first

  const event: SentryEvent = {
    event_id: eventId,
    timestamp: new Date().toISOString(),
    platform: 'javascript',
    level: options?.level || 'error',
    logger: 'edge-function',
    server_name: FUNCTION_NAME,
    environment: ENVIRONMENT,
    exception: {
      values: [
        {
          type: error.name || 'Error',
          value: containsSensitiveData(error.message)
            ? '[FILTERED] Error message contained sensitive data'
            : error.message,
          stacktrace: frames.length > 0 ? { frames } : undefined,
        },
      ],
    },
    tags: {
      function_name: FUNCTION_NAME,
      runtime: 'deno',
      ...options?.tags,
    },
    extra: options?.extra ? filterSensitiveData(options.extra) : undefined,
    user: options?.user,
  };

  // Add request info if available
  if (options?.request) {
    event.request = {
      url: options.request.url,
      method: options.request.method,
      // Don't include headers as they may contain sensitive data
    };
  }

  await sendToSentry(event);
  return eventId;
}

/**
 * Capture a message
 */
export async function captureMessage(
  message: string,
  options?: {
    level?: 'fatal' | 'error' | 'warning' | 'info' | 'debug';
    extra?: Record<string, unknown>;
    tags?: Record<string, string>;
    user?: { id?: string; email?: string };
  }
): Promise<string> {
  const eventId = generateUUID().replace(/-/g, '');

  const event: SentryEvent = {
    event_id: eventId,
    timestamp: new Date().toISOString(),
    platform: 'javascript',
    level: options?.level || 'info',
    logger: 'edge-function',
    server_name: FUNCTION_NAME,
    environment: ENVIRONMENT,
    message: containsSensitiveData(message)
      ? '[FILTERED] Message contained sensitive data'
      : message,
    tags: {
      function_name: FUNCTION_NAME,
      runtime: 'deno',
      ...options?.tags,
    },
    extra: options?.extra ? filterSensitiveData(options.extra) : undefined,
    user: options?.user,
  };

  await sendToSentry(event);
  return eventId;
}

/**
 * Wrap an Edge Function handler with Sentry error tracking
 */
export function withSentry(
  handler: (req: Request) => Promise<Response>
): (req: Request) => Promise<Response> {
  return async (req: Request): Promise<Response> => {
    const startTime = Date.now();

    try {
      const response = await handler(req);

      // Log slow requests
      const duration = Date.now() - startTime;
      if (duration > 5000) {
        await captureMessage(`Slow request: ${duration}ms`, {
          level: 'warning',
          extra: {
            url: req.url,
            method: req.method,
            duration_ms: duration,
          },
        });
      }

      return response;
    } catch (error) {
      // Capture the exception
      const eventId = await captureException(error as Error, {
        request: req,
        extra: {
          duration_ms: Date.now() - startTime,
        },
      });

      // Log locally as well
      console.error(`[Sentry] Captured exception (${eventId}):`, error);

      // Re-throw to let the function handle it
      throw error;
    }
  };
}

/**
 * Set user context for the current scope
 * Note: In Deno Edge Functions, context is per-request, so call this at the start of each request
 */
export function setUser(user: { id?: string; email?: string }): void {
  // Store in a module-level variable that will be used by capture functions
  // This is a simplified version - in production, consider using AsyncLocalStorage
  (globalThis as unknown as Record<string, unknown>).__sentryUser = user;
}

/**
 * Clear user context
 */
export function clearUser(): void {
  delete (globalThis as unknown as Record<string, unknown>).__sentryUser;
}

/**
 * Get current user context
 */
function getCurrentUser(): { id?: string; email?: string } | undefined {
  return (globalThis as unknown as Record<string, unknown>).__sentryUser as { id?: string; email?: string } | undefined;
}

// Export additional helpers
export { filterSensitiveData, containsSensitiveData };
