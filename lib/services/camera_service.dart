import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/camera_model.dart';

/// Handles IP camera connections: MJPEG streaming and snapshot polling.
/// Each camera gets its own stream controller and polling timer.
class CameraService {
  static final CameraService _instance = CameraService._();
  factory CameraService() => _instance;
  CameraService._();

  final Map<String, StreamController<Uint8List>> _frameControllers = {};
  final Map<String, Timer> _snapshotTimers = {};
  final Map<String, StreamSubscription<List<int>>> _mjpegSubscriptions = {};
  final Map<String, http.Client> _httpClients = {};

  // ── Public API ────────────────────────────────────────────────────────────

  /// Start streaming frames for a camera. Returns a Stream of JPEG byte frames.
  Stream<Uint8List> startStream(CameraModel camera) {
    stopStream(camera.id);

    final controller = StreamController<Uint8List>.broadcast();
    _frameControllers[camera.id] = controller;

    switch (camera.streamType) {
      case CameraStreamType.mjpeg:
        _startMjpegStream(camera, controller);
      case CameraStreamType.snapshot:
      case CameraStreamType.rtsp:
        // RTSP is handled via snapshot polling fallback
        _startSnapshotPolling(camera, controller);
    }

    return controller.stream;
  }

  /// Stop streaming for a camera and release all resources.
  void stopStream(String cameraId) {
    _snapshotTimers[cameraId]?.cancel();
    _snapshotTimers.remove(cameraId);

    _mjpegSubscriptions[cameraId]?.cancel();
    _mjpegSubscriptions.remove(cameraId);

    _httpClients[cameraId]?.close();
    _httpClients.remove(cameraId);

    _frameControllers[cameraId]?.close();
    _frameControllers.remove(cameraId);
  }

  void stopAll() {
    for (final id in List<String>.from(_frameControllers.keys)) {
      stopStream(id);
    }
  }

  /// Fetch a single JPEG snapshot from a camera URL.
  /// Returns null on failure.
  Future<Uint8List?> fetchSnapshot(String url) async {
    try {
      final client = http.Client();
      try {
        final response = await client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          // Validate it looks like a JPEG (SOI marker FF D8)
          final bytes = response.bodyBytes;
          if (bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
            return bytes;
          }
          // Return anyway if it has content (could be PNG or other format)
          if (bytes.length > 100) return bytes;
        }
        return null;
      } finally {
        client.close();
      }
    } catch (_) {
      return null;
    }
  }

  // ── MJPEG stream reader ───────────────────────────────────────────────────

  void _startMjpegStream(
      CameraModel camera, StreamController<Uint8List> controller) async {
    final client = http.Client();
    _httpClients[camera.id] = client;

    try {
      final request = http.Request('GET', Uri.parse(camera.streamUrl));
      request.headers['Connection'] = 'keep-alive';

      final response =
          await client.send(request).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        controller.addError('Camera returned ${response.statusCode}');
        _startSnapshotPolling(camera, controller);
        return;
      }

      final buffer = <int>[];

      final sub = response.stream.listen(
        (chunk) {
          buffer.addAll(chunk);
          // Extract complete JPEG frames by scanning for SOI/EOI markers
          while (true) {
            final soiIdx = _findBytes(buffer, [0xFF, 0xD8]);
            if (soiIdx == -1) {
              // No SOI found — keep last 3 bytes in case marker is split
              if (buffer.length > 3) buffer.removeRange(0, buffer.length - 3);
              break;
            }
            final eoiIdx = _findBytes(buffer, [0xFF, 0xD9], start: soiIdx + 2);
            if (eoiIdx == -1) break;

            final frame = Uint8List.fromList(
                buffer.sublist(soiIdx, eoiIdx + 2));
            if (!controller.isClosed) controller.add(frame);
            buffer.removeRange(0, eoiIdx + 2);
          }

          // Prevent unbounded buffer growth
          if (buffer.length > AppConfig.mjpegBufferSize * 4) {
            buffer.removeRange(0, buffer.length - AppConfig.mjpegBufferSize);
          }
        },
        onError: (e) {
          if (!controller.isClosed) {
            controller.addError('MJPEG stream error: $e');
          }
          // Fallback to snapshot polling
          _startSnapshotPolling(camera, controller);
        },
        onDone: () {
          if (!controller.isClosed) {
            _startSnapshotPolling(camera, controller);
          }
        },
        cancelOnError: true,
      );

      _mjpegSubscriptions[camera.id] = sub;
    } catch (e) {
      if (!controller.isClosed) controller.addError('Cannot connect: $e');
      _startSnapshotPolling(camera, controller);
    }
  }

  // ── Snapshot polling ──────────────────────────────────────────────────────

  void _startSnapshotPolling(
      CameraModel camera, StreamController<Uint8List> controller) {
    _snapshotTimers[camera.id]?.cancel();

    void poll() async {
      if (controller.isClosed) return;
      final frame = await fetchSnapshot(camera.snapshotUrl);
      if (frame != null && !controller.isClosed) {
        controller.add(frame);
      }
    }

    // Immediate first poll
    poll();
    _snapshotTimers[camera.id] = Timer.periodic(
      AppConfig.snapshotInterval,
      (_) => poll(),
    );
  }

  // ── Byte pattern search ───────────────────────────────────────────────────

  int _findBytes(List<int> buffer, List<int> pattern, {int start = 0}) {
    for (int i = start; i <= buffer.length - pattern.length; i++) {
      bool found = true;
      for (int j = 0; j < pattern.length; j++) {
        if (buffer[i + j] != pattern[j]) {
          found = false;
          break;
        }
      }
      if (found) return i;
    }
    return -1;
  }
}
