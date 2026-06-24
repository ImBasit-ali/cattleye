// ============================================================================
// TABLE 1: COW TABLE (General Health and Status)
// ============================================================================

class Cow {
  final String id;
  final String cattleId;
  final String? earTagNumber;
  final String species;
  final String? breed;
  final DateTime? dateOfBirth;
  final String? gender;
  
  // Current Status
  final String currentHealthStatus;
  final String currentZone;
  final DateTime? lastSeenTimestamp;
  final String? lastSeenCamera;
  
  // Latest Scores
  final double? latestBcsScore;
  final DateTime? latestBcsDate;
  final int? latestLamenessScore;
  final DateTime? latestLamenessDate;
  final String? latestLamenessSeverity;
  
  // Body Measurements
  final double? estimatedBodyWeight;
  final DateTime? lastWeightUpdate;
  
  // Feeding Statistics
  final double totalDailyFeedingTimeHours;
  final DateTime? lastFeedingDate;
  
  // Feature Embeddings
  final List<double>? faceEmbedding; // ArcFace 512-dim
  final List<double>? bodyEmbedding; // ResNet-101 512-dim
  final List<double>? pointCloudEmbedding; // PointNet++ 256-dim
  
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cow({
    required this.id,
    required this.cattleId,
    this.earTagNumber,
    this.species = 'Dairy Cattle',
    this.breed,
    this.dateOfBirth,
    this.gender,
    this.currentHealthStatus = 'Healthy',
    this.currentZone = 'Resting Space',
    this.lastSeenTimestamp,
    this.lastSeenCamera,
    this.latestBcsScore,
    this.latestBcsDate,
    this.latestLamenessScore,
    this.latestLamenessDate,
    this.latestLamenessSeverity,
    this.estimatedBodyWeight,
    this.lastWeightUpdate,
    this.totalDailyFeedingTimeHours = 0.0,
    this.lastFeedingDate,
    this.faceEmbedding,
    this.bodyEmbedding,
    this.pointCloudEmbedding,
    this.notes,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Cow.fromJson(Map<String, dynamic> json) {
    return Cow(
      id: json['id'] as String,
      cattleId: json['cattle_id'] as String,
      earTagNumber: json['ear_tag_number'] as String?,
      species: json['species'] as String? ?? 'Dairy Cattle',
      breed: json['breed'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      currentHealthStatus: json['current_health_status'] as String? ?? 'Healthy',
      currentZone: json['current_zone'] as String? ?? 'Resting Space',
      lastSeenTimestamp: json['last_seen_timestamp'] != null
          ? DateTime.parse(json['last_seen_timestamp'] as String)
          : null,
      lastSeenCamera: json['last_seen_camera'] as String?,
      latestBcsScore: (json['latest_bcs_score'] as num?)?.toDouble(),
      latestBcsDate: json['latest_bcs_date'] != null
          ? DateTime.parse(json['latest_bcs_date'] as String)
          : null,
      latestLamenessScore: json['latest_lameness_score'] as int?,
      latestLamenessDate: json['latest_lameness_date'] != null
          ? DateTime.parse(json['latest_lameness_date'] as String)
          : null,
      latestLamenessSeverity: json['latest_lameness_severity'] as String?,
      estimatedBodyWeight: (json['estimated_body_weight'] as num?)?.toDouble(),
      lastWeightUpdate: json['last_weight_update'] != null
          ? DateTime.parse(json['last_weight_update'] as String)
          : null,
      totalDailyFeedingTimeHours:
          (json['total_daily_feeding_time_hours'] as num?)?.toDouble() ?? 0.0,
      lastFeedingDate: json['last_feeding_date'] != null
          ? DateTime.parse(json['last_feeding_date'] as String)
          : null,
      faceEmbedding: json['face_embedding'] != null
          ? List<double>.from(json['face_embedding'])
          : null,
      bodyEmbedding: json['body_embedding'] != null
          ? List<double>.from(json['body_embedding'])
          : null,
      pointCloudEmbedding: json['point_cloud_embedding'] != null
          ? List<double>.from(json['point_cloud_embedding'])
          : null,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cattle_id': cattleId,
      'ear_tag_number': earTagNumber,
      'species': species,
      'breed': breed,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'current_health_status': currentHealthStatus,
      'current_zone': currentZone,
      'last_seen_timestamp': lastSeenTimestamp?.toIso8601String(),
      'last_seen_camera': lastSeenCamera,
      'latest_bcs_score': latestBcsScore,
      'latest_bcs_date': latestBcsDate?.toIso8601String(),
      'latest_lameness_score': latestLamenessScore,
      'latest_lameness_date': latestLamenessDate?.toIso8601String(),
      'latest_lameness_severity': latestLamenessSeverity,
      'estimated_body_weight': estimatedBodyWeight,
      'last_weight_update': lastWeightUpdate?.toIso8601String(),
      'total_daily_feeding_time_hours': totalDailyFeedingTimeHours,
      'last_feeding_date': lastFeedingDate?.toIso8601String(),
      'face_embedding': faceEmbedding,
      'body_embedding': bodyEmbedding,
      'point_cloud_embedding': pointCloudEmbedding,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// ============================================================================
// TABLE 2: EAR-TAG CAMERA (Milking Parlor - 94% Accuracy)
// ============================================================================

class EarTagCameraRecord {
  final String id;
  final String cowId;
  final String? earTagNumber;
  final double confidence;
  final DateTime detectionTimestamp;
  
  final int cameraNumber; // 1 or 2
  final String functionalZone;
  
  final String? headImageUrl;
  final String? earTagCropUrl;
  final Map<String, dynamic>? boundingBox;
  final List<Map<String, dynamic>>? detectedCharacters;
  final String recognitionMethod;
  
  final DateTime? milkingSessionStart;
  final DateTime? milkingSessionEnd;
  final int? milkingPosition;

  EarTagCameraRecord({
    required this.id,
    required this.cowId,
    this.earTagNumber,
    required this.confidence,
    DateTime? detectionTimestamp,
    required this.cameraNumber,
    this.functionalZone = 'Milking Parlor',
    this.headImageUrl,
    this.earTagCropUrl,
    this.boundingBox,
    this.detectedCharacters,
    this.recognitionMethod = 'CRAFT+ResNet18',
    this.milkingSessionStart,
    this.milkingSessionEnd,
    this.milkingPosition,
  }) : detectionTimestamp = detectionTimestamp ?? DateTime.now();

  factory EarTagCameraRecord.fromJson(Map<String, dynamic> json) {
    return EarTagCameraRecord(
      id: json['id'] as String,
      cowId: json['cow_id'] as String,
      earTagNumber: json['ear_tag_number'] as String?,
      confidence: (json['confidence'] as num).toDouble(),
      detectionTimestamp: DateTime.parse(json['detection_timestamp'] as String),
      cameraNumber: json['camera_number'] as int,
      functionalZone: json['functional_zone'] as String? ?? 'Milking Parlor',
      headImageUrl: json['head_image_url'] as String?,
      earTagCropUrl: json['ear_tag_crop_url'] as String?,
      boundingBox: json['bounding_box'] as Map<String, dynamic>?,
      detectedCharacters: json['detected_characters'] != null
          ? List<Map<String, dynamic>>.from(json['detected_characters'])
          : null,
      recognitionMethod: json['recognition_method'] as String? ?? 'CRAFT+ResNet18',
      milkingSessionStart: json['milking_session_start'] != null
          ? DateTime.parse(json['milking_session_start'] as String)
          : null,
      milkingSessionEnd: json['milking_session_end'] != null
          ? DateTime.parse(json['milking_session_end'] as String)
          : null,
      milkingPosition: json['milking_position'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cow_id': cowId,
      'ear_tag_number': earTagNumber,
      'confidence': confidence,
      'detection_timestamp': detectionTimestamp.toIso8601String(),
      'camera_number': cameraNumber,
      'functional_zone': functionalZone,
      'head_image_url': headImageUrl,
      'ear_tag_crop_url': earTagCropUrl,
      'bounding_box': boundingBox,
      'detected_characters': detectedCharacters,
      'recognition_method': recognitionMethod,
      'milking_session_start': milkingSessionStart?.toIso8601String(),
      'milking_session_end': milkingSessionEnd?.toIso8601String(),
      'milking_position': milkingPosition,
    };
  }
}

// ============================================================================
// TABLE 3: DEPTH CAMERA (Lameness - 88.2-89.0% Accuracy)
// ============================================================================

class DepthCameraRecord {
  final String id;
  final String cowId;
  final int lamenessScore; // 0-5
  final String lamenessSeverity;
  final double lamenessConfidence;
  
  final String detectionMethod;
  final String timeOfDay; // Morning or Evening
  
  final int cameraNumber; // Camera 3
  final String functionalZone;
  
  final String? depthImageUrl;
  final Map<String, dynamic>? backDepthFeatures;
  final String? segmentationMaskUrl;
  
  final int? trackingId;
  final int? frameNumber;
  
  final DateTime postMilkingTimestamp;
  final String? relatedMilkingSessionId;

  DepthCameraRecord({
    required this.id,
    required this.cowId,
    required this.lamenessScore,
    required this.lamenessSeverity,
    required this.lamenessConfidence,
    this.detectionMethod = 'Detectron2 + Extra Trees',
    required this.timeOfDay,
    this.cameraNumber = 3,
    this.functionalZone = 'Return Lane',
    this.depthImageUrl,
    this.backDepthFeatures,
    this.segmentationMaskUrl,
    this.trackingId,
    this.frameNumber,
    DateTime? postMilkingTimestamp,
    this.relatedMilkingSessionId,
  }) : postMilkingTimestamp = postMilkingTimestamp ?? DateTime.now();

  factory DepthCameraRecord.fromJson(Map<String, dynamic> json) {
    return DepthCameraRecord(
      id: json['id'] as String,
      cowId: json['cow_id'] as String,
      lamenessScore: json['lameness_score'] as int,
      lamenessSeverity: json['lameness_severity'] as String,
      lamenessConfidence: (json['lameness_confidence'] as num).toDouble(),
      detectionMethod: json['detection_method'] as String? ?? 'Detectron2 + Extra Trees',
      timeOfDay: json['time_of_day'] as String,
      cameraNumber: json['camera_number'] as int? ?? 3,
      functionalZone: json['functional_zone'] as String? ?? 'Return Lane',
      depthImageUrl: json['depth_image_url'] as String?,
      backDepthFeatures: json['back_depth_features'] as Map<String, dynamic>?,
      segmentationMaskUrl: json['segmentation_mask_url'] as String?,
      trackingId: json['tracking_id'] as int?,
      frameNumber: json['frame_number'] as int?,
      postMilkingTimestamp: DateTime.parse(json['post_milking_timestamp'] as String),
      relatedMilkingSessionId: json['related_milking_session_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cow_id': cowId,
      'lameness_score': lamenessScore,
      'lameness_severity': lamenessSeverity,
      'lameness_confidence': lamenessConfidence,
      'detection_method': detectionMethod,
      'time_of_day': timeOfDay,
      'camera_number': cameraNumber,
      'functional_zone': functionalZone,
      'depth_image_url': depthImageUrl,
      'back_depth_features': backDepthFeatures,
      'segmentation_mask_url': segmentationMaskUrl,
      'tracking_id': trackingId,
      'frame_number': frameNumber,
      'post_milking_timestamp': postMilkingTimestamp.toIso8601String(),
      'related_milking_session_id': relatedMilkingSessionId,
    };
  }
}

// ============================================================================
// TABLE 4: SIDE VIEW CAMERA (Lameness from RGB - YOLOv9 + SVM)
// ============================================================================

class SideViewCameraRecord {
  final String id;
  final String cowId;
  final int lamenessScore;
  final String lamenessSeverity;
  final double classificationConfidence;
  
  final String detectionMethod;
  final int cameraNumber; // Camera 5
  final String functionalZone;
  
  final String? sideViewImageUrl;
  final Map<String, dynamic>? legKeypoints;
  final Map<String, dynamic>? gaitFeatures;
  final List<Map<String, dynamic>>? movementTrajectory;
  
  final int? trackingId;
  final int? sequenceStartFrame;
  final int? sequenceEndFrame;
  final int? totalFramesAnalyzed;
  
  final DateTime analysisTimestamp;
  final String? videoClipUrl;

  SideViewCameraRecord({
    required this.id,
    required this.cowId,
    required this.lamenessScore,
    required this.lamenessSeverity,
    required this.classificationConfidence,
    this.detectionMethod = 'YOLOv9 + SVM',
    this.cameraNumber = 5,
    this.functionalZone = 'Return Lane',
    this.sideViewImageUrl,
    this.legKeypoints,
    this.gaitFeatures,
    this.movementTrajectory,
    this.trackingId,
    this.sequenceStartFrame,
    this.sequenceEndFrame,
    this.totalFramesAnalyzed,
    DateTime? analysisTimestamp,
    this.videoClipUrl,
  }) : analysisTimestamp = analysisTimestamp ?? DateTime.now();

  factory SideViewCameraRecord.fromJson(Map<String, dynamic> json) {
    return SideViewCameraRecord(
      id: json['id'] as String,
      cowId: json['cow_id'] as String,
      lamenessScore: json['lameness_score'] as int,
      lamenessSeverity: json['lameness_severity'] as String,
      classificationConfidence: (json['classification_confidence'] as num).toDouble(),
      detectionMethod: json['detection_method'] as String? ?? 'YOLOv9 + SVM',
      cameraNumber: json['camera_number'] as int? ?? 5,
      functionalZone: json['functional_zone'] as String? ?? 'Return Lane',
      sideViewImageUrl: json['side_view_image_url'] as String?,
      legKeypoints: json['leg_keypoints'] as Map<String, dynamic>?,
      gaitFeatures: json['gait_features'] as Map<String, dynamic>?,
      movementTrajectory: json['movement_trajectory'] != null
          ? List<Map<String, dynamic>>.from(json['movement_trajectory'])
          : null,
      trackingId: json['tracking_id'] as int?,
      sequenceStartFrame: json['sequence_start_frame'] as int?,
      sequenceEndFrame: json['sequence_end_frame'] as int?,
      totalFramesAnalyzed: json['total_frames_analyzed'] as int?,
      analysisTimestamp: DateTime.parse(json['analysis_timestamp'] as String),
      videoClipUrl: json['video_clip_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cow_id': cowId,
      'lameness_score': lamenessScore,
      'lameness_severity': lamenessSeverity,
      'classification_confidence': classificationConfidence,
      'detection_method': detectionMethod,
      'camera_number': cameraNumber,
      'functional_zone': functionalZone,
      'side_view_image_url': sideViewImageUrl,
      'leg_keypoints': legKeypoints,
      'gait_features': gaitFeatures,
      'movement_trajectory': movementTrajectory,
      'tracking_id': trackingId,
      'sequence_start_frame': sequenceStartFrame,
      'sequence_end_frame': sequenceEndFrame,
      'total_frames_analyzed': totalFramesAnalyzed,
      'analysis_timestamp': analysisTimestamp.toIso8601String(),
      'video_clip_url': videoClipUrl,
    };
  }
}

// ============================================================================
// TABLE 5: RGB-D CAMERA (BCS 86.21% + Identification 99.55%)
// ============================================================================

class RGBDCameraRecord {
  final String id;
  final String cowId;
  final double bcsScore;
  final double bcsConfidence;
  final double bcsTolerance;
  final double bcsAccuracyAtTolerance;
  
  final String detectionMethod;
  final String identificationMethod;
  final double identificationConfidence;
  
  final int cameraNumber; // Camera 4
  final String functionalZone;
  
  final String? pointCloudUrl;
  final Map<String, dynamic>? pointCloudFeatures;
  final int downsampledPoints;
  
  // Geometric features from Random Forest
  final Map<String, dynamic>? normalVectors;
  final Map<String, dynamic>? curvatureValues;
  final double? pointDensity;
  final double? planarity;
  final double? linearity;
  final double? sphericity;
  final Map<String, dynamic>? fpfhDescriptor;
  final double? triangleMeshArea;
  final double? convexHullArea;
  
  final double? estimatedBodyWeight;
  final double? weightEstimationConfidence;
  
  final int? trackingId;
  final DateTime assessmentTimestamp;
  final String? depthImageUrl;
  final String? rgbImageUrl;

  RGBDCameraRecord({
    required this.id,
    required this.cowId,
    required this.bcsScore,
    required this.bcsConfidence,
    this.bcsTolerance = 0.25,
    this.bcsAccuracyAtTolerance = 86.21,
    this.detectionMethod = 'Detectron2 + Random Forest',
    this.identificationMethod = 'PointNet++ Siamese Network',
    required this.identificationConfidence,
    this.cameraNumber = 4,
    this.functionalZone = 'Return Lane',
    this.pointCloudUrl,
    this.pointCloudFeatures,
    this.downsampledPoints = 2048,
    this.normalVectors,
    this.curvatureValues,
    this.pointDensity,
    this.planarity,
    this.linearity,
    this.sphericity,
    this.fpfhDescriptor,
    this.triangleMeshArea,
    this.convexHullArea,
    this.estimatedBodyWeight,
    this.weightEstimationConfidence,
    this.trackingId,
    DateTime? assessmentTimestamp,
    this.depthImageUrl,
    this.rgbImageUrl,
  }) : assessmentTimestamp = assessmentTimestamp ?? DateTime.now();

  factory RGBDCameraRecord.fromJson(Map<String, dynamic> json) {
    return RGBDCameraRecord(
      id: json['id'] as String,
      cowId: json['cow_id'] as String,
      bcsScore: (json['bcs_score'] as num).toDouble(),
      bcsConfidence: (json['bcs_confidence'] as num).toDouble(),
      bcsTolerance: (json['bcs_tolerance_level'] as num?)?.toDouble() ?? 0.25,
      bcsAccuracyAtTolerance: (json['bcs_accuracy_at_tolerance'] as num?)?.toDouble() ?? 86.21,
      detectionMethod: json['detection_method'] as String? ?? 'Detectron2 + Random Forest',
      identificationMethod: json['identification_method'] as String? ?? 'PointNet++ Siamese Network',
      identificationConfidence: (json['identification_confidence'] as num).toDouble(),
      cameraNumber: json['camera_number'] as int? ?? 4,
      functionalZone: json['functional_zone'] as String? ?? 'Return Lane',
      pointCloudUrl: json['point_cloud_url'] as String?,
      pointCloudFeatures: json['point_cloud_features'] as Map<String, dynamic>?,
      downsampledPoints: json['downsampled_points'] as int? ?? 2048,
      normalVectors: json['normal_vectors'] as Map<String, dynamic>?,
      curvatureValues: json['curvature_values'] as Map<String, dynamic>?,
      pointDensity: (json['point_density'] as num?)?.toDouble(),
      planarity: (json['planarity'] as num?)?.toDouble(),
      linearity: (json['linearity'] as num?)?.toDouble(),
      sphericity: (json['sphericity'] as num?)?.toDouble(),
      fpfhDescriptor: json['fpfh_descriptor'] as Map<String, dynamic>?,
      triangleMeshArea: (json['triangle_mesh_area'] as num?)?.toDouble(),
      convexHullArea: (json['convex_hull_area'] as num?)?.toDouble(),
      estimatedBodyWeight: (json['estimated_body_weight'] as num?)?.toDouble(),
      weightEstimationConfidence: (json['weight_estimation_confidence'] as num?)?.toDouble(),
      trackingId: json['tracking_id'] as int?,
      assessmentTimestamp: DateTime.parse(json['assessment_timestamp'] as String),
      depthImageUrl: json['depth_image_url'] as String?,
      rgbImageUrl: json['rgb_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cow_id': cowId,
      'bcs_score': bcsScore,
      'bcs_confidence': bcsConfidence,
      'bcs_tolerance_level': bcsTolerance,
      'bcs_accuracy_at_tolerance': bcsAccuracyAtTolerance,
      'detection_method': detectionMethod,
      'identification_method': identificationMethod,
      'identification_confidence': identificationConfidence,
      'camera_number': cameraNumber,
      'functional_zone': functionalZone,
      'point_cloud_url': pointCloudUrl,
      'point_cloud_features': pointCloudFeatures,
      'downsampled_points': downsampledPoints,
      'normal_vectors': normalVectors,
      'curvature_values': curvatureValues,
      'point_density': pointDensity,
      'planarity': planarity,
      'linearity': linearity,
      'sphericity': sphericity,
      'fpfh_descriptor': fpfhDescriptor,
      'triangle_mesh_area': triangleMeshArea,
      'convex_hull_area': convexHullArea,
      'estimated_body_weight': estimatedBodyWeight,
      'weight_estimation_confidence': weightEstimationConfidence,
      'tracking_id': trackingId,
      'assessment_timestamp': assessmentTimestamp.toIso8601String(),
      'depth_image_url': depthImageUrl,
      'rgb_image_url': rgbImageUrl,
    };
  }
}

// ============================================================================
// TABLE 6: HEAD VIEW CAMERA (Feeding - 93.66% Face Accuracy)
// ============================================================================

class HeadViewCameraRecord {
  final String id;
  final String cowId;
  final String? cattleIdPredicted;
  final double identificationConfidence;
  final String identificationMethod;
  
  final int cameraNumber; // 7-10
  final String functionalZone;
  
  final String? headImageUrl;
  final Map<String, dynamic>? headBoundingBox;
  final int? trackingId;
  
  final List<double>? facialEmbedding; // ArcFace 512-dim
  final Map<String, dynamic>? faceFeatures;
  
  final int? feedingLineYCoordinate;
  final int? headPositionY;
  final bool isFeeding;
  
  final DateTime? feedingSessionStart;
  final DateTime? feedingSessionEnd;
  final double? feedingDurationSeconds;
  final double? cumulativeDailyFeedingSeconds;
  
  final DateTime frameTimestamp;
  final int? frameNumber;

  HeadViewCameraRecord({
    required this.id,
    required this.cowId,
    this.cattleIdPredicted,
    required this.identificationConfidence,
    this.identificationMethod = 'Mask R-CNN + Siamese + ArcFace',
    required this.cameraNumber,
    this.functionalZone = 'Feeding Area',
    this.headImageUrl,
    this.headBoundingBox,
    this.trackingId,
    this.facialEmbedding,
    this.faceFeatures,
    this.feedingLineYCoordinate,
    this.headPositionY,
    this.isFeeding = false,
    this.feedingSessionStart,
    this.feedingSessionEnd,
    this.feedingDurationSeconds,
    this.cumulativeDailyFeedingSeconds,
    DateTime? frameTimestamp,
    this.frameNumber,
  }) : frameTimestamp = frameTimestamp ?? DateTime.now();

  factory HeadViewCameraRecord.fromJson(Map<String, dynamic> json) {
    return HeadViewCameraRecord(
      id: json['id'] as String,
      cowId: json['cow_id'] as String,
      cattleIdPredicted: json['cattle_id_predicted'] as String?,
      identificationConfidence: (json['identification_confidence'] as num).toDouble(),
      identificationMethod: json['identification_method'] as String? ?? 'Mask R-CNN + Siamese + ArcFace',
      cameraNumber: json['camera_number'] as int,
      functionalZone: json['functional_zone'] as String? ?? 'Feeding Area',
      headImageUrl: json['head_image_url'] as String?,
      headBoundingBox: json['head_bounding_box'] as Map<String, dynamic>?,
      trackingId: json['tracking_id'] as int?,
      facialEmbedding: json['facial_embedding'] != null
          ? List<double>.from(json['facial_embedding'])
          : null,
      faceFeatures: json['face_features'] as Map<String, dynamic>?,
      feedingLineYCoordinate: json['feeding_line_y_coordinate'] as int?,
      headPositionY: json['head_position_y'] as int?,
      isFeeding: json['is_feeding'] as bool? ?? false,
      feedingSessionStart: json['feeding_session_start'] != null
          ? DateTime.parse(json['feeding_session_start'] as String)
          : null,
      feedingSessionEnd: json['feeding_session_end'] != null
          ? DateTime.parse(json['feeding_session_end'] as String)
          : null,
      feedingDurationSeconds: (json['feeding_duration_seconds'] as num?)?.toDouble(),
      cumulativeDailyFeedingSeconds: (json['cumulative_daily_feeding_seconds'] as num?)?.toDouble(),
      frameTimestamp: DateTime.parse(json['frame_timestamp'] as String),
      frameNumber: json['frame_number'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cow_id': cowId,
      'cattle_id_predicted': cattleIdPredicted,
      'identification_confidence': identificationConfidence,
      'identification_method': identificationMethod,
      'camera_number': cameraNumber,
      'functional_zone': functionalZone,
      'head_image_url': headImageUrl,
      'head_bounding_box': headBoundingBox,
      'tracking_id': trackingId,
      'facial_embedding': facialEmbedding,
      'face_features': faceFeatures,
      'feeding_line_y_coordinate': feedingLineYCoordinate,
      'head_position_y': headPositionY,
      'is_feeding': isFeeding,
      'feeding_session_start': feedingSessionStart?.toIso8601String(),
      'feeding_session_end': feedingSessionEnd?.toIso8601String(),
      'feeding_duration_seconds': feedingDurationSeconds,
      'cumulative_daily_feeding_seconds': cumulativeDailyFeedingSeconds,
      'frame_timestamp': frameTimestamp.toIso8601String(),
      'frame_number': frameNumber,
    };
  }
}

// ============================================================================
// TABLE 7: BACK VIEW CAMERA (Localization - 92.80% Body Accuracy)
// ============================================================================

class BackViewCameraRecord {
  final String id;
  final String cowId;
  final String? cattleIdPredicted;
  final double identificationConfidence;
  final String identificationMethod;
  
  final int cameraNumber; // 11-23
  final String functionalZone;
  
  final String? bodyImageUrl;
  final Map<String, dynamic>? bodyBoundingBox;
  final String? bodyMaskUrl;
  final int? trackingId;
  
  final List<double>? bodyEmbedding; // ResNet-101 512-dim
  final Map<String, dynamic>? bodyColorFeatures;
  final Map<String, dynamic>? bodyShapeFeatures;
  
  final int positionX;
  final int positionY;
  final String currentZone;
  final DateTime? zoneEntryTimestamp;
  
  final int? previousCameraNumber;
  final int? nextCameraNumber;
  final DateTime? cameraTransitionTimestamp;
  
  final DateTime recordingTimestamp;
  final bool isMinuteMarker; // One-minute interval records

  BackViewCameraRecord({
    required this.id,
    required this.cowId,
    this.cattleIdPredicted,
    required this.identificationConfidence,
    this.identificationMethod = 'Mask R-CNN + ByteTrack + ResNet-101',
    required this.cameraNumber,
    required this.functionalZone,
    this.bodyImageUrl,
    this.bodyBoundingBox,
    this.bodyMaskUrl,
    this.trackingId,
    this.bodyEmbedding,
    this.bodyColorFeatures,
    this.bodyShapeFeatures,
    required this.positionX,
    required this.positionY,
    required this.currentZone,
    this.zoneEntryTimestamp,
    this.previousCameraNumber,
    this.nextCameraNumber,
    this.cameraTransitionTimestamp,
    DateTime? recordingTimestamp,
    this.isMinuteMarker = false,
  }) : recordingTimestamp = recordingTimestamp ?? DateTime.now();

  factory BackViewCameraRecord.fromJson(Map<String, dynamic> json) {
    return BackViewCameraRecord(
      id: json['id'] as String,
      cowId: json['cow_id'] as String,
      cattleIdPredicted: json['cattle_id_predicted'] as String?,
      identificationConfidence: (json['identification_confidence'] as num).toDouble(),
      identificationMethod: json['identification_method'] as String? ?? 'Mask R-CNN + ByteTrack + ResNet-101',
      cameraNumber: json['camera_number'] as int,
      functionalZone: json['functional_zone'] as String,
      bodyImageUrl: json['body_image_url'] as String?,
      bodyBoundingBox: json['body_bounding_box'] as Map<String, dynamic>?,
      bodyMaskUrl: json['body_mask_url'] as String?,
      trackingId: json['tracking_id'] as int?,
      bodyEmbedding: json['body_embedding'] != null
          ? List<double>.from(json['body_embedding'])
          : null,
      bodyColorFeatures: json['body_color_features'] as Map<String, dynamic>?,
      bodyShapeFeatures: json['body_shape_features'] as Map<String, dynamic>?,
      positionX: json['position_x'] as int,
      positionY: json['position_y'] as int,
      currentZone: json['current_zone'] as String,
      zoneEntryTimestamp: json['zone_entry_timestamp'] != null
          ? DateTime.parse(json['zone_entry_timestamp'] as String)
          : null,
      previousCameraNumber: json['previous_camera_number'] as int?,
      nextCameraNumber: json['next_camera_number'] as int?,
      cameraTransitionTimestamp: json['camera_transition_timestamp'] != null
          ? DateTime.parse(json['camera_transition_timestamp'] as String)
          : null,
      recordingTimestamp: DateTime.parse(json['recording_timestamp'] as String),
      isMinuteMarker: json['is_minute_marker'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cow_id': cowId,
      'cattle_id_predicted': cattleIdPredicted,
      'identification_confidence': identificationConfidence,
      'identification_method': identificationMethod,
      'camera_number': cameraNumber,
      'functional_zone': functionalZone,
      'body_image_url': bodyImageUrl,
      'body_bounding_box': bodyBoundingBox,
      'body_mask_url': bodyMaskUrl,
      'tracking_id': trackingId,
      'body_embedding': bodyEmbedding,
      'body_color_features': bodyColorFeatures,
      'body_shape_features': bodyShapeFeatures,
      'position_x': positionX,
      'position_y': positionY,
      'current_zone': currentZone,
      'zone_entry_timestamp': zoneEntryTimestamp?.toIso8601String(),
      'previous_camera_number': previousCameraNumber,
      'next_camera_number': nextCameraNumber,
      'camera_transition_timestamp': cameraTransitionTimestamp?.toIso8601String(),
      'recording_timestamp': recordingTimestamp.toIso8601String(),
      'is_minute_marker': isMinuteMarker,
    };
  }
}
