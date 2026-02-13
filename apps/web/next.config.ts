import type { NextConfig } from 'next'
import { withSentryConfig } from '@sentry/nextjs'

// SECURITY: Block DEMO_BUILD in production to prevent typecheck/lint bypass (F-08)
const isProduction = process.env.NODE_ENV === 'production'
const isDemoBuild = process.env.NEXT_PUBLIC_DEMO_BUILD === 'true'

if (isProduction && isDemoBuild) {
  console.warn(
    '\n⚠️  WARNING: NEXT_PUBLIC_DEMO_BUILD=true in production mode.\n' +
    '   TypeScript and ESLint checks are disabled. This is NOT recommended for production.\n' +
    '   Remove NEXT_PUBLIC_DEMO_BUILD or set to "false" for production deployments.\n'
  )
}

// SECURITY: Prevent demo mode in production builds unless explicitly acknowledged
if (isProduction && process.env.NEXT_PUBLIC_DEMO_MODE === 'true') {
  if (!isDemoBuild) {
    throw new Error(
      'SECURITY: NEXT_PUBLIC_DEMO_MODE=true is not allowed in production builds. ' +
      'Set NEXT_PUBLIC_DEMO_BUILD=true to explicitly acknowledge this is a demo deployment.'
    )
  }
}

const nextConfig: NextConfig = {
  output: 'export', // Enable static export for Firebase Hosting
  images: {
    unoptimized: true, // Required for static export
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '*.supabase.co',
        pathname: '/storage/v1/object/public/**',
      },
      {
        protocol: 'https',
        hostname: '*.supabase.in',
        pathname: '/storage/v1/object/public/**',
      },
      {
        protocol: 'https',
        hostname: 'images.unsplash.com', // Demo images
      },
    ],
  },
  experimental: {
    serverActions: {
      bodySizeLimit: '2mb',
    },
  },
  // Trailing slash for Firebase Hosting compatibility
  trailingSlash: true,
  // SECURITY (F-08): In production, NEVER skip type checking or linting.
  // DEMO_BUILD bypass is only allowed in non-production environments.
  typescript: {
    ignoreBuildErrors: !isProduction && isDemoBuild,
  },
  eslint: {
    ignoreDuringBuilds: !isProduction && isDemoBuild,
  },
}

// Sentry configuration options
const sentryWebpackPluginOptions = {
  // For all available options, see:
  // https://github.com/getsentry/sentry-webpack-plugin#options

  // Organization and project slugs from Sentry
  org: process.env.SENTRY_ORG,
  project: process.env.SENTRY_PROJECT,

  // Auth token for uploading source maps (server-side only)
  authToken: process.env.SENTRY_AUTH_TOKEN,

  // Only upload source maps in production
  silent: process.env.NODE_ENV !== 'production',

  // Upload source maps for debugging
  widenClientFileUpload: true,

  // tunnelRoute: '/monitoring',  // Static export (`output:'export'`)에서는 서버 라우트가 없어 미작동. Direct DSN fallback 사용.

  // Hides source maps from generated client bundles
  hideSourceMaps: true,

  // Automatically tree-shake Sentry logger statements
  disableLogger: true,

  // Enables automatic instrumentation of Vercel Cron Monitors
  automaticVercelMonitors: true,
}

// Wrap config with Sentry if DSN is configured
const finalConfig = process.env.NEXT_PUBLIC_SENTRY_DSN
  ? withSentryConfig(nextConfig, sentryWebpackPluginOptions)
  : nextConfig

export default finalConfig
