import { getMockCampaignIds } from '@/lib/mock/demo-data'
import AdminReviewForm from './admin-review-form'

interface PageProps {
  params: Promise<{ id: string }>
}

// Required for `output: 'export'` — only pre-generated paths are valid.
export const dynamicParams = false

export function generateStaticParams() {
  return getMockCampaignIds().map((id) => ({ id }))
}

export default async function AdminReviewPage({ params }: PageProps) {
  const { id } = await params
  return <AdminReviewForm id={id} />
}
