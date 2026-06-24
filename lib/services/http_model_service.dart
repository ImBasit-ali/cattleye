import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/backend_config.dart';
import '../domain/exceptions/analysis_exceptions.dart';
import '../models/cattle_analysis_result.dart';
import '../models/video_analysis_result.dart';
import '../services/video_preview_service.dart';
import 'settings_service.dart';

/// Calls the Python PyTorch backend (.pth / .pt) on local dev or Render.
class HttpModelService {
  static final HttpModelService instance = HttpModelService._();
  HttpModelService._();

  bool _ready = false;
  late String _baseUrl;

  bool get isReady => _ready;
  String get baseUrl => _ready ? _baseUrl : BackendConfig.modelBackendUrl;

  /// Clear ready state so [initialize] can reconnect (e.g. after backend starts).
  void reset() {
    _ready = false;
  }

  Future<void> initialize() async {
    if (_ready) return;

    final candidates = BackendConfig.modelBackendUrlCandidates;
    if (candidates.isEmpty) {
      throw AnalysisException(
        'Backend URL is missing. Set LOCAL_MODEL_BACKEND_URL (debug) or '
        'RENDER_MODEL_BACKEND_URL (release) in .env.',
      );
    }

    debugPrint(
      'HttpModelService: checking backend (${candidates.join(' → ')})…',
    );

    Object? lastError;
    for (final candidate in candidates) {
      _baseUrl = candidate;
      for (var attempt = 1;
          attempt <= BackendConfig.healthRetryAttempts;
          attempt++) {
        try {
          final resp = await http
              .get(Uri.parse('$_baseUrl/health'))
              .timeout(BackendConfig.healthTimeout);

          if (resp.statusCode != 200) {
            throw AnalysisException(
              'Backend not reachable at $_baseUrl (HTTP ${resp.statusCode}).',
            );
          }

          final body = jsonDecode(resp.body) as Map<String, dynamic>;
          if (body['status'] != 'ok') {
            throw AnalysisException(
              'Backend still loading PyTorch models (attempt $attempt).',
            );
          }

          _ready = true;
          debugPrint('HttpModelService: ready → $_baseUrl');
          return;
        } catch (e) {
          lastError = e;
          debugPrint(
            'HttpModelService: $candidate attempt $attempt failed: $e',
          );
          if (attempt < BackendConfig.healthRetryAttempts) {
            await Future<void>.delayed(BackendConfig.healthRetryDelay);
          }
        }
      }
    }

    final tried = candidates.join(', ');
    throw AnalysisException(
      'Could not reach the Python backend (tried: $tried).\n\n'
      '${BackendConfig.platformHint}'
      '${lastError != null ? '\n\n($lastError)' : ''}',
    );
  }

  String hashBytes(Uint8List bytes) {
    final sample = bytes.length > 102400 ? bytes.sublist(0, 102400) : bytes;
    return md5.convert(sample).toString();
  }

  Future<CattleAnalysisResult> analyzeImage(Uint8List jpegBytes) async {
    _ensureReady();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/analyze-image'),
    );
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        jpegBytes,
        filename: 'frame.jpg',
      ),
    );

    final streamed = await request.send().timeout(BackendConfig.analyzeTimeout);
    final resp = await http.Response.fromStream(streamed);
    _throwIfError(resp, noCattleStatus: 422);

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final hash = json['image_hash'] as String? ?? hashBytes(jpegBytes);
    return CattleAnalysisResult.fromJson(json, hash);
  }

  Future<VideoAnalysisResult> analyzeVideoPreview(
    Uint8List previewBytes,
    String videoFileName,
  ) async {
    _ensureReady();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/analyze-video-preview'),
    );
    request.fields['video_file_name'] = videoFileName;
    request.files.add(
      http.MultipartFile.fromBytes(
        'preview',
        previewBytes,
        filename: 'preview.jpg',
      ),
    );

    final streamed = await request.send().timeout(BackendConfig.analyzeTimeout);
    final resp = await http.Response.fromStream(streamed);
    _throwIfError(resp, noCattleStatus: 422);

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return VideoAnalysisResult.fromJson(json, videoFileName);
  }

  Future<VideoAnalysisResult> analyzeVideoFile(
    String filePath,
    String videoFileName,
  ) async {
    _ensureReady();

    final frames = await VideoPreviewService.extractMultiplePreviews(
      filePath,
      timeMsCandidates: SettingsService.instance.videoFrameSampleMs,
    );
    if (frames.isEmpty) {
      final single = await VideoPreviewService.extractPreview(filePath);
      if (single != null) frames.add(single);
    }
    if (frames.isEmpty) {
      throw AnalysisException(
        'Could not extract video frames. Install FFmpeg and ensure the video file is valid.',
      );
    }

    var bestCount = 0;
    Uint8List? bestFrame;

    for (final frame in frames) {
      await Future<void>.delayed(Duration.zero);
      final count = await _countCattleInFrame(frame);
      if (count > bestCount) {
        bestCount = count;
        bestFrame = frame;
      }
    }

    if (bestCount == 0 || bestFrame == null) {
      throw NoCattleInVideoException();
    }

    if (frames.length > 1) {
      return analyzeVideoFrames(frames, videoFileName);
    }

    return analyzeVideoPreview(bestFrame, videoFileName);
  }

  Future<VideoAnalysisResult> analyzeVideoFrames(
    List<Uint8List> frameBytes,
    String videoFileName,
  ) async {
    _ensureReady();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/analyze-video-frames'),
    );
    request.fields['video_file_name'] = videoFileName;
    for (var i = 0; i < frameBytes.length && i < 20; i++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'frames',
          frameBytes[i],
          filename: 'frame_$i.jpg',
        ),
      );
    }

    final streamed = await request.send().timeout(BackendConfig.analyzeTimeout);
    final resp = await http.Response.fromStream(streamed);
    _throwIfError(resp, noCattleStatus: 422);

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return VideoAnalysisResult.fromJson(json, videoFileName);
  }

  Future<int> _countCattleInFrame(Uint8List jpegBytes) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/count-cattle'),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          jpegBytes,
          filename: 'probe.jpg',
        ),
      );
      final streamed =
          await request.send().timeout(const Duration(seconds: 45));
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        return (json['cattle_count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  void _throwIfError(http.Response resp, {int noCattleStatus = 0}) {
    if (resp.statusCode == noCattleStatus) {
      throw NoCattleInVideoException();
    }
    if (resp.statusCode >= 200 && resp.statusCode < 300) return;

    String detail = resp.body;
    try {
      final parsed = jsonDecode(resp.body) as Map<String, dynamic>;
      detail = parsed['detail']?.toString() ?? detail;
    } catch (_) {}

    throw AnalysisException(
      detail.isEmpty ? 'Backend error (HTTP ${resp.statusCode})' : detail,
    );
  }

  void _ensureReady() {
    if (!_ready) {
      throw AnalysisException(
        'Python backend not connected.\n${BackendConfig.platformHint}',
      );
    }
  }
}
