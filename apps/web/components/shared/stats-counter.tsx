'use client'

import { useEffect, useRef, useState } from 'react'
import { cn } from '@/lib/utils/cn'

interface StatsCounterProps {
  value: number
  label: string
  prefix?: string
  suffix?: string
  duration?: number
  className?: string
}

/**
 * StatsCounter
 *
 * 애니메이션 카운터 (랜딩 페이지 통계용).
 * 뷰포트 진입 시 0에서 목표값까지 카운트업 애니메이션.
 */
export function StatsCounter({
  value,
  label,
  prefix = '',
  suffix = '',
  duration = 1500,
  className,
}: StatsCounterProps) {
  const [count, setCount] = useState(0)
  const [hasAnimated, setHasAnimated] = useState(false)
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && !hasAnimated) {
          setHasAnimated(true)
          animateCount()
        }
      },
      { threshold: 0.3 }
    )

    const el = ref.current
    if (el) observer.observe(el)
    return () => { if (el) observer.unobserve(el) }
  }, [hasAnimated])

  function animateCount() {
    const startTime = Date.now()
    const step = () => {
      const elapsed = Date.now() - startTime
      const progress = Math.min(elapsed / duration, 1)
      // Ease-out cubic
      const eased = 1 - Math.pow(1 - progress, 3)
      setCount(Math.floor(eased * value))

      if (progress < 1) {
        requestAnimationFrame(step)
      } else {
        setCount(value)
      }
    }
    requestAnimationFrame(step)
  }

  const formatted = new Intl.NumberFormat('ko-KR').format(count)

  return (
    <div ref={ref} className={cn('text-center', className)}>
      <p className="text-3xl font-bold text-neutral-900 sm:text-4xl">
        {prefix}{formatted}{suffix}
      </p>
      <p className="mt-1 text-sm text-neutral-500">{label}</p>
    </div>
  )
}
