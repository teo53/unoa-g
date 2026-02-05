// Sentry Server Configuration
// This file configures the initialization of Sentry on the server.
// The config you add here will be used whenever the server handles a request.
// https://docs.sentry.io/platforms/javascript/guides/nextjs/

import * as Sentry from '@sentry/nextjs'

const SENTRY_DSN = process.env.SENTRY_DSN || process.env.NEXT_PUBLIC_SENTRY_DSN
const ENVIRONMENT = process.env.NODE_ENV || 'development'

if (SENTRY_DSN) {
  Sentry.init({
    dsn: SENTRY_DSN,
    environment: ENVIRONMENT,

    // Performance Monitoring
    // Capture 10% of transactions for performance monitoring in production
    tracesSampleRate: ENVIRONMENT === 'production' ? 0.1 : 1.0,

    // Filter sensitive data
    beforeSend(event) {
      // Don't send events in development unless specifically enabled
      if (ENVIRONMENT === 'development' && !process.env.SENTRY_DEBUG) {
        console.log('[Sentry Server] Event captured (dev mode):', event.message || event.exception)
        return null
      }

      // Remove sensitive request data
      if (event.request) {
        // Remove cookies and headers that might contain tokens
        delete event.request.cookies
        if (event.request.headers) {
          delete event.request.headers['authorization']
          delete event.request.headers['cookie']
        }
      }

      return event
    },

    // Ignore common non-critical errors
    ignoreErrors: [
      // Network errors
      'ECONNRESET',
      'ECONNREFUSED',
      'ETIMEDOUT',
      // Next.js specific
      'NEXT_NOT_FOUND',
      'NEXT_REDIRECT',
    ],

    // Debug mode for development
    debug: ENVIRONMENT === 'development',
  })
}

export {}
