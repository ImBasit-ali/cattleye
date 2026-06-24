/// App-wide constants — Supabase + Python PyTorch backend.
class AppConstants {
  // App Info
  static const String appName = 'CattleEye';
  static const String appVersion = '2.0.0';

  // ── Supabase Table Names ─────────────────────────────────────────────────
  static const String animalsTable = 'animals';
  static const String cattleDetectionsTable = 'cattle_detections';
  static const String userProfilesTable = 'user_profiles';

  // AI analysis tables (from migration 04 + 10)
  static const String aiAnalysesTable = 'cattle_ai_analyses';
  static const String cameraFeedsTable = 'camera_feeds';
  static const String bcsRecordsTable = 'bcs_records';
  static const String feedingRecordsTable = 'feeding_records';
  static const String lamenessRecordsTable = 'lameness_records';
  static const String vetAlertsTable = 'veterinary_alerts';

  // ── Animal Species ───────────────────────────────────────────────────────
  static const List<String> animalSpecies = ['Cow', 'Buffalo'];

  // ── Health Status ────────────────────────────────────────────────────────
  static const List<String> healthStatuses = [
    'Healthy',
    'Under Observation',
    'Sick',
    'Critical',
  ];

  // ── Lameness Severity ────────────────────────────────────────────────────
  static const String lamenessNormal = 'Normal';
  static const String lamenessMild = 'Mild Lameness';
  static const String lamenessSevere = 'Severe Lameness';

  // ── Chart Settings ───────────────────────────────────────────────────────
  static const int chartDaysToShow = 7;

  // ── Animation Durations ──────────────────────────────────────────────────
  static const int shortAnimationMs = 200;
  static const int mediumAnimationMs = 400;
  static const int longAnimationMs = 600;

  // ── Pagination ───────────────────────────────────────────────────────────
  static const int itemsPerPage = 20;
}
