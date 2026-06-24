import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/cattle_analysis_result.dart';

/// Two-level cache: in-memory hot cache + SharedPreferences disk persistence.
/// LRU eviction when maxCacheSize is reached. TTL = AppConfig.cacheExpiry (8 h).
class AnalysisCacheService {
  static const String _prefix = 'cattle_cache_';
  static const String _indexKey = 'cattle_cache_index';

  static final AnalysisCacheService _instance = AnalysisCacheService._();
  factory AnalysisCacheService() => _instance;
  AnalysisCacheService._();

  final Map<String, CattleAnalysisResult> _memCache = {};
  final List<String> _cacheIndex = [];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final indexJson = prefs.getString(_indexKey);
    if (indexJson == null) return;

    final List<String> index =
        List<String>.from(jsonDecode(indexJson) as List);
    final now = DateTime.now();

    for (final hash in index) {
      final raw = prefs.getString('$_prefix$hash');
      if (raw == null) continue;
      try {
        final result = CattleAnalysisResult.fromJsonString(raw, hash);
        if (now.difference(result.analyzedAt) < AppConfig.cacheExpiry) {
          _memCache[hash] = result;
          _cacheIndex.add(hash);
        } else {
          await prefs.remove('$_prefix$hash');
        }
      } catch (_) {
        await prefs.remove('$_prefix$hash');
      }
    }
    await _saveIndex();
  }

  CattleAnalysisResult? get(String imageHash) {
    final result = _memCache[imageHash];
    if (result == null) return null;
    if (DateTime.now().difference(result.analyzedAt) > AppConfig.cacheExpiry) {
      _evict(imageHash);
      return null;
    }
    return result;
  }

  Future<void> put(String imageHash, CattleAnalysisResult result) async {
    if (_cacheIndex.length >= AppConfig.maxCacheSize) {
      _evict(_cacheIndex.first);
    }
    _memCache[imageHash] = result;
    if (!_cacheIndex.contains(imageHash)) _cacheIndex.add(imageHash);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$imageHash', result.toJsonString());
    await _saveIndex();
  }

  void _evict(String hash) {
    _memCache.remove(hash);
    _cacheIndex.remove(hash);
    SharedPreferences.getInstance().then((p) => p.remove('$_prefix$hash'));
  }

  Future<void> _saveIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_indexKey, jsonEncode(_cacheIndex));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final h in List<String>.from(_cacheIndex)) {
      await prefs.remove('$_prefix$h');
    }
    _memCache.clear();
    _cacheIndex.clear();
    await prefs.remove(_indexKey);
  }

  int get cachedCount => _memCache.length;
}
