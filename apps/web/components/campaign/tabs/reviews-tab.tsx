'use client'

import { useState } from 'react'
import { CampaignReview } from '@/lib/types/database'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Star, ThumbsUp, Image as ImageIcon, CheckCircle, ChevronDown } from 'lucide-react'
import { cn } from '@/lib/utils'

interface ReviewsTabProps {
  reviews: CampaignReview[]
  onAddReview?: (review: Partial<CampaignReview>) => void
}

export function ReviewsTab({ reviews, onAddReview }: ReviewsTabProps) {
  const [sortBy, setSortBy] = useState<'latest' | 'helpful' | 'rating'>('latest')
  const [filterRating, setFilterRating] = useState<number | null>(null)
  const [showImages, setShowImages] = useState(false)

  // Calculate stats
  const totalReviews = reviews.length
  const avgRating = totalReviews > 0
    ? reviews.reduce((sum, r) => sum + (r.rating || 0), 0) / totalReviews
    : 0
  const ratingCounts = [5, 4, 3, 2, 1].map(rating => ({
    rating,
    count: reviews.filter(r => r.rating === rating).length
  }))

  // Filter & Sort
  let filteredReviews = [...reviews]
  if (filterRating) {
    filteredReviews = filteredReviews.filter(r => r.rating === filterRating)
  }
  if (showImages) {
    filteredReviews = filteredReviews.filter(r => r.images && r.images.length > 0)
  }

  filteredReviews.sort((a, b) => {
    if (sortBy === 'helpful') return b.helpful_count - a.helpful_count
    if (sortBy === 'rating') return (b.rating || 0) - (a.rating || 0)
    return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  })

  if (reviews.length === 0) {
    return (
      <div className="text-center py-12">
        <Star className="h-12 w-12 text-gray-300 mx-auto mb-4" />
        <p className="text-gray-500">아직 후기가 없습니다.</p>
        <p className="text-sm text-gray-400 mt-1">
          펀딩에 참여하신 후 후기를 남겨주세요!
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Rating Summary */}
      <div className="bg-gradient-to-r from-pink-50 to-orange-50 rounded-2xl p-6">
        <div className="flex flex-col md:flex-row gap-6">
          {/* Average Rating */}
          <div className="text-center md:border-r md:border-gray-200 md:pr-6">
            <div className="text-5xl font-bold text-gray-900 mb-1">
              {avgRating.toFixed(1)}
            </div>
            <div className="flex items-center justify-center gap-0.5 mb-2">
              {[1, 2, 3, 4, 5].map((star) => (
                <Star
                  key={star}
                  className={cn(
                    'h-5 w-5',
                    star <= Math.round(avgRating)
                      ? 'fill-yellow-400 text-yellow-400'
                      : 'fill-gray-200 text-gray-200'
                  )}
                />
              ))}
            </div>
            <p className="text-sm text-gray-500">{totalReviews}개의 후기</p>
          </div>

          {/* Rating Breakdown */}
          <div className="flex-1 space-y-2">
            {ratingCounts.map(({ rating, count }) => {
              const percentage = totalReviews > 0 ? (count / totalReviews) * 100 : 0
              return (
                <button
                  key={rating}
                  onClick={() => setFilterRating(filterRating === rating ? null : rating)}
                  className={cn(
                    'w-full flex items-center gap-2 py-1 rounded-lg transition-colors',
                    filterRating === rating && 'bg-white shadow-sm'
                  )}
                >
                  <div className="flex items-center gap-1 w-12">
                    <Star className="h-3 w-3 fill-yellow-400 text-yellow-400" />
                    <span className="text-sm text-gray-600">{rating}</span>
                  </div>
                  <div className="flex-1 bg-gray-200 rounded-full h-2">
                    <div
                      className="bg-yellow-400 h-2 rounded-full transition-all"
                      style={{ width: `${percentage}%` }}
                    />
                  </div>
                  <span className="text-xs text-gray-500 w-8">{count}</span>
                </button>
              )
            })}
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex gap-1 bg-gray-100 rounded-lg p-1">
          {[
            { id: 'latest', label: '최신순' },
            { id: 'helpful', label: '도움순' },
            { id: 'rating', label: '평점순' },
          ].map((option) => (
            <button
              key={option.id}
              onClick={() => setSortBy(option.id as typeof sortBy)}
              className={cn(
                'px-3 py-1 text-sm rounded-md transition-colors',
                sortBy === option.id
                  ? 'bg-white text-gray-900 shadow-sm'
                  : 'text-gray-500 hover:text-gray-700'
              )}
            >
              {option.label}
            </button>
          ))}
        </div>

        <button
          onClick={() => setShowImages(!showImages)}
          className={cn(
            'flex items-center gap-1 px-3 py-1.5 rounded-lg border text-sm transition-colors',
            showImages
              ? 'border-pink-300 bg-pink-50 text-pink-600'
              : 'border-gray-200 text-gray-600 hover:border-gray-300'
          )}
        >
          <ImageIcon className="h-4 w-4" />
          사진 후기만
        </button>

        {filterRating && (
          <button
            onClick={() => setFilterRating(null)}
            className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-pink-300 bg-pink-50 text-pink-600 text-sm"
          >
            {filterRating}점만 보기
            <span className="ml-1">×</span>
          </button>
        )}
      </div>

      {/* Reviews List */}
      <div className="space-y-4">
        {filteredReviews.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            조건에 맞는 후기가 없습니다.
          </div>
        ) : (
          filteredReviews.map((review) => (
            <ReviewItem key={review.id} review={review} />
          ))
        )}
      </div>
    </div>
  )
}

