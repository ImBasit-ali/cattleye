/// Normalize ear tag / cattle IDs for deduplication.
class CattleIdUtil {
  CattleIdUtil._();

  static String normalize(String id) => id.trim().toUpperCase();

  static bool isSame(String a, String b) => normalize(a) == normalize(b);
}
