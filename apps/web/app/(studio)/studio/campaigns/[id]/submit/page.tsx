import { getMockCampaignIds } from '@/lib/mock/demo-data'
import SubmitForm from './submit-form'

interface PageProps {
  params: Promise<{ id: string }>
}

// Generate static params for static export
export function generateStaticParams() {
  return getMockCampaignIds().map((id) => ({ id }))
}

export default async function SubmitCampaignPage({ params }: PageProps) {
  const { id } = await params
  return <SubmitForm id={id} />
}
