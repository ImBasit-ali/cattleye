import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/camera_model.dart';
import '../models/cattle_analysis_result.dart';
import '../models/video_analysis_result.dart';
import '../models/video_process_outcome.dart';
import '../domain/exceptions/analysis_exceptions.dart';
import '../data/repositories/cattle_analysis_repository_impl.dart';
import '../services/camera_service.dart';
import '../services/cattle_service.dart';
import '../services/detection_mapper.dart';
import '../services/ai_storage_service.dart';
import '../services/video_preview_service.dart';
import '../services/video_dedup_service.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';

/// Manages IP cameras, live frames, and on-device AI analysis.
class CameraProvider extends ChangeNotifier {
  static const String _prefsKey = 'ip_cameras_list';

  final _cameraService = CameraService();
  final _analysis = CattleAnalysisRepositoryImpl.instance;
  final _storage = AiStorageService();
  final _cattleService = CattleService.instance;
  final _videoDedup = VideoDedupService.instance;
  final _settings = SettingsService.instance;
  final _uuid = const Uuid();

  final List<CameraModel> _cameras = [];
  final Map<String, StreamSubscription<Uint8List>> _frameSubscriptions = {};
  final Map<String, Timer> _analysisTimers = {};

  List<CameraModel> get cameras => List.unmodifiable(_cameras);
  int get cameraCount => _cameras.length;
  int get connectedCount =>
      _cameras.where((c) => c.isConnected).length;

  Future<void> init() async {
    await _loadFromPrefs();
    for (final cam in _cameras.where((c) => c.isActive)) {
      connectCamera(cam.id);
    }
  }

  Future<CameraModel> addCamera({
    required String name,
    required String streamUrl,
    String? snapshotUrl,
    String cameraType = 'RGB',
    String functionalZone = 'Feeding Area',
  }) async {
    final camera = CameraModel(
      id: _uuid.v4(),
      name: name,
      streamUrl: streamUrl,
      snapshotUrl: snapshotUrl,
      cameraType: cameraType,
      functionalZone: functionalZone,
    );

    _cameras.add(camera);
    await _saveToPrefs();

    await _storage.upsertCameraFeed(
      cameraId: camera.id,
      cameraName: camera.name,
      cameraType: camera.cameraType,
      functionalZone: camera.functionalZone,
      streamUrl: camera.streamUrl,
    );

    connectCamera(camera.id);
    notifyListeners();
    return camera;
  }

  Future<void> removeCamera(String cameraId) async {
    disconnectCamera(cameraId);
    _cameras.removeWhere((c) => c.id == cameraId);
    await _saveToPrefs();
    await _storage.deactivateCameraFeed(cameraId);
    notifyListeners();
  }

