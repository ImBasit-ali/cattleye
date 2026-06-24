import 'package:flutter/foundation.dart';
import '../models/cattle_analysis_result.dart';
import '../data/repositories/cattle_analysis_repository_impl.dart';
import '../services/analysis_cache_service.dart';
import '../services/ai_storage_service.dart';

enum AnalysisState { idle, loading, success, error }

class CattleAnalysisProvider extends ChangeNotifier {
  final _repository = CattleAnalysisRepositoryImpl.instance;
  final _cache = AnalysisCacheService();
  final _storage = AiStorageService();

  AnalysisState _state = AnalysisState.idle;
  CattleAnalysisResult? _result;
  String? _errorMessage;
  String? _activeCameraId;
  bool _isGeneratingReport = false;
  String? _vetReport;

  AnalysisState get state => _state;
  CattleAnalysisResult? get result => _result;
  String? get errorMessage => _errorMessage;
  String? get activeCameraId => _activeCameraId;
  bool get isLoading => _state == AnalysisState.loading;
  bool get isGeneratingReport => _isGeneratingReport;
  String? get vetReport => _vetReport;
  int get cachedCount => _cache.cachedCount;

  Future<void> analyzeImage({
    required Uint8List imageBytes,
    String? cameraId,
    String? animalId,
    String? sourceType,
    String? videoFileName,
    bool forceRefresh = false,
  }) async {
    _activeCameraId = cameraId;
    _state = AnalysisState.loading;
    _errorMessage = null;
    _vetReport = null;
    notifyListeners();

    try {
      _result = await _repository.analyzeImage(
        imageBytes: imageBytes,
        cameraId: cameraId,
        forceRefresh: forceRefresh,
      );
      _state = AnalysisState.success;

      _storage.saveAnalysis(
        result: _result!,
        cameraId: cameraId,
        animalId: animalId,
        sourceType: sourceType ?? (cameraId != null ? 'live_camera' : 'video_upload'),
        videoFileName: videoFileName,
      );
    } catch (e) {
      _errorMessage = formatAnalysisFailure(e);
      _state = AnalysisState.error;
    }

    notifyListeners();
  }

  Future<void> generateVetReport() async {
    if (_result == null) return;
    _isGeneratingReport = true;
    notifyListeners();
    try {
      _vetReport = await _repository.generateVetReport(_result!);
    } catch (e) {
      _vetReport = 'Failed to generate report: $e';
    }
    _isGeneratingReport = false;
    notifyListeners();
  }

  Future<void> clearCache() async {
    await _cache.clearAll();
    notifyListeners();
  }

  void reset() {
    _state = AnalysisState.idle;
    _result = null;
    _errorMessage = null;
    _vetReport = null;
    notifyListeners();
  }
}
