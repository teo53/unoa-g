/// 콘텐츠 편집 다이얼로그 함수들
///
/// creator_profile_edit_screen.dart에서 추출하여
/// WYSIWYG 화면과 프로필 편집 화면 모두에서 재사용 가능하도록 함.
///
/// 패턴: setState() 대신 onSave 콜백 사용
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/creator_content.dart';

/// 드롭(상품) 추가/수정 다이얼로그
void showDropEditDialog(
  BuildContext context,
  bool isDark, {
  CreatorDrop? drop,
  required void Function(CreatorDrop) onSave,
}) {
  final isEdit = drop != null;
  final nameController = TextEditingController(text: drop?.name ?? '');
  final priceController =
      TextEditingController(text: drop?.priceKrw.toString() ?? '');
  final descController = TextEditingController(text: drop?.description ?? '');
  final urlController = TextEditingController(text: drop?.externalUrl ?? '');
  bool isNew = drop?.isNew ?? true;
  bool isSoldOut = drop?.isSoldOut ?? false;
  XFile? selectedImage;
  String? existingImageUrl = drop?.imageUrl;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? '드롭 수정' : '새 드롭 추가',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 20),
              // 이미지 선택
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final image =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setModalState(() {
                      selectedImage = image;
                      existingImageUrl = null;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: selectedImage != null
                      ? _imagePreviewStack(selectedImage!.path, isDark)
                      : existingImageUrl != null
                          ? _cachedImagePreviewStack(existingImageUrl!, isDark)
                          : _imagePlaceholder('상품 이미지 추가', isDark),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '상품명 *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '가격 (원) *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: '상품 설명',
                  hintText: '선택사항',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: '구매 링크',
                  hintText: 'https://...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilterChip(
                    label: const Text('NEW'),
                    selected: isNew,
                    onSelected: (v) => setModalState(() => isNew = v),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('SOLD OUT'),
                    selected: isSoldOut,
                    onSelected: (v) => setModalState(() => isSoldOut = v),
                    selectedColor: Colors.grey.withValues(alpha: 0.2),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isEmpty) return;
                    final newDrop = CreatorDrop(
                      id: drop?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      description: descController.text.isNotEmpty
                          ? descController.text
                          : null,
                      imageUrl: selectedImage?.path ?? existingImageUrl,
                      priceKrw: int.tryParse(priceController.text) ?? 0,
                      isNew: isNew,
                      isSoldOut: isSoldOut,
                      externalUrl: urlController.text.isNotEmpty
                          ? urlController.text
                          : null,
                    );
                    onSave(newDrop);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isEdit ? '수정' : '추가',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 이벤트 추가/수정 다이얼로그
void showEventEditDialog(
  BuildContext context,
  bool isDark, {
  CreatorEvent? event,
  required void Function(CreatorEvent) onSave,
}) {
  final isEdit = event != null;
  final titleController = TextEditingController(text: event?.title ?? '');
  final locationController = TextEditingController(text: event?.location ?? '');
  final descController = TextEditingController(text: event?.description ?? '');
  final ticketUrlController =
      TextEditingController(text: event?.ticketUrl ?? '');
  DateTime selectedDate =
      event?.date ?? DateTime.now().add(const Duration(days: 30));
  bool isOffline = event?.isOffline ?? true;
  XFile? selectedImage;
  String? existingImageUrl = event?.imageUrl;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? '이벤트 수정' : '새 이벤트 추가',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 20),
              // 이미지 선택
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final image =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setModalState(() {
                      selectedImage = image;
                      existingImageUrl = null;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: selectedImage != null
                      ? _imagePreviewStack(selectedImage!.path, isDark)
                      : existingImageUrl != null
                          ? _cachedImagePreviewStack(existingImageUrl!, isDark)
                          : _imagePlaceholder('이벤트 이미지 추가', isDark),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '이벤트 제목 *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: '장소 *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '날짜: ${selectedDate.year}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  trailing: Icon(
                    Icons.calendar_today,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: '이벤트 설명',
                  hintText: '선택사항',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ticketUrlController,
                decoration: InputDecoration(
                  labelText: '티켓/예매 링크',
                  hintText: 'https://...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilterChip(
                    label: const Text('OFFLINE'),
                    selected: isOffline,
                    onSelected: (v) => setModalState(() => isOffline = true),
                    selectedColor: Colors.purple.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('ONLINE'),
                    selected: !isOffline,
                    onSelected: (v) => setModalState(() => isOffline = false),
                    selectedColor: Colors.green.withValues(alpha: 0.2),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty) return;
                    final newEvent = CreatorEvent(
                      id: event?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      location: locationController.text,
                      date: selectedDate,
                      isOffline: isOffline,
                      description: descController.text.isNotEmpty
                          ? descController.text
                          : null,
                      ticketUrl: ticketUrlController.text.isNotEmpty
                          ? ticketUrlController.text
                          : null,
                      imageUrl: selectedImage?.path ?? existingImageUrl,
                    );
                    onSave(newEvent);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isEdit ? '수정' : '추가',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 직캠 추가/수정 다이얼로그
void showFancamEditDialog(
  BuildContext context,
  bool isDark, {
  CreatorFancam? fancam,
  required void Function(CreatorFancam) onSave,
}) {
  final isEdit = fancam != null;
  final urlController = TextEditingController(
    text: fancam != null ? 'https://youtube.com/watch?v=${fancam.videoId}' : '',
  );
  String fetchedTitle = fancam?.title ?? '';
  bool isLoading = false;
  String? errorMessage;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? '직캠 수정' : '새 직캠 추가',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: 'YouTube URL',
                      hintText: 'https://youtube.com/watch?v=...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      errorText: errorMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final videoId = CreatorFancam.extractVideoId(
                                urlController.text);
                            if (videoId == null) {
                              setModalState(
                                  () => errorMessage = '올바른 URL을 입력하세요');
                              return;
                            }
                            setModalState(() {
                              isLoading = true;
                              errorMessage = null;
                            });
                            try {
                              final response = await http
                                  .get(Uri.parse(
                                      'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json'))
                                  .timeout(const Duration(seconds: 5));
                              if (response.statusCode == 200) {
                                final data = jsonDecode(response.body);
                                setModalState(() {
                                  fetchedTitle = data['title'] ?? '';
                                  isLoading = false;
                                });
                              } else {
                                setModalState(() {
                                  errorMessage = '영상을 찾을 수 없습니다';
                                  isLoading = false;
                                });
                              }
                            } catch (e) {
                              setModalState(() {
                                errorMessage = '제목을 불러올 수 없습니다';
                                isLoading = false;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('불러오기',
                            style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '제목 (자동)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fetchedTitle.isEmpty
                        ? 'URL을 입력하고 불러오기를 눌러주세요'
                        : fetchedTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: fetchedTitle.isEmpty
                          ? FontWeight.w400
                          : FontWeight.w500,
                      color: fetchedTitle.isEmpty
                          ? (isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMuted)
                          : (isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: fetchedTitle.isEmpty
                    ? null
                    : () {
                        final videoId =
                            CreatorFancam.extractVideoId(urlController.text);
                        if (videoId == null) return;
                        final newFancam = CreatorFancam(
                          id: fancam?.id ??
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          videoId: videoId,
                          title: fetchedTitle,
                          isPinned: fancam?.isPinned ?? false,
                        );
                        onSave(newFancam);
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: fetchedTitle.isEmpty
                      ? (isDark ? Colors.grey[700] : Colors.grey[300])
                      : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isEdit ? '수정' : '추가',
                  style: TextStyle(
                    color: fetchedTitle.isEmpty
                        ? (isDark ? Colors.grey[500] : Colors.grey[600])
                        : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 소셜링크 편집 다이얼로그
void showSocialLinksEditDialog(
  BuildContext context,
  bool isDark, {
  required SocialLinks links,
  required void Function(SocialLinks) onSave,
}) {
  final igController = TextEditingController(text: links.instagram ?? '');
  final ytController = TextEditingController(text: links.youtube ?? '');
  final ttController = TextEditingController(text: links.tiktok ?? '');
  final twController = TextEditingController(text: links.twitter ?? '');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '소셜 링크 편집',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 20),
            _socialField(
                igController, 'Instagram', 'https://instagram.com/...', isDark),
            const SizedBox(height: 12),
            _socialField(
                ytController, 'YouTube', 'https://youtube.com/@...', isDark),
            const SizedBox(height: 12),
            _socialField(
                ttController, 'TikTok', 'https://tiktok.com/@...', isDark),
            const SizedBox(height: 12),
            _socialField(
                twController, 'X (Twitter)', 'https://x.com/...', isDark),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onSave(SocialLinks(
                    instagram:
                        igController.text.isNotEmpty ? igController.text : null,
                    youtube:
                        ytController.text.isNotEmpty ? ytController.text : null,
                    tiktok:
                        ttController.text.isNotEmpty ? ttController.text : null,
                    twitter:
                        twController.text.isNotEmpty ? twController.text : null,
                  ));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  '저장',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 삭제 확인 다이얼로그 (통합)
void showDeleteConfirmDialog(
  BuildContext context, {
  required String itemType,
  required String itemName,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$itemType 삭제'),
      content: Text('"$itemName"을(를) 삭제하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text('삭제', style: TextStyle(color: AppColors.danger)),
        ),
      ],
    ),
  );
}

// ===== 헬퍼 위젯 =====

Widget _socialField(
  TextEditingController controller,
  String label,
  String hint,
  bool isDark,
) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    style: TextStyle(
      color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
    ),
  );
}

Widget _imagePreviewStack(String path, bool isDark) {
  return Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.network(
          path,
          width: double.infinity,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.image, size: 40, color: Colors.grey),
          ),
        ),
      ),
      Positioned(
        top: 8,
        right: 8,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.edit, size: 16, color: Colors.white),
        ),
      ),
    ],
  );
}

Widget _cachedImagePreviewStack(String imageUrl, bool isDark) {
  return Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          height: 120,
          fit: BoxFit.cover,
        ),
      ),
      Positioned(
        top: 8,
        right: 8,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.edit, size: 16, color: Colors.white),
        ),
      ),
    ],
  );
}

Widget _imagePlaceholder(String label, bool isDark) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.add_photo_alternate_outlined,
        size: 40,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
      ),
      const SizedBox(height: 8),
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),
    ],
  );
}
