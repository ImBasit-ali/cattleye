import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cattle_analysis_result.dart';
import '../core/constants/app_constants.dart';
import 'cattle_service.dart';

/// Persists on-device AI analysis results into Supabase tables.
/// Uses existing schema (camera_feeds, bcs_records, feeding_records,
/// lameness_records) and the new cattle_ai_analyses table for full results.
class AiStorageService {
  static final AiStorageService _instance = AiStorageService._();
  factory AiStorageService() => _instance;
  AiStorageService._();

  SupabaseClient get _db => Supabase.instance.client;
  final _cattleService = CattleService.instance;

  String? get _userId => _db.auth.currentUser?.id;

  // ── Save full analysis ────────────────────────────────────────────────────

  /// Save a complete cattle analysis result to the ai_analyses table.
  /// [animalId] must be animals.id UUID, OR pass [cattleTag] to resolve it.
  Future<void> saveAnalysis({
    required CattleAnalysisResult result,
    String? cameraId,
    String? animalId,
    String? cattleTag,
    String? sourceType, // 'live_camera' | 'video_upload'
    String? videoFileName,
  }) async {
    final uid = _userId;
    if (uid == null) {
      debugPrint('AiStorageService: no user — skip save');
      return;
    }

    // Resolve UUID — never pass ear-tag strings into the UUID column
    String? animalUuid = animalId;
    final tag = cattleTag ?? result.earTag.tagNumber;
    if (animalUuid == null && tag != null && tag.isNotEmpty) {
      animalUuid = await _cattleService.resolveAnimalUuid(tag);
    }

    try {
      await _db.from(AppConstants.aiAnalysesTable).insert({
        'user_id': uid,
        'image_hash': result.imageHash,
        'analyzed_at': result.analyzedAt.toIso8601String(),
        'camera_id': cameraId,
        'animal_id': animalUuid,
        'source_type': sourceType ?? 'live_camera',
        'video_file_name': videoFileName,
        'ear_tag_detected': result.earTag.detected,
        'ear_tag_number': result.earTag.tagNumber ?? tag,
        'ear_tag_confidence': result.earTag.ocrConfidence,
        'breed_estimate': result.muzzle.breedEstimate,
        'bcs_score': result.bcs.score,
        'bcs_category': result.bcs.category,
        'lameness_detected': result.lameness.detected,
        'lameness_score': result.lameness.locomotionScore,
        'lameness_urgency': result.lameness.urgency,
        'feeding_behavior': result.feeding.currentBehavior,
        'feeding_engagement': result.feeding.feedingEngagement,
        'health_status': result.overall.status,
        'priority_alert': result.overall.priorityAlert,
        'full_result': result.toJson(),
      });
      debugPrint('AiStorageService: saved analysis for ${tag ?? 'unknown'}');

      if (animalUuid != null) {
        await _saveBcsRecord(result, uid, animalUuid, cameraId);
        if (result.lameness.detected) {
          await _saveLamenessRecord(result, uid, animalUuid, cameraId);
        }
        await _saveFeedingRecord(result, uid, animalUuid, cameraId);
      }

      if (result.lameness.urgency == 'urgent' ||
          result.overall.status == 'Critical') {
        await _raiseVetAlert(result, uid, animalUuid);
      }
    } catch (e) {
      debugPrint('AiStorageService: failed to save — $e');
      rethrow;
    }
  }

  // ── Save batch (video processing) ────────────────────────────────────────

  Future<void> saveVideoAnalysisBatch({
    required List<CattleAnalysisResult> results,
    required String videoFileName,
    String? animalId,
  }) async {
    for (final result in results) {
      await saveAnalysis(
        result: result,
        animalId: animalId,
        sourceType: 'video_upload',
        videoFileName: videoFileName,
      );
    }
  }

