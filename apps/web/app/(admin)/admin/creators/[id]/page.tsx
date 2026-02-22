import CreatorDetailClient from './creator-detail-client'

interface PageProps {
  params: Promise<{ id: string }>
}

// Required for `output: 'export'` — only pre-generated paths are valid.
export const dynamicParams = false

export function generateStaticParams() {
  return [{ id: '_' }]
}

export default async function CreatorDetailPage({ params }: PageProps) {
  const { id } = await params
  return <CreatorDetailClient id={id} />
}
