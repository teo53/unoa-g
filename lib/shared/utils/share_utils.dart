import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base URL for web profile pages
const _webBaseUrl = 'https://unoa-app-demo.web.app';

/// Share an artist profile link
Future<void> shareArtistProfile({
  required String artistId,
  required String artistName,
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final url = '$_webBaseUrl/artist/$artistId';
  final text = '$artistName 프로필을 확인해보세요!\n$url';

  final isDemoMode = ref.read(isDemoModeProvider);
  if (isDemoMode) {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 링크가 복사되었습니다')),
      );
    }
    return;
  }

  await Share.share(text);
}

/// Share creator content (drops, events, fancams)
Future<void> shareCreatorContent({
  required String type,
  required String title,
  required String artistId,
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final url = '$_webBaseUrl/artist/$artistId';
  final typeLabel = switch (type) {
    'drop' => '굿즈',
    'event' => '이벤트',
    'fancam' => '직캠',
    _ => '콘텐츠',
  };
  final text = '[$typeLabel] $title\n$url';

  final isDemoMode = ref.read(isDemoModeProvider);
  if (isDemoMode) {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$typeLabel 링크가 복사되었습니다')),
      );
    }
    return;
  }

  await Share.share(text);
}

/// Share a funding campaign
Future<void> shareFundingCampaign({
  required String campaignId,
  required String campaignTitle,
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final url = '$_webBaseUrl/funding/$campaignId';
  final text = '[$campaignTitle] 펀딩에 참여해보세요!\n$url';

  final isDemoMode = ref.read(isDemoModeProvider);
  if (isDemoMode) {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('펀딩 링크가 복사되었습니다')),
      );
    }
    return;
  }

  await Share.share(text);
}
