/// Lameness Record Model - Represents lameness detection results
class LamenessRecord {
  final String id;
  final String animalId;
  final DateTime detectionDate;
  final String severity; // Normal, Mild Lameness, Severe Lameness
  final double confidenceScore; // 0-1
  final String detectionMethod; // Rule-Based, ML-Based
  final DateTime timestamp;
  
  // Rule-based detection factors
  final int? stepCount;
  final double? activityHours;
  final double? restHours;
  
  // ML-based detection inputs
  final Map<String, dynamic>? mlInputFeatures;
  final List<double>? mlOutputProbabilities; // [normal, mild, severe]
  
  // Additional data
  final String? videoUrl;
  final String? notes;
  final bool requiresAttention;

  LamenessRecord({
    required this.id,
    required this.animalId,
    required this.detectionDate,
    required this.severity,
    required this.confidenceScore,
    required this.detectionMethod,
    required this.timestamp,
    this.stepCount,
    this.activityHours,
    this.restHours,
    this.mlInputFeatures,
    this.mlOutputProbabilities,
    this.videoUrl,
    this.notes,
    this.requiresAttention = false,
  });

  /// Create LamenessRecord from JSON
  factory LamenessRecord.fromJson(Map<String, dynamic> json) {
    return LamenessRecord(
      id: json['id'] as String,
      animalId: json['animal_id'] as String,
      detectionDate: DateTime.parse(json['detection_date'] as String),
      severity: json['severity'] as String,
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      detectionMethod: json['detection_method'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      stepCount: json['step_count'] as int?,
      activityHours: json['activity_hours'] != null 
          ? (json['activity_hours'] as num).toDouble() 
          : null,
      restHours: json['rest_hours'] != null 
          ? (json['rest_hours'] as num).toDouble() 
          : null,
      mlInputFeatures: json['ml_input_features'] as Map<String, dynamic>?,
      mlOutputProbabilities: json['ml_output_probabilities'] != null
          ? List<double>.from(json['ml_output_probabilities'] as List)
          : null,
      videoUrl: json['video_url'] as String?,
      notes: json['notes'] as String?,
      requiresAttention: json['requires_attention'] as bool? ?? false,
    );
  }

  /// Convert LamenessRecord to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'animal_id': animalId,
      'detection_date': detectionDate.toIso8601String(),
      'severity': severity,
      'confidence_score': confidenceScore,
      'detection_method': detectionMethod,
      'timestamp': timestamp.toIso8601String(),
      'step_count': stepCount,
      'activity_hours': activityHours,
      'rest_hours': restHours,
      'ml_input_features': mlInputFeatures,
      'ml_output_probabilities': mlOutputProbabilities,
      'video_url': videoUrl,
      'notes': notes,
      'requires_attention': requiresAttention,
    };
  }

  /// Create a copy with modified fields
  LamenessRecord copyWith({
    String? id,
    String? animalId,
    DateTime? detectionDate,
    String? severity,
    double? confidenceScore,
    String? detectionMethod,
    DateTime? timestamp,
    int? stepCount,
    double? activityHours,
    double? restHours,
    Map<String, dynamic>? mlInputFeatures,
    List<double>? mlOutputProbabilities,
    String? videoUrl,
    String? notes,
    bool? requiresAttention,
  }) {
    return LamenessRecord(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      detectionDate: detectionDate ?? this.detectionDate,
      severity: severity ?? this.severity,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      detectionMethod: detectionMethod ?? this.detectionMethod,
      timestamp: timestamp ?? this.timestamp,
      stepCount: stepCount ?? this.stepCount,
      activityHours: activityHours ?? this.activityHours,
      restHours: restHours ?? this.restHours,
      mlInputFeatures: mlInputFeatures ?? this.mlInputFeatures,
      mlOutputProbabilities: mlOutputProbabilities ?? this.mlOutputProbabilities,
      videoUrl: videoUrl ?? this.videoUrl,
      notes: notes ?? this.notes,
      requiresAttention: requiresAttention ?? this.requiresAttention,
    );
  }

  /// Check if lameness is detected
  bool get isLame => severity != 'Normal';

  /// Get severity level as integer (0: Normal, 1: Mild, 2: Severe)
  int get severityLevel {
    switch (severity) {
      case 'Normal':
        return 0;
      case 'Mild Lameness':
        return 1;
      case 'Severe Lameness':
        return 2;
      default:
        return 0;
    }
  }

  @override
  String toString() {
    return 'LamenessRecord{id: $id, animalId: $animalId, severity: $severity, confidence: $confidenceScore}';
  }
}
