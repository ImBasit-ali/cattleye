/// Result of analyzing an uploaded video file (one row per detected animal).
class VideoAnalysisResult {
  final int cattleCount;
  final int buffaloCount;
  final List<VideoAnimalDetection> animals;
  final String videoFileName;

  const VideoAnalysisResult({
    required this.cattleCount,
    required this.buffaloCount,
    required this.animals,
    required this.videoFileName,
  });

  factory VideoAnalysisResult.fromJson(
    Map<String, dynamic> json,
    String videoFileName,
  ) {
    final rawAnimals = json['animals'] ?? json['cattle'] ?? json['detections'];
    final animals = <VideoAnimalDetection>[];
    if (rawAnimals is List) {
      for (var i = 0; i < rawAnimals.length; i++) {
        final item = rawAnimals[i];
        if (item is Map<String, dynamic>) {
          animals.add(VideoAnimalDetection.fromJson(item, fallbackIndex: i + 1));
        } else if (item is Map) {
          animals.add(VideoAnimalDetection.fromJson(
            Map<String, dynamic>.from(item),
            fallbackIndex: i + 1,
          ));
        }
      }
    }

    final cattleCount = (json['cattle_count'] as num?)?.toInt() ??
        (json['total_cattle'] as num?)?.toInt() ??
        animals.length;

    // If AI reports count but empty array, create placeholder rows
    if (animals.isEmpty && cattleCount > 0) {
      for (var i = 0; i < cattleCount; i++) {
        animals.add(VideoAnimalDetection.fromJson(
          {},
          fallbackIndex: i + 1,
        ));
      }
    }

    return VideoAnalysisResult(
      cattleCount: cattleCount.clamp(0, 999),
      buffaloCount: (json['buffalo_count'] as num?)?.toInt() ?? 0,
      animals: animals,
      videoFileName: videoFileName,
    );
  }
}

class VideoAnimalDetection {
  final String cattleId;
  final String milkingStatus;
  final double bcsScore;
  final double lamenessScore;
  final bool isLame;
  final double confidence;
  final bool feedingAlert;
  final String healthStatus;

  const VideoAnimalDetection({
    required this.cattleId,
    required this.milkingStatus,
    required this.bcsScore,
    required this.lamenessScore,
    required this.isLame,
    required this.confidence,
    required this.feedingAlert,
    required this.healthStatus,
  });

  factory VideoAnimalDetection.fromJson(
    Map<String, dynamic> json, {
    required int fallbackIndex,
  }) {
    final id = (json['cattle_id'] as String?)?.trim();
    return VideoAnimalDetection(
      cattleId: (id != null && id.isNotEmpty)
          ? id
          : 'VID-${fallbackIndex.toString().padLeft(3, '0')}',
      milkingStatus: _normalizeMilking(json['milking_status'] as String?),
      bcsScore: (json['bcs_score'] as num?)?.toDouble() ?? 3.0,
      lamenessScore: (json['lameness_score'] as num?)?.toDouble() ?? 0.0,
      isLame: json['is_lame'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
      feedingAlert: json['feeding_alert'] as bool? ?? false,
      healthStatus: json['health_status'] as String? ?? 'Healthy',
    );
  }

  static String _normalizeMilking(String? status) {
    final s = (status ?? 'unknown').toLowerCase();
    if (s.contains('lact') || s.contains('milk')) return 'lactating';
    if (s.contains('dry')) return 'dry';
    return 'unknown';
  }

  Map<String, dynamic> toDetectionRow() => {
        'cattle_id': cattleId,
        'confidence': confidence,
        'cattle_count': 1,
        'buffalo_count': 0,
        'lameness_score': lamenessScore,
        'is_lame': isLame,
        'milking_status': milkingStatus,
        'bcs_score': bcsScore,
        'feeding_alert': feedingAlert,
        'source': 'video_upload',
        'detected_at': DateTime.now().toIso8601String(),
      };
}

/// Keep one row per ear tag ID (case-insensitive).
List<VideoAnimalDetection> dedupeVideoAnimals(List<VideoAnimalDetection> animals) {
  final seen = <String>{};
  final out = <VideoAnimalDetection>[];
  for (final a in animals) {
    final key = a.cattleId.trim().toUpperCase();
    if (key.isEmpty) continue;
    if (seen.add(key)) out.add(a);
  }
  return out;
}
