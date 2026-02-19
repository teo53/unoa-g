'use client'

import { ReactNode } from 'react'

interface FeatureCardProps {
  icon: ReactNode
  title: string
  description: string
  gradient: string
}

export function FeatureCard({ icon, title, description, gradient }: FeatureCardProps) {
  return (
    <div className="group relative p-6 rounded-2xl bg-white border border-gray-100 hover:border-primary-200 transition-all duration-300 hover:shadow-lg hover:-translate-y-1">
      <div
        className={`w-14 h-14 rounded-2xl flex items-center justify-center mb-4 ${gradient} transition-transform duration-300 group-hover:scale-110`}
      >
        {icon}
      </div>
      <h3 className="text-lg font-bold text-gray-900 mb-2">{title}</h3>
      <p className="text-sm text-gray-500 leading-relaxed">{description}</p>
    </div>
  )
}
