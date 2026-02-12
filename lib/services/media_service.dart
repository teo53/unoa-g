import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import '../core/utils/app_logger.dart';
import '../core/supabase/supabase_client.dart';

/// Media types supported by the chat system
enum MediaType {
  image,
  video,
  voice,
  file,
}

/// Result of media upload
class MediaUploadResult {
  final String mainUrl;
  final String? thumbUrl;
  final String mainPath; // Storage path for signed URL generation
  final String? thumbPath;
  final int? width;
  final int? height;
  final int? duration; // For video/voice in seconds
  final MediaType type;
  final Map<String, dynamic> metadata;

  const MediaUploadResult({
    required this.mainUrl,
    this.thumbUrl,
    required this.mainPath,
    this.thumbPath,
    this.width,
    this.height,
    this.duration,
    required this.type,
    required this.metadata,
  });

  /// Legacy getter for backward compatibility
  String get url => mainUrl;
}

/// Video validation result
class VideoValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int? durationSeconds;
  final int? fileSizeBytes;

  const VideoValidationResult({
    required this.isValid,
    this.errorMessage,
    this.durationSeconds,
    this.fileSizeBytes,
  });
}

/// Service for handling media operations (pick, compress, upload)
class MediaService {
  final ImagePicker _picker = ImagePicker();
  static const _uuid = Uuid();

  // Max file sizes in bytes
  static const int maxImageSize = 10 * 1024 * 1024; // 10 MB
  static const int maxVideoSize = 30 * 1024 * 1024; // 30 MB (MVP limit)
  static const int maxVoiceSize = 5 * 1024 * 1024; // 5 MB

  // Video constraints (MVP)
  static const int maxVideoDurationSeconds = 15; // 15 seconds max

  // Image compression settings
  static const int mainImageMaxWidth = 1280;
  static const int mainImageQuality = 80;
  static const int thumbImageMaxWidth = 480;
  static const int thumbImageQuality = 70;

  // Signed URL settings
  static const int signedUrlExpirationSeconds = 3600; // 1 hour

