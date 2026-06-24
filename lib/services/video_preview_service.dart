import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'video_ffmpeg_helper.dart';

/// Extracts one JPEG frame from a local video for AI analysis.
/// Desktop (Windows/macOS/Linux) uses FFmpeg CLI — mobile uses native plugins.
class VideoPreviewService {
  // Keep this list small on desktop: each candidate requires JPEG decode + model
  // inference to pick the best frame, which can freeze the UI if too many.
  static const _timeMsCandidates = [0, 1500, 5000, 12000];
  static bool _loggedMobilePluginHint = false;

  static bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  /// Returns JPEG bytes, or null if every extraction strategy fails.
  static Future<Uint8List?> extractPreview(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      debugPrint('VideoPreview: file not found — $filePath');
      return null;
    }

    // Desktop — FFmpeg only (mobile plugins are not registered on Windows).
    if (VideoFfmpegHelper.isDesktop) {
      for (final ms in _timeMsCandidates) {
        final bytes = await VideoFfmpegHelper.extractJpegFrame(
          filePath,
          timeSeconds: ms / 1000.0,
        );
        if (bytes != null && bytes.isNotEmpty) return bytes;
      }
      debugPrint(
        'VideoPreview: FFmpeg frame extraction failed on desktop. '
        'Install FFmpeg: https://ffmpeg.org/download.html',
      );
      return null;
    }

    // Mobile — native plugins.
    if (_isMobile) {
      final fromCompress = await _extractViaVideoCompress(filePath);
      if (fromCompress != null) return fromCompress;

      final fromThumbnail = await _extractViaVideoThumbnail(filePath);
      if (fromThumbnail != null) return fromThumbnail;
    }

    debugPrint('VideoPreview: no frame extracted for $filePath');
    return null;
  }

  /// Samples multiple timestamps — used to find a frame with visible cattle.
  static Future<List<Uint8List>> extractMultiplePreviews(
    String filePath, {
    List<int>? timeMsCandidates,
  }) async {
    final frames = <Uint8List>[];
    final candidates = timeMsCandidates ?? _timeMsCandidates;
    for (final ms in candidates) {
      Uint8List? bytes;
      if (VideoFfmpegHelper.isDesktop) {
        bytes = await VideoFfmpegHelper.extractJpegFrame(
          filePath,
          timeSeconds: ms / 1000.0,
        );
      } else if (_isMobile) {
        bytes = await _extractViaVideoThumbnailAt(filePath, ms);
      }
      if (bytes != null && bytes.isNotEmpty) {
        frames.add(bytes);
      }
    }
    return frames;
  }

  static Future<Uint8List?> _extractViaVideoThumbnailAt(
    String filePath,
    int timeMs,
  ) async {
    try {
      return await VideoThumbnail.thumbnailData(
        video: filePath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        quality: 65,
        timeMs: timeMs,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _extractViaVideoCompress(String filePath) async {
    for (final ms in _timeMsCandidates) {
      try {
        final position = _compressPositionArg(ms);
        final bytes = await VideoCompress.getByteThumbnail(
          filePath,
          quality: 65,
          position: position,
        );
        if (bytes != null && bytes.isNotEmpty) {
          debugPrint(
            'VideoPreview: video_compress OK at ${ms}ms (${bytes.length} bytes)',
          );
          return bytes;
        }
      } on MissingPluginException {
        _logMobilePluginHintOnce();
        return null;
      } catch (e) {
        debugPrint('VideoPreview: video_compress failed at ${ms}ms — $e');
      }
    }
    return null;
  }

  static int _compressPositionArg(int timeMs) {
    if (Platform.isAndroid) return timeMs * 1000;
    if (Platform.isIOS) return (timeMs / 1000).floor().clamp(0, 9999);
    return timeMs;
  }

  static Future<Uint8List?> _extractViaVideoThumbnail(String filePath) async {
    for (final ms in _timeMsCandidates) {
      try {
        final bytes = await VideoThumbnail.thumbnailData(
          video: filePath,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 720,
          quality: 65,
          timeMs: ms,
        );
        if (bytes != null && bytes.isNotEmpty) {
          debugPrint(
            'VideoPreview: video_thumbnail OK at ${ms}ms (${bytes.length} bytes)',
          );
          return bytes;
        }
      } on MissingPluginException {
        _logMobilePluginHintOnce();
        return null;
      } catch (e) {
        debugPrint('VideoPreview: video_thumbnail failed at ${ms}ms — $e');
      }
    }
    return null;
  }

  static void _logMobilePluginHintOnce() {
    if (_loggedMobilePluginHint) return;
    _loggedMobilePluginHint = true;
    debugPrint(
      'VideoPreview: native plugin not registered — '
      'run: flutter clean && flutter pub get && flutter run',
    );
  }
}
