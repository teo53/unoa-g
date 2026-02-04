import { getMockCampaignIds } from '@/lib/mock/demo-data'
import AdminReviewForm from './admin-review-form'

interface PageProps {
  params: Promise<{ id: string }>
}

// Generate static params for static export
export function generateStaticParams() {
  return getMockCampaignIds().map((id) => ({ id }))
}

export default async function AdminReviewPage({ params }: PageProps) {
  const { id } = await params
  return <AdminReviewForm id={id} />
}
