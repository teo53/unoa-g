import BannerDetailClient from './banner-detail-client'

interface PageProps {
  params: Promise<{ id: string }>
}

// Required for `output: 'export'` — only pre-generated paths are valid.
export const dynamicParams = false

// Static export: provide placeholder param for build (actual data loaded client-side)
export function generateStaticParams() {
  return [{ id: '_' }]
}

export default async function BannerDetailPage({ params }: PageProps) {
  const { id } = await params
  return <BannerDetailClient id={id} />
}
