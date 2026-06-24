import 'dart:typed_data';

import '../../domain/exceptions/analysis_exceptions.dart';
import '../../domain/repositories/cattle_analysis_repository.dart';
import '../../models/cattle_analysis_result.dart';
import '../../models/video_analysis_result.dart';
import '../../services/analysis_cache_service.dart';
import '../../services/http_model_service.dart';

class CattleAnalysisRepositoryImpl implements CattleAnalysisRepository {
  static final CattleAnalysisRepositoryImpl instance =
      CattleAnalysisRepositoryImpl._();

  CattleAnalysisRepositoryImpl._();

  final _backend = HttpModelService.instance;
  final _cache = AnalysisCacheService();

  @override
  Future<void> ensureInitialized() => _backend.initialize();

  @override
  bool get isReady => _backend.isReady;

  @override
  Future<CattleAnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    String? cameraId,
    bool forceRefresh = false,
  }) async {
    await ensureInitialized();
    final hash = _backend.hashBytes(imageBytes);

    if (!forceRefresh) {
      final cached = _cache.get(hash);
      if (cached != null) return cached;
    }

    final result = await _backend.analyzeImage(imageBytes);
    await _cache.put(hash, result);
    return result;
  }

  @override
  Future<VideoAnalysisResult> analyzeVideoPreview({
    required Uint8List previewBytes,
    required String videoFileName,
  }) async {
    await ensureInitialized();
    return _backend.analyzeVideoPreview(previewBytes, videoFileName);
  }

  @override
  Future<VideoAnalysisResult> analyzeVideoFile({
    required String filePath,
    required String videoFileName,
  }) async {
    await ensureInitialized();
    return _backend.analyzeVideoFile(filePath, videoFileName);
  }

  @override
  Future<String> generateVetReport(CattleAnalysisResult result) async {
    final r = result;
    return '''
CATTLE MONITORING REPORT (PyTorch backend)
──────────────────────────────────────────
Ear tag: ${r.earTag.detected ? (r.earTag.tagNumber ?? 'detected') : 'not detected'}
BCS: ${r.bcs.score} (${r.bcs.category}) — ${r.bcs.recommendation}
Lameness: ${r.lameness.detected ? 'YES (score ${r.lameness.locomotionScore}, ${r.lameness.urgency})' : 'No'}
Behavior: ${r.feeding.currentBehavior} (${r.feeding.feedingEngagement}% engagement)
Overall: ${r.overall.status}
${r.overall.summary}
''';
  }
}

String formatAnalysisFailure(Object? error) {
  if (error is NoCattleInVideoException) return NoCattleInVideoException.message;
  if (error is AnalysisException) return error.message;
  return error?.toString().replaceFirst('Exception: ', '') ?? 'Analysis failed';
}
