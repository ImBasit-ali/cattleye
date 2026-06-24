import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/animal.dart';
import '../services/cattle_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../core/utils/cattle_id_util.dart';

/// Row shown on the Animals screen (detection data merged with manual animals).
class CattleDisplayRow {
  final String earTagId;
  final String? milkingStatus;
  final bool? isLame;
  final double? lamenessScore;
  final bool hasDetection;
  final String? animalRecordId;

  const CattleDisplayRow({
    required this.earTagId,
    this.milkingStatus,
    this.isLame,
    this.lamenessScore,
    this.hasDetection = false,
    this.animalRecordId,
  });

  factory CattleDisplayRow.fromDetection(CattleDetection d) => CattleDisplayRow(
        earTagId: d.cattleId,
        milkingStatus: d.milkingStatus,
        isLame: d.isLame,
        lamenessScore: d.lamenessScore,
        hasDetection: true,
      );

  factory CattleDisplayRow.fromAnimal(Animal a) => CattleDisplayRow(
        earTagId: (a.earTag?.trim().isNotEmpty == true) ? a.earTag! : a.animalId,
        animalRecordId: a.id,
      );
}

/// CattleProvider — unified state for animals + detections + aggregated stats.
class CattleProvider with ChangeNotifier {
  final CattleService _service = CattleService.instance;

  List<Animal> _animals = [];
  bool _animalsLoading = false;
  String? _animalsError;

  List<Animal> get animals => _animals;
  bool get animalsLoading => _animalsLoading;
  String? get animalsError => _animalsError;

  List<CattleDetection> _todaysDetections = [];
  List<CattleDetection> _allDetections = [];
  bool _detectionsLoading = false;

  /// Today only — dashboard daily table & cattle info recent list.
  List<CattleDetection> get todaysDetections => _todaysDetections;

  /// Full history — milking screen, animals merge, stats source.
  List<CattleDetection> get allDetections => _allDetections;

  bool get detectionsLoading => _detectionsLoading;

  CattleDetection? get latestDetection =>
      _todaysDetections.isEmpty ? null : _todaysDetections.first;

  DashboardStats _stats = const DashboardStats();
  bool _statsLoading = false;
  String? _statsError;

  DashboardStats get stats => _stats;
  bool get statsLoading => _statsLoading;
  String? get statsError => _statsError;

  RealtimeChannel? _realtimeChannel;
  Timer? _syncTimer;
  bool _realtimeActive = false;
  bool get realtimeActive => _realtimeActive;

  final SettingsService _settings = SettingsService.instance;

  Future<void> initialize() async {
    await Future.wait([loadAnimals(), loadDetections()]);
    await applySyncSettings();
  }

  /// Reconfigure realtime + periodic sync when settings change.
  Future<void> applySyncSettings() async {
    _stopPeriodicSync();
    _stopRealtime();

    if (!_settings.autoSync) {
      _realtimeActive = false;
      notifyListeners();
      return;
    }

    if (!await _canSync()) {
      debugPrint('CattleProvider: sync paused (WiFi only)');
      _realtimeActive = false;
      notifyListeners();
      return;
    }

    _startRealtime();
    _startPeriodicSync();
  }

  Future<bool> _canSync() async {
    if (!_settings.wifiOnly) return true;
    final result = await Connectivity().checkConnectivity();
    return result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;
  }

  Future<bool> deleteAllUserData() async {
    final ok = await _service.deleteAllUserData();
    if (ok) clearData();
    return ok;
  }

  void clearData() {
    _animals = [];
    _todaysDetections = [];
    _allDetections = [];
    _stats = const DashboardStats();
    _animalsError = null;
    _statsError = null;
    _stopRealtime();
    notifyListeners();
    debugPrint('CattleProvider: data cleared');
  }