  /// Pick an image from gallery or camera
  Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: quality ?? mainImageQuality,
      );
      return image;
    } catch (e) {
      AppLogger.error(e, tag: 'Media', message: 'Error picking image');
      return null;
    }
  }

  /// Pick multiple images from gallery
  Future<List<XFile>> pickMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? quality,
    int limit = 10,
  }) async {
    try {
      final images = await _picker.pickMultiImage(
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: quality ?? mainImageQuality,
        limit: limit,
      );
      return images;
    } catch (e) {
      AppLogger.error(e, tag: 'Media', message: 'Error picking images');
      return [];
    }
  }

  /// Pick a video from gallery or camera
  Future<XFile?> pickVideo({
    ImageSource source = ImageSource.gallery,
    Duration? maxDuration,
  }) async {
    try {
      final video = await _picker.pickVideo(
        source: source,
        maxDuration:
            maxDuration ?? const Duration(seconds: maxVideoDurationSeconds),
      );
      return video;
    } catch (e) {
      AppLogger.error(e, tag: 'Media', message: 'Error picking video');
      return null;
    }
  }

  /// Validate video file (duration and size)
  Future<VideoValidationResult> validateVideo(XFile file) async {
    try {
      if (kIsWeb) {
        // Web: Basic size check only
        final bytes = await file.readAsBytes();
        if (bytes.length > maxVideoSize) {
          return VideoValidationResult(
            isValid: false,
            errorMessage: '동영상 크기가 ${maxVideoSize ~/ 1024 ~/ 1024}MB를 초과합니다.',
            fileSizeBytes: bytes.length,
          );
        }
        return VideoValidationResult(
          isValid: true,
          fileSizeBytes: bytes.length,
        );
      }

      // Mobile: Full validation with duration check
      final info = await VideoCompress.getMediaInfo(file.path);
      final durationSeconds = (info.duration ?? 0) ~/ 1000;
      final fileSizeBytes = info.filesize ?? 0;

      if (durationSeconds > maxVideoDurationSeconds) {
        return VideoValidationResult(
          isValid: false,
          errorMessage:
              '동영상 길이가 $maxVideoDurationSeconds초를 초과합니다. (현재: $durationSeconds초)',
          durationSeconds: durationSeconds,
          fileSizeBytes: fileSizeBytes,
        );
      }

      if (fileSizeBytes > maxVideoSize) {
        return VideoValidationResult(
          isValid: false,
          errorMessage: '동영상 크기가 ${maxVideoSize ~/ 1024 ~/ 1024}MB를 초과합니다.',
          durationSeconds: durationSeconds,
          fileSizeBytes: fileSizeBytes,
        );
      }

      return VideoValidationResult(
        isValid: true,
        durationSeconds: durationSeconds,
        fileSizeBytes: fileSizeBytes,
      );
    } catch (e) {
      AppLogger.error(e, tag: 'Media', message: 'Error validating video');
      return const VideoValidationResult(
        isValid: false,
        errorMessage: '동영상 검증 중 오류가 발생했습니다.',
      );
    }
  }

  /// Compress an image and return both main and thumbnail versions
  Future<({Uint8List main, Uint8List thumb, int width, int height})?>
      compressImageWithThumbnail(
    XFile file,
  ) async {
    try {
      final bytes = await file.readAsBytes();

      if (kIsWeb) {
        // Web: Return original (no compression available)
        return (main: bytes, thumb: bytes, width: 0, height: 0);
      }

      // Mobile: Use flutter_image_compress
      final mainResult = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: mainImageMaxWidth,
        minHeight: mainImageMaxWidth,
        quality: mainImageQuality,
        format: CompressFormat.webp,
      );

      final thumbResult = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: thumbImageMaxWidth,
        minHeight: thumbImageMaxWidth,
        quality: thumbImageQuality,
        format: CompressFormat.webp,
      );

      // Get dimensions (approximate based on compression settings)
      return (
        main: mainResult,
        thumb: thumbResult,
        width: mainImageMaxWidth,
        height: mainImageMaxWidth,
      );
    } catch (e) {
      AppLogger.error(e, tag: 'Media', message: 'Error compressing image');
      return null;
    }
  }

  /// Generate video thumbnail
  Future<Uint8List?> generateVideoThumbnail(XFile file) async {
    try {
      if (kIsWeb) {
        return null; // Video thumbnail not supported on web
      }

      final thumbnail = await VideoCompress.getByteThumbnail(
        file.path,
        quality: thumbImageQuality,
        position: 0, // First frame
      );

      return thumbnail;
    } catch (e) {
      AppLogger.error(e,
          tag: 'Media', message: 'Error generating video thumbnail');
      return null;
    }
  }

  /// Upload image with automatic compression and thumbnail generation
  Future<MediaUploadResult?> uploadImage(
    XFile file, {
    required String channelId,
    required String userId,
  }) async {
    try {
      // Compress and generate thumbnail
      final compressed = await compressImageWithThumbnail(file);
      if (compressed == null) {
        throw StateError('이미지 압축에 실패했습니다.');
      }

      // Validate size
      if (compressed.main.length > maxImageSize) {
        throw StateError('이미지 크기가 ${maxImageSize ~/ 1024 ~/ 1024}MB를 초과합니다.');
      }

      final fileId = _uuid.v4();
      final mainPath = 'channels/$channelId/media/$userId/${fileId}_main.webp';
      final thumbPath =
          'channels/$channelId/media/$userId/${fileId}_thumb.webp';

      // Upload main image
      await SupabaseConfig.client.storage
          .from('chat-media')
          .uploadBinary(mainPath, compressed.main);

      // Upload thumbnail
      await SupabaseConfig.client.storage
          .from('chat-media')
          .uploadBinary(thumbPath, compressed.thumb);

      // Get URLs (using public URL for now, can switch to signed URL)
      final mainUrl = SupabaseConfig.client.storage
          .from('chat-media')
          .getPublicUrl(mainPath);

      final thumbUrl = SupabaseConfig.client.storage
          .from('chat-media')
          .getPublicUrl(thumbPath);

      return MediaUploadResult(
        mainUrl: mainUrl,
        thumbUrl: thumbUrl,
        mainPath: mainPath,
        thumbPath: thumbPath,
        width: compressed.width,
        height: compressed.height,
        type: MediaType.image,
        metadata: {
          'type': 'image',
          'size': compressed.main.length,
          'thumb_size': compressed.thumb.length,
          'width': compressed.width,
          'height': compressed.height,
          'format': 'webp',
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.error(e, tag: 'Media', message: 'Error uploading image');
      rethrow;
    }
  }

  /// Upload video with validation and thumbnail generation
  Future<MediaUploadResult?> uploadVideo(
    XFile file, {
    required String channelId,
    required String userId,
  }) async {
    try {
      // Validate video
      final validation = await validateVideo(file);
      if (!validation.isValid) {
        throw StateError(validation.errorMessage ?? '동영상 검증 실패');
      }

      final bytes = await file.readAsBytes();
      final extension = path.extension(file.path).toLowerCase();
      final fileId = _uuid.v4();
      final mainPath = 'channels/$channelId/media/$userId/$fileId$extension';

      // Upload video
      await SupabaseConfig.client.storage
          .from('chat-media')
          .uploadBinary(mainPath, bytes);

      final mainUrl = SupabaseConfig.client.storage
          .from('chat-media')
          .getPublicUrl(mainPath);

      // Generate and upload thumbnail
      String? thumbUrl;
      String? thumbPath;
      final thumbnail = await generateVideoThumbnail(file);
      if (thumbnail != null) {
        thumbPath = 'channels/$channelId/media/$userId/${fileId}_thumb.jpg';
        await SupabaseConfig.client.storage
            .from('chat-media')
            .uploadBinary(thumbPath, thumbnail);
        thumbUrl = SupabaseConfig.client.storage
            .from('chat-media')
            .getPublicUrl(thumbPath);
      }

      return MediaUploadResult(
        mainUrl: mainUrl,
        thumbUrl: thumbUrl,
        mainPath: mainPath,
        thumbPath: thumbPath,
        duration: validation.durationSeconds,
        type: MediaType.video,
        metadata: {
          'type': 'video',
          'size': bytes.length,
          'duration': validation.durationSeconds,
          'thumbnail_url': thumbUrl,
          'format': extension.replaceAll('.', ''),
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.error(e, tag: 'Media', message: 'Error uploading video');
      rethrow;
    }
  }

  /// Upload voice message
  Future<MediaUploadResult?> uploadVoice(
    XFile file, {
    required String channelId,
    required String userId,
    int? durationSeconds,
  }) async {
    try {
      final bytes = await file.readAsBytes();

      if (bytes.length > maxVoiceSize) {
        throw StateError('음성 파일 크기가 ${maxVoiceSize ~/ 1024 ~/ 1024}MB를 초과합니다.');
      }

      final extension = path.extension(file.path).toLowerCase();
      final fileId = _uuid.v4();
      final mainPath = 'channels/$channelId/media/$userId/$fileId$extension';

      await SupabaseConfig.client.storage
          .from('chat-media')
          .uploadBinary(mainPath, bytes);

      final mainUrl = SupabaseConfig.client.storage
          .from('chat-media')
          .getPublicUrl(mainPath);

      return MediaUploadResult(
        mainUrl: mainUrl,
        mainPath: mainPath,
        duration: durationSeconds,
        type: MediaType.voice,
        metadata: {
          'type': 'voice',
          'size': bytes.length,
          'duration': durationSeconds,
          'format': extension.replaceAll('.', ''),
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.error(e, tag: 'Media', message: 'Error uploading voice');
      rethrow;
    }
  }

  /// Legacy upload method for backward compatibility
  Future<MediaUploadResult?> uploadMedia(
    XFile file, {
    required String channelId,
    required String userId,
    MediaType? type,
  }) async {
    final extension = path.extension(file.path).toLowerCase();
    final mediaType = type ?? _getMediaType(extension);

    switch (mediaType) {
      case MediaType.image:
        return uploadImage(file, channelId: channelId, userId: userId);
      case MediaType.video:
        return uploadVideo(file, channelId: channelId, userId: userId);
      case MediaType.voice:
        return uploadVoice(file, channelId: channelId, userId: userId);
      case MediaType.file:
        // For generic files, use the old upload method
        return _uploadGenericFile(file, channelId: channelId, userId: userId);
    }
  }

  Future<MediaUploadResult?> _uploadGenericFile(
    XFile file, {
    required String channelId,
    required String userId,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final extension = path.extension(file.path).toLowerCase();
      final fileName = '${_uuid.v4()}$extension';
      final filePath = 'channels/$channelId/media/$userId/$fileName';

      await SupabaseConfig.client.storage
          .from('chat-media')
          .uploadBinary(filePath, bytes);

      final url = SupabaseConfig.client.storage
          .from('chat-media')
          .getPublicUrl(filePath);

      return MediaUploadResult(
        mainUrl: url,
        mainPath: filePath,
        type: MediaType.file,
        metadata: {
          'type': 'file',
          'size': bytes.length,
          'extension': extension,
          'original_name': path.basename(file.path),
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.error(e, tag: 'Media', message: 'Error uploading file');
      rethrow;
    }
  }

  /// Generate signed URL for private bucket access
  Future<String> getSignedUrl(String storagePath, {int? expiresIn}) async {
    final result = await SupabaseConfig.client.storage
        .from('chat-media')
        .createSignedUrl(storagePath, expiresIn ?? signedUrlExpirationSeconds);
    return result;
  }

  /// Delete media from storage
  Future<void> deleteMedia(String storagePath) async {
    try {
      await SupabaseConfig.client.storage
          .from('chat-media')
          .remove([storagePath]);
    } catch (e) {
      AppLogger.error(e, tag: 'Media', message: 'Error deleting media');
    }
  }

  MediaType _getMediaType(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
      case '.heic':
        return MediaType.image;
      case '.mp4':
      case '.mov':
      case '.avi':
      case '.webm':
        return MediaType.video;
      case '.mp3':
      case '.m4a':
      case '.wav':
      case '.aac':
        return MediaType.voice;
      default:
        return MediaType.file;
    }
  }
}
