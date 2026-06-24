import 'dart:convert';

class CattleAnalysisResult {
  final String imageHash;
  final DateTime analyzedAt;
  final EarTagResult earTag;
  final MuzzleResult muzzle;
  final BcsResult bcs;
  final LamenessResult lameness;
  final FeedingResult feeding;
  final OverallHealth overall;

  const CattleAnalysisResult({
    required this.imageHash,
    required this.analyzedAt,
    required this.earTag,
    required this.muzzle,
    required this.bcs,
    required this.lameness,
    required this.feeding,
    required this.overall,
  });

  factory CattleAnalysisResult.fromJson(Map<String, dynamic> json, String hash) {
    return CattleAnalysisResult(
      imageHash: hash,
      analyzedAt: DateTime.now(),
      earTag: EarTagResult.fromJson(json['eartag'] ?? {}),
      muzzle: MuzzleResult.fromJson(json['muzzle'] ?? {}),
      bcs: BcsResult.fromJson(json['bcs'] ?? {}),
      lameness: LamenessResult.fromJson(json['lameness'] ?? {}),
      feeding: FeedingResult.fromJson(json['feeding'] ?? {}),
      overall: OverallHealth.fromJson(json['overall_health'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'imageHash': imageHash,
        'analyzedAt': analyzedAt.toIso8601String(),
        'eartag': earTag.toJson(),
        'muzzle': muzzle.toJson(),
        'bcs': bcs.toJson(),
        'lameness': lameness.toJson(),
        'feeding': feeding.toJson(),
        'overall_health': overall.toJson(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory CattleAnalysisResult.fromJsonString(String s, String hash) =>
      CattleAnalysisResult.fromJson(jsonDecode(s) as Map<String, dynamic>, hash);
}

// ── Sub-models ───────────────────────────────────────────────────────────────

class EarTagResult {
  final bool detected;
  final String? tagNumber;
  final String? tagColor;
  final String tagPosition;
  final int ocrConfidence;
  final String notes;

  const EarTagResult({
    required this.detected,
    this.tagNumber,
    this.tagColor,
    required this.tagPosition,
    required this.ocrConfidence,
    required this.notes,
  });

  factory EarTagResult.fromJson(Map<String, dynamic> j) => EarTagResult(
        detected: j['detected'] ?? false,
        tagNumber: j['tag_number'] as String?,
        tagColor: j['tag_color'] as String?,
        tagPosition: j['tag_position'] ?? 'not visible',
        ocrConfidence: (j['ocr_confidence'] ?? 0).toInt(),
        notes: j['notes'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'detected': detected,
        'tag_number': tagNumber,
        'tag_color': tagColor,
        'tag_position': tagPosition,
        'ocr_confidence': ocrConfidence,
        'notes': notes,
      };
}

class MuzzleResult {
  final bool detected;
  final String patternDescription;
  final String breedEstimate;
  final String distinctiveness;
  final List<String> biometricFeatures;
  final String notes;

  const MuzzleResult({
    required this.detected,
    required this.patternDescription,
    required this.breedEstimate,
    required this.distinctiveness,
    required this.biometricFeatures,
    required this.notes,
  });

  factory MuzzleResult.fromJson(Map<String, dynamic> j) => MuzzleResult(
        detected: j['detected'] ?? false,
        patternDescription: j['pattern_description'] ?? '',
        breedEstimate: j['breed_estimate'] ?? '',
        distinctiveness: j['distinctiveness'] ?? 'medium',
        biometricFeatures: List<String>.from(j['biometric_features'] ?? []),
        notes: j['notes'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'detected': detected,
        'pattern_description': patternDescription,
        'breed_estimate': breedEstimate,
        'distinctiveness': distinctiveness,
        'biometric_features': biometricFeatures,
        'notes': notes,
      };
}

class BcsResult {
  final double score;
  final String category;
  final bool visibleRibs;
  final bool spineVisible;
  final String hipBones;
  final String recommendation;
  final int confidence;

  const BcsResult({
    required this.score,
    required this.category,
    required this.visibleRibs,
    required this.spineVisible,
    required this.hipBones,
    required this.recommendation,
    required this.confidence,
  });

  factory BcsResult.fromJson(Map<String, dynamic> j) => BcsResult(
        score: (j['score'] ?? 3.0).toDouble(),
        category: j['category'] ?? 'Optimal',
        visibleRibs: j['visible_ribs'] ?? false,
        spineVisible: j['spine_visible'] ?? false,
        hipBones: j['hip_bones'] ?? 'normal',
        recommendation: j['recommendation'] ?? '',
        confidence: (j['confidence'] ?? 0).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'score': score,
        'category': category,
        'visible_ribs': visibleRibs,
        'spine_visible': spineVisible,
        'hip_bones': hipBones,
        'recommendation': recommendation,
        'confidence': confidence,
      };
}

class LamenessResult {
  final bool detected;
  final int locomotionScore;
  final String posture;
  final String weightDistribution;
  final String affectedLimb;
  final String urgency;
  final int confidence;

  const LamenessResult({
    required this.detected,
    required this.locomotionScore,
    required this.posture,
    required this.weightDistribution,
    required this.affectedLimb,
    required this.urgency,
    required this.confidence,
  });

  factory LamenessResult.fromJson(Map<String, dynamic> j) => LamenessResult(
        detected: j['detected'] ?? false,
        locomotionScore: (j['locomotion_score'] ?? 1).toInt(),
        posture: j['posture'] ?? 'normal',
        weightDistribution: j['weight_distribution'] ?? 'even',
        affectedLimb: j['affected_limb'] ?? 'none',
        urgency: j['urgency'] ?? 'none',
        confidence: (j['confidence'] ?? 0).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'detected': detected,
        'locomotion_score': locomotionScore,
        'posture': posture,
        'weight_distribution': weightDistribution,
        'affected_limb': affectedLimb,
        'urgency': urgency,
        'confidence': confidence,
      };
}

class FeedingResult {
  final String currentBehavior;
  final String headPosition;
  final String locationZone;
  final int feedingEngagement;
  final String notes;

  const FeedingResult({
    required this.currentBehavior,
    required this.headPosition,
    required this.locationZone,
    required this.feedingEngagement,
    required this.notes,
  });

  factory FeedingResult.fromJson(Map<String, dynamic> j) => FeedingResult(
        currentBehavior: j['current_behavior'] ?? 'unknown',
        headPosition: j['head_position'] ?? 'level',
        locationZone: j['location_zone'] ?? 'unknown',
        feedingEngagement: (j['estimated_feeding_engagement'] ?? 0).toInt(),
        notes: j['notes'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'current_behavior': currentBehavior,
        'head_position': headPosition,
        'location_zone': locationZone,
        'estimated_feeding_engagement': feedingEngagement,
        'notes': notes,
      };
}

class OverallHealth {
  final String status;
  final String? priorityAlert;
  final String summary;

  const OverallHealth({
    required this.status,
    this.priorityAlert,
    required this.summary,
  });

  factory OverallHealth.fromJson(Map<String, dynamic> j) => OverallHealth(
        status: j['status'] ?? 'Healthy',
        priorityAlert: j['priority_alert'] as String?,
        summary: j['summary'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'status': status,
        'priority_alert': priorityAlert,
        'summary': summary,
      };
}
