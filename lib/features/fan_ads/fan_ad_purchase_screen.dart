import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/fan_ad_provider.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/app_toast.dart'
    show showAppSuccess, showAppError, showAppInfo;

// ── 구매 플로우 단계 ──

enum _PurchaseStep { setup, preview, payment }

class FanAdPurchaseScreen extends ConsumerStatefulWidget {
  final String? artistId;

  const FanAdPurchaseScreen({super.key, this.artistId});

  @override
  ConsumerState<FanAdPurchaseScreen> createState() =>
      _FanAdPurchaseScreenState();
}

class _FanAdPurchaseScreenState extends ConsumerState<FanAdPurchaseScreen> {
  _PurchaseStep _step = _PurchaseStep.setup;
  FanAdDraft _draft = const FanAdDraft();

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _linkUrlController = TextEditingController();
  DateTime? _startAt;
  DateTime? _endAt;
  int _selectedPriceKrw = 4900;

  static const _priceTiers = [4900, 9900, 19900, 49900];

  @override
  void initState() {
    super.initState();
    // 입력값은 channel_id를 우선 계약으로 사용하고,
    // provider에서 legacy creator/user id를 channel_id로 해석한다.
    _draft = _draft.copyWith(
      artistChannelId: widget.artistId,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _linkUrlController.dispose();
    super.dispose();
  }

  void _updateDraftFromFields() {
    _draft = _draft.copyWith(
      title: _titleController.text,
      body: _bodyController.text,
      linkUrl: _linkUrlController.text.trim().isEmpty
          ? null
          : _linkUrlController.text.trim(),
      linkType: _linkUrlController.text.trim().isEmpty ? 'none' : 'external',
      startAt: _startAt,
      endAt: _endAt,
      paymentAmountKrw: _selectedPriceKrw,
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startAt ?? now.add(const Duration(days: 1)))
        : (_endAt ?? (_startAt ?? now).add(const Duration(days: 7)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startAt = picked;
        if (_endAt != null && !_endAt!.isAfter(_startAt!)) {
          _endAt = _startAt!.add(const Duration(days: 7));
        }
      } else {
        _endAt = picked;
      }
    });
  }

  void _goNext() {
    _updateDraftFromFields();
    if (_step == _PurchaseStep.setup) {
      if (_titleController.text.trim().isEmpty) {
        showAppInfo(context, '광고 제목을 입력해주세요');
        return;
      }
      if (_startAt == null || _endAt == null) {
        showAppInfo(context, '노출 기간을 선택해주세요');
        return;
      }
      setState(() => _step = _PurchaseStep.preview);
    } else if (_step == _PurchaseStep.preview) {
      setState(() => _step = _PurchaseStep.payment);
    }
  }

  void _goBack() {
    if (_step == _PurchaseStep.preview) {
      setState(() => _step = _PurchaseStep.setup);
    } else if (_step == _PurchaseStep.payment) {
      setState(() => _step = _PurchaseStep.preview);
    } else {
      context.pop();
    }
  }

