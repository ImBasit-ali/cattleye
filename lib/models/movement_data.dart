/// Movement Data Model - Represents daily movement tracking data
class MovementData {
  final String id;
  final String animalId;
  final DateTime date;
  final int stepCount;
  final double activityDurationHours; // Active time in hours
  final double restDurationHours; // Rest time in hours
  final double movementScore; // 0-100 calculated score
  final String movementLevel; // Normal, Reduced, Abnormal
  final DateTime timestamp;
  
  // Additional metrics
  final double? averageSpeed; // meters per minute
  final int? distanceCovered; // in meters
  final Map<String, dynamic>? rawSensorData; // IoT sensor data

  MovementData({
    required this.id,
    required this.animalId,
    required this.date,
    required this.stepCount,
    required this.activityDurationHours,
    required this.restDurationHours,
    required this.movementScore,
    required this.movementLevel,
    required this.timestamp,
    this.averageSpeed,
    this.distanceCovered,
    this.rawSensorData,
  });

  /// Create MovementData from JSON
  factory MovementData.fromJson(Map<String, dynamic> json) {
    return MovementData(
      id: json['id'] as String,
      animalId: json['animal_id'] as String,
      date: DateTime.parse(json['date'] as String),
      stepCount: json['step_count'] as int,
      activityDurationHours: (json['activity_duration_hours'] as num).toDouble(),
      restDurationHours: (json['rest_duration_hours'] as num).toDouble(),
      movementScore: (json['movement_score'] as num).toDouble(),
      movementLevel: json['movement_level'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      averageSpeed: json['average_speed'] != null 
          ? (json['average_speed'] as num).toDouble() 
          : null,
      distanceCovered: json['distance_covered'] as int?,
      rawSensorData: json['raw_sensor_data'] as Map<String, dynamic>?,
    );
  }

  /// Convert MovementData to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'animal_id': animalId,
      'date': date.toIso8601String(),
      'step_count': stepCount,
      'activity_duration_hours': activityDurationHours,
      'rest_duration_hours': restDurationHours,
      'movement_score': movementScore,
      'movement_level': movementLevel,
      'timestamp': timestamp.toIso8601String(),
      'average_speed': averageSpeed,
      'distance_covered': distanceCovered,
      'raw_sensor_data': rawSensorData,
    };
  }

  /// Create a copy with modified fields
  MovementData copyWith({
    String? id,
    String? animalId,
    DateTime? date,
    int? stepCount,
    double? activityDurationHours,
    double? restDurationHours,
    double? movementScore,
    String? movementLevel,
    DateTime? timestamp,
    double? averageSpeed,
    int? distanceCovered,
    Map<String, dynamic>? rawSensorData,
  }) {
    return MovementData(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      date: date ?? this.date,
      stepCount: stepCount ?? this.stepCount,
      activityDurationHours: activityDurationHours ?? this.activityDurationHours,
      restDurationHours: restDurationHours ?? this.restDurationHours,
      movementScore: movementScore ?? this.movementScore,
      movementLevel: movementLevel ?? this.movementLevel,
      timestamp: timestamp ?? this.timestamp,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      distanceCovered: distanceCovered ?? this.distanceCovered,
      rawSensorData: rawSensorData ?? this.rawSensorData,
    );
  }

  @override
  String toString() {
    return 'MovementData{id: $id, animalId: $animalId, stepCount: $stepCount, score: $movementScore}';
  }
}
