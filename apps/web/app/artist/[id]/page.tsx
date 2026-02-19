'use client'

import { useParams } from 'next/navigation'
import { useArtistProfile } from '@/lib/hooks/use-artist-profile'
import Link from 'next/link'

function formatFollowers(count: number): string {
  if (count >= 10000) return `${(count / 10000).toFixed(1)}만`
  if (count >= 1000) return `${(count / 1000).toFixed(1)}K`
  return count.toString()
}

export default function ArtistProfilePage() {
  const params = useParams()
  const artistId = params.id as string
  const { profile, isLoading, error } = useArtistProfile(artistId)

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-primary-500 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-gray-500 text-sm">프로필 로딩 중...</p>
        </div>
      </div>
    )
  }

  if (error || !profile) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center max-w-sm mx-4">
          <div className="w-20 h-20 bg-gray-200 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-10 h-10 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
          </div>
          <h2 className="text-lg font-semibold text-gray-900 mb-2">아티스트를 찾을 수 없습니다</h2>
          <p className="text-gray-500 text-sm mb-6">프로필이 존재하지 않거나 비공개 상태입니다.</p>
          <Link
            href="/"
            className="inline-block px-6 py-3 bg-gray-900 text-white rounded-xl hover:bg-gray-800 transition-colors text-sm font-medium"
          >
            홈으로 돌아가기
          </Link>
        </div>
      </div>
    )
  }

  const deepLink = `com.unoa.app://artist/${artistId}`
  const storeLink = 'https://unoa-app-demo.web.app' // fallback

  return (
    <div className="min-h-screen bg-gray-50">
      {/* App Download Banner */}
      <div className="bg-gray-900 text-white px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 bg-primary-500 rounded-lg flex items-center justify-center text-xs font-bold">
            U
          </div>
          <div>
            <p className="text-sm font-medium">UNO A</p>
            <p className="text-xs text-gray-400">앱에서 더 많은 콘텐츠를 만나보세요</p>
          </div>
        </div>
        <a
          href={deepLink}
          onClick={(e) => {
            // Try deep link first, fallback to store
            setTimeout(() => {
              window.location.href = storeLink
            }, 1500)
          }}
          className="px-4 py-2 bg-primary-500 text-white text-sm font-medium rounded-lg hover:bg-primary-600 transition-colors"
        >
          앱에서 보기
        </a>
      </div>

      {/* Cover Image */}
      <div className="relative h-64 bg-gradient-to-b from-primary-500 to-primary-600 overflow-hidden">
        {profile.avatar_url && (
          <img
            src={profile.avatar_url}
            alt={profile.display_name}
            className="w-full h-full object-cover opacity-60"
          />
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent" />

        {/* Profile Info Overlay */}
        <div className="absolute bottom-6 left-6 right-6">
          <div className="flex items-end gap-4">
            <div className="w-20 h-20 rounded-full border-3 border-white overflow-hidden bg-gray-200 flex-shrink-0">
              {profile.avatar_url ? (
                <img
                  src={profile.avatar_url}
                  alt={profile.display_name}
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center">
                  <svg className="w-10 h-10 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                </div>
              )}
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 mb-1">
                <h1 className="text-2xl font-bold text-white truncate">
                  {profile.display_name}
                </h1>
                {profile.is_verified && (
                  <span className="flex-shrink-0 w-5 h-5 bg-blue-500 rounded-full flex items-center justify-center">
                    <svg className="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                    </svg>
                  </span>
                )}
              </div>
              {profile.group_name && (
                <p className="text-sm text-white/80">{profile.group_name}</p>
              )}
              <p className="text-sm text-white/70">
                팬 {formatFollowers(profile.follower_count)}명
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-lg mx-auto px-4 py-6">
        {/* Bio */}
        {profile.bio && (
          <div className="bg-white rounded-2xl p-5 shadow-sm mb-4">
            <h3 className="text-sm font-semibold text-gray-500 mb-2">소개</h3>
            <p className="text-gray-800 text-sm leading-relaxed">{profile.bio}</p>
          </div>
        )}

        {/* Social Links */}
        {profile.social_links && Object.keys(profile.social_links).length > 0 && (
          <div className="bg-white rounded-2xl p-5 shadow-sm mb-4">
            <h3 className="text-sm font-semibold text-gray-500 mb-3">소셜 미디어</h3>
            <div className="flex flex-wrap gap-3">
              {profile.social_links.instagram && (
                <a
                  href={profile.social_links.instagram}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-purple-500 to-pink-500 text-white rounded-lg text-sm font-medium hover:opacity-90 transition-opacity"
                >
                  Instagram
                </a>
              )}
              {profile.social_links.youtube && (
                <a
                  href={profile.social_links.youtube}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg text-sm font-medium hover:opacity-90 transition-opacity"
                >
                  YouTube
                </a>
              )}
              {profile.social_links.twitter && (
                <a
                  href={profile.social_links.twitter}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-2 px-4 py-2 bg-gray-900 text-white rounded-lg text-sm font-medium hover:opacity-90 transition-opacity"
                >
                  X (Twitter)
                </a>
              )}
              {profile.social_links.tiktok && (
                <a
                  href={profile.social_links.tiktok}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-2 px-4 py-2 bg-gray-900 text-white rounded-lg text-sm font-medium hover:opacity-90 transition-opacity"
                >
                  TikTok
                </a>
              )}
            </div>
          </div>
        )}

        {/* CTA */}
        <div className="bg-gradient-to-r from-primary-500 to-pink-500 rounded-2xl p-6 text-center text-white">
          <h3 className="text-lg font-bold mb-2">UNO A에서 소통하기</h3>
          <p className="text-sm text-white/80 mb-4">
            프라이빗 메시지로 {profile.display_name}님과 1:1 소통하세요
          </p>
          <a
            href={deepLink}
            className="inline-block px-8 py-3 bg-white text-gray-900 rounded-xl font-semibold text-sm hover:bg-gray-100 transition-colors"
          >
            앱에서 보기
          </a>
        </div>

        {/* Footer */}
        <div className="text-center mt-8 pb-8">
          <Link href="/" className="text-sm text-gray-400 hover:text-gray-600 transition-colors">
            UNO A 홈으로
          </Link>
        </div>
      </div>
    </div>
  )
}