  Future<void> _submitPayment() async {
    _updateDraftFromFields();
    if (!_draft.isValid) {
      showAppInfo(context, '입력 내용을 확인해주세요');
      return;
    }

    final adId = await ref.read(fanAdProvider.notifier).createAd(_draft);
    if (!mounted) return;

    if (adId != null) {
      showAppSuccess(context, '광고 신청이 완료됐어요. 심사 후 노출됩니다!');
      context.pop();
    } else {
      showAppError(context, '광고 신청에 실패했어요. 다시 시도해주세요');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('광고 구매'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        elevation: 0,
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      ),
      body: Column(
        children: [
          _StepIndicator(step: _step),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: switch (_step) {
                _PurchaseStep.setup => _buildSetupStep(isDark),
                _PurchaseStep.preview => _buildPreviewStep(isDark),
                _PurchaseStep.payment => _buildPaymentStep(isDark),
              },
            ),
          ),
          _BottomBar(
            step: _step,
            onNext: _goNext,
            onSubmit: _submitPayment,
            price: _selectedPriceKrw,
          ),
        ],
      ),
    );
  }

  Widget _buildSetupStep(bool isDark) {
    final fmt = DateFormat('yyyy.MM.dd');
    final labelStyle = TextStyle(
      fontSize: 13,
      color: isDark ? AppColors.iconMuted : AppColors.textMuted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('광고 제목 *', style: labelStyle),
        const SizedBox(height: 6),
        TextField(
          controller: _titleController,
          maxLength: 50,
          decoration: const InputDecoration(
            hintText: '예: 생일 축하 광고',
            counterText: '',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('광고 메시지 (선택)', style: labelStyle),
        const SizedBox(height: 6),
        TextField(
          controller: _bodyController,
          maxLength: 100,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '팬들에게 전하고 싶은 메시지',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('링크 URL (선택)', style: labelStyle),
        const SizedBox(height: 6),
        TextField(
          controller: _linkUrlController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://...',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('노출 기간 *', style: labelStyle),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _DateButton(
                label: _startAt != null ? fmt.format(_startAt!) : '시작일',
                onTap: () => _pickDate(isStart: true),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('~'),
            ),
            Expanded(
              child: _DateButton(
                label: _endAt != null ? fmt.format(_endAt!) : '종료일',
                onTap: () => _pickDate(isStart: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('광고 요금 *', style: labelStyle),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: _priceTiers.map((price) {
            final selected = price == _selectedPriceKrw;
            return ChoiceChip(
              label: Text('${NumberFormat('#,###').format(price)}원'),
              selected: selected,
              onSelected: (_) => setState(() => _selectedPriceKrw = price),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPreviewStep(bool isDark) {
    final fmt = DateFormat('yyyy.MM.dd');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('광고 미리보기',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary500),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.campaign_outlined,
                    size: 16, color: AppColors.primary500),
                const SizedBox(width: 4),
                Text('팬 광고',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.primary500)),
              ]),
              const SizedBox(height: 6),
              Text(_titleController.text,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              if (_bodyController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(_bodyController.text,
                    style: const TextStyle(fontSize: 13)),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PreviewRow('노출 기간',
            '${_startAt != null ? fmt.format(_startAt!) : '-'} ~ ${_endAt != null ? fmt.format(_endAt!) : '-'}'),
        _PreviewRow(
            '광고 요금', '${NumberFormat('#,###').format(_selectedPriceKrw)}원'),
        if (_linkUrlController.text.trim().isNotEmpty)
          _PreviewRow('링크', _linkUrlController.text.trim()),
      ],
    );
  }

  Widget _buildPaymentStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('결제 확인',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              _PreviewRow('광고 제목', _titleController.text),
              _PreviewRow('결제 금액',
                  '${NumberFormat('#,###').format(_selectedPriceKrw)}원'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '※ 결제 후 광고는 심사 대기 상태가 됩니다.\n심사 완료 시 노출이 시작됩니다.',
          style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMuted : AppColors.textMuted),
        ),
      ],
    );
  }
}

// ── Sub-widgets ──

class _StepIndicator extends StatelessWidget {
  final _PurchaseStep step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    final steps = ['설정', '미리보기', '결제'];
    final current = _PurchaseStep.values.indexOf(step);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 1,
                color:
                    i ~/ 2 < current ? AppColors.primary500 : AppColors.border,
              ),
            );
          }
          final idx = i ~/ 2;
          final active = idx == current;
          final done = idx < current;
          return Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      done || active ? AppColors.primary500 : AppColors.border,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text('${idx + 1}',
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  active ? Colors.white : AppColors.textMuted)),
                ),
              ),
              const SizedBox(height: 4),
              Text(steps[idx],
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          active ? AppColors.primary500 : AppColors.textMuted)),
            ],
          );
        }),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _PreviewRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final _PurchaseStep step;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  final int price;

  const _BottomBar({
    required this.step,
    required this.onNext,
    required this.onSubmit,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = step == _PurchaseStep.payment;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: PrimaryButton(
          onPressed: isLast ? onSubmit : onNext,
          label: isLast ? '${NumberFormat('#,###').format(price)}원 결제하기' : '다음',
        ),
      ),
    );
  }
}
