import FlagDetailClient from './flag-detail-client'

interface PageProps {
  params: Promise<{ id: string }>
}

// Static export: provide placeholder param for build (actual data loaded client-side)
export function generateStaticParams() {
  return [{ id: '_' }]
}

export default async function FlagDetailPage({ params }: PageProps) {
  const { id } = await params
  return <FlagDetailClient id={id} />
}
