// Sentry Client Configuration
// This file configures the initialization of Sentry on the client.
// The config you add here will be used whenever a users loads a page in their browser.
// https://docs.sentry.io/platforms/javascript/guides/nextjs/

import * as Sentry from '@sentry/nextjs'

const SENTRY_DSN = process.env.NEXT_PUBLIC_SENTRY_DSN
const ENVIRONMENT = process.env.NODE_ENV || 'development'

if (SENTRY_DSN) {
  Sentry.init({
    dsn: SENTRY_DSN,
    environment: ENVIRONMENT,

    // Performance Monitoring
    // Capture 10% of transactions for performance monitoring in production
    tracesSampleRate: ENVIRONMENT === 'production' ? 0.1 : 1.0,

    // Session Replay
    // Capture 10% of sessions for replay, 100% of sessions with errors
    replaysSessionSampleRate: ENVIRONMENT === 'production' ? 0.1 : 0,
    replaysOnErrorSampleRate: 1.0,

    // Trace propagation targets (controls which outgoing requests get tracing headers)
    tracePropagationTargets: ['localhost', /^https:\/\/.*\.supabase\.co/],

    // Integrations
    integrations: [
      // Session Replay
      Sentry.replayIntegration({
        // Additional Replay configuration
        maskAllText: true,
        blockAllMedia: true,
      }),
      // Browser Tracing for performance
      Sentry.browserTracingIntegration(),
    ],

    // Filter sensitive data
    beforeSend(event) {
      // Don't send events in development unless specifically enabled
      if (ENVIRONMENT === 'development' && !process.env.NEXT_PUBLIC_SENTRY_DEBUG) {
        console.log('[Sentry] Event captured (dev mode):', event.message || event.exception)
        return null
      }

      // Filter out sensitive data from breadcrumbs
      if (event.breadcrumbs) {
        event.breadcrumbs = event.breadcrumbs.map((breadcrumb) => {
          if (breadcrumb.category === 'fetch' || breadcrumb.category === 'xhr') {
            // Remove authorization headers
            if (breadcrumb.data?.['request_headers']) {
              delete breadcrumb.data['request_headers']
            }
          }
          return breadcrumb
        })
      }

      return event
    },

    // Ignore common non-critical errors
    ignoreErrors: [
      // Browser extensions
      /extensions\//i,
      /^chrome:\/\//i,
      // Network errors that users might experience
      'Network request failed',
      'Failed to fetch',
      'Load failed',
      // ResizeObserver errors (common and non-critical)
      'ResizeObserver loop limit exceeded',
      'ResizeObserver loop completed with undelivered notifications',
    ],

    // Don't report from these URLs
    denyUrls: [
      // Browser extensions
      /extensions\//i,
      /^chrome:\/\//i,
      /^chrome-extension:\/\//i,
      /^moz-extension:\/\//i,
    ],

    // Debug mode for development
    debug: ENVIRONMENT === 'development',
  })
}

export {}
