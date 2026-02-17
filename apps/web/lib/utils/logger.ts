/**
 * App Logger
 *
 * Flutter AppLogger 미러링.
 * 환경별 로깅 + Sentry 연동 준비.
 */

const isDev = process.env.NODE_ENV === 'development' ||
  (process.env.NEXT_PUBLIC_ENV || 'development') === 'development'

export const appLogger = {
  /**
   * 디버그 로그 (개발 환경에서만 출력)
   */
  debug(message: string, tag?: string): void {
    if (isDev) {
      console.log(`[${tag || 'DEBUG'}]`, message)
    }
  },

  /**
   * 정보 로그
   */
  info(message: string, tag?: string): void {
    if (isDev) {
      console.info(`[${tag || 'INFO'}]`, message)
    }
  },

  /**
   * 경고 로그
   */
  warning(message: string, tag?: string): void {
    console.warn(`[${tag || 'WARN'}]`, message)
  },

  /**
   * 에러 로그 + Sentry 연동
   */
  error(error: unknown, context?: string): void {
    const errorObj = error instanceof Error ? error : new Error(String(error))
    console.error(`[ERROR${context ? `: ${context}` : ''}]`, errorObj.message)

    // Sentry 연동 (설정 시)
    if (typeof window !== 'undefined' && 'Sentry' in window) {
      try {
        // @ts-expect-error Sentry global
        window.Sentry.captureException(errorObj, {
          extra: { context },
        })
      } catch {
        // Sentry 미설정 시 무시
      }
    }
  },

  /**
   * 비즈니스 이벤트 로그 (분석용)
   */
  event(eventName: string, data?: Record<string, unknown>): void {
    if (isDev) {
      console.log(`[EVENT] ${eventName}`, data || '')
    }
  },
}
