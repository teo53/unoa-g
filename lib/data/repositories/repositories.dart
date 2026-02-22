/// Barrel export for all repositories
library repositories;

// Interfaces
export 'chat_repository.dart';

// Supabase implementations
export 'supabase_chat_repository.dart';
export 'supabase_inbox_repository.dart';
export 'supabase_profile_repository.dart';
export 'supabase_wallet_repository.dart';

// CRM
export 'crm_repository.dart';
export 'supabase_crm_repository.dart';
export 'mock_crm_repository.dart';

// Moments
export 'moments_repository.dart';
export 'supabase_moments_repository.dart';
export 'mock_moments_repository.dart';

// Challenges
export 'challenge_repository.dart';
export 'supabase_challenge_repository.dart';
export 'mock_challenge_repository.dart';

// Moderation
export 'supabase_moderation_repository.dart';

// Celebrations
export 'supabase_celebration_repository.dart';

// Agency
export 'supabase_agency_repository.dart';

// Settlement
export 'supabase_settlement_repository.dart';

// Auto Charge
export 'supabase_auto_charge_repository.dart';

// Creator Chat Operations
export 'supabase_creator_chat_repository.dart';
