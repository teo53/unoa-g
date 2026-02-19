import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/fan_profile_summary.dart';
import '../../../providers/fan_crm_provider.dart';
import 'fan_tag_chips.dart';

/// 팬 프로필 바텀시트 (CRM)
/// 크리에이터가 팬 아바타 탭 시 표시됨
/// 메모 + 태그 + 구독정보 + DT 사용액
class FanProfileSheet extends ConsumerStatefulWidget {
  final String fanId;

  const FanProfileSheet({super.key, required this.fanId});

  /// static show 메서드
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    String fanId,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FanProfileSheet(fanId: fanId),
    );
  }

  @override
  ConsumerState<FanProfileSheet> createState() => _FanProfileSheetState();
}

class _FanProfileSheetState extends ConsumerState<FanProfileSheet> {
  late TextEditingController _memoController;
  bool _memoInitialized = false;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController();
  }

  @override
  void dispose() {
    // 닫기 전 즉시 저장
    final creatorId = ref.read(currentCreatorIdProvider);
    if (creatorId != null && _memoController.text.isNotEmpty) {
      final params = FanMemoParams(creatorId: creatorId, fanId: widget.fanId);
      ref.read(fanMemoProvider(params).notifier).saveImmediately(
            _memoController.text,
          );
    }
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(fanProfileProvider(widget.fanId));
    final creatorId = ref.watch(currentCreatorIdProvider);

    // 메모 상태 연결
    if (creatorId != null) {
      final memoParams =
          FanMemoParams(creatorId: creatorId, fanId: widget.fanId);
      final memoAsync = ref.watch(fanMemoProvider(memoParams));

      // 초기 메모 내용 로드
      if (!_memoInitialized) {
        memoAsync.whenData((note) {
          if (!_memoInitialized && note != null) {
            _memoController.text = note.content;
            _memoInitialized = true;
          } else if (!_memoInitialized) {
            _memoInitialized = true;
          }
        });
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // 드래그 핸들
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 본문
              Expanded(
                child: profileAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      '프로필 로드 실패',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                  ),
                  data: (profile) => _buildContent(
                    context,
                    profile,
                    isDark,
                    scrollController,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    FanProfileSummary profile,
    bool isDark,
    ScrollController scrollController,
  ) {
    final creatorId = ref.watch(currentCreatorIdProvider) ?? '';

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // 프로필 헤더
        _buildProfileHeader(profile, isDark),
        const SizedBox(height: 20),

        // 구독 정보 카드
        _buildInfoCard(profile, isDark),
        const SizedBox(height: 16),

        // 메모 영역
        _buildMemoSection(isDark, creatorId),
        const SizedBox(height: 16),

        // 태그 영역
        _buildTagSection(isDark),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProfileHeader(FanProfileSummary profile, bool isDark) {
    return Row(
      children: [
        // 아바타
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            border: Border.all(
              color: _getTierColor(profile.tier).withValues(alpha: 0.5),
              width: 2.5,
            ),
          ),
          child: profile.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    profile.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildAvatarFallback(profile, isDark),
                  ),
                )
              : _buildAvatarFallback(profile, isDark),
        ),
        const SizedBox(width: 14),

        // 이름 + 티어 + 구독기간
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      profile.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTierBadge(profile.tier),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '구독 ${profile.subscribedDaysText}',
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFallback(FanProfileSummary profile, bool isDark) {
    return Center(
      child: Text(
        profile.displayName.isNotEmpty ? profile.displayName[0] : '?',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildInfoCard(FanProfileSummary profile, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          _buildInfoItem(
            icon: Icons.diamond_outlined,
            label: 'DT 사용',
            value: _formatDt(profile.totalDtSpent),
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildInfoItem(
            icon: Icons.calendar_today_outlined,
            label: '구독일',
            value: '${profile.subscribedDays}일',
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildInfoItem(
            icon: Icons.workspace_premium_outlined,
            label: '티어',
            value: profile.tierLabel,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }

  Widget _buildMemoSection(bool isDark, String creatorId) {
    final memoParams = FanMemoParams(creatorId: creatorId, fanId: widget.fanId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 16,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
            const SizedBox(width: 6),
            Text(
              '메모',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _memoController,
          maxLines: 3,
          minLines: 2,
          onChanged: (text) {
            ref.read(fanMemoProvider(memoParams).notifier).updateMemo(text);
          },
          decoration: InputDecoration(
            hintText: '이 팬에 대한 메모를 남겨보세요...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTagSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.label_outlined,
              size: 16,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
            const SizedBox(width: 6),
            Text(
              '태그',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FanTagChips(fanId: widget.fanId),
      ],
    );
  }

  Widget _buildTierBadge(String tier) {
    Color bgColor;
    Color textColor;
    switch (tier.toUpperCase()) {
      case 'VIP':
        bgColor = Colors.amber[100]!;
        textColor = Colors.amber[800]!;
        break;
      case 'STANDARD':
        bgColor = AppColors.primary.withValues(alpha: 0.15);
        textColor = AppColors.primary;
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[600]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tier.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'VIP':
        return Colors.amber[700]!;
      case 'STANDARD':
        return AppColors.primary;
      default:
        return Colors.grey[500]!;
    }
  }

  String _formatDt(int amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(1)}만';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}천';
    }
    return '$amount';
  }
}