  void connectCamera(String cameraId) {
    final idx = _cameras.indexWhere((c) => c.id == cameraId);
    if (idx == -1) return;

    _cameras[idx].connectionState = CameraConnectionState.connecting;
    notifyListeners();

    final stream = _cameraService.startStream(_cameras[idx]);

    var firstFrame = true;
    _frameSubscriptions[cameraId]?.cancel();
    _frameSubscriptions[cameraId] = stream.listen(
      (frame) {
        final camIdx = _cameras.indexWhere((c) => c.id == cameraId);
        if (camIdx == -1) return;

        _cameras[camIdx].currentFrame = frame;
        _cameras[camIdx].lastFrameTime = DateTime.now();
        _cameras[camIdx].frameCount++;

        if (firstFrame) {
          firstFrame = false;
          _cameras[camIdx].connectionState = CameraConnectionState.connected;
          _cameras[camIdx].errorMessage = null;
          _startAnalysisTimer(cameraId);
        }
        notifyListeners();
      },
      onError: (e) {
        final camIdx = _cameras.indexWhere((c) => c.id == cameraId);
        if (camIdx == -1) return;
        _cameras[camIdx].connectionState = CameraConnectionState.error;
        _cameras[camIdx].errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  void disconnectCamera(String cameraId) {
    _frameSubscriptions[cameraId]?.cancel();
    _frameSubscriptions.remove(cameraId);
    _analysisTimers[cameraId]?.cancel();
    _analysisTimers.remove(cameraId);
    _cameraService.stopStream(cameraId);

    final idx = _cameras.indexWhere((c) => c.id == cameraId);
    if (idx != -1) {
      _cameras[idx].connectionState = CameraConnectionState.disconnected;
      notifyListeners();
    }
  }

  void reconnectCamera(String cameraId) {
    disconnectCamera(cameraId);
    Future.delayed(const Duration(seconds: 1), () => connectCamera(cameraId));
  }

  Future<CattleAnalysisResult?> analyzeCurrentFrame(String cameraId) async {
    final idx = _cameras.indexWhere((c) => c.id == cameraId);
    if (idx == -1) return null;

    final frame = _cameras[idx].currentFrame;
    if (frame == null || frame.isEmpty) return null;

    return _runAnalysis(cameraId, frame, idx);
  }

  Future<VideoProcessOutcome> processVideoFile({
    required String filePath,
    required String videoFileName,
    void Function(String status)? onProgress,
  }) async {
    if (!_settings.autoProcessVideos) {
      throw AnalysisException(
        'Auto video processing is disabled. Enable it in Settings → AI Detection.',
      );
    }

    if (!_analysis.isReady) {
      await _analysis.ensureInitialized();
    }

    onProgress?.call('Reading video file…');
    await Future<void>.delayed(Duration.zero);

    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Video file not found.');
    }

    onProgress?.call('Checking for duplicate video…');
    final fileHash = await _videoDedup.hashFile(filePath);
    if (await _videoDedup.isProcessed(fileHash)) {
      throw VideoAlreadyProcessedException();
    }

    onProgress?.call('Extracting frames and detecting cattle…');
    onProgress?.call(
      'Running PyTorch models (ear tag, muzzle, BCS, lameness, behavior)…',
    );
    await Future<void>.delayed(Duration.zero);

    var analysis = await _analysis.analyzeVideoFile(
      filePath: filePath,
      videoFileName: videoFileName,
    );

    var uniqueAnimals = dedupeVideoAnimals(analysis.animals);
    final threshold = _settings.detectionConfidence;
    uniqueAnimals = uniqueAnimals
        .where((a) => a.confidence >= threshold)
        .toList(growable: false);

    if (uniqueAnimals.isEmpty) {
      throw AnalysisException(
        'No cattle met the confidence threshold (${(threshold * 100).toInt()}%). '
        'Lower the threshold in Settings → AI Detection.',
      );
    }
    if (uniqueAnimals.length != analysis.animals.length) {
      debugPrint(
        'processVideoFile: filtered/deduped ${analysis.animals.length} → ${uniqueAnimals.length} cattle',
      );
    }
    analysis = VideoAnalysisResult(
      cattleCount: uniqueAnimals.length,
      buffaloCount: analysis.buffaloCount,
      animals: uniqueAnimals,
      videoFileName: videoFileName,
    );

    final preview = await VideoPreviewService.extractPreview(filePath);
    final previewForStorage =
        preview ?? Uint8List.fromList([videoFileName.hashCode]);

    if (analysis.animals.isEmpty) {
      throw NoCattleInVideoException();
    }

    onProgress?.call('Saving ${analysis.animals.length} detection(s)…');
    await Future<void>.delayed(Duration.zero);
    final errors = <String>[];
    var saved = 0;
    final savedRows = <CattleDetection>[];

    // Fast path: batch upserts/inserts to reduce Supabase round-trips.
    // If anything goes wrong, fall back to the existing per-animal loop.
    try {
      final tags = analysis.animals.map((a) => a.cattleId).toList(growable: false);

      onProgress?.call('Registering animals…');
      await _cattleService.ensureAnimalRecordsBatch(
        animals: analysis.animals
            .map((a) => {'cattleId': a.cattleId, 'healthStatus': a.healthStatus})
            .toList(growable: false),
      );

      onProgress?.call('Saving detections…');
      final inserted = await _cattleService.insertDetectionsBatch(
        analysis.animals.map((a) => a.toDetectionRow()).toList(growable: false),
      );
      if (inserted.isEmpty) {
        errors.add(
          _cattleService.isDetectionsTableReady
              ? 'Failed to save detections.'
              : 'Database table missing — run 11_cattle_detections.sql in Supabase',
        );
      } else {
        saved = inserted.length;
        savedRows.addAll(inserted);
        await _videoDedup.markProcessed(fileHash);
      }

      if (_settings.saveProcessedVideos) {
        onProgress?.call('Saving AI analysis results…');
        final uuidMap = await _cattleService.resolveAnimalUuidsBatch(tags);
        final items = analysis.animals
            .map((a) => _analysisFromVideoAnimal(a, previewForStorage))
            .toList(growable: false);
        await _storage.saveVideoAnalysesBatchFast(
          results: items,
          videoFileName: videoFileName,
          animalUuidByTag: {
            for (final t in tags) t: uuidMap[t],
          },
        );
      }
    } catch (e) {
      debugPrint('processVideoFile batch save failed; falling back — $e');
      // Fall back to the existing per-animal behavior.
      for (final animal in analysis.animals) {
        try {
          await _cattleService.ensureAnimalRecord(
            cattleId: animal.cattleId,
            healthStatus: animal.healthStatus,
          );

          final detection =
              await _cattleService.insertDetection(animal.toDetectionRow());
          if (detection == null) {
            errors.add(
              _cattleService.isDetectionsTableReady
                  ? 'Failed to save detection for ${animal.cattleId}'
                  : 'Database table missing — run 11_cattle_detections.sql in Supabase',
            );
            continue;
          }
          saved++;
          savedRows.add(detection);

          if (_settings.saveProcessedVideos) {
            await _storage.saveAnalysis(
              result: _analysisFromVideoAnimal(animal, previewForStorage),
              sourceType: 'video_upload',
              videoFileName: videoFileName,
              cattleTag: animal.cattleId,
            );
          }
        } catch (inner) {
          errors.add('${animal.cattleId}: $inner');
          debugPrint('processVideoFile save error: $inner');
        }
      }
      if (saved > 0) {
        await _videoDedup.markProcessed(fileHash);
      }
    }

    onProgress?.call(
      saved > 0
          ? 'Done — $saved cattle saved.'
          : 'Analysis done but database save failed.',
    );

    notifyListeners();
    return VideoProcessOutcome(
      analysis: analysis,
      savedDetections: saved,
      savedDetectionRows: savedRows,
      errors: errors,
    );
  }

  CattleAnalysisResult _analysisFromVideoAnimal(
    VideoAnimalDetection animal,
    Uint8List preview,
  ) {
    final hash = preview.length.toString();
    return CattleAnalysisResult(
      imageHash: hash,
      analyzedAt: DateTime.now(),
      earTag: EarTagResult(
        detected: !animal.cattleId.startsWith('VID-'),
        tagNumber: animal.cattleId,
        tagPosition: 'not visible',
        ocrConfidence: (animal.confidence * 100).round(),
        notes: 'From video upload',
      ),
      muzzle: const MuzzleResult(
        detected: false,
        patternDescription: '',
        breedEstimate: 'Unknown',
        distinctiveness: 'medium',
        biometricFeatures: [],
        notes: 'Video analysis',
      ),
      bcs: BcsResult(
        score: animal.bcsScore,
        category: 'Optimal',
        visibleRibs: false,
        spineVisible: false,
        hipBones: 'normal',
        recommendation: '',
        confidence: (animal.confidence * 100).round(),
      ),
      lameness: LamenessResult(
        detected: animal.isLame,
        locomotionScore: animal.lamenessScore.round().clamp(1, 5),
        posture: animal.isLame ? 'slightly arched' : 'normal',
        weightDistribution: animal.isLame ? 'uneven' : 'even',
        affectedLimb: animal.isLame ? 'cannot determine' : 'none',
        urgency: animal.isLame ? 'veterinary attention' : 'none',
        confidence: (animal.confidence * 100).round(),
      ),
      feeding: FeedingResult(
        currentBehavior:
            animal.feedingAlert ? 'unknown' : 'feeding',
        headPosition: 'level',
        locationZone: 'unknown',
        feedingEngagement: animal.feedingAlert ? 20 : 70,
        notes: 'Video upload analysis',
      ),
      overall: OverallHealth(
        status: animal.healthStatus,
        priorityAlert: animal.isLame ? 'Lameness detected' : null,
        summary:
            'Cattle ${animal.cattleId}: BCS ${animal.bcsScore}, '
            'milking ${animal.milkingStatus}.',
      ),
    );
  }

  void reconfigureAnalysisTimers() {
    for (final cam in _cameras.where((c) => c.isConnected)) {
      _startAnalysisTimer(cam.id);
    }
  }

  void _startAnalysisTimer(String cameraId) {
    _analysisTimers[cameraId]?.cancel();
    _analysisTimers[cameraId] = Timer.periodic(
      _settings.liveAnalysisInterval,
      (_) async {
        final idx = _cameras.indexWhere((c) => c.id == cameraId);
        if (idx == -1) return;
        final frame = _cameras[idx].currentFrame;
        if (frame != null && frame.isNotEmpty) {
          await _runAnalysis(cameraId, frame, idx);
        }
      },
    );
  }

  bool _meetsConfidenceThreshold(CattleAnalysisResult result) {
    final threshold = _settings.detectionConfidence;
    final scores = [
      result.earTag.ocrConfidence / 100.0,
      result.lameness.confidence / 100.0,
      result.bcs.confidence / 100.0,
    ];
    return scores.reduce((a, b) => a > b ? a : b) >= threshold;
  }

  Future<CattleAnalysisResult?> _runAnalysis(
      String cameraId, Uint8List frame, int camIdx) async {
    try {
      final result = await _analysis.analyzeImage(
        imageBytes: frame,
        cameraId: cameraId,
      );

      if (!_meetsConfidenceThreshold(result)) {
        debugPrint('Live analysis skipped: below confidence threshold');
        return null;
      }

      _cameras[camIdx].lastAnalysis = result;
      _cameras[camIdx].lastAnalysisTime = DateTime.now();
      notifyListeners();

      if (_settings.saveProcessedVideos) {
        await _storage.saveAnalysis(
          result: result,
          cameraId: cameraId,
          sourceType: 'live_camera',
        );
      }

      final cattleId = DetectionMapper.resolveCattleId(result);
      await _cattleService.ensureAnimalRecord(
        cattleId: cattleId,
        healthStatus: result.overall.status,
      );
      final detection = await _cattleService.insertDetection(
        DetectionMapper.fromLiveAnalysis(result, cattleId: cattleId),
      );

      if (detection != null && !_settings.autoSync) {
        NotificationService.instance.notifyDetection(
          cattleId: detection.cattleId,
          isLame: detection.isLame,
          lamenessScore: detection.lamenessScore,
          milkingStatus: detection.milkingStatus,
          feedingAlert: detection.feedingAlert,
        );
      }

      return result;
    } catch (e) {
      debugPrint('Live analysis error: $e');
      return null;
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _cameras.map((c) => c.toJsonString()).toList();
    await prefs.setString(_prefsKey, jsonEncode(list));
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _cameras.clear();
      for (final item in list) {
        _cameras.add(CameraModel.fromJsonString(item as String));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final sub in _frameSubscriptions.values) {
      sub.cancel();
    }
    for (final timer in _analysisTimers.values) {
      timer.cancel();
    }
    _cameraService.stopAll();
    super.dispose();
  }
}
