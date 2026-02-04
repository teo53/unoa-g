import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalAmountController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  int _currentStep = 0;
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _coverImageUrl;

  final List<String> _categories = [
    '앨범',
    '팬미팅',
    '콘서트',
    '화보집',
    '굿즈',
    '서포트',
    '기타',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.campaignId != null;
    if (_isEditing) {
      _loadCampaignData();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _goalAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadCampaignData() async {
    // For demo mode or actual loading
    final isDemoMode = ref.read(isDemoModeProvider);
    if (isDemoMode) {
      // Load demo data
      _titleController.text = '데모 펀딩 제목';
      _subtitleController.text = '데모 부제목';
      _descriptionController.text = '데모 펀딩 설명입니다.';
      _goalAmountController.text = '10000000';
      _selectedCategory = '앨범';
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 30));
    }
    // TODO: Load actual campaign data from Supabase
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
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveDraft,
            child: const Text('임시저장'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          onStepTapped: (step) => setState(() => _currentStep = step),
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  if (_currentStep < 3)
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary600,
                        foregroundColor: AppColors.onPrimary,
                      ),
                      child: const Text('다음'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitCampaign,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary600,
                        foregroundColor: AppColors.onPrimary,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEditing ? '수정 완료' : '펀딩 등록'),
                    ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('이전'),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('기본 정보'),
              subtitle: const Text('펀딩 제목과 카테고리'),
              content: _buildBasicInfoStep(isDark),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('상세 정보'),
              subtitle: const Text('펀딩 설명과 목표 금액'),
              content: _buildDetailStep(isDark),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('기간 설정'),
              subtitle: const Text('펀딩 시작일과 종료일'),
              content: _buildDateStep(isDark),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('이미지'),
              subtitle: const Text('커버 이미지 업로드'),
              content: _buildImageStep(isDark),
              isActive: _currentStep >= 3,
              state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: '펀딩 제목 *',
            hintText: '펀딩 제목을 입력해주세요',
            filled: true,
            fillColor: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          maxLength: 50,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '펀딩 제목을 입력해주세요';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _subtitleController,
          decoration: InputDecoration(
            labelText: '부제목',
            hintText: '짧은 설명을 입력해주세요',
            filled: true,
            fillColor: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          maxLength: 100,
        ),
        const SizedBox(height: 16),
        Text(
          '카테고리 *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textDark : AppColors.text,
          ),
        ),
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
      ],
    );
  }

  Widget _buildDetailStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: '펀딩 설명 *',
            hintText: '펀딩에 대한 자세한 설명을 입력해주세요',
            filled: true,
            fillColor: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            alignLabelWithHint: true,
          ),
          maxLines: 8,
          maxLength: 2000,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '펀딩 설명을 입력해주세요';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _goalAmountController,
          decoration: InputDecoration(
            labelText: '목표 금액 (DT) *',
            hintText: '1000000',
            prefixText: 'DT ',
            filled: true,
            fillColor: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '목표 금액을 입력해주세요';
            }
            final amount = int.tryParse(value);
            if (amount == null || amount < 100000) {
              return '최소 10만 DT 이상 설정해주세요';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          '* 100,000 DT = 약 10만원',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

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
      ],
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
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textDark : AppColors.text,
          ),
        ),
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
                  color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '커버 이미지 *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textDark : AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '권장 크기: 1200x675 (16:9 비율)',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _selectImage,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: _coverImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _coverImageUrl!,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filled(
                            onPressed: () {
                              setState(() {
                                _coverImageUrl = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: isDark ? AppColors.iconMutedDark : AppColors.iconMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '이미지를 업로드하세요',
                        style: TextStyle(
                          color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary100.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '펀딩 등록 후 리워드 티어를 추가할 수 있습니다',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now().add(const Duration(days: 30)));

    final firstDate = isStart
        ? DateTime.now()
        : (_startDate ?? DateTime.now()).add(const Duration(days: 7));

    final lastDate = isStart
        ? DateTime.now().add(const Duration(days: 365))
        : (_startDate ?? DateTime.now()).add(const Duration(days: 60));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Adjust end date if needed
          if (_endDate != null && _endDate!.difference(picked).inDays < 7) {
            _endDate = picked.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _selectImage() {
    // Demo mode: use placeholder image
    final isDemoMode = ref.read(isDemoModeProvider);
    if (isDemoMode) {
      setState(() {
        _coverImageUrl = 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/1200/675';
      });
      return;
    }
    // TODO: Implement actual image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이미지 선택 기능은 준비 중입니다')),
    );
  }

  void _onStepContinue() {
    if (_currentStep < 3) {
      // Validate current step
      bool isValid = true;

      switch (_currentStep) {
        case 0:
          if (_titleController.text.isEmpty || _selectedCategory == null) {
            isValid = false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('제목과 카테고리를 입력해주세요')),
            );
          }
          break;
        case 1:
          if (_descriptionController.text.isEmpty ||
              _goalAmountController.text.isEmpty) {
            isValid = false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('설명과 목표 금액을 입력해주세요')),
            );
          }
          break;
        case 2:
          if (_endDate == null) {
            isValid = false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('종료일을 선택해주세요')),
            );
          }
          break;
      }

      if (isValid) {
        setState(() => _currentStep++);
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _saveDraft() async {
    // Demo mode: just show success message
    final isDemoMode = ref.read(isDemoModeProvider);
    if (isDemoMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('임시저장 되었습니다 (데모)')),
      );
      return;
    }
    // TODO: Implement actual save draft
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('임시저장 기능은 준비 중입니다')),
    );
  }

  Future<void> _submitCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    if (_coverImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('커버 이미지를 업로드해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Demo mode: just show success message
    final isDemoMode = ref.read(isDemoModeProvider);
    if (isDemoMode) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? '펀딩이 수정되었습니다 (데모)' : '펀딩이 등록되었습니다 (데모)'),
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    // TODO: Implement actual campaign submission
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('펀딩 등록 기능은 준비 중입니다')),
    );
  }
}
