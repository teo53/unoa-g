import CreatorDetailClient from './creator-detail-client'

interface PageProps {
  params: Promise<{ id: string }>
}

export function generateStaticParams() {
  return [{ id: '_' }]
}

export default async function CreatorDetailPage({ params }: PageProps) {
  const { id } = await params
  return <CreatorDetailClient id={id} />
}
