import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/funding_provider.dart';

/// Screen for creating or editing a funding campaign
class CreateCampaignScreen extends ConsumerStatefulWidget {
  final String? campaignId;

  const CreateCampaignScreen({
    super.key,
    this.campaignId,
  });

  @override
  ConsumerState<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends ConsumerState<CreateCampaignScreen> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalAmountController = TextEditingController();
  final _targetArtistController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  int _currentStep = 0;
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _coverImageUrl;
  final List<String> _detailImages = [];

  final List<String> _categories = [
    '앨범',
    '팬미팅',
    '콘서트',
    '화보집',
    '굿즈',
    '서포트',
    '기타',
  ];

  final List<String> _suggestedArtists = [
    'BLACKPINK',
    'BTS',
    'aespa',
    'NewJeans',
    'SEVENTEEN',
    'Stray Kids',
    'IVE',
    'LE SSERAFIM',
    'NCT',
    'TWICE',
    '(G)I-DLE',
    'TXT',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.campaignId != null;
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCampaignData();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _goalAmountController.dispose();
    _targetArtistController.dispose();
    super.dispose();
  }

  void _loadCampaignData() {
    final campaign = ref.read(fundingProvider.notifier).getCampaignById(widget.campaignId!);

    if (campaign != null) {
      setState(() {
        _titleController.text = campaign.title;
        _subtitleController.text = campaign.subtitle ?? '';
        _descriptionController.text = campaign.description ?? '';
        _goalAmountController.text = campaign.goalAmountKrw > 0
            ? campaign.goalAmountKrw.toString()
            : '';
        _selectedCategory = campaign.category;
        _startDate = campaign.startAt;
        _endDate = campaign.endAt;
        _coverImageUrl = campaign.coverImageUrl;
        _targetArtistController.text = campaign.targetArtist ?? '';
        _detailImages.addAll(campaign.detailImages);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? '펀딩 수정' : '새 펀딩 만들기'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.textDark : AppColors.text,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveDraft,
            child: const Text('임시저장'),
          ),
        ],
      ),
      body: Stepper(
        type: StepperType.vertical,
        physics: const ClampingScrollPhysics(),
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        onStepTapped: (step) {
          if (step < _currentStep) {
            setState(() => _currentStep = step);
          }
        },
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == 2;
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: isLastStep
                      ? (_isLoading ? null : _submitCampaign)
                      : details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading && isLastStep
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isLastStep
                              ? (_isEditing ? '수정 완료' : '펀딩 등록')
                              : '다음',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      '이전',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('기본 정보'),
            subtitle: const Text('제목, 카테고리, 대상, 커버 이미지'),
            content: _buildBasicInfoStep(isDark),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('상세 정보'),
            subtitle: const Text('설명, 목표 금액, 상세 이미지'),
            content: _buildDetailStep(isDark),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('기간 설정'),
            subtitle: const Text('시작일과 종료일'),
            content: _buildDateStep(isDark),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Step 1: Basic Info (title, subtitle, category, target artist, cover image)
  // =========================================================================
  Widget _buildBasicInfoStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        _buildLabel(isDark, '펀딩 제목 *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: _inputDecoration(isDark, '펀딩 제목을 입력해주세요'),
          maxLength: 50,
        ),
        const SizedBox(height: 16),

        // Subtitle
        _buildLabel(isDark, '부제목'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _subtitleController,
          decoration: _inputDecoration(isDark, '짧은 설명을 입력해주세요'),
          maxLength: 100,
        ),
        const SizedBox(height: 16),

        // Category
        _buildLabel(isDark, '카테고리 *'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : null;
                });
              },
              selectedColor: AppColors.primary100,
              checkmarkColor: AppColors.primary600,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary600 : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Target artist/agency
        _buildLabel(isDark, '대상 아티스트/소속사'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _targetArtistController,
          decoration: _inputDecoration(isDark, '아티스트 또는 소속사 이름').copyWith(
            suffixIcon: _targetArtistController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        _targetArtistController.clear();
                      });
                    },
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _suggestedArtists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final artist = _suggestedArtists[index];
              final isSelected = _targetArtistController.text == artist;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _targetArtistController.text = artist;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary100
                        : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt),
                    borderRadius: BorderRadius.circular(18),
                    border: isSelected
                        ? Border.all(color: AppColors.primary600, width: 1.5)
                        : null,
                  ),
                  child: Text(
                    artist,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary600
                          : (isDark ? AppColors.textDark : AppColors.text),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Cover image
        _buildLabel(isDark, '커버 이미지 *'),
        const SizedBox(height: 4),
        Text(
          '권장 크기: 1200x675 (16:9 비율)',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        _buildImagePicker(
          isDark,
          imageUrl: _coverImageUrl,
          height: 180,
          onTap: () => _selectCoverImage(),
          onRemove: () => setState(() => _coverImageUrl = null),
          placeholder: '커버 이미지를 업로드하세요',
        ),
      ],
    );
  }

  // =========================================================================
  // Step 2: Detail Info (description, goal amount, detail images)
  // =========================================================================
  Widget _buildDetailStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        _buildLabel(isDark, '펀딩 설명 *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: _inputDecoration(isDark, '펀딩에 대한 자세한 설명을 입력해주세요').copyWith(
            alignLabelWithHint: true,
          ),
          maxLines: 8,
          maxLength: 2000,
        ),
        const SizedBox(height: 16),

        // Goal amount
        _buildLabel(isDark, '목표 금액 (원) *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _goalAmountController,
          decoration: _inputDecoration(isDark, '1000000').copyWith(
            prefixText: '₩ ',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 4),
        Text(
          '* 최소 100,000원 이상',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 24),

        // Detail images
        _buildLabel(isDark, '상세 이미지'),
        const SizedBox(height: 4),
        Text(
          '펀딩 상세 페이지에 표시될 이미지를 추가하세요 (최대 5장)',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailImageGrid(isDark),
      ],
    );
  }

  // =========================================================================
  // Step 3: Date (start date, end date)
  // =========================================================================
  Widget _buildDateStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateField(
          isDark,
          label: '시작일',
          date: _startDate,
          onTap: () => _selectDate(isStart: true),
          hint: '펀딩 시작일을 선택해주세요',
        ),
        const SizedBox(height: 16),
        _buildDateField(
          isDark,
          label: '종료일 *',
          date: _endDate,
          onTap: () => _selectDate(isStart: false),
          hint: '펀딩 종료일을 선택해주세요',
        ),
        const SizedBox(height: 8),
        Text(
          '* 펀딩 기간은 최소 7일에서 최대 60일까지 설정 가능합니다',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 24),

        // Summary info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary100.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary600,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '펀딩 등록 후 리워드 티어를 추가할 수 있습니다.\n등록 후 바로 활성화됩니다.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // Shared UI Components
  // =========================================================================

  Widget _buildLabel(bool isDark, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textDark : AppColors.text,
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
      ),
      filled: true,
      fillColor: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildImagePicker(
    bool isDark, {
    required String? imageUrl,
    required double height,
    required VoidCallback onTap,
    required VoidCallback onRemove,
    required String placeholder,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(isDark, placeholder),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Semantics(
                        label: '이미지 삭제',
                        button: true,
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Tooltip(
                            message: '이미지 삭제',
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : _buildImagePlaceholder(isDark, placeholder),
      ),
    );
  }

  Widget _buildImagePlaceholder(bool isDark, String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 40,
          color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailImageGrid(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._detailImages.asMap().entries.map((entry) {
          final idx = entry.key;
          final url = entry.value;
          return _buildDetailImageTile(isDark, url, idx);
        }),
        if (_detailImages.length < 5)
          _buildAddImageTile(isDark),
      ],
    );
  }

  Widget _buildDetailImageTile(bool isDark, String url, int index) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _detailImages.removeAt(index);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
            // Index badge
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddImageTile(bool isDark) {
    return GestureDetector(
      onTap: _addDetailImage,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              size: 28,
              color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
            ),
            const SizedBox(height: 4),
            Text(
              '추가',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
    bool isDark, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(isDark, label),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: date != null
                      ? AppColors.primary600
                      : (isDark ? AppColors.iconMutedDark : AppColors.iconMuted),
                ),
                const SizedBox(width: 12),
                Text(
                  date != null
                      ? '${date.year}년 ${date.month}월 ${date.day}일'
                      : hint,
                  style: TextStyle(
                    fontSize: 15,
                    color: date != null
                        ? (isDark ? AppColors.textDark : AppColors.text)
                        : (isDark ? AppColors.textMutedDark : AppColors.textMuted),
                  ),
                ),
                const Spacer(),
                if (date != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (label.contains('시작')) {
                          _startDate = null;
                        } else {
                          _endDate = null;
                        }
                      });
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // Actions
  // =========================================================================

  Future<void> _selectDate({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart
        ? (_startDate ?? now)
        : (_endDate ?? now.add(const Duration(days: 30)));

    final firstDate = isStart
        ? now
        : (_startDate ?? now).add(const Duration(days: 7));

    final lastDate = isStart
        ? now.add(const Duration(days: 365))
        : (_startDate ?? now).add(const Duration(days: 60));

    // Ensure initialDate is within range
    final clampedInitialDate = initialDate.isBefore(firstDate)
        ? firstDate
        : (initialDate.isAfter(lastDate) ? lastDate : initialDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: clampedInitialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary600,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.difference(picked).inDays < 7) {
            _endDate = picked.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _selectCoverImage() {
    // Demo mode: use placeholder image
    setState(() {
      _coverImageUrl =
          'https://picsum.photos/seed/cover_${DateTime.now().millisecondsSinceEpoch}/1200/675';
    });
  }

  void _addDetailImage() {
    if (_detailImages.length >= 5) return;
    // Demo mode: use placeholder image
    setState(() {
      _detailImages.add(
        'https://picsum.photos/seed/detail_${DateTime.now().millisecondsSinceEpoch}_${_detailImages.length}/800/600',
      );
    });
  }

  void _onStepContinue() {
    if (_currentStep >= 2) return;

    String? error;
    switch (_currentStep) {
      case 0:
        if (_titleController.text.trim().isEmpty) {
          error = '펀딩 제목을 입력해주세요';
        } else if (_selectedCategory == null) {
          error = '카테고리를 선택해주세요';
        } else if (_coverImageUrl == null) {
          error = '커버 이미지를 업로드해주세요';
        }
        break;
      case 1:
        if (_descriptionController.text.trim().isEmpty) {
          error = '펀딩 설명을 입력해주세요';
        } else if (_goalAmountController.text.isEmpty) {
          error = '목표 금액을 입력해주세요';
        } else {
          final amount = int.tryParse(_goalAmountController.text);
          if (amount == null || amount < 100000) {
            error = '최소 10만원 이상 설정해주세요';
          }
        }
        break;
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    setState(() => _currentStep++);
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _saveDraft() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(fundingProvider.notifier).saveDraft(
        existingCampaignId: widget.campaignId,
        title: _titleController.text.isNotEmpty
            ? _titleController.text
            : '제목 없음 (임시저장)',
        subtitle: _subtitleController.text.isNotEmpty
            ? _subtitleController.text
            : null,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        category: _selectedCategory,
        coverImageUrl: _coverImageUrl,
        goalAmountKrw: int.tryParse(_goalAmountController.text) ?? 0,
        startAt: _startDate,
        endAt: _endDate,
        targetArtist: _targetArtistController.text.isNotEmpty
            ? _targetArtistController.text
            : null,
        detailImages: _detailImages.isNotEmpty ? _detailImages : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('임시저장 되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitCampaign() async {
    // Final validation
    if (_coverImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('커버 이미지를 업로드해주세요')),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설명을 입력해주세요')),
      );
      return;
    }

    final amount = int.tryParse(_goalAmountController.text);
    if (amount == null || amount < 100000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 10만원 이상 설정해주세요')),
      );
      return;
    }

    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료일을 선택해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(fundingProvider.notifier).submitCampaign(
        existingCampaignId: widget.campaignId,
        title: _titleController.text,
        subtitle: _subtitleController.text.isNotEmpty
            ? _subtitleController.text
            : null,
        description: _descriptionController.text,
        category: _selectedCategory,
        coverImageUrl: _coverImageUrl,
        goalAmountKrw: amount,
        startAt: _startDate,
        endAt: _endDate!,
        targetArtist: _targetArtistController.text.isNotEmpty
            ? _targetArtistController.text
            : null,
        detailImages: _detailImages.isNotEmpty ? _detailImages : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? '펀딩이 수정되었습니다' : '펀딩이 등록되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
