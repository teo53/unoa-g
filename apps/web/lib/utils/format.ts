import { format, formatDistanceToNow, differenceInDays } from 'date-fns'
import { ko } from 'date-fns/locale'

export function formatDT(amount: number): string {
  return new Intl.NumberFormat('ko-KR').format(amount) + ' DT'
}

export function formatKRW(amount: number): string {
  return new Intl.NumberFormat('ko-KR', {
    style: 'currency',
    currency: 'KRW',
  }).format(amount)
}

export function formatPercent(current: number, goal: number): number {
  if (goal <= 0) return 0
  return Math.floor((current / goal) * 100)
}

export function formatDate(date: string | Date): string {
  const d = typeof date === 'string' ? new Date(date) : date
  return format(d, 'yyyy.MM.dd', { locale: ko })
}

export function formatDateTime(date: string | Date): string {
  const d = typeof date === 'string' ? new Date(date) : date
  return format(d, 'yyyy.MM.dd HH:mm', { locale: ko })
}

export function formatRelativeTime(date: string | Date): string {
  const d = typeof date === 'string' ? new Date(date) : date
  return formatDistanceToNow(d, { addSuffix: true, locale: ko })
}

export function formatDaysLeft(endDate: string | Date): string {
  const end = typeof endDate === 'string' ? new Date(endDate) : endDate
  const days = differenceInDays(end, new Date())

  if (days < 0) return '마감됨'
  if (days === 0) return '오늘 마감'
  if (days === 1) return '내일 마감'
  return `${days}일 남음`
}

export function formatBackerCount(count: number): string {
  if (count >= 10000) {
    return `${(count / 10000).toFixed(1)}만명`
  }
  if (count >= 1000) {
    return `${(count / 1000).toFixed(1)}천명`
  }
  return `${count}명`
}

export function truncate(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text
  return text.slice(0, maxLength) + '...'
}

// ============================================================
// 펀딩/정산 포맷터 (businessConfig 참조)
// ============================================================

/**
 * 펀딩 금액 포맷 (KRW 표시)
 * @example formatFundingAmount(500000) → "500,000원"
 */
export function formatFundingAmount(amount: number): string {
  return new Intl.NumberFormat('ko-KR').format(amount) + '원'
}

/**
 * 정산 금액 포맷 (KRW 통화 기호 포함)
 * @example formatSettlementAmount(1250000) → "₩1,250,000"
 */
export function formatSettlementAmount(amount: number): string {
  return new Intl.NumberFormat('ko-KR', {
    style: 'currency',
    currency: 'KRW',
  }).format(amount)
}

/**
 * 세율 포맷
 * @example formatTaxRate(3.3) → "3.3%"
 */
export function formatTaxRate(rate: number): string {
  return `${rate}%`
}

/**
 * 계좌번호 마스킹
 * @example formatAccountNumber('123456789012') → '****9012'
 */
export function formatAccountNumber(account: string): string {
  if (account.length < 4) return '****'
  return '****' + account.slice(-4)
}

/**
 * 큰 수 포맷 (만 단위)
 * @example formatLargeNumber(12500000) → "1,250만"
 */
export function formatLargeNumber(amount: number): string {
  if (amount >= 100000000) {
    return `${(amount / 100000000).toFixed(1)}억`
  }
  if (amount >= 10000) {
    return `${new Intl.NumberFormat('ko-KR').format(Math.floor(amount / 10000))}만`
  }
  return new Intl.NumberFormat('ko-KR').format(amount)
}

/**
 * 수수료 금액 계산 및 포맷
 * @example formatCommission(100000, 20) → "20,000원 (20%)"
 */
export function formatCommission(amount: number, commissionPercent: number): string {
  const commission = Math.floor(amount * commissionPercent / 100)
  return `${new Intl.NumberFormat('ko-KR').format(commission)}원 (${commissionPercent}%)`
}
