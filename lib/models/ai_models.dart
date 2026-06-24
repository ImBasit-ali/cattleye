/// Camera Feed Model
/// Represents real-time camera feeds from the multi-camera setup
class CameraFeed {
  final String id;
  final String cameraId;
  final String cameraName;
  final String cameraType; // RGB, RGB-D, ToF Depth
  final String functionalZone; // Milking Parlor, Return Lane, etc.
  final String viewType; // EarTag, Eating, Resting, etc.
  final String streamUrl;
  final bool isActive;
  final double currentFPS;
  final double latency; // in seconds
  final DateTime lastFrameTime;
  final Map<String, dynamic>? metadata;

  CameraFeed({
    required this.id,
    required this.cameraId,
    required this.cameraName,
    required this.cameraType,
    required this.functionalZone,
    required this.viewType,
    required this.streamUrl,
    this.isActive = true,
    this.currentFPS = 30.0,
    this.latency = 0.62,
    DateTime? lastFrameTime,
    this.metadata,
  }) : lastFrameTime = lastFrameTime ?? DateTime.now();

  factory CameraFeed.fromJson(Map<String, dynamic> json) {
    return CameraFeed(
      id: json['id'] as String,
      cameraId: json['camera_id'] as String,
      cameraName: json['camera_name'] as String,
      cameraType: json['camera_type'] as String,
      functionalZone: json['functional_zone'] as String,
      viewType: json['view_type'] as String,
      streamUrl: json['stream_url'] as String,
      isActive: json['is_active'] as bool? ?? true,
      currentFPS: (json['current_fps'] as num?)?.toDouble() ?? 30.0,
      latency: (json['latency'] as num?)?.toDouble() ?? 0.62,
      lastFrameTime: json['last_frame_time'] != null
          ? DateTime.parse(json['last_frame_time'] as String)
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'camera_id': cameraId,
      'camera_name': cameraName,
      'camera_type': cameraType,
      'functional_zone': functionalZone,
      'view_type': viewType,
      'stream_url': streamUrl,
      'is_active': isActive,
      'current_fps': currentFPS,
      'latency': latency,
      'last_frame_time': lastFrameTime.toIso8601String(),
      'metadata': metadata,
    };
  }

