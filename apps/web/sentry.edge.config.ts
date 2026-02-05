// Sentry Edge Configuration
// This file configures the initialization of Sentry for edge features (Middleware, Edge API routes).
// The config you add here will be used whenever a request is handled by the middleware.
// https://docs.sentry.io/platforms/javascript/guides/nextjs/

import * as Sentry from '@sentry/nextjs'

const SENTRY_DSN = process.env.SENTRY_DSN || process.env.NEXT_PUBLIC_SENTRY_DSN
const ENVIRONMENT = process.env.NODE_ENV || 'development'

if (SENTRY_DSN) {
  Sentry.init({
    dsn: SENTRY_DSN,
    environment: ENVIRONMENT,

    // Performance Monitoring
    tracesSampleRate: ENVIRONMENT === 'production' ? 0.1 : 1.0,

    // Filter sensitive data
    beforeSend(event) {
      if (ENVIRONMENT === 'development' && !process.env.SENTRY_DEBUG) {
        return null
      }

      // Remove sensitive request data
      if (event.request) {
        delete event.request.cookies
        if (event.request.headers) {
          delete event.request.headers['authorization']
          delete event.request.headers['cookie']
        }
      }

      return event
    },

    // Debug mode
    debug: ENVIRONMENT === 'development',
  })
}

export {}