  /// Faster batch-save path for video processing.
  ///
  /// Inserts into `cattle_ai_analyses` in one request and batches the auxiliary
  /// tables (`bcs_records`, `feeding_records`, `lameness_records`,
  /// `veterinary_alerts`) to drastically reduce round-trips.
  ///
  /// This method expects animal UUIDs to already be resolved. If a UUID is not
  /// available, the analysis row is still saved but auxiliary rows are skipped
  /// (same behavior as `saveAnalysis`).
  Future<int> saveVideoAnalysesBatchFast({
    required List<CattleAnalysisResult> results,
    required String videoFileName,
    required Map<String, String?> animalUuidByTag,
    String? cameraId,
  }) async {
    final uid = _userId;
    if (uid == null) {
      debugPrint('AiStorageService: no user — skip batch save');
      return 0;
    }
    if (results.isEmpty) return 0;

    final analysisRows = <Map<String, dynamic>>[];
    final bcsRows = <Map<String, dynamic>>[];
    final feedingRows = <Map<String, dynamic>>[];
    final lamenessRows = <Map<String, dynamic>>[];
    final vetAlertRows = <Map<String, dynamic>>[];

    for (final r in results) {
      final now = DateTime.now();
      final tag = r.earTag.tagNumber;
      final uuid = (tag == null || tag.isEmpty) ? null : animalUuidByTag[tag];

      analysisRows.add({
        'user_id': uid,
        'image_hash': r.imageHash,
        'analyzed_at': r.analyzedAt.toIso8601String(),
        'camera_id': cameraId,
        'animal_id': uuid,
        'source_type': 'video_upload',
        'video_file_name': videoFileName,
        'ear_tag_detected': r.earTag.detected,
        'ear_tag_number': r.earTag.tagNumber ?? tag,
        'ear_tag_confidence': r.earTag.ocrConfidence,
        'breed_estimate': r.muzzle.breedEstimate,
        'bcs_score': r.bcs.score,
        'bcs_category': r.bcs.category,
        'lameness_detected': r.lameness.detected,
        'lameness_score': r.lameness.locomotionScore,
        'lameness_urgency': r.lameness.urgency,
        'feeding_behavior': r.feeding.currentBehavior,
        'feeding_engagement': r.feeding.feedingEngagement,
        'health_status': r.overall.status,
        'priority_alert': r.overall.priorityAlert,
        'full_result': r.toJson(),
      });

      if (uuid != null) {
        bcsRows.add({
          'animal_id': uuid,
          'user_id': uid,
          'bcs_score': r.bcs.score,
          'confidence': r.bcs.confidence.toDouble(),
          'assessment_method': 'AI-predicted',
          'camera_id': cameraId,
          'measurements': {
            'category': r.bcs.category,
            'visible_ribs': r.bcs.visibleRibs,
            'spine_visible': r.bcs.spineVisible,
            'hip_bones': r.bcs.hipBones,
            'recommendation': r.bcs.recommendation,
          },
        });

        feedingRows.add({
          'animal_id': uuid,
          'user_id': uid,
          'start_time': now.toIso8601String(),
          'functional_zone': _mapZone(r.feeding.locationZone),
          'camera_id': cameraId,
          'confidence': r.feeding.feedingEngagement.toDouble(),
          'behavior_data': {
            'behavior': r.feeding.currentBehavior,
            'head_position': r.feeding.headPosition,
            'engagement': r.feeding.feedingEngagement,
            'notes': r.feeding.notes,
          },
        });

        if (r.lameness.detected) {
          lamenessRows.add({
            'animal_id': uuid,
            'user_id': uid,
            'is_lame': r.lameness.detected,
            'lameness_score': r.lameness.locomotionScore,
            'severity': _mapUrgencyToSeverity(r.lameness.urgency),
            'camera_id': cameraId,
            'gait_analysis': {
              'posture': r.lameness.posture,
              'weight_distribution': r.lameness.weightDistribution,
              'affected_limb': r.lameness.affectedLimb,
              'urgency': r.lameness.urgency,
              'confidence': r.lameness.confidence,
            },
          });
        }
      }

      if (uuid != null &&
          (r.lameness.urgency == 'urgent' || r.overall.status == 'Critical')) {
        vetAlertRows.add({
          'animal_id': uuid,
          'user_id': uid,
          'alert_type': r.lameness.urgency == 'urgent'
              ? 'Lameness Detected'
              : 'Health Alert',
          'severity': r.lameness.urgency == 'urgent' ? 'Critical' : 'High',
          'message': r.overall.priorityAlert ?? r.overall.summary,
          'is_acknowledged': false,
        });
      }
    }

    await _db.from(AppConstants.aiAnalysesTable).insert(analysisRows);

    // Best-effort auxiliary inserts (keep same behavior as single-save where
    // missing UUID means "skip auxiliary tables").
    if (bcsRows.isNotEmpty) {
      try {
        await _db.from('bcs_records').insert(bcsRows);
      } catch (e) {
        debugPrint('AiStorageService: batch bcs_records failed — $e');
      }
    }
    if (feedingRows.isNotEmpty) {
      try {
        await _db.from('feeding_records').insert(feedingRows);
      } catch (e) {
        debugPrint('AiStorageService: batch feeding_records failed — $e');
      }
    }
    if (lamenessRows.isNotEmpty) {
      try {
        await _db.from('lameness_records').insert(lamenessRows);
      } catch (e) {
        debugPrint('AiStorageService: batch lameness_records failed — $e');
      }
    }
    if (vetAlertRows.isNotEmpty) {
      try {
        await _db.from('veterinary_alerts').insert(vetAlertRows);
      } catch (e) {
        debugPrint('AiStorageService: batch veterinary_alerts failed — $e');
      }
    }

    return analysisRows.length;
  }

