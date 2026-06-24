import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';

/// CattleDetection — mirrors the `cattle_detections` Supabase table row
class CattleDetection {
  final String id;
  final String cattleId;
  final String? userId;
  final double confidence;
  final int cattleCount;
  final int buffaloCount;
  final double lamenessScore;
  final bool isLame;
  final String milkingStatus;
  final double? bcsScore;
  final bool feedingAlert;
  final String source;
  final DateTime detectedAt;

  CattleDetection({
    required this.id,
    required this.cattleId,
    this.userId,
    required this.confidence,
    required this.cattleCount,
    required this.buffaloCount,
    required this.lamenessScore,
    required this.isLame,
    required this.milkingStatus,
    this.bcsScore,
    required this.feedingAlert,
    required this.source,
    required this.detectedAt,
  });

  factory CattleDetection.fromJson(Map<String, dynamic> j) => CattleDetection(
        id: j['id'] as String? ?? '',
        cattleId: j['cattle_id'] as String? ?? '',
        userId: j['user_id'] as String?,
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0.0,
        cattleCount: (j['cattle_count'] as num?)?.toInt() ?? 1,
        buffaloCount: (j['buffalo_count'] as num?)?.toInt() ?? 0,
        lamenessScore: (j['lameness_score'] as num?)?.toDouble() ?? 0.0,
        isLame: j['is_lame'] as bool? ?? false,
        milkingStatus: j['milking_status'] as String? ?? 'unknown',
        bcsScore: (j['bcs_score'] as num?)?.toDouble(),
        feedingAlert: j['feeding_alert'] as bool? ?? false,
        source: j['source'] as String? ?? 'camera',
        detectedAt: j['detected_at'] != null
            ? DateTime.parse(j['detected_at'] as String)
            : DateTime.now(),
      );
}

/// DashboardStats — aggregated stats derived from cattle_detections
class DashboardStats {
  /// All-time totals (dashboard cards, cattle info, milking summaries, charts).
  final int totalCattle;
  final int healthyCattle;
  final int lamenessCattle;
  final int milkingCattle;
  final int totalRecords;

  /// Today-only totals (today's cattle table on dashboard).
  final int todayTotalCattle;
  final int todayHealthyCattle;
  final int todayLamenessCattle;
  final int todayMilkingCattle;
  final int todayRecords;

  final Map<String, int> dailyCounts;
  final Map<String, int> lamenessCount;
  final Map<String, int> monthlyDetections;
  final Map<String, int> monthlyLameness;
  final Map<String, int> monthlyMilking;

