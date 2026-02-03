import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/supabase_chat_repository.dart';
import '../data/repositories/supabase_wallet_repository.dart';

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

/// Chat repository interface for easier testing
abstract class IChatRepository {
  Stream<List<dynamic>> watchMessages(String channelId);
  Future<void> sendMessage({
    required String channelId,
    required String content,
    String? mediaUrl,
    String? mediaType,
    String? replyToId,
  });
  Future<void> deleteMessage(String messageId);
  Future<void> editMessage(String messageId, String newContent);
  Future<void> reactToMessage(String messageId, String emoji);
  Future<void> removeReaction(String messageId, String emoji);
}

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
// Environment-based Repository Switching
// ============================================

/// Feature flags for development/testing
class FeatureFlags {
  static bool get useMockRepositories {
    // Check environment variable or compile-time constant
    const useMock = bool.fromEnvironment('USE_MOCK_REPOSITORIES', defaultValue: false);
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
