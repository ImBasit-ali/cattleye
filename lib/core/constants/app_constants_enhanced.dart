/// Enhanced App Constants - AI-Powered Cattle Health Monitoring System
/// Based on Research: Multi-camera, Multi-zone Intelligent Monitoring
class AppConstants {
  // App Info
  static const String appName = 'CattleEye';
  static const String appVersion = '1.0.0';
  static const String appSubtitle = 'AI-Powered Health Monitoring System';

  // Firebase Configuration (used for authentication and database)
  // See firebase_options.dart for platform-specific configuration

  // Storage Buckets (Firebase Storage)
  static const String animalImagesBucket = 'animal-images';
  static const String videosBucket = 'videos';
  static const String mlModelsBucket = 'ml-models';
  static const String cameraBucket = 'camera-feeds';

  // Database Tables
  static const String animalsTable = 'animals';
  static const String movementDataTable = 'movement_data';
  static const String lamenessRecordsTable = 'lameness_records';
  static const String videoRecordsTable = 'video_records';
  static const String cameraFeedsTable = 'camera_feeds';
  static const String identificationRecordsTable = 'identification_records';
  static const String bcsRecordsTable = 'bcs_records';
  static const String feedingRecordsTable = 'feeding_records';
  static const String localizationRecordsTable = 'localization_records';

  // Camera System Configuration (Research-based: 22 cameras)
  static const int totalCameras = 22;
  static const double averageLatencyPerFrame = 0.62; // seconds

  // Camera Types (Multi-camera setup from research)
  static const String cameraTypeRGB = 'RGB';
  static const String cameraTypeRGBD = 'RGB-D';
  static const String cameraTypeToF = 'ToF Depth';

  // Functional Zones (4 zones from research)
  static const String zoneMilkingParlor = 'Milking Parlor';
  static const String zoneReturnLane = 'Return Lane';
  static const String zoneFeedingArea = 'Feeding Area';
  static const String zoneRestingSpace = 'Resting Space';

  static const List<String> functionalZones = [
    zoneMilkingParlor,
    zoneReturnLane,
    zoneFeedingArea,
    zoneRestingSpace,
  ];

  // Cattle Identification Methods (from research)
  static const String identificationEarTag = 'Ear Tag';
  static const String identificationFace = 'Face-based';
  static const String identificationBody = 'Body-based';
  static const String identificationBodyColor = 'Body-Color Point Cloud';

  // AI Model Accuracies (from research paper)
  static const double earTagAccuracy = 94.00;
  static const double faceBasedAccuracy = 93.66;
  static const double bodyBasedAccuracy = 92.80;
  static const double bodyColorAccuracy = 99.55;
  static const double bcsAccuracy = 86.21;
  static const double lamenessAccuracy = 88.88;

  // Animal Species
  static const List<String> animalSpecies = ['Cow', 'Buffalo', 'Dairy Cattle'];

  // Health Status
  static const List<String> healthStatuses = [
    'Healthy',
    'Under Observation',
    'Sick',
    'Critical',
  ];

  // Body Condition Score (BCS) Levels (1-5 scale)
  static const List<double> bcsLevels = [
    1.0,
    1.5,
    2.0,
    2.5,
    3.0,
    3.5,
    4.0,
    4.5,
    5.0,
  ];
  static const double bcsOptimal = 3.5;
  static const double bcsLow = 2.5;
  static const double bcsHigh = 4.5;

  // Lameness Severity Levels (from research)
  static const String lamenessNormal = 'Normal'; // Score 0-1
  static const String lamenessMild = 'Mild Lameness'; // Score 2-3
  static const String lamenessSevere = 'Severe Lameness'; // Score 4-5

  // Lameness Scores (0-5 scale used in research)
  static const List<int> lamenessScores = [0, 1, 2, 3, 4, 5];

  // Movement Thresholds
  static const int normalStepsPerDay = 3000;
  static const int lowActivityThreshold = 1500;
  static const double normalActivityDurationHours = 8.0;
  static const double lowActivityDurationHours = 4.0;

