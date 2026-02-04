import { mockCampaigns } from '@/lib/mock/demo-data'
import PrelaunchForm from './prelaunch-form'

interface PageProps {
  params: Promise<{ slug: string }>
}

// Generate static params for static export
export function generateStaticParams() {
  return mockCampaigns.map((campaign) => ({
    slug: campaign.slug,
  }))
}

export default async function PrelaunchPage({ params }: PageProps) {
  const { slug } = await params
  return <PrelaunchForm slug={slug} />
}
