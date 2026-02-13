'use client'

interface OpsToggleSwitchProps {
  checked: boolean
  onChange: (checked: boolean) => void
  label?: string
  description?: string
  disabled?: boolean
  size?: 'sm' | 'md' | 'lg'
}

const SIZE_STYLES = {
  sm: { track: 'w-8 h-4', thumb: 'w-3 h-3', translate: 'translate-x-4' },
  md: { track: 'w-11 h-6', thumb: 'w-5 h-5', translate: 'translate-x-5' },
  lg: { track: 'w-14 h-7', thumb: 'w-6 h-6', translate: 'translate-x-7' },
}

export function OpsToggleSwitch({
  checked,
  onChange,
  label,
  description,
  disabled = false,
  size = 'md',
}: OpsToggleSwitchProps) {
  const s = SIZE_STYLES[size]

  return (
    <label
      className={`inline-flex items-start gap-3 ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`}
    >
      {/* Switch */}
      <button
        type="button"
        role="switch"
        aria-checked={checked}
        aria-label={label}
        disabled={disabled}
        className={`
          relative inline-flex flex-shrink-0 rounded-full transition-colors duration-200 ease-in-out
          focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-blue-500
          ${s.track}
          ${checked ? 'bg-green-500' : 'bg-gray-300'}
          ${disabled ? '' : 'hover:shadow-md'}
        `}
        onClick={() => !disabled && onChange(!checked)}
      >
        <span
          className={`
            inline-block rounded-full bg-white shadow-sm transform transition-transform duration-200 ease-in-out
            ${s.thumb}
            ${checked ? s.translate : 'translate-x-0.5'}
            mt-0.5
          `}
        />
      </button>

      {/* Label + Description */}
      {(label || description) && (
        <div className="flex flex-col">
          {label && (
            <span className="text-sm font-medium text-gray-900">{label}</span>
          )}
          {description && (
            <span className="text-xs text-gray-500 mt-0.5">{description}</span>
          )}
        </div>
      )}
    </label>
  )
}

/** Rollout gauge visual indicator */
interface RolloutGaugeProps {
  percent: number
  size?: 'sm' | 'md'
}

export function RolloutGauge({ percent, size = 'md' }: RolloutGaugeProps) {
  // Color based on rollout percentage
  const getColor = (p: number) => {
    if (p === 0) return 'bg-gray-300'
    if (p <= 25) return 'bg-red-500'
    if (p <= 50) return 'bg-yellow-500'
    if (p <= 75) return 'bg-blue-500'
    return 'bg-green-500'
  }

  const height = size === 'sm' ? 'h-1.5' : 'h-2.5'

  return (
    <div className="flex items-center gap-2">
      <div className={`flex-1 ${height} bg-gray-200 rounded-full overflow-hidden`}>
        <div
          className={`${height} ${getColor(percent)} rounded-full transition-all duration-300 ease-out`}
          style={{ width: `${Math.max(percent, 2)}%` }}
        />
      </div>
      <span className="text-xs font-mono text-gray-600 tabular-nums w-10 text-right">
        {percent}%
      </span>
    </div>
  )
}