  // ── Fetch recent analyses ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchRecentAnalyses({
    String? cameraId,
    int limit = 50,
  }) async {
    final uid = _userId;
    if (uid == null) return [];

    try {
      final List data;
      if (cameraId != null) {
        data = await _db
            .from(AppConstants.aiAnalysesTable)
            .select()
            .eq('user_id', uid)
            .eq('camera_id', cameraId)
            .order('analyzed_at', ascending: false)
            .limit(limit);
      } else {
        data = await _db
            .from(AppConstants.aiAnalysesTable)
            .select()
            .eq('user_id', uid)
            .order('analyzed_at', ascending: false)
            .limit(limit);
      }
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  // ── Camera feed registration ──────────────────────────────────────────────

  Future<void> upsertCameraFeed({
    required String cameraId,
    required String cameraName,
    required String cameraType,
    required String functionalZone,
    required String streamUrl,
  }) async {
    final uid = _userId;
    if (uid == null) return;

    try {
      await _db.from('camera_feeds').upsert({
        'user_id': uid,
        'camera_id': cameraId,
        'camera_name': cameraName,
        'camera_type': cameraType,
        'functional_zone': functionalZone,
        'view_type': 'Fixed',
        'stream_url': streamUrl,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'camera_id');
    } catch (_) {}
  }

  Future<void> deactivateCameraFeed(String cameraId) async {
    try {
      await _db
          .from('camera_feeds')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('camera_id', cameraId);
    } catch (_) {}
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _saveBcsRecord(
    CattleAnalysisResult result,
    String uid,
    String animalId,
    String? cameraId,
  ) async {
    await _db.from('bcs_records').insert({
      'animal_id': animalId,
      'user_id': uid,
      'bcs_score': result.bcs.score,
      'confidence': result.bcs.confidence.toDouble(),
      'assessment_method': 'AI-predicted',
      'camera_id': cameraId,
      'measurements': {
        'category': result.bcs.category,
        'visible_ribs': result.bcs.visibleRibs,
        'spine_visible': result.bcs.spineVisible,
        'hip_bones': result.bcs.hipBones,
        'recommendation': result.bcs.recommendation,
      },
    });
  }

  Future<void> _saveLamenessRecord(
    CattleAnalysisResult result,
    String uid,
    String animalId,
    String? cameraId,
  ) async {
    await _db.from('lameness_records').insert({
      'animal_id': animalId,
      'user_id': uid,
      'is_lame': result.lameness.detected,
      'lameness_score': result.lameness.locomotionScore,
      'severity': _mapUrgencyToSeverity(result.lameness.urgency),
      'camera_id': cameraId,
      'gait_analysis': {
        'posture': result.lameness.posture,
        'weight_distribution': result.lameness.weightDistribution,
        'affected_limb': result.lameness.affectedLimb,
        'urgency': result.lameness.urgency,
        'confidence': result.lameness.confidence,
      },
    });
  }

  Future<void> _saveFeedingRecord(
    CattleAnalysisResult result,
    String uid,
    String animalId,
    String? cameraId,
  ) async {
    final now = DateTime.now();
    await _db.from('feeding_records').insert({
      'animal_id': animalId,
      'user_id': uid,
      'start_time': now.toIso8601String(),
      'functional_zone': _mapZone(result.feeding.locationZone),
      'camera_id': cameraId,
      'confidence': result.feeding.feedingEngagement.toDouble(),
      'behavior_data': {
        'behavior': result.feeding.currentBehavior,
        'head_position': result.feeding.headPosition,
        'engagement': result.feeding.feedingEngagement,
        'notes': result.feeding.notes,
      },
    });
  }

  Future<void> _raiseVetAlert(
    CattleAnalysisResult result,
    String uid,
    String? animalId,
  ) async {
    if (animalId == null) return;
    await _db.from('veterinary_alerts').insert({
      'animal_id': animalId,
      'user_id': uid,
      'alert_type': result.lameness.urgency == 'urgent'
          ? 'Lameness Detected'
          : 'Health Alert',
      'severity':
          result.lameness.urgency == 'urgent' ? 'Critical' : 'High',
      'message': result.overall.priorityAlert ??
          result.overall.summary,
      'is_acknowledged': false,
    });
  }

  String _mapUrgencyToSeverity(String urgency) {
    switch (urgency) {
      case 'urgent':
        return 'Severe Lameness';
      case 'veterinary attention':
        return 'Mild Lameness';
      default:
        return 'Normal';
    }
  }

  String _mapZone(String zone) {
    if (zone.contains('feed')) return 'Feeding Area';
    if (zone.contains('rest')) return 'Resting Space';
    if (zone.contains('walk')) return 'Return Lane';
    return 'Feeding Area';
  }
}
