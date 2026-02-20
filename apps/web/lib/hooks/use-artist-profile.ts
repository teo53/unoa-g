'use client'

import { useState, useEffect } from 'react'
import { DEMO_MODE } from '@/lib/mock/demo-data'

export interface ArtistProfile {
  id: string
  display_name: string
  avatar_url: string
  bio: string
  group_name: string | null
  follower_count: number
  is_verified: boolean
  social_links: {
    instagram?: string
    youtube?: string
    tiktok?: string
    twitter?: string
  }
  theme_color: string
}

const DEMO_ARTISTS: Record<string, ArtistProfile> = {
  'demo_creator_001': {
    id: 'demo_creator_001',
    display_name: '하늘달 (Starlight)',
    avatar_url: 'https://picsum.photos/seed/starlight/400',
    bio: '음악으로 세상을 밝히는 아티스트 하늘달입니다. 팬 여러분과 함께하는 매 순간이 소중해요.',
    group_name: null,
    follower_count: 12500,
    is_verified: true,
    social_links: {
      instagram: 'https://instagram.com/starlight_official',
      youtube: 'https://youtube.com/@starlight_music',
      twitter: 'https://twitter.com/starlight_twt',
    },
    theme_color: '#FF3B30',
  },
  'artist_2': {
    id: 'artist_2',
    display_name: '루나 (Luna)',
    avatar_url: 'https://picsum.photos/seed/luna/400',
    bio: 'K-POP 댄서 & 싱어. 매일 연습하고 팬들과 소통하는 게 행복해요!',
    group_name: 'STELLAR',
    follower_count: 8700,
    is_verified: true,
    social_links: {
      instagram: 'https://instagram.com/luna_stellar',
      tiktok: 'https://tiktok.com/@luna_dance',
    },
    theme_color: '#5856D6',
  },
}

export function useArtistProfile(artistId: string) {
  const [profile, setProfile] = useState<ArtistProfile | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (DEMO_MODE) {
      const demoProfile = DEMO_ARTISTS[artistId] ?? DEMO_ARTISTS['demo_creator_001']
      setProfile(demoProfile ? { ...demoProfile, id: artistId } : null)
      setIsLoading(false)
      return
    }

    const url = process.env.NEXT_PUBLIC_SUPABASE_URL
    const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
    if (!url || !key) {
      setError('Configuration missing')
      setIsLoading(false)
      return
    }

    fetch(`${url}/rest/v1/creator_profiles_public?or=(channel_id.eq.${artistId},user_id.eq.${artistId})&select=*`, {
      headers: {
        apikey: key,
        Authorization: `Bearer ${key}`,
      },
    })
      .then((res) => res.json())
      .then((rows) => {
        if (Array.isArray(rows) && rows.length > 0) {
          const raw = rows[0]
          const mapped: ArtistProfile = {
            id: raw.channel_id ?? raw.user_id ?? raw.id,
            display_name: raw.stage_name ?? 'Unknown',
            avatar_url: raw.profile_image_url ?? '',
            bio: raw.full_bio ?? raw.short_bio ?? '',
            group_name: null,
            follower_count: raw.total_subscribers ?? 0,
            is_verified: raw.verification_status === 'verified',
            social_links: raw.social_links ?? {},
            theme_color: '#FF3B30',
          }
          setProfile(mapped)
        } else {
          setError('Artist not found')
        }
      })
      .catch(() => {
        setError('Failed to load profile')
      })
      .finally(() => setIsLoading(false))
  }, [artistId])

  return { profile, isLoading, error }
}
