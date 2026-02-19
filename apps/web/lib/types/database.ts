// Supabase Database Types
// Auto-generate with: npx supabase gen types typescript --project-id YOUR_PROJECT_ID > lib/types/database.ts

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      funding_campaigns: {
        Row: {
          id: string
          creator_id: string
          slug: string
          title: string
          subtitle: string | null
          cover_image_url: string | null
          category: string | null
          status: 'draft' | 'submitted' | 'approved' | 'rejected' | 'active' | 'completed' | 'cancelled'
          goal_amount_dt: number
          current_amount_dt: number
          backer_count: number
          start_at: string | null
          end_at: string | null
          description_md: string | null
          description_html: string | null
          rejection_reason: string | null
          reviewed_by: string | null
          reviewed_at: string | null
          created_at: string
          updated_at: string
          submitted_at: string | null
          approved_at: string | null
          completed_at: string | null
        }
        Insert: {
          id?: string
          creator_id: string
          slug?: string
          title: string
          subtitle?: string | null
          cover_image_url?: string | null
          category?: string | null
          status?: 'draft' | 'submitted' | 'approved' | 'rejected' | 'active' | 'completed' | 'cancelled'
          goal_amount_dt?: number
          current_amount_dt?: number
          backer_count?: number
          start_at?: string | null
          end_at?: string | null
          description_md?: string | null
          description_html?: string | null
          rejection_reason?: string | null
          reviewed_by?: string | null
          reviewed_at?: string | null
          created_at?: string
          updated_at?: string
          submitted_at?: string | null
          approved_at?: string | null
          completed_at?: string | null
        }
        Update: {
          id?: string
          creator_id?: string
          slug?: string
          title?: string
          subtitle?: string | null
          cover_image_url?: string | null
          category?: string | null
          status?: 'draft' | 'submitted' | 'approved' | 'rejected' | 'active' | 'completed' | 'cancelled'
          goal_amount_dt?: number
          current_amount_dt?: number
          backer_count?: number
          start_at?: string | null
          end_at?: string | null
          description_md?: string | null
          description_html?: string | null
          rejection_reason?: string | null
          reviewed_by?: string | null
          reviewed_at?: string | null
          created_at?: string
          updated_at?: string
          submitted_at?: string | null
          approved_at?: string | null
          completed_at?: string | null
        }
      }
      funding_reward_tiers: {
        Row: {
          id: string
          campaign_id: string
          title: string
          description: string | null
          price_dt: number
          total_quantity: number | null
          remaining_quantity: number | null
          display_order: number
          is_active: boolean
          is_featured: boolean
          pledge_count: number
          estimated_delivery_at: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          campaign_id: string
          title: string
          description?: string | null
          price_dt: number
          total_quantity?: number | null
          remaining_quantity?: number | null
          display_order?: number
          is_active?: boolean
          is_featured?: boolean
          pledge_count?: number
          estimated_delivery_at?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          campaign_id?: string
          title?: string
          description?: string | null
          price_dt?: number
          total_quantity?: number | null
          remaining_quantity?: number | null
          display_order?: number
          is_active?: boolean
          is_featured?: boolean
          pledge_count?: number
          estimated_delivery_at?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      funding_pledges: {
        Row: {
          id: string
          campaign_id: string
          tier_id: string | null
          user_id: string
          amount_dt: number
          extra_support_dt: number
          total_amount_dt: number
          status: 'pending' | 'paid' | 'cancelled' | 'refunded'
          ledger_entry_id: string | null
          idempotency_key: string | null
          is_anonymous: boolean
          support_message: string | null
          created_at: string
          paid_at: string | null
          cancelled_at: string | null
          refunded_at: string | null
        }
        Insert: {
          id?: string
          campaign_id: string
          tier_id?: string | null
          user_id: string
          amount_dt: number
          extra_support_dt?: number
          status?: 'pending' | 'paid' | 'cancelled' | 'refunded'
          ledger_entry_id?: string | null
          idempotency_key?: string | null
          is_anonymous?: boolean
          support_message?: string | null
          created_at?: string
          paid_at?: string | null
          cancelled_at?: string | null
          refunded_at?: string | null
        }
        Update: {
          id?: string
          campaign_id?: string
          tier_id?: string | null
          user_id?: string
          amount_dt?: number
          extra_support_dt?: number
          status?: 'pending' | 'paid' | 'cancelled' | 'refunded'
          ledger_entry_id?: string | null
          idempotency_key?: string | null
          is_anonymous?: boolean
          support_message?: string | null
          created_at?: string
          paid_at?: string | null
          cancelled_at?: string | null
          refunded_at?: string | null
        }
      }
      funding_faq_items: {
        Row: {
          id: string
          campaign_id: string
          question: string
          answer: string
          display_order: number
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          campaign_id: string
          question: string
          answer: string
          display_order?: number
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          campaign_id?: string
          question?: string
          answer?: string
          display_order?: number
          created_at?: string
          updated_at?: string
        }
      }
      funding_updates: {
        Row: {
          id: string
          campaign_id: string
          title: string
          content_md: string
          content_html: string | null
          is_public: boolean
          view_count: number
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          campaign_id: string
          title: string
          content_md: string
          content_html?: string | null
          is_public?: boolean
          view_count?: number
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          campaign_id?: string
          title?: string
          content_md?: string
          content_html?: string | null
          is_public?: boolean
          view_count?: number
          created_at?: string
          updated_at?: string
        }
      }
      user_profiles: {
        Row: {
          id: string
          role: 'fan' | 'creator' | 'creator_manager' | 'admin'
          display_name: string | null
          avatar_url: string | null
          bio: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          role?: 'fan' | 'creator' | 'creator_manager' | 'admin'
          display_name?: string | null
          avatar_url?: string | null
          bio?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          role?: 'fan' | 'creator' | 'creator_manager' | 'admin'
          display_name?: string | null
          avatar_url?: string | null
          bio?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      wallets: {
        Row: {
          id: string
          user_id: string
          balance_dt: number
          lifetime_purchased_dt: number
          lifetime_spent_dt: number
          lifetime_earned_dt: number
          lifetime_refunded_dt: number
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          balance_dt?: number
          lifetime_purchased_dt?: number
          lifetime_spent_dt?: number
          lifetime_earned_dt?: number
          lifetime_refunded_dt?: number
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          balance_dt?: number
          lifetime_purchased_dt?: number
          lifetime_spent_dt?: number
          lifetime_earned_dt?: number
          lifetime_refunded_dt?: number
          created_at?: string
          updated_at?: string
        }
      }
      fan_ads: {
        Row: {
          id: string
          fan_user_id: string
          artist_channel_id: string
          title: string
          body: string | null
          image_url: string | null
          link_url: string | null
          link_type: 'internal' | 'external' | 'none'
          start_at: string
          end_at: string
          payment_amount_krw: number
          payment_status: 'pending' | 'paid' | 'refunded' | 'failed'
          status: 'pending_review' | 'approved' | 'rejected' | 'active' | 'completed' | 'cancelled'
          rejection_reason: string | null
          impressions: number
          clicks: number
          ops_banner_id: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          fan_user_id: string
          artist_channel_id: string
          title: string
          body?: string | null
          image_url?: string | null
          link_url?: string | null
          link_type?: 'internal' | 'external' | 'none'
          start_at: string
          end_at: string
          payment_amount_krw: number
          payment_status?: 'pending' | 'paid' | 'refunded' | 'failed'
          status?: 'pending_review' | 'approved' | 'rejected' | 'active' | 'completed' | 'cancelled'
          rejection_reason?: string | null
          impressions?: number
          clicks?: number
          ops_banner_id?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          fan_user_id?: string
          artist_channel_id?: string
          title?: string
          body?: string | null
          image_url?: string | null
          link_url?: string | null
          link_type?: 'internal' | 'external' | 'none'
          start_at?: string
          end_at?: string
          payment_amount_krw?: number
          payment_status?: 'pending' | 'paid' | 'refunded' | 'failed'
          status?: 'pending_review' | 'approved' | 'rejected' | 'active' | 'completed' | 'cancelled'
          rejection_reason?: string | null
          impressions?: number
          clicks?: number
          ops_banner_id?: string | null
          created_at?: string
          updated_at?: string
        }
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      is_admin: {
        Args: { p_user_id?: string }
        Returns: boolean
      }
      get_funding_percentage: {
        Args: { p_current: number; p_goal: number }
        Returns: number
      }
      is_campaign_fundable: {
        Args: { p_campaign_id: string }
        Returns: boolean
      }
      is_tier_available: {
        Args: { p_tier_id: string }
        Returns: boolean
      }
    }
    Enums: {
      [_ in never]: never
    }
  }
}

// Convenience types
export type Campaign = Database['public']['Tables']['funding_campaigns']['Row']
export type CampaignInsert = Database['public']['Tables']['funding_campaigns']['Insert']
export type CampaignUpdate = Database['public']['Tables']['funding_campaigns']['Update']

export type RewardTier = Database['public']['Tables']['funding_reward_tiers']['Row']
export type RewardTierInsert = Database['public']['Tables']['funding_reward_tiers']['Insert']
export type RewardTierUpdate = Database['public']['Tables']['funding_reward_tiers']['Update']

export type Pledge = Database['public']['Tables']['funding_pledges']['Row']
export type FaqItem = Database['public']['Tables']['funding_faq_items']['Row']
export type CampaignUpdate_ = Database['public']['Tables']['funding_updates']['Row']
export type UserProfile = Database['public']['Tables']['user_profiles']['Row']
export type Wallet = Database['public']['Tables']['wallets']['Row']

// Campaign with related data
export type CampaignWithTiers = Campaign & {
  funding_reward_tiers: RewardTier[]
}

export type CampaignWithCreator = Campaign & {
  creator: UserProfile
}

export type CampaignFull = Campaign & {
  funding_reward_tiers: RewardTier[]
  funding_faq_items: FaqItem[]
  creator: UserProfile
}

// ============================================
// Enhanced Types for Makestar/Tumblbug/Wadiz Style
// ============================================

// Gallery Image (Tumblbug style)
export interface GalleryImage {
  url: string
  caption?: string
  display_order: number
}

// Event Schedule (Makestar style)
export interface EventSchedule {
  sale_period?: { start: string; end: string }
  winner_announce?: string
  fansign_date?: string
  videocall_date?: string
  shipping_date?: string
  custom_events?: Array<{ label: string; date: string; description?: string }>
}

// Budget Item (Tumblbug style)
export interface BudgetItem {
  name: string
  amount: number
  percentage: number
  description?: string
}

export interface BudgetInfo {
  items: BudgetItem[]
  total: number
  currency: string
}

// Schedule Milestone (Tumblbug style)
export interface ScheduleMilestone {
  date: string
  milestone: string
  description?: string
  is_completed?: boolean
}

// Team Member (Tumblbug style)
export interface TeamMember {
  name: string
  role: string
  avatar_url?: string
  bio?: string
  links?: Array<{ type: string; url: string }>
}

export interface TeamInfo {
  members: TeamMember[]
  company_name?: string
  company_description?: string
}

// Stretch Goal (Tumblbug style)
export interface StretchGoal {
  amount_dt: number
  title: string
  description?: string
  is_reached: boolean
  reached_at?: string
}

// Benefit/Perk (Makestar style)
export interface Benefit {
  title: string
  description: string
  images?: string[]
  for_type: 'all' | 'winner' | 'videocall' | 'fansign'
}

// Notice Section
export interface Notice {
  title: string
  content_html: string
  display_order: number
}

// Member Option (Makestar style - for idol selection)
export interface MemberOption {
  member_name: string
  member_id: string
  avatar_url?: string
  additional_info?: string
}

// Included Item in Reward
export interface IncludedItem {
  name: string
  quantity: number
  description?: string
  image_url?: string
}

// Reward Badge Types
export type RewardBadgeType = 'recommended' | 'limited' | 'early_bird' | 'best' | 'new' | null

// ============================================
// Enhanced Reward Tier (Makestar/Tumblbug style)
// ============================================
export interface RewardTierEnhanced extends RewardTier {
  // Badges (Tumblbug style)
  badge_type?: RewardBadgeType
  badge_label?: string

  // Member Options (Makestar style)
  member_options: MemberOption[]
  has_member_selection: boolean

  // Included Items
  included_items: IncludedItem[]

  // Delivery Info
  shipping_info?: string

  // Images
  images: Array<{ url: string; caption?: string }>
}

// ============================================
// Enhanced Campaign (Makestar/Tumblbug style)
// ============================================
export interface CampaignEnhanced extends Campaign {
  // Gallery Images (Tumblbug style)
  gallery_images: GalleryImage[]

  // Event Schedule (Makestar style)
  event_schedule: EventSchedule

  // Related Products (Makestar style)
  related_campaign_ids: string[]

  // Sub-sections (Tumblbug 서브탭)
  budget_info: BudgetInfo
  schedule_info: ScheduleMilestone[]
  team_info: TeamInfo

  // Stretch Goals (Tumblbug style)
  stretch_goals: StretchGoal[]

  // Benefits/Perks (Makestar 특전)
  benefits: Benefit[]

  // Tab Configuration
  enabled_tabs: string[]

  // Notice/Caution sections
  notices: Notice[]

  // Joined data (optional)
  creator?: UserProfile
  reward_tiers?: RewardTierEnhanced[]
  faq_items?: FaqItem[]
  updates?: CampaignUpdate_[]
  related_campaigns?: CampaignEnhanced[]
}

// ============================================
// Comment System (Community)
// ============================================
export interface CampaignComment {
  id: string
  campaign_id: string
  user_id: string
  parent_id?: string
  content: string
  is_creator_reply: boolean
  is_pinned: boolean
  like_count: number
  created_at: string
  updated_at: string

  // Joined data
  user?: UserProfile
  replies?: CampaignComment[]
}

// ============================================
// Review System (Tumblbug style)
// ============================================
export interface CampaignReview {
  id: string
  campaign_id: string
  pledge_id?: string
  user_id: string
  rating: number
  title?: string
  content: string
  images: string[]
  is_verified_purchase: boolean
  helpful_count: number
  created_at: string

  // Joined data
  user?: UserProfile
}

// ============================================
// Waitlist (빈자리 알림)
// ============================================
export interface TierWaitlist {
  id: string
  tier_id: string
  user_id: string
  notified_at?: string
  created_at: string
}

// ============================================
// Platform Policies (Wadiz style)
// ============================================
export interface PolicyTOCItem {
  id: string
  title: string
  anchor: string
}

export interface PlatformPolicy {
  id: string
  slug: string
  category: 'general' | 'funding' | 'creator' | 'privacy' | 'advertising'
  title: string
  title_en?: string
  content_html: string
  version: string
  effective_at: string
  toc: PolicyTOCItem[]
  is_active: boolean
  is_required: boolean
  update_notes?: string
  previous_version_id?: string
  created_at: string
  updated_at: string
}

// ============================================
// Tab Types for Campaign Detail
// ============================================
export type CampaignTabType =
  | 'intro'
  | 'rewards'
  | 'updates'
  | 'faq'
  | 'community'
  | 'reviews'

export type IntroSubTabType =
  | 'intro'
  | 'budget'
  | 'schedule'
  | 'team'

// ============================================
// Default values for enhanced fields
// ============================================
export const DEFAULT_EVENT_SCHEDULE: EventSchedule = {}

export const DEFAULT_BUDGET_INFO: BudgetInfo = {
  items: [],
  total: 0,
  currency: 'KRW'
}

export const DEFAULT_TEAM_INFO: TeamInfo = {
  members: []
}

export function createDefaultEnhancedCampaign(base: Campaign): CampaignEnhanced {
  return {
    ...base,
    gallery_images: [],
    event_schedule: DEFAULT_EVENT_SCHEDULE,
    related_campaign_ids: [],
    budget_info: DEFAULT_BUDGET_INFO,
    schedule_info: [],
    team_info: DEFAULT_TEAM_INFO,
    stretch_goals: [],
    benefits: [],
    enabled_tabs: ['intro', 'rewards', 'updates', 'faq', 'community'],
    notices: []
  }
}

export function createDefaultEnhancedTier(base: RewardTier): RewardTierEnhanced {
  return {
    ...base,
    badge_type: null,
    badge_label: undefined,
    member_options: [],
    has_member_selection: false,
    included_items: [],
    shipping_info: undefined,
    images: []
  }
}
