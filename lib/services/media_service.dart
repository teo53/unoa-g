import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
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
  final String url;
  final MediaType type;
  final Map<String, dynamic> metadata;

  const MediaUploadResult({
    required this.url,
    required this.type,
    required this.metadata,
  });
}

/// Service for handling media operations (pick, compress, upload)
class MediaService {
  final ImagePicker _picker = ImagePicker();
  static const _uuid = Uuid();

  // Max file sizes in bytes
  static const int maxImageSize = 10 * 1024 * 1024; // 10 MB
  static const int maxVideoSize = 100 * 1024 * 1024; // 100 MB
  static const int maxVoiceSize = 5 * 1024 * 1024; // 5 MB

  // Compression quality
  static const int imageQuality = 85;
  static const int thumbnailQuality = 70;
  static const int thumbnailMaxWidth = 300;

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
        imageQuality: quality ?? imageQuality,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
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
        imageQuality: quality ?? imageQuality,
        limit: limit,
      );
      return images;
    } catch (e) {
      debugPrint('Error picking images: $e');
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
        maxDuration: maxDuration ?? const Duration(minutes: 5),
      );
      return video;
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  /// Compress an image file
  Future<Uint8List?> compressImage(
    XFile file, {
    int quality = imageQuality,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // For web, return original bytes
      if (kIsWeb) {
        return await file.readAsBytes();
      }

      // For mobile, use flutter_image_compress
      // Note: This would need the flutter_image_compress package
      // For now, return original bytes
      final bytes = await file.readAsBytes();

      // Check size
      if (bytes.length > maxImageSize) {
        throw StateError('Image too large (max ${maxImageSize ~/ 1024 ~/ 1024} MB)');
      }

      return bytes;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  /// Generate thumbnail for an image
  Future<Uint8List?> generateThumbnail(XFile file) async {
    return compressImage(
      file,
      quality: thumbnailQuality,
      maxWidth: thumbnailMaxWidth,
      maxHeight: thumbnailMaxWidth,
    );
  }

  /// Upload media to Supabase Storage
  Future<MediaUploadResult?> uploadMedia(
    XFile file, {
    required String channelId,
    required String userId,
    MediaType? type,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final extension = path.extension(file.path).toLowerCase();
      final fileName = '${_uuid.v4()}$extension';
      final filePath = 'channels/$channelId/media/$userId/$fileName';

      // Determine media type
      final mediaType = type ?? _getMediaType(extension);

      // Validate file size
      _validateFileSize(bytes.length, mediaType);

      // Upload to Supabase Storage
      await SupabaseConfig.client.storage
          .from('chat-media')
          .uploadBinary(filePath, bytes);

      // Get public URL
      final url = SupabaseConfig.client.storage
          .from('chat-media')
          .getPublicUrl(filePath);

      // Build metadata
      final metadata = await _buildMetadata(file, bytes, mediaType);

      return MediaUploadResult(
        url: url,
        type: mediaType,
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('Error uploading media: $e');
      rethrow;
    }
  }

  /// Upload multiple media files
  Future<List<MediaUploadResult>> uploadMultipleMedia(
    List<XFile> files, {
    required String channelId,
    required String userId,
    void Function(int completed, int total)? onProgress,
  }) async {
    final results = <MediaUploadResult>[];

    for (var i = 0; i < files.length; i++) {
      final result = await uploadMedia(
        files[i],
        channelId: channelId,
        userId: userId,
      );
      if (result != null) {
        results.add(result);
      }
      onProgress?.call(i + 1, files.length);
    }

    return results;
  }

  /// Delete media from storage
  Future<void> deleteMedia(String url) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('chat-media');
      if (bucketIndex == -1) return;

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      await SupabaseConfig.client.storage
          .from('chat-media')
          .remove([filePath]);
    } catch (e) {
      debugPrint('Error deleting media: $e');
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

  void _validateFileSize(int sizeInBytes, MediaType type) {
    final maxSize = switch (type) {
      MediaType.image => maxImageSize,
      MediaType.video => maxVideoSize,
      MediaType.voice => maxVoiceSize,
      MediaType.file => maxImageSize,
    };

    if (sizeInBytes > maxSize) {
      final maxMb = maxSize ~/ 1024 ~/ 1024;
      throw StateError('File too large (max $maxMb MB)');
    }
  }

  Future<Map<String, dynamic>> _buildMetadata(
    XFile file,
    Uint8List bytes,
    MediaType type,
  ) async {
    final metadata = <String, dynamic>{
      'size': bytes.length,
      'extension': path.extension(file.path),
      'original_name': path.basename(file.path),
      'uploaded_at': DateTime.now().toIso8601String(),
    };

    // Add type-specific metadata
    switch (type) {
      case MediaType.image:
        // Would use image package to get dimensions
        metadata['type'] = 'image';
        break;
      case MediaType.video:
        metadata['type'] = 'video';
        // Would use video_compress to get duration
        break;
      case MediaType.voice:
        metadata['type'] = 'voice';
        break;
      case MediaType.file:
        metadata['type'] = 'file';
        break;
    }

    return metadata;
  }
}

/// Voice recording service
class VoiceRecordingService {
  bool _isRecording = false;
  String? _recordingPath;

  bool get isRecording => _isRecording;

  /// Start recording voice
  Future<void> startRecording() async {
    if (_isRecording) return;

    // Note: Would need record package for actual recording
    // This is a placeholder implementation
    _isRecording = true;
    debugPrint('Voice recording started');
  }

  /// Stop recording and return the file
  Future<XFile?> stopRecording() async {
    if (!_isRecording) return null;

    _isRecording = false;

    if (_recordingPath != null) {
      return XFile(_recordingPath!);
    }

    return null;
  }

  /// Cancel ongoing recording
  Future<void> cancelRecording() async {
    _isRecording = false;
    _recordingPath = null;
  }

  /// Get recording duration
  Duration getRecordingDuration() {
    // Would track actual recording duration
    return Duration.zero;
  }
}
