/// App-wide constants — Supabase + on-device AI settings.
class AppConfig {
  static const String appName = 'CattleEye';

  // Cache settings
  static const Duration cacheExpiry = Duration(hours: 8);
  static const int maxCacheSize = 500;

  // Camera settings
  static const Duration snapshotInterval = Duration(seconds: 2);
  static const Duration analysisInterval = Duration(seconds: 30);
  static const int mjpegBufferSize = 65536;
}
