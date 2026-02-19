import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/fan_ad_provider.dart';
import '../../providers/discover_provider.dart';
import '../../shared/widgets/app_scaffold.dart';

class FanAdPurchaseScreen extends ConsumerStatefulWidget {
  final String? initialArtistId;

  const FanAdPurchaseScreen({super.key, this.initialArtistId});

  @override
  ConsumerState<FanAdPurchaseScreen> createState() =>
      _FanAdPurchaseScreenState();
}

class _FanAdPurchaseScreenState extends ConsumerState<FanAdPurchaseScreen> {
  int _currentStep = 0;
  String? _selectedArtistId;
  FanAdPackage? _selectedPackage;
  final _headlineController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedArtistId = widget.initialArtistId;
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canProceed => switch (_currentStep) {
        0 => _selectedArtistId != null && _selectedPackage != null,
        1 => _headlineController.text.trim().isNotEmpty,
        2 => true,
        _ => false,
      };

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _submitAd();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _submitAd() async {
    if (_selectedPackage == null || _selectedArtistId == null) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(fanAdNotifierProvider.notifier).submitAd(
          packageId: _selectedPackage!.id,
          targetArtistId: _selectedArtistId!,
          headline: _headlineController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 28),
              SizedBox(width: 8),
              Text('광고 신청 완료'),
            ],
          ),
          content: const Text(
            '광고가 성공적으로 신청되었습니다.\n관리자 심사 후 게재됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop();
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
        appBar: AppBar(
          title: const Text('아티스트 응원 광고'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _previousStep,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor:
                  isDark ? AppColors.surfaceDark : Colors.grey[200],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary500),
            ),
          ),
        ),
        body: Column(
          children: [
            // Step Indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _StepDot(
                      index: 0,
                      current: _currentStep,
                      label: '패키지 선택'),
                  Expanded(
                      child: Container(
                          height: 1,
                          color: _currentStep > 0
                              ? AppColors.primary500
                              : Colors.grey[300])),
                  _StepDot(
                      index: 1,
                      current: _currentStep,
                      label: '콘텐츠 작성'),
                  Expanded(
                      child: Container(
                          height: 1,
                          color: _currentStep > 1
                              ? AppColors.primary500
                              : Colors.grey[300])),
                  _StepDot(
                      index: 2, current: _currentStep, label: '결제'),
                ],
              ),
            ),

            // Step Content
            Expanded(
              child: switch (_currentStep) {
                0 => _buildStep1PackageSelection(isDark),
                1 => _buildStep2ContentCreation(isDark),
                2 => _buildStep3Payment(isDark),
                _ => const SizedBox(),
              },
            ),

            // Bottom Button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canProceed && !_isSubmitting
                        ? _nextStep
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      disabledBackgroundColor:
                          isDark ? Colors.grey[800] : Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _currentStep == 2 ? '결제하기' : '다음',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1PackageSelection(bool isDark) {
    final packagesAsync = ref.watch(fanAdPackagesProvider);
    final artists = ref.watch(trendingArtistsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artist Selection
          Text(
            '응원할 아티스트',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: artists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final artist = artists[index];
                final isSelected = _selectedArtistId == artist.id;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedArtistId = artist.id),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary500
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: isDark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          child: Text(
                            artist.name.isNotEmpty
                                ? artist.name[0]
                                : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.primary500
                                  : Colors.grey[500],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary500
                              : (isDark
                                  ? AppColors.textSubDark
                                  : AppColors.textSubLight),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Package Selection
          Text(
            '광고 패키지 선택',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 12),

          packagesAsync.when(
            data: (packages) {
              // Group by placement
              final grouped = <String, List<FanAdPackage>>{};
              for (final pkg in packages) {
                grouped.putIfAbsent(pkg.placement, () => []).add(pkg);
              }

              return Column(
                children: grouped.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 8),
                        child: Text(
                          entry.value.first.placementLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSubDark
                                : AppColors.textSubLight,
                          ),
                        ),
                      ),
                      ...entry.value.map((pkg) => _PackageCard(
                            package: pkg,
                            isSelected: _selectedPackage?.id == pkg.id,
                            onTap: () =>
                                setState(() => _selectedPackage = pkg),
                            isDark: isDark,
                          )),
                    ],
                  );
                }).toList(),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('패키지를 불러올 수 없습니다')),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStep2ContentCreation(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '광고 콘텐츠',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),

          // Headline
          TextField(
            controller: _headlineController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: '헤드라인 *',
              hintText: '예: 최고의 아티스트 OOO을 응원합니다!',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              counterText: '${_headlineController.text.length}/50',
            ),
            maxLength: 50,
          ),

          const SizedBox(height: 16),

          // Description
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: '설명 (선택)',
              hintText: '추가 설명을 입력해주세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
            maxLength: 100,
          ),

          const SizedBox(height: 24),

          // Preview
          Text(
            '미리보기',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey[200]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '광고',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[800],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '팬 응원 광고',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _headlineController.text.isEmpty
                      ? '헤드라인이 여기에 표시됩니다'
                      : _headlineController.text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _headlineController.text.isEmpty
                        ? Colors.grey[400]
                        : (isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight),
                  ),
                ),
                if (_descriptionController.text.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _descriptionController.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Payment(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '주문 확인',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 16),

          // Order Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey[200]!,
              ),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: '광고 패키지',
                  value: _selectedPackage?.name ?? '',
                  isDark: isDark,
                ),
                const Divider(height: 24),
                _SummaryRow(
                  label: '게재 위치',
                  value: _selectedPackage?.placementLabel ?? '',
                  isDark: isDark,
                ),
                const Divider(height: 24),
                _SummaryRow(
                  label: '기간',
                  value: '${_selectedPackage?.durationDays ?? 0}일',
                  isDark: isDark,
                ),
                const Divider(height: 24),
                _SummaryRow(
                  label: '헤드라인',
                  value: _headlineController.text,
                  isDark: isDark,
                ),
                const Divider(height: 24),
                _SummaryRow(
                  label: '결제 금액',
                  value: _selectedPackage?.formattedPrice ?? '',
                  isDark: isDark,
                  isHighlighted: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Payment Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.amber[800]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '결제 후 관리자 심사를 거쳐 광고가 게재됩니다.\n부적절한 콘텐츠는 거절될 수 있으며, 거절 시 환불됩니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[900],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final int current;
  final String label;

  const _StepDot({
    required this.index,
    required this.current,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index <= current;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary500 : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppColors.primary500 : Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  final FanAdPackage package;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _PackageCard({
    required this.package,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary500.withValues(alpha: 0.08)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary500 : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${package.durationDays}일간 노출',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              package.formattedPrice,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.primary600
                    : (isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle,
                  color: AppColors.primary500, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isHighlighted;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 18 : 14,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
            color: isHighlighted
                ? AppColors.primary600
                : (isDark
                    ? AppColors.textMainDark
                    : AppColors.textMainLight),
          ),
        ),
      ],
    );
  }
}
