import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/movement_data.dart';
import '../core/utils/helpers.dart';

/// IoT Simulation Service
/// Simulates IoT sensor data for cattle monitoring
/// In production, this would be replaced with actual IoT hardware integration
class IoTSimulationService {
  static final IoTSimulationService _instance = IoTSimulationService._internal();
  factory IoTSimulationService() => _instance;
  IoTSimulationService._internal();

  final math.Random _random = math.Random();
  final Map<String, Timer?> _activeSimulations = {};
  final Map<String, AnimalBehaviorProfile> _behaviorProfiles = {};

  /// Start simulating movement data for an animal
  void startSimulation({
    required String animalId,
    required Function(SimulatedMovementData) onDataGenerated,
    AnimalHealthCondition healthCondition = AnimalHealthCondition.healthy,
  }) {
    // Stop existing simulation if any
    stopSimulation(animalId);

    // Create behavior profile
    _behaviorProfiles[animalId] = AnimalBehaviorProfile(
      healthCondition: healthCondition,
    );

    // Start periodic data generation
    const simulationIntervalSeconds = 5;
    _activeSimulations[animalId] = Timer.periodic(
      const Duration(seconds: simulationIntervalSeconds),
      (timer) {
        final data = _generateMovementData(animalId);
        onDataGenerated(data);
      },
    );

    if (kDebugMode) {
      debugPrint('Started IoT simulation for animal: $animalId');
    }
  }

  /// Stop simulation for an animal
  void stopSimulation(String animalId) {
    _activeSimulations[animalId]?.cancel();
    _activeSimulations.remove(animalId);
    _behaviorProfiles.remove(animalId);
    if (kDebugMode) {
      debugPrint('Stopped IoT simulation for animal: $animalId');
    }
  }

  /// Stop all simulations
  void stopAllSimulations() {
    for (final animalId in _activeSimulations.keys.toList()) {
      stopSimulation(animalId);
    }
  }

  /// Generate simulated movement data
  SimulatedMovementData _generateMovementData(String animalId) {
    final profile = _behaviorProfiles[animalId]!;
    final now = DateTime.now();
    final hour = now.hour;

    // Simulate circadian rhythm (animals more active during day)
    final timeOfDayFactor = _getTimeOfDayFactor(hour);
    
    // Generate base values based on health condition
    int stepCount;
    double activityMinutes;
    double restMinutes;
    double averageSpeed;
    double symmetryScore;

    switch (profile.healthCondition) {
      case AnimalHealthCondition.healthy:
        stepCount = _randomInRange(150, 250) * timeOfDayFactor ~/ 100;
        activityMinutes = _randomDouble(20, 40) * timeOfDayFactor / 100;
        restMinutes = 60 - activityMinutes;
        averageSpeed = _randomDouble(40, 80); // meters per minute
        symmetryScore = _randomDouble(0.85, 0.98);
        break;

      case AnimalHealthCondition.mildLameness:
        stepCount = _randomInRange(80, 140) * timeOfDayFactor ~/ 100;
        activityMinutes = _randomDouble(10, 25) * timeOfDayFactor / 100;
        restMinutes = 60 - activityMinutes;
        averageSpeed = _randomDouble(25, 45);
        symmetryScore = _randomDouble(0.60, 0.75);
        break;

      case AnimalHealthCondition.severeLameness:
        stepCount = _randomInRange(20, 60) * timeOfDayFactor ~/ 100;
        activityMinutes = _randomDouble(5, 15) * timeOfDayFactor / 100;
        restMinutes = 60 - activityMinutes;
        averageSpeed = _randomDouble(10, 25);
        symmetryScore = _randomDouble(0.30, 0.50);
        break;
    }

    // Add some noise/variation
    stepCount = (stepCount + _randomInRange(-10, 10)).clamp(0, 500);
    activityMinutes = (activityMinutes + _randomDouble(-2, 2)).clamp(0, 60);
    restMinutes = 60 - activityMinutes;

    // Simulate accelerometer data
    final accelerometerData = _generateAccelerometerData(
      activityLevel: activityMinutes / 60,
      healthCondition: profile.healthCondition,
    );

    // Calculate distance covered
    final distanceCovered = (stepCount * 0.7).toInt(); // Average step length ~0.7m

    return SimulatedMovementData(
      animalId: animalId,
      timestamp: now,
      stepCount: stepCount,
      activityMinutes: activityMinutes,
      restMinutes: restMinutes,
      averageSpeed: averageSpeed,
      distanceCovered: distanceCovered,
      symmetryScore: symmetryScore,
      accelerometerData: accelerometerData,
      heartRate: _randomInRange(60, 90),
      bodyTemperature: _randomDouble(38.0, 39.5),
    );
  }

  /// Get time of day activity factor (0-100)
  int _getTimeOfDayFactor(int hour) {
    // Animals most active: 6-10am (morning) and 4-8pm (evening)
    if (hour >= 6 && hour < 10) return 100; // Morning peak
    if (hour >= 10 && hour < 16) return 70; // Midday moderate
    if (hour >= 16 && hour < 20) return 90; // Evening active
    if (hour >= 20 || hour < 6) return 30; // Night rest
    return 50;
  }

