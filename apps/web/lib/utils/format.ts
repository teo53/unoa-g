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
