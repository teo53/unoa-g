import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/supabase_chat_repository.dart';
import '../data/repositories/supabase_funding_repository.dart';
import '../data/repositories/supabase_wallet_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/mock_chat_repository.dart';
import '../data/repositories/supabase_inbox_repository.dart';
import '../services/payment_service.dart';
import '../core/config/app_config.dart';
import 'auth_provider.dart';

/// Repository Providers for Dependency Injection
///
/// Use these providers to access repositories throughout the app.
/// This enables easy testing by allowing repository mocking.

// ============================================
// Chat Repository
// ============================================

/// Chat repository provider
final chatRepositoryProvider = Provider<SupabaseChatRepository>((ref) {
  return SupabaseChatRepository();
});

// ============================================
// Wallet Repository
// ============================================

/// Wallet repository provider
final walletRepositoryProvider = Provider<SupabaseWalletRepository>((ref) {
  return SupabaseWalletRepository();
});

/// Wallet interface for easier testing
abstract class IWalletRepository {
  Future<Wallet> getWallet();
  Stream<Wallet> watchWallet();
  Future<List<DtPackage>> getPackages();
  Future<Map<String, dynamic>> createCheckout(String packageId);
  Future<List<LedgerEntry>> getTransactionHistory({
    int limit = 50,
    int offset = 0,
    String? entryType,
  });
}

// ============================================
// Funding Repository
// ============================================

/// Funding repository provider
final fundingRepositoryProvider = Provider<SupabaseFundingRepository>((ref) {
  return SupabaseFundingRepository();
});

// ============================================
// Artist Inbox Repository
// ============================================

/// Artist inbox repository provider - switches between demo and production
final artistInboxRepositoryProvider = Provider<IArtistInboxRepository>((ref) {
  final authState = ref.watch(authProvider);
  final isDemoMode = authState is AuthDemoMode;
  if (isDemoMode || FeatureFlags.useMockRepositories) {
    return MockArtistInboxRepository();
  }
  return SupabaseInboxRepository();
});

// ============================================
// Environment-based Repository Switching
// ============================================

/// Feature flags for development/testing
class FeatureFlags {
  static bool get useMockRepositories {
    // Check environment variable or compile-time constant
    const useMock =
        bool.fromEnvironment('USE_MOCK_REPOSITORIES', defaultValue: false);
    return useMock;
  }

  static bool get enableDebugLogging {
    const debug = bool.fromEnvironment('DEBUG_LOGGING', defaultValue: false);
    return debug;
  }
}

// ============================================
// Utility Providers
// ============================================

/// Current user ID provider (from auth state)
final currentUserIdProvider = Provider<String?>((ref) {
  // This should be connected to auth provider
  // For now, returns null which triggers auth check
  return null;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return userId != null;
});

// ============================================
// Payment Service
// ============================================

/// Payment service provider - switches between demo and production
final paymentServiceProvider = Provider<IPaymentService>((ref) {
  final authState = ref.watch(authProvider);
  final isDemoMode = authState is AuthDemoMode;
  if (isDemoMode || AppConfig.isDevelopment) {
    return DemoPaymentService();
  }
  return PortOnePaymentService();
});
