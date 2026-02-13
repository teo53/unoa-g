'use client'

import { STATUS_CONFIG } from '@/lib/ops/ops-types'

interface OpsStatusBadgeProps {
  status: string
  size?: 'sm' | 'md'
}

export function OpsStatusBadge({ status, size = 'md' }: OpsStatusBadgeProps) {
  const config = STATUS_CONFIG[status] || {
    label: status,
    color: 'text-gray-700',
    bgColor: 'bg-gray-100',
  }

  const sizeClasses = size === 'sm'
    ? 'text-xs px-2 py-0.5'
    : 'text-sm px-2.5 py-1'

  return (
    <span
      className={`inline-flex items-center rounded-full font-medium ${config.bgColor} ${config.color} ${sizeClasses}`}
    >
      {config.label}
    </span>
  )
}
