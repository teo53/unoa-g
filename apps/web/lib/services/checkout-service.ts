import { DEMO_MODE } from '@/lib/mock/demo-data'
import { appConfig } from '@/lib/config/app-config'
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

  if (!appConfig.dtPurchaseEnabled) {
    throw new Error('결제가 현재 비활성화되어 있습니다.')
  }

  const supabase = createClient()
  const { data, error } = await supabase.functions.invoke('payment-checkout', {
    body: {
      packageId,
      platform: 'web',
    },
  })

  if (error) {
    const errorCode = (error as { context?: { json?: { errorCode?: string } } })
      .context?.json?.errorCode
    if (errorCode === 'PAYMENTS_DISABLED') {
      throw new Error('결제가 현재 비활성화되어 있습니다.')
    }
    if (errorCode === 'PAYMENT_PROVIDER_NOT_READY') {
      throw new Error('결제 서비스 준비 중입니다. 잠시 후 다시 시도해주세요.')
    }
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