// Review Item Component
function ReviewItem({ review }: { review: CampaignReview }) {
  const [helpful, setHelpful] = useState(false)
  const [helpfulCount, setHelpfulCount] = useState(review.helpful_count)
  const [showFullContent, setShowFullContent] = useState(false)
  const [selectedImage, setSelectedImage] = useState<string | null>(null)

  const handleHelpful = () => {
    setHelpful(!helpful)
    setHelpfulCount(prev => helpful ? prev - 1 : prev + 1)
  }

  const isLongContent = review.content.length > 200

  return (
    <article className="bg-white border border-gray-200 rounded-xl p-4">
      {/* Header */}
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center gap-3">
          {/* Avatar */}
          {review.user?.avatar_url ? (
            <img
              src={review.user.avatar_url}
              alt=""
              className="w-10 h-10 rounded-full object-cover"
            />
          ) : (
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-pink-400 to-purple-400 flex items-center justify-center text-white font-medium">
              {(review.user?.display_name || 'U').charAt(0)}
            </div>
          )}

          <div>
            <div className="flex items-center gap-2">
              <span className="font-medium text-gray-900">
                {review.user?.display_name || '익명'}
              </span>
              {review.is_verified_purchase && (
                <Badge variant="outline" className="text-xs border-green-300 text-green-600">
                  <CheckCircle className="h-3 w-3 mr-1" />
                  구매인증
                </Badge>
              )}
            </div>
            <div className="flex items-center gap-2 text-sm">
              <div className="flex items-center gap-0.5">
                {[1, 2, 3, 4, 5].map((star) => (
                  <Star
                    key={star}
                    className={cn(
                      'h-3.5 w-3.5',
                      star <= (review.rating || 0)
                        ? 'fill-yellow-400 text-yellow-400'
                        : 'fill-gray-200 text-gray-200'
                    )}
                  />
                ))}
              </div>
              <span className="text-gray-400">·</span>
              <span className="text-gray-400">
                {new Date(review.created_at).toLocaleDateString('ko-KR')}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Title */}
      {review.title && (
        <h4 className="font-medium text-gray-900 mb-2">{review.title}</h4>
      )}

      {/* Content */}
      <p className="text-gray-700 whitespace-pre-wrap">
        {showFullContent || !isLongContent
          ? review.content
          : `${review.content.slice(0, 200)}...`}
      </p>
      {isLongContent && (
        <button
          onClick={() => setShowFullContent(!showFullContent)}
          className="text-sm text-pink-600 hover:text-pink-700 mt-1 flex items-center gap-1"
        >
          {showFullContent ? '접기' : '더보기'}
          <ChevronDown className={cn('h-4 w-4', showFullContent && 'rotate-180')} />
        </button>
      )}

      {/* Images */}
      {review.images && review.images.length > 0 && (
        <div className="flex gap-2 mt-3 overflow-x-auto pb-2">
          {review.images.map((image, index) => (
            <button
              key={index}
              onClick={() => setSelectedImage(image)}
              className="flex-shrink-0 w-20 h-20 rounded-lg overflow-hidden bg-gray-100"
            >
              <img
                src={image}
                alt={`후기 이미지 ${index + 1}`}
                className="w-full h-full object-cover hover:opacity-90 transition-opacity"
              />
            </button>
          ))}
        </div>
      )}

      {/* Actions */}
      <div className="flex items-center justify-between mt-4 pt-3 border-t border-gray-100">
        <button
          onClick={handleHelpful}
          className={cn(
            'flex items-center gap-1.5 text-sm transition-colors',
            helpful ? 'text-pink-600' : 'text-gray-500 hover:text-pink-600'
          )}
        >
          <ThumbsUp className={cn('h-4 w-4', helpful && 'fill-pink-600')} />
          도움이 돼요 {helpfulCount > 0 && `(${helpfulCount})`}
        </button>
      </div>

      {/* Image Lightbox */}
      {selectedImage && (
        <div
          className="fixed inset-0 z-50 bg-black/90 flex items-center justify-center p-4"
          onClick={() => setSelectedImage(null)}
        >
          <img
            src={selectedImage}
            alt="후기 이미지"
            className="max-w-full max-h-full object-contain"
          />
          <button
            className="absolute top-4 right-4 text-white text-2xl"
            onClick={() => setSelectedImage(null)}
          >
            ×
          </button>
        </div>
      )}
    </article>
  )
}
