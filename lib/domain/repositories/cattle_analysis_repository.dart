import 'dart:typed_data';

import '../../models/cattle_analysis_result.dart';
import '../../models/video_analysis_result.dart';

/// Domain contract for cattle vision analysis via Python PyTorch backend.
abstract class CattleAnalysisRepository {
  Future<void> ensureInitialized();

  bool get isReady;

  Future<CattleAnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    String? cameraId,
    bool forceRefresh = false,
  });

  Future<VideoAnalysisResult> analyzeVideoPreview({
    required Uint8List previewBytes,
    required String videoFileName,
  });

  Future<VideoAnalysisResult> analyzeVideoFile({
    required String filePath,
    required String videoFileName,
  });

  Future<String> generateVetReport(CattleAnalysisResult result);
}