  /// Generate simulated accelerometer data
  Map<String, dynamic> _generateAccelerometerData({
    required double activityLevel,
    required AnimalHealthCondition healthCondition,
  }) {
    // Simulate 3-axis accelerometer (x, y, z)
    double xVariance, yVariance, zVariance;

    switch (healthCondition) {
      case AnimalHealthCondition.healthy:
        xVariance = _randomDouble(0.3, 0.8) * activityLevel;
        yVariance = _randomDouble(0.3, 0.8) * activityLevel;
        zVariance = _randomDouble(0.2, 0.6) * activityLevel;
        break;
      case AnimalHealthCondition.mildLameness:
        xVariance = _randomDouble(0.2, 0.5) * activityLevel;
        yVariance = _randomDouble(0.2, 0.5) * activityLevel;
        zVariance = _randomDouble(0.1, 0.4) * activityLevel;
        break;
      case AnimalHealthCondition.severeLameness:
        xVariance = _randomDouble(0.1, 0.3) * activityLevel;
        yVariance = _randomDouble(0.1, 0.3) * activityLevel;
        zVariance = _randomDouble(0.05, 0.2) * activityLevel;
        break;
    }

    return {
      'x': _randomDouble(-xVariance, xVariance),
      'y': _randomDouble(-yVariance, yVariance),
      'z': 1.0 + _randomDouble(-zVariance, zVariance), // Gravity component
      'magnitude': math.sqrt(
        xVariance * xVariance + yVariance * yVariance + zVariance * zVariance,
      ),
    };
  }

  /// Generate daily summary from hourly data
  MovementData generateDailySummary({
    required String animalId,
    required List<SimulatedMovementData> hourlyData,
  }) {
    final totalSteps = hourlyData.fold<int>(0, (sum, data) => sum + data.stepCount);
    final totalActivityMinutes = hourlyData.fold<double>(
      0, 
      (sum, data) => sum + data.activityMinutes,
    );
    final totalRestMinutes = hourlyData.fold<double>(
      0,
      (sum, data) => sum + data.restMinutes,
    );
    final avgSpeed = hourlyData.fold<double>(0, (sum, data) => sum + data.averageSpeed) / 
        hourlyData.length;
    final totalDistance = hourlyData.fold<int>(0, (sum, data) => sum + data.distanceCovered);

    final activityHours = totalActivityMinutes / 60;
    final restHours = totalRestMinutes / 60;

    // Calculate movement score
    final movementScore = CalculationUtils.calculateMovementScore(
      stepCount: totalSteps,
      activityHours: activityHours,
    );

    // Determine movement level
    String movementLevel;
    const normalStepsPerDay = 3000;
    const normalActivityDurationHours = 8.0;
    const lowActivityThreshold = 1500;
    if (totalSteps >= normalStepsPerDay &&
        activityHours >= normalActivityDurationHours) {
      movementLevel = 'Normal';
    } else if (totalSteps >= lowActivityThreshold) {
      movementLevel = 'Reduced';
    } else {
      movementLevel = 'Abnormal';
    }

    return MovementData(
      id: StringUtils.generateId(),
      animalId: animalId,
      date: DateTimeUtils.startOfDay(DateTime.now()),
      stepCount: totalSteps,
      activityDurationHours: activityHours,
      restDurationHours: restHours,
      movementScore: movementScore,
      movementLevel: movementLevel,
      timestamp: DateTime.now(),
      averageSpeed: avgSpeed,
      distanceCovered: totalDistance,
    );
  }

  /// Helper: Generate random integer in range
  int _randomInRange(int min, int max) {
    return min + _random.nextInt(max - min + 1);
  }

  /// Helper: Generate random double in range
  double _randomDouble(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  /// Check if simulation is active for animal
  bool isSimulationActive(String animalId) {
    return _activeSimulations.containsKey(animalId);
  }

  /// Get active simulation count
  int get activeSimulationCount => _activeSimulations.length;
}

/// Animal Behavior Profile
class AnimalBehaviorProfile {
  final AnimalHealthCondition healthCondition;
  final DateTime createdAt;

  AnimalBehaviorProfile({
    required this.healthCondition,
  }) : createdAt = DateTime.now();
}

/// Animal Health Condition for Simulation
enum AnimalHealthCondition {
  healthy,
  mildLameness,
  severeLameness,
}

/// Simulated Movement Data (real-time, per interval)
class SimulatedMovementData {
  final String animalId;
  final DateTime timestamp;
  final int stepCount; // Steps in this interval
  final double activityMinutes; // Active time in interval
  final double restMinutes; // Rest time in interval
  final double averageSpeed; // meters per minute
  final int distanceCovered; // meters
  final double symmetryScore; // 0-1, gait symmetry
  final Map<String, dynamic> accelerometerData;
  final int heartRate; // beats per minute
  final double bodyTemperature; // celsius

  SimulatedMovementData({
    required this.animalId,
    required this.timestamp,
    required this.stepCount,
    required this.activityMinutes,
    required this.restMinutes,
    required this.averageSpeed,
    required this.distanceCovered,
    required this.symmetryScore,
    required this.accelerometerData,
    required this.heartRate,
    required this.bodyTemperature,
  });

  Map<String, dynamic> toJson() {
    return {
      'animal_id': animalId,
      'timestamp': timestamp.toIso8601String(),
      'step_count': stepCount,
      'activity_minutes': activityMinutes,
      'rest_minutes': restMinutes,
      'average_speed': averageSpeed,
      'distance_covered': distanceCovered,
      'symmetry_score': symmetryScore,
      'accelerometer_data': accelerometerData,
      'heart_rate': heartRate,
      'body_temperature': bodyTemperature,
    };
  }
}
