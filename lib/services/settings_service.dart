import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

/// Settings Service - Centralized settings management
/// Provides access to app settings from anywhere in the app
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static SettingsService get instance => _instance;

  SharedPreferences? _prefs;

  /// Initialize the settings service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('SettingsService not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  // ==================== NOTIFICATION SETTINGS ====================

  bool get enableNotifications => prefs.getBool('enableNotifications') ?? true;
  bool get lamenessAlerts => prefs.getBool('lamenessAlerts') ?? true;
  bool get milkingAlerts => prefs.getBool('milkingAlerts') ?? true;
  bool get healthAlerts => prefs.getBool('healthAlerts') ?? true;

  Future<void> setEnableNotifications(bool value) async {
    await prefs.setBool('enableNotifications', value);
  }

  Future<void> setLamenessAlerts(bool value) async {
    await prefs.setBool('lamenessAlerts', value);
  }

  Future<void> setMilkingAlerts(bool value) async {
    await prefs.setBool('milkingAlerts', value);
  }

  Future<void> setHealthAlerts(bool value) async {
    await prefs.setBool('healthAlerts', value);
  }

  // ==================== AI DETECTION SETTINGS ====================

  double get detectionConfidence => prefs.getDouble('detectionConfidence') ?? 0.7;
  bool get autoProcessVideos => prefs.getBool('autoProcessVideos') ?? true;
  bool get saveProcessedVideos => prefs.getBool('saveProcessedVideos') ?? true;

  Future<void> setDetectionConfidence(double value) async {
    await prefs.setDouble('detectionConfidence', value);
  }

  Future<void> setAutoProcessVideos(bool value) async {
    await prefs.setBool('autoProcessVideos', value);
  }

  Future<void> setSaveProcessedVideos(bool value) async {
    await prefs.setBool('saveProcessedVideos', value);
  }

  // ==================== CAMERA SETTINGS ====================

  int get cameraFPS => prefs.getInt('cameraFPS') ?? 30;
  String get videoQuality => prefs.getString('videoQuality') ?? 'high';

  Future<void> setCameraFPS(int value) async {
    const allowed = [15, 24, 30, 60];
    await prefs.setInt(
      'cameraFPS',
      allowed.contains(value) ? value : 30,
    );
  }

  Future<void> setVideoQuality(String value) async {
    await prefs.setString('videoQuality', value);
  }

  // ==================== DATA & SYNC SETTINGS ====================

  bool get autoSync => prefs.getBool('autoSync') ?? true;
  int get dataSyncInterval => prefs.getInt('dataSyncInterval') ?? 5;
  bool get wifiOnly => prefs.getBool('wifiOnly') ?? false;

  Future<void> setAutoSync(bool value) async {
    await prefs.setBool('autoSync', value);
  }

  Future<void> setDataSyncInterval(int value) async {
    await prefs.setInt('dataSyncInterval', normalizedSyncInterval(value));
  }

  Future<void> setWifiOnly(bool value) async {
    await prefs.setBool('wifiOnly', value);
  }

  // ==================== PRIVACY SETTINGS ====================

  bool get shareAnalytics => prefs.getBool('shareAnalytics') ?? false;
  bool get crashReporting => prefs.getBool('crashReporting') ?? true;

  Future<void> setShareAnalytics(bool value) async {
    await prefs.setBool('shareAnalytics', value);
  }

  Future<void> setCrashReporting(bool value) async {
    await prefs.setBool('crashReporting', value);
  }

  // ==================== DISPLAY SETTINGS ====================

  bool get darkMode => prefs.getBool('darkMode') ?? false;

  /// BCP-47 language code: en, es, fr, de, zh.
  String get languageCode {
    final raw =
        prefs.getString('languageCode') ?? prefs.getString('language') ?? 'en';
    return AppLocalizations.normalizeLanguageCode(raw);
  }

  /// @deprecated Use [languageCode]. Kept for migration.
  String get language => languageCode;

  Locale get locale => Locale(languageCode);

  Future<void> setDarkMode(bool value) async {
    await prefs.setBool('darkMode', value);
  }

  Future<void> setLanguageCode(String code) async {
    final normalized = AppLocalizations.normalizeLanguageCode(code);
    await prefs.setString('languageCode', normalized);
    await prefs.setString('language', normalized);
  }

  Future<void> setLanguage(String value) async {
    await setLanguageCode(value);
  }

  // ==================== UTILITY METHODS ====================

  static const _settingsKeys = [
    'enableNotifications',
    'lamenessAlerts',
    'milkingAlerts',
    'healthAlerts',
    'detectionConfidence',
    'autoProcessVideos',
    'saveProcessedVideos',
    'cameraFPS',
    'videoQuality',
    'autoSync',
    'dataSyncInterval',
    'wifiOnly',
    'darkMode',
    'language',
    'languageCode',
    'shareAnalytics',
    'crashReporting',
  ];

  static const syncIntervalOptions = [1, 5, 15, 30, 60];

  /// Normalizes stored sync interval to a supported value.
  int normalizedSyncInterval(int minutes) {
    if (syncIntervalOptions.contains(minutes)) return minutes;
    return 5;
  }

  String syncIntervalLabel(int minutes) =>
      '${normalizedSyncInterval(minutes)} minutes';

  /// Frame sample timestamps (ms) based on video quality preference.
  List<int> get videoFrameSampleMs {
    switch (videoQuality) {
      case 'low':
        return const [0, 12000];
      case 'medium':
        return const [0, 5000, 12000];
      case 'ultra':
        return const [0, 1500, 3000, 5000, 12000, 20000];
      case 'high':
      default:
        return const [0, 1500, 5000, 12000];
    }
  }

  /// Live analysis interval derived from camera FPS setting.
  Duration get liveAnalysisInterval {
    switch (cameraFPS) {
      case 60:
        return const Duration(seconds: 15);
      case 24:
        return const Duration(seconds: 35);
      case 15:
        return const Duration(seconds: 45);
      case 30:
      default:
        return const Duration(seconds: 30);
    }
  }

  /// Reset all settings to default without wiping unrelated app data.
  Future<void> resetToDefault() async {
    for (final key in _settingsKeys) {
      await prefs.remove(key);
    }
  }

  /// Get video quality as integer (for backend)
  int getVideoQualityAsInt() {
    switch (videoQuality) {
      case 'low':
        return 480;
      case 'medium':
        return 720;
      case 'high':
        return 1080;
      case 'ultra':
        return 2160;
      default:
        return 1080;
    }
  }

  /// Check if notifications should be shown for a specific type
  bool shouldShowNotification(String type) {
    if (!enableNotifications) return false;

    switch (type.toLowerCase()) {
      case 'lameness':
        return lamenessAlerts;
      case 'milking':
        return milkingAlerts;
      case 'health':
        return healthAlerts;
      default:
        return true;
    }
  }
}