  // Feeding Time Estimation
  static const double averageFeedingTimeHours = 5.0;
  static const double minFeedingTimeHours = 2.0;
  static const double maxFeedingTimeHours = 8.0;

  // ML Model Constants
  static const String lamenessModelPath = 'assets/ml/lameness_model.tflite';
  static const String bcsModelPath = 'assets/ml/bcs_model.tflite';
  static const String faceRecognitionModelPath =
      'assets/ml/face_recognition_model.tflite';
  static const String bodyRecognitionModelPath =
      'assets/ml/body_recognition_model.tflite';
  static const int mlInputSize = 224; // Standard image input size
  static const double mlConfidenceThreshold = 0.7;

  // Camera Settings
  static const int videoMaxDurationSeconds = 60;
  static const double videoQuality = 0.8;
  static const int cameraFPS = 30;
  static const String videoResolution = '1920x1080';

  // Real-time Processing
  static const int maxProcessingThreads = 4; // Multiprocessing support
  static const bool enableEdgeComputing = true;
  static const int dataBufferSize = 100; // frames

  // Chart Settings
  static const int chartDaysToShow = 7;
  static const int chartDataPointsPerDay = 24;
  static const int chartMonthsToShow = 3; // 3 months as per dashboard

  // Animation Durations
  static const int shortAnimationMs = 200;
  static const int mediumAnimationMs = 400;
  static const int longAnimationMs = 600;

  // Pagination
  static const int itemsPerPage = 20;

  // IoT Simulation Settings
  static const int simulationIntervalSeconds = 5;
  static const int simulationDataRetentionDays = 30;

  // System Monitoring
  static const int systemHealthCheckIntervalMinutes = 5;
  static const double maxAllowedLatency = 1.0; // seconds
  static const int continuousOperationHours = 24; // 24-hour operation

  // Green & Digital Transformation (GX/DX) Features
  static const bool enableSustainabilityMetrics = true;
  static const bool enableSmartFarmingDashboard = true;
  static const bool enableVeterinaryAlerts = true;

  // API Configuration
  static const String apiBaseUrl = 'https://api.cattleai.com/v1';
  static const int apiTimeout = 30; // seconds
  static const bool useRestfulAPI = true;

  // Database Configuration (Firebase Realtime Database)
  static const bool enableRealtimeSync = true;
  static const int maxDatabaseConnections = 10;

  // Clean Architecture Layers
  static const bool useCleanArchitecture = true;
  static const bool separateDomainLayer = true;
  static const bool useRepositoryPattern = true;

  // Notification Types
  static const String notificationHealth = 'Health Alert';
  static const String notificationLameness = 'Lameness Detected';
  static const String notificationFeeding = 'Feeding Alert';
  static const String notificationLocation = 'Location Alert';
  static const String notificationBCS = 'BCS Alert';

  // Camera View Types (from research images)
  static const String cameraViewEarTag = 'EarTag Camera';
  static const String cameraViewEating = 'Eating Camera';
  static const String cameraViewResting = 'Resting Camera';
  static const String cameraViewDepth = 'Depth Camera';
  static const String cameraViewHead = 'Head View Camera';
  static const String cameraViewBack = 'Back View Camera';
  static const String cameraViewSide = 'Side View Camera';
  static const String cameraViewRGBD = 'RGB-D Camera';

  // Data Collection Intervals
  static const int bcsCheckIntervalDays = 7; // Weekly BCS monitoring
  static const int lamenessCheckIntervalDays = 1; // Daily lameness check
  static const int feedingCheckIntervalHours = 1; // Hourly feeding tracking
  static const int locationUpdateIntervalSeconds = 10; // Real-time localization

  // Performance Metrics
  static const String metricAccuracy = 'Accuracy';
  static const String metricLatency = 'Latency';
  static const String metricThroughput = 'Throughput';
  static const String metricUptime = 'Uptime';

  // Export Formats
  static const String exportFormatPDF = 'PDF';
  static const String exportFormatCSV = 'CSV';
  static const String exportFormatJSON = 'JSON';
  static const String exportFormatExcel = 'Excel';
}
