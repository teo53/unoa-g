import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../config/demo_config.dart';
import '../../data/models/user.dart';

/// Demo Mode Service
///
/// Centralized service for managing demo mode state and data.
/// Provides demo users, mock data generation, and demo state management.
class DemoModeService {
  DemoModeService._();

  static final DemoModeService _instance = DemoModeService._();
  static DemoModeService get instance => _instance;

  // ============================================================
  // Demo Mode State
  // ============================================================

  bool _isInDemoMode = false;
  bool _isCreatorMode = false;

  /// Check if currently in demo mode
  bool get isInDemoMode => _isInDemoMode;

  /// Check if in creator demo mode
  bool get isCreatorMode => _isCreatorMode && _isInDemoMode;

  /// Check if in fan demo mode
  bool get isFanMode => !_isCreatorMode && _isInDemoMode;

  /// Check if demo mode is available
  bool get isDemoModeAvailable => AppConfig.enableDemoMode;

  // ============================================================
  // Demo Mode Control
  // ============================================================

  /// Enter demo mode
  void enterDemoMode({bool asCreator = false}) {
    if (!isDemoModeAvailable) return;
    _isInDemoMode = true;
    _isCreatorMode = asCreator;
  }

  /// Exit demo mode
  void exitDemoMode() {
    _isInDemoMode = false;
    _isCreatorMode = false;
  }

  /// Toggle between creator and fan mode
  void toggleMode() {
    if (_isInDemoMode) {
      _isCreatorMode = !_isCreatorMode;
    }
  }

  // ============================================================
  // Demo User Profiles
  // ============================================================

  /// Get demo creator profile
  UserAuthProfile get demoCreatorProfile => UserAuthProfile(
        id: DemoConfig.demoCreatorId,
        role: 'creator',
        displayName: DemoConfig.demoCreatorName,
        avatarUrl: DemoConfig.demoCreatorAvatarUrl,
        bio: DemoConfig.demoCreatorBio,
        createdAt:
            DateTime.now().subtract(Duration(days: DemoConfig.demoAccountCreatedDaysAgo)),
      );

  /// Get demo fan profile
  UserAuthProfile get demoFanProfile => UserAuthProfile(
        id: DemoConfig.demoFanId,
        role: 'fan',
        displayName: DemoConfig.demoFanName,
        avatarUrl: null,
        bio: DemoConfig.demoFanBio,
        createdAt: DateTime.now(),
      );

  /// Get current demo profile based on mode
  UserAuthProfile? get currentDemoProfile {
    if (!_isInDemoMode) return null;
    return _isCreatorMode ? demoCreatorProfile : demoFanProfile;
  }

  // ============================================================
  // Demo Data Generators
  // ============================================================

  /// Generate demo avatar URL
  String generateAvatarUrl(String seed, {int size = 200}) {
    return DemoConfig.avatarUrl(seed, size: size);
  }

  /// Generate demo banner URL
  String generateBannerUrl(String seed, {int width = 400, int height = 200}) {
    return DemoConfig.bannerUrl(seed, width: width, height: height);
  }

  /// Get random artist avatar URL
  String getRandomArtistAvatar(int index) {
    final seed = DemoConfig.artistAvatarSeeds[
        index % DemoConfig.artistAvatarSeeds.length];
    return generateAvatarUrl(seed);
  }

  /// Get random fan avatar URL
  String getRandomFanAvatar(int index) {
    final seed =
        DemoConfig.fanAvatarSeeds[index % DemoConfig.fanAvatarSeeds.length];
    return generateAvatarUrl(seed);
  }

  // ============================================================
  // Demo Statistics
  // ============================================================

  /// Get demo dashboard statistics
  Map<String, int> get demoDashboardStats => {
        'subscribers': DemoConfig.demoSubscriberCount,
        'totalMessages': DemoConfig.demoTotalMessages,
        'todayNewSubscribers': DemoConfig.demoTodayNewSubscribers,
        'todayMessages': DemoConfig.demoTodayMessages,
        'todayHearts': DemoConfig.demoTodayHearts,
        'monthlyRevenue': DemoConfig.demoMonthlyRevenue,
      };

  // ============================================================
  // Demo Wallet
  // ============================================================

  int _demoDtBalance = DemoConfig.initialDtBalance;
  int _demoStarBalance = DemoConfig.initialStarBalance;

  /// Get current demo DT balance
  int get demoDtBalance => _demoDtBalance;

  /// Get current demo Star balance
  int get demoStarBalance => _demoStarBalance;

  /// Add DT to demo wallet
  void addDemoDt(int amount) {
    _demoDtBalance += amount;
  }

  /// Spend DT from demo wallet
  bool spendDemoDt(int amount) {
    if (_demoDtBalance >= amount) {
      _demoDtBalance -= amount;
      return true;
    }
    return false;
  }

  /// Add Stars to demo wallet
  void addDemoStars(int amount) {
    _demoStarBalance += amount;
  }

  /// Spend Stars from demo wallet
  bool spendDemoStars(int amount) {
    if (_demoStarBalance >= amount) {
      _demoStarBalance -= amount;
      return true;
    }
    return false;
  }

  /// Reset demo wallet to initial values
  void resetDemoWallet() {
    _demoDtBalance = DemoConfig.initialDtBalance;
    _demoStarBalance = DemoConfig.initialStarBalance;
  }

  // ============================================================
  // Demo Messages
  // ============================================================

  /// Get sample broadcast message
  String getSampleBroadcast(int index) {
    return DemoConfig.sampleBroadcastMessages[
        index % DemoConfig.sampleBroadcastMessages.length];
  }

  /// Get sample fan reply
  String getSampleFanReply(int index) {
    return DemoConfig
        .sampleFanReplies[index % DemoConfig.sampleFanReplies.length];
  }

  // ============================================================
  // Reset
  // ============================================================

  /// Reset all demo state
  void reset() {
    exitDemoMode();
    resetDemoWallet();
  }
}

// ============================================================
// Riverpod Providers
// ============================================================

/// Demo mode service provider
final demoModeServiceProvider = Provider<DemoModeService>((ref) {
  return DemoModeService.instance;
});

/// Is demo mode active provider
final isDemoModeActiveProvider = Provider<bool>((ref) {
  return DemoModeService.instance.isInDemoMode;
});

/// Is creator demo mode provider
final isCreatorDemoModeProvider = Provider<bool>((ref) {
  return DemoModeService.instance.isCreatorMode;
});

/// Demo DT balance provider
final demoDtBalanceProvider = Provider<int>((ref) {
  return DemoModeService.instance.demoDtBalance;
});

/// Demo Star balance provider
final demoStarBalanceProvider = Provider<int>((ref) {
  return DemoModeService.instance.demoStarBalance;
});
