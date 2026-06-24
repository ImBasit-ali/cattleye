import '../services/cattle_service.dart';
import 'video_analysis_result.dart';

/// Outcome of processing an uploaded video — includes save status.
class VideoProcessOutcome {
  final VideoAnalysisResult analysis;
  final int savedDetections;
  final List<CattleDetection> savedDetectionRows;
  final List<String> errors;

  const VideoProcessOutcome({
    required this.analysis,
    required this.savedDetections,
    this.savedDetectionRows = const [],
    this.errors = const [],
    this.alreadyProcessed = false,
  });

  final bool alreadyProcessed;

  bool get hasSavedData => savedDetections > 0;
}
