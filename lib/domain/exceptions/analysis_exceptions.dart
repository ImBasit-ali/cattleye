/// Thrown when analysis completes but no cattle are detected.
class NoCattleInVideoException implements Exception {
  static const String message =
      'No cattle found — use a video with visible cattle (person-only videos are rejected)';

  @override
  String toString() => message;
}

class AnalysisException implements Exception {
  final String message;
  AnalysisException(this.message);

  @override
  String toString() => message;
}

/// Thrown when the same video file was already analyzed and saved.
class VideoAlreadyProcessedException implements Exception {
  static const String message =
      'This video was already analyzed — data was not extracted again.';

  @override
  String toString() => message;
}