  CameraFeed copyWith({
    String? id,
    String? cameraId,
    String? cameraName,
    String? cameraType,
    String? functionalZone,
    String? viewType,
    String? streamUrl,
    bool? isActive,
    double? currentFPS,
    double? latency,
    DateTime? lastFrameTime,
    Map<String, dynamic>? metadata,
  }) {
    return CameraFeed(
      id: id ?? this.id,
      cameraId: cameraId ?? this.cameraId,
      cameraName: cameraName ?? this.cameraName,
      cameraType: cameraType ?? this.cameraType,
      functionalZone: functionalZone ?? this.functionalZone,
      viewType: viewType ?? this.viewType,
      streamUrl: streamUrl ?? this.streamUrl,
      isActive: isActive ?? this.isActive,
      currentFPS: currentFPS ?? this.currentFPS,
      latency: latency ?? this.latency,
      lastFrameTime: lastFrameTime ?? this.lastFrameTime,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Identification Record Model
/// Stores results from multiple identification methods
class IdentificationRecord {
  final String id;
  final String animalId;
  final String identificationMethod; // Ear Tag, Face-based, Body-based, Body-Color
  final double confidence;
  final DateTime timestamp;
  final String? cameraId;
  final String? imageUrl;
  final Map<String, dynamic>? features;

  IdentificationRecord({
    required this.id,
    required this.animalId,
    required this.identificationMethod,
    required this.confidence,
    DateTime? timestamp,
    this.cameraId,
    this.imageUrl,
    this.features,
  }) : timestamp = timestamp ?? DateTime.now();

  factory IdentificationRecord.fromJson(Map<String, dynamic> json) {
    return IdentificationRecord(
      id: json['id'] as String,
      animalId: json['animal_id'] as String,
      identificationMethod: json['identification_method'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      cameraId: json['camera_id'] as String?,
      imageUrl: json['image_url'] as String?,
      features: json['features'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'animal_id': animalId,
      'identification_method': identificationMethod,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'camera_id': cameraId,
      'image_url': imageUrl,
      'features': features,
    };
  }
}

/// Body Condition Score (BCS) Record
/// From research: 86.21% accuracy
class BCSRecord {
  final String id;
  final String animalId;
  final double bcsScore; // 1.0 - 5.0 scale
  final double confidence;
  final DateTime assessmentDate;
  final String assessmentMethod; // AI-predicted or Manual
  final String? veterinarianNotes;
  final String? imageUrl;
  final Map<String, dynamic>? measurements;

  BCSRecord({
    required this.id,
    required this.animalId,
    required this.bcsScore,
    required this.confidence,
    DateTime? assessmentDate,
    this.assessmentMethod = 'AI-predicted',
    this.veterinarianNotes,
    this.imageUrl,
    this.measurements,
  }) : assessmentDate = assessmentDate ?? DateTime.now();

  String get bcsCategory {
    if (bcsScore < 2.5) return 'Thin';
    if (bcsScore > 4.0) return 'Fat';
    return 'Optimal';
  }

  factory BCSRecord.fromJson(Map<String, dynamic> json) {
    return BCSRecord(
      id: json['id'] as String,
      animalId: json['animal_id'] as String,
      bcsScore: (json['bcs_score'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      assessmentDate: json['assessment_date'] != null
          ? DateTime.parse(json['assessment_date'] as String)
          : DateTime.now(),
      assessmentMethod: json['assessment_method'] as String? ?? 'AI-predicted',
      veterinarianNotes: json['veterinarian_notes'] as String?,
      imageUrl: json['image_url'] as String?,
      measurements: json['measurements'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'animal_id': animalId,
      'bcs_score': bcsScore,
      'confidence': confidence,
      'assessment_date': assessmentDate.toIso8601String(),
      'assessment_method': assessmentMethod,
      'veterinarian_notes': veterinarianNotes,
      'image_url': imageUrl,
      'measurements': measurements,
      'bcs_category': bcsCategory,
    };
  }
}

/// Feeding Record Model
/// Tracks feeding time estimation from AI analysis
class FeedingRecord {
  final String id;
  final String animalId;
  final DateTime startTime;
  final DateTime? endTime;
  final double durationHours;
  final String functionalZone;
  final String? cameraId;
  final double confidence;
  final Map<String, dynamic>? behaviorData;

  FeedingRecord({
    required this.id,
    required this.animalId,
    required this.startTime,
    this.endTime,
    required this.durationHours,
    this.functionalZone = 'Feeding Area',
    this.cameraId,
    this.confidence = 0.0,
    this.behaviorData,
  });

  bool get isOngoing => endTime == null;

  factory FeedingRecord.fromJson(Map<String, dynamic> json) {
    return FeedingRecord(
      id: json['id'] as String,
      animalId: json['animal_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      durationHours: (json['duration_hours'] as num).toDouble(),
      functionalZone: json['functional_zone'] as String? ?? 'Feeding Area',
      cameraId: json['camera_id'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      behaviorData: json['behavior_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'animal_id': animalId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_hours': durationHours,
      'functional_zone': functionalZone,
      'camera_id': cameraId,
      'confidence': confidence,
      'behavior_data': behaviorData,
      'is_ongoing': isOngoing,
    };
  }
}

/// Localization Record Model
/// Real-time cattle location tracking across zones
class LocalizationRecord {
  final String id;
  final String animalId;
  final String currentZone; // Milking Parlor, Return Lane, etc.
  final double positionX;
  final double positionY;
  final double? positionZ; // From depth cameras
  final DateTime timestamp;
  final String? cameraId;
  final double confidence;
  final Map<String, dynamic>? spatialData;

  LocalizationRecord({
    required this.id,
    required this.animalId,
    required this.currentZone,
    required this.positionX,
    required this.positionY,
    this.positionZ,
    DateTime? timestamp,
    this.cameraId,
    this.confidence = 0.0,
    this.spatialData,
  }) : timestamp = timestamp ?? DateTime.now();

  factory LocalizationRecord.fromJson(Map<String, dynamic> json) {
    return LocalizationRecord(
      id: json['id'] as String,
      animalId: json['animal_id'] as String,
      currentZone: json['current_zone'] as String,
      positionX: (json['position_x'] as num).toDouble(),
      positionY: (json['position_y'] as num).toDouble(),
      positionZ: (json['position_z'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      cameraId: json['camera_id'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      spatialData: json['spatial_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'animal_id': animalId,
      'current_zone': currentZone,
      'position_x': positionX,
      'position_y': positionY,
      'position_z': positionZ,
      'timestamp': timestamp.toIso8601String(),
      'camera_id': cameraId,
      'confidence': confidence,
      'spatial_data': spatialData,
    };
  }
}
