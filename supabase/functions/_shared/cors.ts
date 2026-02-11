/**
 * Shared CORS configuration for Supabase Edge Functions
 *
 * SECURITY: Restricts allowed origins to known domains instead of wildcard (*)
 */

// Allowed origins configuration
const PRODUCTION_ORIGINS = [
  'https://unoa.app',
  'https://www.unoa.app',
  'https://studio.unoa.app',
  'https://admin.unoa.app',
  'https://unoa-app-demo.web.app',
  'https://unoa-app-demo.firebaseapp.com',
];

const DEVELOPMENT_ORIGINS = [
  'http://localhost:3000',
  'http://localhost:5173',
  'http://localhost:8080',
  'http://127.0.0.1:3000',
  'http://127.0.0.1:5173',
];

// Get environment
const ENVIRONMENT = Deno.env.get('ENVIRONMENT') || 'production';
const isDevelopment = ENVIRONMENT === 'development';

// Combine allowed origins based on environment
const ALLOWED_ORIGINS = isDevelopment
  ? [...PRODUCTION_ORIGINS, ...DEVELOPMENT_ORIGINS]
  : PRODUCTION_ORIGINS;

/**
 * Check if origin is allowed
 */
export function isAllowedOrigin(origin: string | null): boolean {
  if (!origin) return false;
  return ALLOWED_ORIGINS.includes(origin);
}

/**
 * Get CORS headers for a request
 * Returns appropriate Access-Control-Allow-Origin based on request origin
 */
export function getCorsHeaders(request?: Request): Record<string, string> {
  const origin = request?.headers.get('Origin') || '';
  const allowedOrigin = isAllowedOrigin(origin) ? origin : PRODUCTION_ORIGINS[0];

  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Max-Age': '86400', // 24 hours
    'Vary': 'Origin',
  };
}

/**
 * Get CORS headers for webhook endpoints
 * Webhooks may come from payment providers, so we need different handling
 */
export function getWebhookCorsHeaders(): Record<string, string> {
  return {
    'Access-Control-Allow-Origin': '*', // Webhooks need to accept from payment providers
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, webhook-id, webhook-timestamp, webhook-signature, x-webhook-signature, x-payment-provider',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };
}

/**
 * Create CORS preflight response
 */
export function handleCorsPreflightRequest(request?: Request): Response {
  return new Response('ok', {
    headers: getCorsHeaders(request),
  });
}

/**
 * Create CORS preflight response for webhooks
 */
export function handleWebhookPreflightRequest(): Response {
  return new Response('ok', {
    headers: getWebhookCorsHeaders(),
  });
}

// NOTE: Legacy corsHeaders export removed in Sprint 2.
// All functions now use getCorsHeaders(req) or getWebhookCorsHeaders().
