'use client'

import { useState, useEffect } from 'react'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import { LANDING_DEFAULTS, type LandingContent } from '@/lib/config/landing-defaults'

const CACHE_KEY = 'unoa_landing_content'
const CACHE_TTL = 5 * 60 * 1000 // 5 minutes

interface CachedContent {
  data: LandingContent
  timestamp: number
}

function getCached(): LandingContent | null {
  if (typeof window === 'undefined') return null
  try {
    const raw = localStorage.getItem(CACHE_KEY)
    if (!raw) return null
    const cached: CachedContent = JSON.parse(raw)
    if (Date.now() - cached.timestamp > CACHE_TTL) {
      localStorage.removeItem(CACHE_KEY)
      return null
    }
    return cached.data
  } catch {
    return null
  }
}

function setCache(data: LandingContent) {
  if (typeof window === 'undefined') return
  try {
    const cached: CachedContent = { data, timestamp: Date.now() }
    localStorage.setItem(CACHE_KEY, JSON.stringify(cached))
  } catch {
    // localStorage full or unavailable - ignore
  }
}

/**
 * Fetches landing page content from Supabase.
 * Falls back to hardcoded defaults if unavailable.
 * Caches in localStorage with 5-min TTL.
 */
export function useLandingContent() {
  const [content, setContent] = useState<LandingContent>(LANDING_DEFAULTS)
  const [isLoading, setIsLoading] = useState(!DEMO_MODE)

  useEffect(() => {
    if (DEMO_MODE) {
      setContent(LANDING_DEFAULTS)
      setIsLoading(false)
      return
    }

    // Check cache first
    const cached = getCached()
    if (cached) {
      setContent(cached)
      setIsLoading(false)
      return
    }

    // Fetch from Supabase
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL
    const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
    if (!url || !key) {
      setIsLoading(false)
      return
    }

    fetch(`${url}/rest/v1/landing_content?id=eq.main&select=*`, {
      headers: {
        apikey: key,
        Authorization: `Bearer ${key}`,
      },
    })
      .then((res) => res.json())
      .then((rows) => {
        if (Array.isArray(rows) && rows.length > 0) {
          const row = rows[0] as LandingContent
          setContent(row)
          setCache(row)
        }
      })
      .catch(() => {
        // Silently fall back to defaults
      })
      .finally(() => setIsLoading(false))
  }, [])

  return { content, isLoading }
}

/**
 * Saves landing content to Supabase (for admin editor).
 * Uses upsert on the single 'main' row.
 */
export async function saveLandingContent(
  content: Partial<LandingContent>
): Promise<boolean> {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
  if (!url || !key) return false

  try {
    const res = await fetch(
      `${url}/rest/v1/landing_content?id=eq.main`,
      {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          apikey: key,
          Authorization: `Bearer ${key}`,
          Prefer: 'return=minimal',
        },
        body: JSON.stringify(content),
      }
    )

    if (res.ok) {
      // Invalidate cache
      if (typeof window !== 'undefined') {
        localStorage.removeItem(CACHE_KEY)
      }
      return true
    }
    return false
  } catch {
    return false
  }
}
