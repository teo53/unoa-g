/**
 * App Configuration
 *
 * Flutter AppConfig 미러링.
 * 환경 감지, 기능 플래그, 런타임 검증.
 */
export const appConfig = {
  // Environment
  env: process.env.NEXT_PUBLIC_ENV || 'development',
  isDevelopment: (process.env.NEXT_PUBLIC_ENV || 'development') === 'development',
  isProduction: process.env.NEXT_PUBLIC_ENV === 'production',

  // Demo mode: Supabase URL/Key 미설정 시 자동 활성화
  isDemoMode: !process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,

  // Supabase
  supabaseUrl: process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  supabaseAnonKey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',

  // Monitoring
  sentryDsn: process.env.NEXT_PUBLIC_SENTRY_DSN || '',

  // App URLs
  appUrl: process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000',
  flutterAppUrl: process.env.NEXT_PUBLIC_FLUTTER_APP_URL || 'https://unoa-app-demo.web.app',

  // Feature Flags
  enableAnalytics: process.env.NEXT_PUBLIC_ENABLE_ANALYTICS === 'true',
  enableCrashReporting: process.env.NEXT_PUBLIC_ENABLE_CRASH_REPORTING === 'true',
  dtPurchaseEnabled: process.env.NEXT_PUBLIC_DT_PURCHASE_ENABLED === 'true',

  // Firebase Hosting Sites
  sites: {
    web: 'https://unoa-web.web.app',
    agency: 'https://unoa-agency.web.app',
    studio: 'https://unoa-studio.web.app',
    admin: 'https://unoa-admin.web.app',
  },

  /**
   * 프로덕션 필수 환경변수 검증
   * 빌드 타임이 아닌 런타임에서 호출
   */
  validate(): string[] {
    const errors: string[] = []

    if (this.isProduction) {
      if (!this.supabaseUrl) errors.push('NEXT_PUBLIC_SUPABASE_URL is required in production')
      if (!this.supabaseAnonKey) errors.push('NEXT_PUBLIC_SUPABASE_ANON_KEY is required in production')
      if (!this.sentryDsn) errors.push('NEXT_PUBLIC_SENTRY_DSN is recommended in production')
      if (this.isDemoMode) errors.push('Demo mode should not be active in production')
    }

    return errors
  },
} as const
