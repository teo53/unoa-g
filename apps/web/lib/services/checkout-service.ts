import { DEMO_MODE } from '@/lib/mock/demo-data'
import { createClient } from '@/lib/supabase/client'

export type DtCheckoutResult = {
  checkoutUrl: string
  purchaseId?: string
}

export async function createDtCheckout(packageId: string): Promise<DtCheckoutResult> {
  if (DEMO_MODE) {
    // Demo: do not call Edge Functions (static export safe)
    return {
      checkoutUrl: `https://pay.example.com/demo?product=dt&packageId=${encodeURIComponent(packageId)}`,
    }
  }

  const supabase = createClient()
  const { data, error } = await supabase.functions.invoke('payment-checkout', {
    body: {
      packageId,
      platform: 'web',
    },
  })

  if (error) {
    throw error
  }

  if (!data || typeof (data as any).checkoutUrl !== 'string') {
    throw new Error('Checkout URL was not returned from payment-checkout.')
  }

  return {
    checkoutUrl: (data as any).checkoutUrl,
    purchaseId: (data as any).purchaseId,
  }
}
