/// Shared labels for milking and lameness status across screens.
class CattleStatusFormat {
  CattleStatusFormat._();

  static String milkingLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'lactating':
        return 'Milking';
      case 'dry':
        return 'Not Milking';
      default:
        return 'Not Milking';
    }
  }

  static String lamenessLabel({required bool? isLame, double? score}) {
    if (isLame == null) return 'Unknown';
    if (isLame) {
      return score != null ? 'Lame (${score.toStringAsFixed(1)})' : 'Lame';
    }
    return 'Healthy';
  }

  static String monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  static String monthLabel(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = int.tryParse(parts[1]) ?? 1;
    final year = parts[0];
    final name = names[(month - 1).clamp(0, 11)];
    return '$name $year';
  }
}
