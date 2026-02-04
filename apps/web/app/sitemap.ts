import { mockCampaigns } from '@/lib/mock/demo-data'
import type { MetadataRoute } from 'next'

// Required for static export
export const dynamic = 'force-static'

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = process.env.NEXT_PUBLIC_APP_URL || 'https://unoa-demo.web.app'

  // For static export, we can only use demo data
  const campaignUrls: MetadataRoute.Sitemap = mockCampaigns.map((campaign) => ({
    url: `${baseUrl}/p/${campaign.slug}`,
    lastModified: new Date(campaign.updated_at),
    changeFrequency: 'daily' as const,
    priority: 0.8,
  }))

  return [
    {
      url: baseUrl,
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 1,
    },
    {
      url: `${baseUrl}/funding`,
      lastModified: new Date(),
      changeFrequency: 'hourly',
      priority: 0.9,
    },
    ...campaignUrls,
  ]
}
