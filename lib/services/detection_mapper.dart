import '../models/cattle_analysis_result.dart';

/// Maps AI analysis results to `cattle_detections` Supabase rows.
class DetectionMapper {
  DetectionMapper._();

  static String resolveCattleId(CattleAnalysisResult result, {String prefix = 'LIVE'}) {
    final tag = result.earTag.tagNumber?.trim();
    if (tag != null && tag.isNotEmpty) return tag;
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}';
  }

  static Map<String, dynamic> fromLiveAnalysis(
    CattleAnalysisResult result, {
    required String cattleId,
  }) {
    return {
      'cattle_id': cattleId,
      'confidence': (result.earTag.ocrConfidence / 100.0).clamp(0.0, 1.0),
      'cattle_count': 1,
      'buffalo_count': 0,
      'lameness_score': result.lameness.locomotionScore.toDouble(),
      'is_lame': result.lameness.detected,
      'milking_status': _milkingFromLive(result),
      'bcs_score': result.bcs.score,
      'feeding_alert': result.feeding.currentBehavior != 'feeding' &&
          result.feeding.currentBehavior != 'drinking',
      'source': 'live_camera',
      'detected_at': DateTime.now().toIso8601String(),
    };
  }

  static String _milkingFromLive(CattleAnalysisResult result) {
    final summary = result.overall.summary.toLowerCase();
    if (summary.contains('lactat') || summary.contains('milking')) {
      return 'lactating';
    }
    if (summary.contains('dry')) return 'dry';
    return 'unknown';
  }
}