  const DashboardStats({
    this.totalCattle = 0,
    this.healthyCattle = 0,
    this.lamenessCattle = 0,
    this.milkingCattle = 0,
    this.totalRecords = 0,
    this.todayTotalCattle = 0,
    this.todayHealthyCattle = 0,
    this.todayLamenessCattle = 0,
    this.todayMilkingCattle = 0,
    this.todayRecords = 0,
    this.dailyCounts = const {},
    this.lamenessCount = const {},
    this.monthlyDetections = const {},
    this.monthlyLameness = const {},
    this.monthlyMilking = const {},
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        totalCattle: (j['total_cattle'] as num?)?.toInt() ?? 0,
        healthyCattle: (j['healthy_cattle'] as num?)?.toInt() ?? 0,
        lamenessCattle: (j['lameness_cattle'] as num?)?.toInt() ?? 0,
        milkingCattle: (j['milking_cattle'] as num?)?.toInt() ?? 0,
        totalRecords: (j['total_records'] as num?)?.toInt() ?? 0,
        todayTotalCattle: (j['today_total_cattle'] as num?)?.toInt() ?? 0,
        todayHealthyCattle: (j['today_healthy_cattle'] as num?)?.toInt() ?? 0,
        todayLamenessCattle: (j['today_lameness_cattle'] as num?)?.toInt() ?? 0,
        todayMilkingCattle: (j['today_milking_cattle'] as num?)?.toInt() ?? 0,
        todayRecords: (j['today_records'] as num?)?.toInt() ?? 0,
        dailyCounts: _parseIntMap(j['daily_counts']),
        lamenessCount: _parseIntMap(j['lameness_count']),
        monthlyDetections: _parseIntMap(j['monthly_detections']),
        monthlyLameness: _parseIntMap(j['monthly_lameness']),
        monthlyMilking: _parseIntMap(j['monthly_milking']),
      );

  /// Build stats from the full detection history.
  factory DashboardStats.fromDetections(List<CattleDetection> detections) {
    if (detections.isEmpty) return const DashboardStats();

    final todayKey = _dayKey(DateTime.now());

    var totalCattle = 0;
    var lamenessCattle = 0;
    var milkingCattle = 0;
    var healthyCattle = 0;

    var todayTotalCattle = 0;
    var todayLamenessCattle = 0;
    var todayMilkingCattle = 0;
    var todayHealthyCattle = 0;
    var todayRecords = 0;

    final dailyCounts = <String, int>{};
    final lamenessCount = <String, int>{};
    final monthlyDetections = <String, int>{};
    final monthlyLameness = <String, int>{};
    final monthlyMilking = <String, int>{};

    for (final d in detections) {
      totalCattle += d.cattleCount;
      if (d.isLame) {
        lamenessCattle++;
      } else {
        healthyCattle++;
      }
      if (d.milkingStatus == 'lactating') milkingCattle++;

      final day = _dayKey(d.detectedAt);
      dailyCounts[day] = (dailyCounts[day] ?? 0) + d.cattleCount;
      if (d.isLame) lamenessCount[day] = (lamenessCount[day] ?? 0) + 1;

      final month = _monthKey(d.detectedAt);
      monthlyDetections[month] = (monthlyDetections[month] ?? 0) + d.cattleCount;
      if (d.isLame) {
        monthlyLameness[month] = (monthlyLameness[month] ?? 0) + 1;
      }
      if (d.milkingStatus == 'lactating') {
        monthlyMilking[month] = (monthlyMilking[month] ?? 0) + 1;
      }

      if (day == todayKey) {
        todayRecords++;
        todayTotalCattle += d.cattleCount;
        if (d.isLame) {
          todayLamenessCattle++;
        } else {
          todayHealthyCattle++;
        }
        if (d.milkingStatus == 'lactating') todayMilkingCattle++;
      }
    }

    return DashboardStats(
      totalCattle: totalCattle,
      healthyCattle: healthyCattle,
      lamenessCattle: lamenessCattle,
      milkingCattle: milkingCattle,
      totalRecords: detections.length,
      todayTotalCattle: todayTotalCattle,
      todayHealthyCattle: todayHealthyCattle,
      todayLamenessCattle: todayLamenessCattle,
      todayMilkingCattle: todayMilkingCattle,
      todayRecords: todayRecords,
      dailyCounts: dailyCounts,
      lamenessCount: lamenessCount,
      monthlyDetections: monthlyDetections,
      monthlyLameness: monthlyLameness,
      monthlyMilking: monthlyMilking,
    );
  }

  static String _dayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String _monthKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

  static Map<String, int> _parseIntMap(dynamic data) {
    if (data == null || data is! Map) return {};
    return Map<String, int>.from(
      data.map(
        (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
      ),
    );
  }
}

/// CattleService — the single source of truth for Supabase operations
///
/// Responsibilities:
///  • CRUD for `animals` table
///  • Read / realtime subscription on `cattle_detections`
///  • Fetch aggregated dashboard stats from the Railway backend
class CattleService {
  CattleService._();
  static final CattleService instance = CattleService._();

  SupabaseClient get _db => Supabase.instance.client;

  // ── Animals ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAnimals() async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return [];
      final res = await _db
          .from(AppConstants.animalsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('CattleService.getAnimals error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createAnimal(
      Map<String, dynamic> data) async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return null;
      final payload = {...data, 'user_id': userId};
      final res = await _db
          .from(AppConstants.animalsTable)
          .insert(payload)
          .select()
          .single();
      return res;
    } catch (e) {
      debugPrint('CattleService.createAnimal error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateAnimal(
      String id, Map<String, dynamic> data) async {
    try {
      final res = await _db
          .from(AppConstants.animalsTable)
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .select()
          .single();
      return res;
    } catch (e) {
      debugPrint('CattleService.updateAnimal error: $e');
      return null;
    }
  }

  Future<bool> deleteAnimal(String id) async {
    try {
      await _db.from(AppConstants.animalsTable).delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('CattleService.deleteAnimal error: $e');
      return false;
    }
  }

  /// Delete all cloud data for the signed-in user (DB + storage).
  Future<bool> deleteAllUserData() async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return false;

      if (await _ensureDetectionsTable()) {
        await _db
            .from(AppConstants.cattleDetectionsTable)
            .delete()
            .eq('user_id', userId);
      }

      try {
        await _db
            .from(AppConstants.aiAnalysesTable)
            .delete()
            .eq('user_id', userId);
      } catch (e) {
        debugPrint('CattleService: ai analyses delete skipped — $e');
      }

      await _db.from(AppConstants.animalsTable).delete().eq('user_id', userId);
      await _deleteUserStorage(userId);
      return true;
    } catch (e) {
      debugPrint('CattleService.deleteAllUserData error: $e');
      return false;
    }
  }

  Future<void> _deleteUserStorage(String userId) async {
    const buckets = ['videos', 'cattle_images'];
    for (final bucket in buckets) {
      try {
        final entries = await _db.storage.from(bucket).list(path: userId);
        if (entries.isEmpty) continue;
        final paths = entries
            .where((e) => e.name.isNotEmpty)
            .map((e) => '$userId/${e.name}')
            .toList(growable: false);
        if (paths.isNotEmpty) {
          await _db.storage.from(bucket).remove(paths);
        }
      } catch (e) {
        debugPrint('CattleService: storage cleanup $bucket — $e');
      }
    }
  }

  // ── Detections table availability ─────────────────────────────────────────

  bool? _detectionsTableReady;
  bool _loggedMissingDetectionsTable = false;

  static const String _missingTableHint =
      'Run supabase/migrations/11_cattle_detections.sql in Supabase '
      'Dashboard → SQL Editor (creates public.cattle_detections).';

  Future<bool> _ensureDetectionsTable() async {
    if (_detectionsTableReady == true) return true;
    if (_detectionsTableReady == false) return false;

    try {
      await _db
          .from(AppConstants.cattleDetectionsTable)
          .select('id')
          .limit(1);
      _detectionsTableReady = true;
      return true;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') {
        _detectionsTableReady = false;
        if (!_loggedMissingDetectionsTable) {
          _loggedMissingDetectionsTable = true;
          debugPrint('CattleService: $_missingTableHint');
        }
        return false;
      }
      rethrow;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('PGRST205') || msg.contains('cattle_detections')) {
        _detectionsTableReady = false;
        if (!_loggedMissingDetectionsTable) {
          _loggedMissingDetectionsTable = true;
          debugPrint('CattleService: $_missingTableHint');
        }
        return false;
      }
      rethrow;
    }
  }

  String get detectionsSetupHint => _missingTableHint;
  bool get isDetectionsTableReady => _detectionsTableReady == true;

  // ── Detections ────────────────────────────────────────────────────────────

  /// Fetch today's detections for the dashboard daily table.
  Future<List<CattleDetection>> getTodaysDetections() async {
    try {
      if (!await _ensureDetectionsTable()) return [];
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return [];

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = todayStart.add(const Duration(days: 1));

      final res = await _db
          .from(AppConstants.cattleDetectionsTable)
          .select()
          .eq('user_id', userId)
          .gte('detected_at', todayStart.toIso8601String())
          .lt('detected_at', tomorrowStart.toIso8601String())
          .order('detected_at', ascending: false)
          .limit(200);
      return res.map((r) => CattleDetection.fromJson(r)).toList();
    } catch (e) {
      debugPrint('CattleService.getTodaysDetections error: $e');
      return [];
    }
  }

  /// Fetch all detection records for the signed-in user (paginated).
  Future<List<CattleDetection>> getAllDetections() async {
    try {
      if (!await _ensureDetectionsTable()) return [];
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return [];

      const pageSize = 1000;
      final all = <CattleDetection>[];
      var offset = 0;

      while (true) {
        final res = await _db
            .from(AppConstants.cattleDetectionsTable)
            .select()
            .eq('user_id', userId)
            .order('detected_at', ascending: false)
            .range(offset, offset + pageSize - 1);

        final batch = (res as List)
            .map((r) => CattleDetection.fromJson(r as Map<String, dynamic>))
            .toList();
        if (batch.isEmpty) break;
        all.addAll(batch);
        if (batch.length < pageSize) break;
        offset += pageSize;
      }

      return all;
    } catch (e) {
      debugPrint('CattleService.getAllDetections error: $e');
      return [];
    }
  }

  /// Insert one detection row (video upload or live camera).
  Future<CattleDetection?> insertDetection(Map<String, dynamic> row) async {
    try {
      if (!await _ensureDetectionsTable()) return null;
      final userId = _db.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('CattleService.insertDetection: no authenticated user');
        return null;
      }
      final payload = {...row, 'user_id': userId};
      debugPrint('CattleService.insertDetection → ${AppConstants.cattleDetectionsTable}: $payload');
      final res = await _db
          .from(AppConstants.cattleDetectionsTable)
          .insert(payload)
          .select()
          .single();
      debugPrint('CattleService.insertDetection ✓ id=${res['id']}');
      return CattleDetection.fromJson(res);
    } catch (e) {
      debugPrint('CattleService.insertDetection error: $e');
      return null;
    }
  }

  /// Look up animals.id UUID from the human-readable animal_id / ear tag.
  Future<String?> resolveAnimalUuid(String cattleId) async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return null;
      final res = await _db
          .from(AppConstants.animalsTable)
          .select('id')
          .eq('user_id', userId)
          .eq('animal_id', cattleId)
          .maybeSingle();
      return res?['id'] as String?;
    } catch (e) {
      debugPrint('CattleService.resolveAnimalUuid error: $e');
      return null;
    }
  }

  /// Resolve many animals.id UUIDs in one request.
  /// Returns a map of cattleId (animal_id) → UUID (animals.id).
  Future<Map<String, String>> resolveAnimalUuidsBatch(
    List<String> cattleIds,
  ) async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return {};

      final ids = cattleIds
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList(growable: false);
      if (ids.isEmpty) return {};

      final res = await _db
          .from(AppConstants.animalsTable)
          .select('id, animal_id')
          .eq('user_id', userId)
          .inFilter('animal_id', ids);

      final map = <String, String>{};
      for (final row in List<Map<String, dynamic>>.from(res as List)) {
        final tag = (row['animal_id'] as String?)?.trim();
        final uuid = row['id'] as String?;
        if (tag != null && tag.isNotEmpty && uuid != null && uuid.isNotEmpty) {
          map[tag] = uuid;
        }
      }
      return map;
    } catch (e) {
      debugPrint('CattleService.resolveAnimalUuidsBatch error: $e');
      return {};
    }
  }

  /// Create an animal record if this cattle ID is not already registered.
  Future<void> ensureAnimalRecord({
    required String cattleId,
    required String healthStatus,
    String species = 'Cow',
  }) async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return;

      final existing = await _db
          .from(AppConstants.animalsTable)
          .select('id')
          .eq('user_id', userId)
          .eq('animal_id', cattleId)
          .maybeSingle();
      if (existing != null) return;

      await _db.from(AppConstants.animalsTable).insert({
        'user_id': userId,
        'animal_id': cattleId,
        'ear_tag': cattleId,
        'species': species,
        'age': 0,
        'health_status': healthStatus,
        'notes': 'Auto-registered from video analysis',
      });
    } catch (e) {
      debugPrint('CattleService.ensureAnimalRecord error: $e');
    }
  }

  /// Best-effort: create missing animal rows in batch (no-op if they already exist).
  ///
  /// This is intentionally tolerant to races: if a row is created concurrently,
  /// this method may fail for that specific insert but overall video processing
  /// should continue.
  Future<void> ensureAnimalRecordsBatch({
    required List<Map<String, String>> animals, // {cattleId, healthStatus}
    String species = 'Cow',
  }) async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return;
      if (animals.isEmpty) return;

      final unique = <String, String>{};
      for (final a in animals) {
        final id = (a['cattleId'] ?? '').trim();
        if (id.isEmpty) continue;
        unique[id] = (a['healthStatus'] ?? 'Healthy').trim();
      }
      if (unique.isEmpty) return;

      final existing = await resolveAnimalUuidsBatch(unique.keys.toList());
      final missing = unique.keys.where((k) => !existing.containsKey(k)).toList();
      if (missing.isEmpty) return;

      final rows = missing
          .map(
            (id) => {
              'user_id': userId,
              'animal_id': id,
              'ear_tag': id,
              'species': species,
              'age': 0,
              'health_status': unique[id] ?? 'Healthy',
              'notes': 'Auto-registered from video analysis',
            },
          )
          .toList(growable: false);

      await _db.from(AppConstants.animalsTable).insert(rows);
    } catch (e) {
      debugPrint('CattleService.ensureAnimalRecordsBatch error: $e');
    }
  }

  /// Fetch last N-days detections for chart data
  Future<List<CattleDetection>> getRecentDetections({int days = 7}) async {
    try {
      if (!await _ensureDetectionsTable()) return [];
      final from = DateTime.now().subtract(Duration(days: days));
      final res = await _db
          .from(AppConstants.cattleDetectionsTable)
          .select()
          .gte('detected_at', from.toIso8601String())
          .order('detected_at', ascending: false);
      return res
          .map((r) => CattleDetection.fromJson(r))
          .toList();
    } catch (e) {
      debugPrint('CattleService.getRecentDetections error: $e');
      return [];
    }
  }

  /// Insert many detection rows in a single request.
  Future<List<CattleDetection>> insertDetectionsBatch(
    List<Map<String, dynamic>> rows,
  ) async {
    try {
      if (rows.isEmpty) return const [];
      if (!await _ensureDetectionsTable()) return const [];

      final userId = _db.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('CattleService.insertDetectionsBatch: no authenticated user');
        return const [];
      }

      final payloads = rows
          .map((r) => {...r, 'user_id': userId})
          .toList(growable: false);

      final res = await _db
          .from(AppConstants.cattleDetectionsTable)
          .insert(payloads)
          .select();
      return (res as List)
          .map((r) => CattleDetection.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('CattleService.insertDetectionsBatch error: $e');
      return const [];
    }
  }

  // ── Realtime ──────────────────────────────────────────────────────────────

  /// Subscribe to new rows inserted into cattle_detections.
  RealtimeChannel subscribeToDetections({
    required void Function(CattleDetection detection) onInsert,
    void Function()? onSubscribed,
  }) {
    return _db
        .channel('cattle_detections_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: AppConstants.cattleDetectionsTable,
          callback: (payload) {
            try {
              final detection =
                  CattleDetection.fromJson(payload.newRecord);
              onInsert(detection);
            } catch (e) {
              debugPrint('Realtime parse error: $e');
            }
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            onSubscribed?.call();
          } else if (error != null) {
            debugPrint('CattleService realtime subscribe error: $error');
          }
        });
  }

  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _db.removeChannel(channel);
  }

  // ── Stats (from Railway backend) ──────────────────────────────────────────

  /// Compute dashboard stats from all user detection records.
  Future<DashboardStats> getDashboardStats() async {
    try {
      final detections = await getAllDetections();
      return DashboardStats.fromDetections(detections);
    } catch (e) {
      debugPrint('CattleService.getDashboardStats error: $e');
      return const DashboardStats();
    }
  }
}
