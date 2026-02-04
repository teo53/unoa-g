'use client'

import { EventSchedule } from '@/lib/types/database'
import { Calendar, Clock, Gift, Video, Users, Truck } from 'lucide-react'

interface EventScheduleBoxProps {
  schedule: EventSchedule
  className?: string
}

export function EventScheduleBox({ schedule, className = '' }: EventScheduleBoxProps) {
  const hasAnySchedule =
    schedule.sale_period ||
    schedule.winner_announce ||
    schedule.fansign_date ||
    schedule.videocall_date ||
    schedule.shipping_date ||
    (schedule.custom_events && schedule.custom_events.length > 0)

  if (!hasAnySchedule) return null

  return (
    <div className={`bg-gray-50 rounded-xl p-4 ${className}`}>
      <h3 className="font-bold text-gray-900 mb-3 flex items-center gap-2">
        <Calendar className="h-4 w-4 text-pink-500" />
        이벤트 안내
      </h3>
      <div className="space-y-3 text-sm">
        {/* Sale Period */}
        {schedule.sale_period && (
          <div className="flex items-start gap-3">
            <div className="w-5 h-5 flex items-center justify-center">
              <span className="text-lg">🛒</span>
            </div>
            <div className="flex-1">
              <span className="text-gray-500">판매기간</span>
              <p className="font-medium text-gray-900">
                {schedule.sale_period.start} ~ {schedule.sale_period.end}
              </p>
            </div>
          </div>
        )}

        {/* Winner Announcement */}
        {schedule.winner_announce && (
          <div className="flex items-start gap-3">
            <div className="w-5 h-5 flex items-center justify-center">
              <span className="text-lg">🎉</span>
            </div>
            <div className="flex-1">
              <span className="text-gray-500">당첨자 발표</span>
              <p className="font-medium text-gray-900">
                {schedule.winner_announce}
              </p>
            </div>
          </div>
        )}

        {/* Fansign Date */}
        {schedule.fansign_date && (
          <div className="flex items-start gap-3">
            <div className="w-5 h-5 flex items-center justify-center">
              <span className="text-lg">🎤</span>
            </div>
            <div className="flex-1">
              <span className="text-gray-500">FANSIGN</span>
              <p className="font-medium text-gray-900">
                {schedule.fansign_date}
              </p>
            </div>
          </div>
        )}

        {/* Videocall Date */}
        {schedule.videocall_date && (
          <div className="flex items-start gap-3">
            <div className="w-5 h-5 flex items-center justify-center">
              <span className="text-lg">📱</span>
            </div>
            <div className="flex-1">
              <span className="text-gray-500">VIDEOCALL</span>
              <p className="font-medium text-gray-900">
                {schedule.videocall_date}
              </p>
            </div>
          </div>
        )}

        {/* Shipping Date */}
        {schedule.shipping_date && (
          <div className="flex items-start gap-3">
            <div className="w-5 h-5 flex items-center justify-center">
              <span className="text-lg">📦</span>
            </div>
            <div className="flex-1">
              <span className="text-gray-500">배송 예정</span>
              <p className="font-medium text-gray-900">
                {schedule.shipping_date}
              </p>
            </div>
          </div>
        )}

        {/* Custom Events */}
        {schedule.custom_events?.map((event, index) => (
          <div key={index} className="flex items-start gap-3">
            <div className="w-5 h-5 flex items-center justify-center">
              <span className="text-lg">📌</span>
            </div>
            <div className="flex-1">
              <span className="text-gray-500">{event.label}</span>
              <p className="font-medium text-gray-900">{event.date}</p>
              {event.description && (
                <p className="text-xs text-gray-500 mt-0.5">{event.description}</p>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
