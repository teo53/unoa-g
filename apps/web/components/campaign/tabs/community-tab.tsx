'use client'

import { useState } from 'react'
import { CampaignComment } from '@/lib/types/database'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
  MessageCircle,
  Heart,
  Reply,
  MoreHorizontal,
  Pin,
  Send,
  ChevronDown,
  ChevronUp
} from 'lucide-react'
import { cn } from '@/lib/utils'

interface CommunityTabProps {
  comments: CampaignComment[]
  onAddComment?: (content: string, parentId?: string) => void
  currentUserId?: string
}

export function CommunityTab({ comments, onAddComment, currentUserId }: CommunityTabProps) {
  const [newComment, setNewComment] = useState('')
  const [replyingTo, setReplyingTo] = useState<string | null>(null)
  const [replyContent, setReplyContent] = useState('')
  const [sortBy, setSortBy] = useState<'latest' | 'popular'>('latest')
  const [expandedReplies, setExpandedReplies] = useState<Set<string>>(new Set())

  // Separate root comments and replies
  const rootComments = comments.filter(c => !c.parent_id)
  const repliesMap = new Map<string, CampaignComment[]>()
  comments.filter(c => c.parent_id).forEach(reply => {
    const existing = repliesMap.get(reply.parent_id!) || []
    repliesMap.set(reply.parent_id!, [...existing, reply])
  })

  // Sort root comments
  const sortedComments = [...rootComments].sort((a, b) => {
    if (a.is_pinned && !b.is_pinned) return -1
    if (!a.is_pinned && b.is_pinned) return 1

    if (sortBy === 'popular') {
      return b.like_count - a.like_count
    }
    return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  })

  const toggleReplies = (commentId: string) => {
    setExpandedReplies(prev => {
      const newSet = new Set(prev)
      if (newSet.has(commentId)) {
        newSet.delete(commentId)
      } else {
        newSet.add(commentId)
      }
      return newSet
    })
  }

  const handleSubmitComment = () => {
    if (newComment.trim() && onAddComment) {
      onAddComment(newComment.trim())
      setNewComment('')
    }
  }

  const handleSubmitReply = (parentId: string) => {
    if (replyContent.trim() && onAddComment) {
      onAddComment(replyContent.trim(), parentId)
      setReplyContent('')
      setReplyingTo(null)
    }
  }

  if (comments.length === 0 && !onAddComment) {
    return (
      <div className="text-center py-12">
        <MessageCircle className="h-12 w-12 text-gray-300 mx-auto mb-4" />
        <p className="text-gray-500">아직 댓글이 없습니다.</p>
        <p className="text-sm text-gray-400 mt-1">
          첫 번째 댓글을 남겨보세요!
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Comment Form */}
      <div className="bg-white border border-gray-200 rounded-xl p-4">
        <div className="flex gap-3">
          <div className="w-10 h-10 rounded-full bg-gradient-to-br from-pink-400 to-purple-400 flex items-center justify-center text-white font-medium flex-shrink-0">
            U
          </div>
          <div className="flex-1">
            <textarea
              value={newComment}
              onChange={(e) => setNewComment(e.target.value)}
              placeholder="응원의 메시지를 남겨주세요!"
              className="w-full border border-gray-200 rounded-lg p-3 text-sm resize-none focus:outline-none focus:ring-2 focus:ring-pink-200 focus:border-pink-300"
              rows={3}
            />
            <div className="flex justify-end mt-2">
              <Button
                onClick={handleSubmitComment}
                disabled={!newComment.trim()}
                size="sm"
                className="bg-pink-500 hover:bg-pink-600"
              >
                <Send className="h-4 w-4 mr-1" />
                댓글 작성
              </Button>
            </div>
          </div>
        </div>
      </div>

      {/* Sort & Stats */}
      <div className="flex items-center justify-between">
        <span className="text-sm text-gray-500">
          댓글 <span className="font-medium text-gray-900">{comments.length}</span>개
        </span>
        <div className="flex gap-1 bg-gray-100 rounded-lg p-1">
          <button
            onClick={() => setSortBy('latest')}
            className={cn(
              'px-3 py-1 text-sm rounded-md transition-colors',
              sortBy === 'latest'
                ? 'bg-white text-gray-900 shadow-sm'
                : 'text-gray-500 hover:text-gray-700'
            )}
          >
            최신순
          </button>
          <button
            onClick={() => setSortBy('popular')}
            className={cn(
              'px-3 py-1 text-sm rounded-md transition-colors',
              sortBy === 'popular'
                ? 'bg-white text-gray-900 shadow-sm'
                : 'text-gray-500 hover:text-gray-700'
            )}
          >
            인기순
          </button>
        </div>
      </div>

      {/* Comments List */}
      <div className="space-y-4">
        {sortedComments.map((comment) => {
          const replies = repliesMap.get(comment.id) || []
          const isExpanded = expandedReplies.has(comment.id)
          const isReplying = replyingTo === comment.id

          return (
            <div key={comment.id} className="space-y-2">
              {/* Main Comment */}
              <CommentItem
                comment={comment}
                onReply={() => setReplyingTo(comment.id)}
                isOwn={comment.user_id === currentUserId}
              />

              {/* Replies */}
              {replies.length > 0 && (
                <div className="ml-12">
                  <button
                    onClick={() => toggleReplies(comment.id)}
                    className="flex items-center gap-1 text-sm text-pink-600 hover:text-pink-700 mb-2"
                  >
                    {isExpanded ? (
                      <ChevronUp className="h-4 w-4" />
                    ) : (
                      <ChevronDown className="h-4 w-4" />
                    )}
                    답글 {replies.length}개
                  </button>

                  {isExpanded && (
                    <div className="space-y-2 border-l-2 border-gray-100 pl-4">
                      {replies.map((reply) => (
                        <CommentItem
                          key={reply.id}
                          comment={reply}
                          isReply
                          isOwn={reply.user_id === currentUserId}
                        />
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* Reply Form */}
              {isReplying && (
                <div className="ml-12 mt-2">
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={replyContent}
                      onChange={(e) => setReplyContent(e.target.value)}
                      placeholder="답글을 입력하세요..."
                      className="flex-1 border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-pink-200"
                      onKeyPress={(e) => {
                        if (e.key === 'Enter' && !e.shiftKey) {
                          handleSubmitReply(comment.id)
                        }
                      }}
                    />
                    <Button
                      size="sm"
                      onClick={() => handleSubmitReply(comment.id)}
                      disabled={!replyContent.trim()}
                      className="bg-pink-500 hover:bg-pink-600"
                    >
                      등록
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      onClick={() => {
                        setReplyingTo(null)
                        setReplyContent('')
                      }}
                    >
                      취소
                    </Button>
                  </div>
                </div>
              )}
            </div>
          )
        })}
      </div>
    </div>
  )
}

// Comment Item Component
interface CommentItemProps {
  comment: CampaignComment
  onReply?: () => void
  isReply?: boolean
  isOwn?: boolean
}

function CommentItem({ comment, onReply, isReply, isOwn }: CommentItemProps) {
  const [liked, setLiked] = useState(false)
  const [likeCount, setLikeCount] = useState(comment.like_count)

  const handleLike = () => {
    setLiked(!liked)
    setLikeCount(prev => liked ? prev - 1 : prev + 1)
  }

  return (
    <div className={cn(
      'bg-white rounded-xl p-4',
      !isReply && 'border border-gray-200',
      comment.is_pinned && 'ring-2 ring-pink-200 border-pink-200'
    )}>
      {/* Header */}
      <div className="flex items-start justify-between mb-2">
        <div className="flex items-center gap-2">
          {/* Avatar */}
          {comment.user?.avatar_url ? (
            <img
              src={comment.user.avatar_url}
              alt=""
              className={cn(
                'rounded-full object-cover',
                isReply ? 'w-7 h-7' : 'w-9 h-9'
              )}
            />
          ) : (
            <div className={cn(
              'rounded-full bg-gradient-to-br from-pink-400 to-purple-400 flex items-center justify-center text-white font-medium',
              isReply ? 'w-7 h-7 text-xs' : 'w-9 h-9 text-sm'
            )}>
              {(comment.user?.display_name || 'U').charAt(0)}
            </div>
          )}

          <div>
            <div className="flex items-center gap-2">
              <span className={cn(
                'font-medium text-gray-900',
                isReply && 'text-sm'
              )}>
                {comment.user?.display_name || '익명'}
              </span>
              {comment.is_creator_reply && (
                <Badge className="bg-pink-500 text-white text-xs">
                  크리에이터
                </Badge>
              )}
              {comment.is_pinned && (
                <Badge variant="outline" className="text-xs border-pink-300 text-pink-600">
                  <Pin className="h-3 w-3 mr-1" />
                  고정
                </Badge>
              )}
            </div>
            <span className="text-xs text-gray-400">
              {formatTimeAgo(comment.created_at)}
            </span>
          </div>
        </div>

        <button className="p-1 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-100">
          <MoreHorizontal className="h-4 w-4" />
        </button>
      </div>

      {/* Content */}
      <p className={cn(
        'text-gray-700 whitespace-pre-wrap',
        isReply ? 'text-sm' : 'text-base'
      )}>
        {comment.content}
      </p>

      {/* Actions */}
      <div className="flex items-center gap-4 mt-3">
        <button
          onClick={handleLike}
          className={cn(
            'flex items-center gap-1 text-sm transition-colors',
            liked ? 'text-pink-500' : 'text-gray-400 hover:text-pink-500'
          )}
        >
          <Heart className={cn('h-4 w-4', liked && 'fill-pink-500')} />
          <span>{likeCount > 0 && likeCount}</span>
        </button>

        {!isReply && onReply && (
          <button
            onClick={onReply}
            className="flex items-center gap-1 text-sm text-gray-400 hover:text-gray-600 transition-colors"
          >
            <Reply className="h-4 w-4" />
            답글
          </button>
        )}
      </div>
    </div>
  )
}

// Helper function
function formatTimeAgo(dateString: string): string {
  const date = new Date(dateString)
  const now = new Date()
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000)

  if (diffInSeconds < 60) return '방금 전'
  if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}분 전`
  if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}시간 전`
  if (diffInSeconds < 604800) return `${Math.floor(diffInSeconds / 86400)}일 전`

  return date.toLocaleDateString('ko-KR', {
    month: 'long',
    day: 'numeric'
  })
}
