import 'dart:convert';
import 'dart:typed_data';
import 'cattle_analysis_result.dart';

enum CameraStreamType { mjpeg, snapshot, rtsp }

enum CameraConnectionState { disconnected, connecting, connected, error }

class CameraModel {
  final String id;
  final String name;
  final String streamUrl;
  final String snapshotUrl;
  final String cameraType; // RGB | RGB-D | ToF Depth
  final String functionalZone;
  final bool isActive;
  final DateTime createdAt;

  // Runtime state — not persisted to disk
  CameraConnectionState connectionState;
  Uint8List? currentFrame;
  CattleAnalysisResult? lastAnalysis;
  DateTime? lastFrameTime;
  DateTime? lastAnalysisTime;
  String? errorMessage;
  int frameCount;

  CameraModel({
    required this.id,
    required this.name,
    required this.streamUrl,
    String? snapshotUrl,
    this.cameraType = 'RGB',
    this.functionalZone = 'Feeding Area',
    this.isActive = true,
    DateTime? createdAt,
    this.connectionState = CameraConnectionState.disconnected,
    this.currentFrame,
    this.lastAnalysis,
    this.lastFrameTime,
    this.lastAnalysisTime,
    this.errorMessage,
    this.frameCount = 0,
  })  : snapshotUrl = snapshotUrl ?? streamUrl,
        createdAt = createdAt ?? DateTime.now();

  /// Infer stream type from URL
  CameraStreamType get streamType {
    final url = streamUrl.toLowerCase();
    if (url.startsWith('rtsp://')) return CameraStreamType.rtsp;
    if (url.contains('.mjpg') ||
        url.contains('mjpeg') ||
        url.contains('video.cgi')) {
      return CameraStreamType.mjpeg;
    }
    return CameraStreamType.snapshot;
  }

  bool get isConnected => connectionState == CameraConnectionState.connected;

  bool get hasFrame => currentFrame != null && currentFrame!.isNotEmpty;

  bool get needsAnalysis {
    if (lastAnalysisTime == null) return true;
    return DateTime.now().difference(lastAnalysisTime!) >
        const Duration(seconds: 30);
  }

  CameraModel copyWith({
    String? name,
    String? streamUrl,
    String? snapshotUrl,
    String? cameraType,
    String? functionalZone,
    bool? isActive,
    CameraConnectionState? connectionState,
    Uint8List? currentFrame,
    CattleAnalysisResult? lastAnalysis,
    DateTime? lastFrameTime,
    DateTime? lastAnalysisTime,
    String? errorMessage,
    int? frameCount,
  }) {
    return CameraModel(
      id: id,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      snapshotUrl: snapshotUrl ?? this.snapshotUrl,
      cameraType: cameraType ?? this.cameraType,
      functionalZone: functionalZone ?? this.functionalZone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      connectionState: connectionState ?? this.connectionState,
      currentFrame: currentFrame ?? this.currentFrame,
      lastAnalysis: lastAnalysis ?? this.lastAnalysis,
      lastFrameTime: lastFrameTime ?? this.lastFrameTime,
      lastAnalysisTime: lastAnalysisTime ?? this.lastAnalysisTime,
      errorMessage: errorMessage ?? this.errorMessage,
      frameCount: frameCount ?? this.frameCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'streamUrl': streamUrl,
        'snapshotUrl': snapshotUrl,
        'cameraType': cameraType,
        'functionalZone': functionalZone,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CameraModel.fromJson(Map<String, dynamic> j) => CameraModel(
        id: j['id'] as String,
        name: j['name'] as String,
        streamUrl: j['streamUrl'] as String,
        snapshotUrl: j['snapshotUrl'] as String?,
        cameraType: j['cameraType'] as String? ?? 'RGB',
        functionalZone: j['functionalZone'] as String? ?? 'Feeding Area',
        isActive: j['isActive'] as bool? ?? true,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  String toJsonString() => jsonEncode(toJson());

  factory CameraModel.fromJsonString(String s) =>
      CameraModel.fromJson(jsonDecode(s) as Map<String, dynamic>);

  static const List<String> cameraTypes = ['RGB', 'RGB-D', 'ToF Depth'];
  static const List<String> functionalZones = [
    'Milking Parlor',
    'Return Lane',
    'Feeding Area',
    'Resting Space',
  ];
}