  Future<void> loadAnimals() async {
    _animalsLoading = true;
    _animalsError = null;
    notifyListeners();
    try {
      final rows = await _service.getAnimals();
      _animals = rows.map(_rowToAnimal).whereType<Animal>().toList();
    } catch (e) {
      _animalsError = e.toString();
      debugPrint('CattleProvider.loadAnimals error: $e');
    } finally {
      _animalsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAnimal(Map<String, dynamic> data) async {
    try {
      final created = await _service.createAnimal(data);
      if (created != null) {
        final a = _rowToAnimal(created);
        if (a != null) _animals.insert(0, a);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('CattleProvider.addAnimal error: $e');
      return false;
    }
  }

  Future<bool> updateAnimal(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateAnimal(id, data);
      if (updated != null) {
        final a = _rowToAnimal(updated);
        if (a != null) {
          final idx = _animals.indexWhere((x) => x.id == id);
          if (idx != -1) _animals[idx] = a;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('CattleProvider.updateAnimal error: $e');
      return false;
    }
  }

  Future<bool> deleteAnimal(String id) async {
    final ok = await _service.deleteAnimal(id);
    if (ok) {
      _animals.removeWhere((a) => a.id == id);
      notifyListeners();
    }
    return ok;
  }

  Future<void> loadDetections() async {
    _detectionsLoading = true;
    _statsLoading = true;
    _statsError = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getTodaysDetections(),
        _service.getAllDetections(),
      ]);
      _todaysDetections = results[0];
      _allDetections = results[1];
      _stats = DashboardStats.fromDetections(_allDetections);
    } catch (e) {
      _statsError = e.toString();
      debugPrint('CattleProvider.loadDetections error: $e');
    } finally {
      _detectionsLoading = false;
      _statsLoading = false;
      notifyListeners();
    }
  }

  void _startRealtime() {
    _stopRealtime();
    _realtimeChannel = _service.subscribeToDetections(
      onInsert: _handleRealtimeDetection,
      onSubscribed: () {
        _realtimeActive = true;
        notifyListeners();
        debugPrint('CattleProvider: realtime subscribed');
      },
    );
  }

  /// Merge freshly saved rows (e.g. after video upload) without duplicates.
  void ingestDetections(
    Iterable<CattleDetection> detections, {
    bool notify = true,
  }) {
    var changed = false;
    for (final detection in detections) {
      if (detection.id.isEmpty) continue;
      if (_allDetections.any((d) => d.id == detection.id)) continue;

      _allDetections.insert(0, detection);

      final todayKey = _dayKey(DateTime.now());
      if (_dayKey(detection.detectedAt) == todayKey) {
        _todaysDetections.insert(0, detection);
        if (_todaysDetections.length > 200) _todaysDetections.removeLast();
      }

      changed = true;
      if (notify) {
        NotificationService.instance.notifyDetection(
          cattleId: detection.cattleId,
          isLame: detection.isLame,
          lamenessScore: detection.lamenessScore,
          milkingStatus: detection.milkingStatus,
          feedingAlert: detection.feedingAlert,
        );
      }
    }

    if (changed) {
      _stats = DashboardStats.fromDetections(_allDetections);
      notifyListeners();
    }
  }

  void _handleRealtimeDetection(CattleDetection detection) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null &&
        detection.userId != null &&
        detection.userId != userId) {
      return;
    }

    if (_allDetections.any((d) => d.id == detection.id)) {
      return;
    }

    ingestDetections([detection]);
    debugPrint('🔔 Realtime: new detection ${detection.cattleId}');
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    if (!_settings.autoSync) return;

    final minutes = _settings.normalizedSyncInterval(_settings.dataSyncInterval);
    _syncTimer = Timer.periodic(Duration(minutes: minutes), (_) {
      _runScheduledSync();
    });
  }

  Future<void> _runScheduledSync() async {
    if (!_settings.autoSync) return;
    if (!await _canSync()) {
      debugPrint('CattleProvider: scheduled sync skipped (WiFi only)');
      return;
    }
    await Future.wait([loadDetections(), loadAnimals()]);
  }

  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  void _stopRealtime() {
    if (_realtimeChannel != null) {
      _service.unsubscribe(_realtimeChannel!);
      _realtimeChannel = null;
      _realtimeActive = false;
    }
  }

  static String _dayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Animal? _rowToAnimal(Map<String, dynamic> r) {
    try {
      return Animal(
        id: r['id'] as String,
        animalId: r['animal_id'] as String,
        species: r['species'] as String? ?? 'Cow',
        age: (r['age'] as num?)?.toInt() ?? 0,
        healthStatus: r['health_status'] as String? ?? 'Healthy',
        imageUrl: r['image_url'] as String?,
        createdAt: r['created_at'] != null
            ? DateTime.parse(r['created_at'] as String)
            : DateTime.now(),
        updatedAt: r['updated_at'] != null
            ? DateTime.parse(r['updated_at'] as String)
            : DateTime.now(),
        userId: r['user_id'] as String? ?? '',
        breed: r['breed'] as String?,
        weight: (r['weight'] as num?)?.toDouble(),
        notes: r['notes'] as String?,
        earTag: r['ear_tag'] as String?,
      );
    } catch (e) {
      debugPrint('_rowToAnimal error: $e');
      return null;
    }
  }

  List<CattleDetection> get lameDetections =>
      _allDetections.where((d) => d.isLame).toList();

  List<CattleDetection> get milkingDetections =>
      _allDetections.where((d) => d.milkingStatus == 'lactating').toList();

  List<CattleDisplayRow> get cattleDisplayRows {
    final byTag = <String, CattleDisplayRow>{};

    // Newest detections first — keep latest per normalized ear tag.
    for (final d in _allDetections) {
      final key = CattleIdUtil.normalize(d.cattleId);
      if (key.isEmpty) continue;
      byTag.putIfAbsent(key, () => CattleDisplayRow.fromDetection(d));
    }

    for (final a in _animals) {
      final tag = (a.earTag?.trim().isNotEmpty == true) ? a.earTag! : a.animalId;
      final key = CattleIdUtil.normalize(tag);
      if (key.isEmpty || byTag.containsKey(key)) continue;
      byTag[key] = CattleDisplayRow.fromAnimal(a);
    }

    return byTag.values.toList()
      ..sort((a, b) {
        if (a.hasDetection != b.hasDetection) {
          return a.hasDetection ? -1 : 1;
        }
        return a.earTagId.compareTo(b.earTagId);
      });
  }

  @override
  void dispose() {
    _stopPeriodicSync();
    _stopRealtime();
    super.dispose();
  }
}
