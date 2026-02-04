import { getMockCampaignIds } from '@/lib/mock/demo-data'
import EditForm from './edit-form'

interface PageProps {
  params: Promise<{ id: string }>
}

// Generate static params for static export
export function generateStaticParams() {
  return getMockCampaignIds().map((id) => ({ id }))
}

export default async function EditCampaignPage({ params }: PageProps) {
  const { id } = await params
  return <EditForm id={id} />
}
