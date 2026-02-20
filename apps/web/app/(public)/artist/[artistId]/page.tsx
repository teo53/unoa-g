import { notFound } from 'next/navigation'
import Image from 'next/image'
import Link from 'next/link'
import type { Metadata } from 'next'
import { DEMO_MODE, mockCreators } from '@/lib/mock/demo-data'

interface PageProps {
  params: Promise<{ artistId: string }>
}

interface ArtistData {
  id: string // canonical channel_id
  artist_user_id: string
  display_name: string
  avatar_url: string | null
  banner_url: string | null
  bio: string | null
  subscriber_count: number
  is_verified: boolean
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
const IS_DEMO_BUILD = process.env.NEXT_PUBLIC_DEMO_BUILD === 'true'

async function getArtistData(artistId: string): Promise<ArtistData | null> {
  const decoded = decodeURIComponent(artistId)

  // Demo mode: keep local mock behavior
  if (DEMO_MODE) {
    const creator = mockCreators[decoded]
    if (!creator) return null
    return {
      id: creator.id,
      artist_user_id: creator.id,
      display_name: creator.display_name ?? decoded,
      avatar_url: creator.avatar_url ?? null,
      banner_url: null,
      bio: creator.bio ?? null,
      subscriber_count: 0,
      is_verified: false,
    }
  }

  // channel_id contract and legacy creator/user id fallback are both UUID-based
  if (!UUID_RE.test(decoded)) return null

  const { createClient } = await import('@/lib/supabase/server')
  const supabase = await createClient()

  // 1) channel_id direct lookup
  const { data: directChannel } = await (supabase as any)
    .from('channels')
    .select('id, artist_id, name, avatar_url')
    .eq('id', decoded)
    .maybeSingle()

  // 2) one-release fallback: creator/user id -> channels.artist_id
  const channel = directChannel ?? (await (supabase as any)
    .from('channels')
    .select('id, artist_id, name, avatar_url')
    .eq('artist_id', decoded)
    .maybeSingle()).data

  if (!channel) return null

  const { data: creatorProfile } = await (supabase as any)
    .from('creator_profiles')
    .select('user_id, display_name, avatar_url, banner_url, bio, subscriber_count, is_verified')
    .eq('user_id', channel.artist_id)
    .maybeSingle()

  return {
    id: channel.id,
    artist_user_id: channel.artist_id,
    display_name: (creatorProfile?.display_name as string | null) ?? (channel.name as string | null) ?? channel.id,
    avatar_url: (creatorProfile?.avatar_url as string | null) ?? (channel.avatar_url as string | null) ?? null,
    banner_url: (creatorProfile?.banner_url as string | null) ?? null,
    bio: (creatorProfile?.bio as string | null) ?? null,
    subscriber_count: (creatorProfile?.subscriber_count as number | null) ?? 0,
    is_verified: (creatorProfile?.is_verified as boolean | null) ?? false,
  }
}

export async function generateStaticParams() {
  if (DEMO_MODE || IS_DEMO_BUILD) {
    return Object.keys(mockCreators).map((id) => ({ artistId: id }))
  }
  return []
}

export const revalidate = 3600

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { artistId } = await params
  const artist = await getArtistData(artistId)

  if (!artist) {
    return { title: '아티스트를 찾을 수 없습니다 — UNO A' }
  }

  const description = artist.bio ?? `${artist.display_name}의 UNO A 프로필`

  return {
    title: `${artist.display_name} — UNO A`,
    description,
    openGraph: {
      title: `${artist.display_name} — UNO A`,
      description,
      images: artist.avatar_url ? [{ url: artist.avatar_url, width: 400, height: 400 }] : [],
      type: 'profile',
    },
    twitter: {
      card: 'summary',
      title: `${artist.display_name} — UNO A`,
      description,
      images: artist.avatar_url ? [artist.avatar_url] : [],
    },
  }
}

export default async function ArtistProfilePage({ params }: PageProps) {
  const { artistId } = await params
  const artist = await getArtistData(artistId)

  if (!artist) {
    notFound()
  }

  const appDeepLink = `unoa://artist/${encodeURIComponent(artist.id)}`

  return (
    <main className="min-h-screen bg-white">
      <div className="relative h-48 overflow-hidden bg-gradient-to-b from-red-500 to-red-700">
        {artist.banner_url && (
          <Image
            src={artist.banner_url}
            alt={`${artist.display_name} 배너`}
            fill
            className="object-cover"
            priority
          />
        )}
      </div>

      <div className="mx-auto max-w-xl px-6">
        <div className="relative mb-4 -mt-16">
          <div className="h-28 w-28 overflow-hidden rounded-full border-4 border-white bg-gray-100 shadow-md">
            {artist.avatar_url ? (
              <Image
                src={artist.avatar_url}
                alt={artist.display_name}
                width={112}
                height={112}
                className="h-full w-full object-cover"
              />
            ) : (
              <div className="flex h-full w-full items-center justify-center bg-red-100">
                <span className="text-3xl text-red-400">🎤</span>
              </div>
            )}
          </div>
        </div>

        <div className="mb-2 flex items-center gap-2">
          <h1 className="text-2xl font-bold text-gray-900">{artist.display_name}</h1>
          {artist.is_verified && <span className="rounded-full bg-red-500 px-2 py-0.5 text-sm text-white">인증</span>}
        </div>

        {artist.subscriber_count > 0 && (
          <p className="mb-3 text-sm text-gray-500">구독자 {artist.subscriber_count.toLocaleString('ko-KR')}명</p>
        )}

        {artist.bio && <p className="mb-6 whitespace-pre-line text-sm leading-relaxed text-gray-700">{artist.bio}</p>}

        <div className="mb-10 flex flex-col gap-3">
          <a
            href={appDeepLink}
            className="block rounded-xl bg-red-500 py-3.5 text-center font-semibold text-white transition-colors hover:bg-red-600"
          >
            앱에서 구독하기
          </a>
          <Link
            href="/"
            className="block rounded-xl border border-gray-200 py-3.5 text-center text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50"
          >
            UNO A 앱 다운로드
          </Link>
        </div>

        <p className="pb-8 text-center text-xs text-gray-400">이 페이지는 UNO A 앱에서 더 풍부하게 즐길 수 있어요.</p>
      </div>
    </main>
  )
}
