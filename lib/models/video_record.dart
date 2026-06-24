/// Video Record Model - Represents uploaded video records
class VideoRecord {
  final String id;
  final String animalId;
  final String videoUrl;
  final String? thumbnailUrl;
  final DateTime uploadDate;
  final int durationSeconds;
  final double fileSizeBytes;
  final String purpose; // Identification, Movement Analysis, Lameness Detection
  final String processingStatus; // Pending, Processing, Completed, Failed
  final DateTime timestamp;
  
  // Processing results
  final Map<String, dynamic>? analysisResults;
  final String? errorMessage;

  VideoRecord({
    required this.id,
    required this.animalId,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.uploadDate,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.purpose,
    required this.processingStatus,
    required this.timestamp,
    this.analysisResults,
    this.errorMessage,
  });

  /// Create VideoRecord from JSON
  factory VideoRecord.fromJson(Map<String, dynamic> json) {
    return VideoRecord(
      id: json['id'] as String,
      animalId: json['animal_id'] as String,
      videoUrl: json['video_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      uploadDate: DateTime.parse(json['upload_date'] as String),
      durationSeconds: json['duration_seconds'] as int,
      fileSizeBytes: (json['file_size_bytes'] as num).toDouble(),
      purpose: json['purpose'] as String,
      processingStatus: json['processing_status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      analysisResults: json['analysis_results'] as Map<String, dynamic>?,
      errorMessage: json['error_message'] as String?,
    );
  }

  /// Convert VideoRecord to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'animal_id': animalId,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'upload_date': uploadDate.toIso8601String(),
      'duration_seconds': durationSeconds,
      'file_size_bytes': fileSizeBytes,
      'purpose': purpose,
      'processing_status': processingStatus,
      'timestamp': timestamp.toIso8601String(),
      'analysis_results': analysisResults,
      'error_message': errorMessage,
    };
  }

  /// Create a copy with modified fields
  VideoRecord copyWith({
    String? id,
    String? animalId,
    String? videoUrl,
    String? thumbnailUrl,
    DateTime? uploadDate,
    int? durationSeconds,
    double? fileSizeBytes,
    String? purpose,
    String? processingStatus,
    DateTime? timestamp,
    Map<String, dynamic>? analysisResults,
    String? errorMessage,
  }) {
    return VideoRecord(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      uploadDate: uploadDate ?? this.uploadDate,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      purpose: purpose ?? this.purpose,
      processingStatus: processingStatus ?? this.processingStatus,
      timestamp: timestamp ?? this.timestamp,
      analysisResults: analysisResults ?? this.analysisResults,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Check if processing is complete
  bool get isProcessed => processingStatus == 'Completed';

  /// Check if processing failed
  bool get hasFailed => processingStatus == 'Failed';

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSizeBytes < 1024) {
      return '${fileSizeBytes.toStringAsFixed(0)} B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(2)} KB';
    } else if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  @override
  String toString() {
    return 'VideoRecord{id: $id, animalId: $animalId, purpose: $purpose, status: $processingStatus}';
  }
}
