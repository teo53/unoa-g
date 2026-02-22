import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/demo_config.dart';
import '../core/utils/app_logger.dart';
import '../data/models/agency.dart';
import 'auth_provider.dart';
import 'repository_providers.dart';

// ============================================================================
// State
// ============================================================================

class AgencyState {
  final AgencyContract? activeContract;
  final List<AgencyInvitation> pendingInvitations;
  final bool isLoading;
  final String? error;

  const AgencyState({
    this.activeContract,
    this.pendingInvitations = const [],
    this.isLoading = false,
    this.error,
  });

  bool get hasAgency => activeContract != null;

  AgencyState copyWith({
    AgencyContract? activeContract,
    List<AgencyInvitation>? pendingInvitations,
    bool? isLoading,
    String? error,
    bool clearContract = false,
  }) {
    return AgencyState(
      activeContract:
          clearContract ? null : (activeContract ?? this.activeContract),
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ============================================================================
// Notifier
// ============================================================================

class AgencyNotifier extends StateNotifier<AgencyState> {
  final Ref _ref;

  AgencyNotifier(this._ref) : super(const AgencyState()) {
    loadAgencyInfo();
  }

  Future<void> loadAgencyInfo() async {
    state = state.copyWith(isLoading: true, error: null);

    final authState = _ref.read(authProvider);
    final isDemoMode = authState is AuthDemoMode;

    if (isDemoMode) {
      await _loadDemoAgencyInfo(authState);
    } else {
      await _loadRealAgencyInfo();
    }
  }

  Future<void> _loadDemoAgencyInfo(AuthDemoMode auth) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Demo: only show agency for creator role
    if (auth.demoProfile.role != 'creator') {
      state = const AgencyState(isLoading: false);
      return;
    }

    // Demo: creator has an active agency contract
    state = AgencyState(
      activeContract: AgencyContract(
        id: DemoConfig.demoAgencyContractId,
        agencyId: DemoConfig.demoAgencyId,
        agencyName: DemoConfig.demoAgencyName,
        agencyLogoUrl: DemoConfig.avatarUrl('agency-logo', size: 100),
        status: 'active',
        revenueShareRate: 0.10,
        settlementPeriod: 'monthly',
        contractStartDate: '2025-07-01',
        contractEndDate: '2027-06-30',
        hasPowerOfAttorney: false,
        createdAt: '2025-06-20T00:00:00Z',
      ),
      pendingInvitations: [],
      isLoading: false,
    );
  }

  Future<void> _loadRealAgencyInfo() async {
    try {
      final repo = _ref.read(agencyRepositoryProvider);

      // Get creator profile ID
      final profileResult = await repo.getCreatorProfile();

      if (profileResult == null) {
        state = const AgencyState(isLoading: false);
        return;
      }

      final creatorProfileId = profileResult['id'] as String;

      // Get active contract with agency info
      final contractResult = await repo.getActiveContract(creatorProfileId);

      AgencyContract? activeContract;
      if (contractResult != null) {
        final agencyData = contractResult['agencies'] as Map<String, dynamic>?;
        activeContract = AgencyContract(
          id: contractResult['id'] as String,
          agencyId: contractResult['agency_id'] as String,
          agencyName: agencyData?['name'] as String? ?? '',
          agencyLogoUrl: agencyData?['logo_url'] as String?,
          status: contractResult['status'] as String,
          revenueShareRate:
              (contractResult['revenue_share_rate'] as num).toDouble(),
          settlementPeriod:
              contractResult['settlement_period'] as String? ?? 'monthly',
          contractStartDate: contractResult['contract_start_date'] as String?,
          contractEndDate: contractResult['contract_end_date'] as String?,
          hasPowerOfAttorney: contractResult['power_of_attorney_url'] != null,
          notes: contractResult['notes'] as String?,
          createdAt: contractResult['created_at'] as String,
        );
      }

      // Get pending invitations
      final invitationsResult =
          await repo.getPendingInvitations(creatorProfileId);

      final invitations = invitationsResult.map((json) {
        final agencyData = json['agencies'] as Map<String, dynamic>?;
        return AgencyInvitation(
          contractId: json['id'] as String,
          agencyId: json['agency_id'] as String,
          agencyName: agencyData?['name'] as String? ?? '',
          agencyLogoUrl: agencyData?['logo_url'] as String?,
          revenueShareRate: (json['revenue_share_rate'] as num).toDouble(),
          contractStartDate: json['contract_start_date'] as String?,
          contractEndDate: json['contract_end_date'] as String?,
          settlementPeriod: json['settlement_period'] as String? ?? 'monthly',
          hasPowerOfAttorney: json['power_of_attorney_url'] != null,
          notes: json['notes'] as String?,
          createdAt: json['created_at'] as String,
        );
      }).toList();

      state = AgencyState(
        activeContract: activeContract,
        pendingInvitations: invitations,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error(e, tag: 'Agency', message: 'Agency info load error');
      state = state.copyWith(
        isLoading: false,
        error: '소속사 정보를 불러올 수 없습니다',
      );
    }
  }

  /// Accept a pending agency invitation
  Future<bool> acceptInvitation(String contractId) async {
    final authState = _ref.read(authProvider);
    final isDemoMode = authState is AuthDemoMode;

    if (isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      // In demo, just reload
      await loadAgencyInfo();
      return true;
    }

    try {
      final repo = _ref.read(agencyRepositoryProvider);
      final result = await repo.respondToInvitation(
        contractId: contractId,
        accept: true,
      );

      if (result != null && result['success'] == true) {
        await loadAgencyInfo();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error(e, tag: 'Agency', message: 'Contract accept error');
      return false;
    }
  }

  /// Reject a pending agency invitation
  Future<bool> rejectInvitation(String contractId) async {
    final authState = _ref.read(authProvider);
    final isDemoMode = authState is AuthDemoMode;

    if (isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(
        pendingInvitations: state.pendingInvitations
            .where((i) => i.contractId != contractId)
            .toList(),
      );
      return true;
    }

    try {
      final repo = _ref.read(agencyRepositoryProvider);
      final result = await repo.respondToInvitation(
        contractId: contractId,
        accept: false,
      );

      if (result != null && result['success'] == true) {
        state = state.copyWith(
          pendingInvitations: state.pendingInvitations
              .where((i) => i.contractId != contractId)
              .toList(),
        );
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error(e, tag: 'Agency', message: 'Contract reject error');
      return false;
    }
  }
}

// ============================================================================
// Providers
// ============================================================================

final agencyProvider =
    StateNotifierProvider<AgencyNotifier, AgencyState>((ref) {
  return AgencyNotifier(ref);
});

/// Convenience: does the current creator have an active agency?
final hasActiveAgencyProvider = Provider<bool>((ref) {
  return ref.watch(agencyProvider).hasAgency;
});
